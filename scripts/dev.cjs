const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const chokidar = require("chokidar");

const rootDir = path.join(__dirname, "..");
const distDir = path.join(rootDir, "dist");
const staticDir = path.join(rootDir, "static");
const elmEntrypoint = path.join(rootDir, "src", "Main.elm");
const elmBinary = path.join(rootDir, "node_modules", ".bin", "elm");
const port = Number(process.env.PORT || 4174);
const reloadClients = new Set();

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".txt": "text/plain; charset=utf-8",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".xml": "application/xml; charset=utf-8",
};

const liveReloadSnippet = `
<script>
  (function () {
    var source = new EventSource("/__dev_reload");
    source.addEventListener("reload", function () {
      window.location.reload();
    });
    source.addEventListener("build-error", function (event) {
      try {
        var payload = JSON.parse(event.data);
        console.error("[quone dev] Build failed. Fix the error and save again.");
        if (payload && payload.message) {
          console.error(payload.message);
        }
      } catch (_) {
        console.error("[quone dev] Build failed.");
      }
    });
  })();
</script>
`;

let server;
let watcher;
let buildTimer = null;
let buildRunning = false;
let buildPending = false;
let hasBuiltOnce = false;

function safePathname(rawPathname) {
  const pathname = decodeURIComponent(rawPathname);
  const relativePath = pathname === "/" ? "index.html" : pathname.slice(1);
  const resolvedPath = path.resolve(distDir, relativePath);

  if (!resolvedPath.startsWith(distDir)) {
    return null;
  }

  return resolvedPath;
}

function injectLiveReload(html) {
  if (html.includes("/__dev_reload")) {
    return html;
  }

  if (html.includes("</body>")) {
    return html.replace("</body>", `${liveReloadSnippet}\n  </body>`);
  }

  return `${html}\n${liveReloadSnippet}`;
}

function sendText(res, statusCode, body, contentType) {
  res.writeHead(statusCode, { "Content-Type": contentType });
  res.end(body);
}

function sendFile(req, res, filePath) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      sendText(res, 500, "Internal Server Error", "text/plain; charset=utf-8");
      return;
    }

    const ext = path.extname(filePath);
    const contentType = contentTypes[ext] || "application/octet-stream";

    if (ext === ".html") {
      const html = injectLiveReload(data.toString("utf8"));
      res.writeHead(200, { "Content-Type": contentType });

      if (req.method === "HEAD") {
        res.end();
        return;
      }

      res.end(html);
      return;
    }

    res.writeHead(200, { "Content-Type": contentType });

    if (req.method === "HEAD") {
      res.end();
      return;
    }

    res.end(data);
  });
}

function handleReloadStream(_req, res) {
  res.writeHead(200, {
    "Cache-Control": "no-cache, no-transform",
    Connection: "keep-alive",
    "Content-Type": "text/event-stream",
  });
  res.write("retry: 250\n\n");
  reloadClients.add(res);

  res.on("close", () => {
    reloadClients.delete(res);
  });
}

function broadcast(eventName, payload) {
  const body =
    payload === undefined
      ? `event: ${eventName}\ndata: {}\n\n`
      : `event: ${eventName}\ndata: ${JSON.stringify(payload)}\n\n`;

  for (const client of reloadClients) {
    client.write(body);
  }
}

function replacePlaceholders(indexPath, bundleName) {
  let html = fs.readFileSync(indexPath, "utf8");

  const bundlePlaceholder = "__ELM_BUNDLE__";
  if (!html.includes(bundlePlaceholder)) {
    throw new Error(`Missing ${bundlePlaceholder} in ${indexPath}`);
  }
  html = html.replace(bundlePlaceholder, bundleName);

  const fontsDir = path.join(distDir, "fonts");
  if (fs.existsSync(fontsDir)) {
    for (const fontFile of fs.readdirSync(fontsDir)) {
      const ext = path.extname(fontFile).toLowerCase();
      if (ext !== ".woff" && ext !== ".woff2") {
        continue;
      }

      const fontName = path.basename(fontFile, ext);
      const placeholder = `__FONT_${fontName.toUpperCase()}__`;

      if (!html.includes(placeholder)) {
        throw new Error(`Missing ${placeholder} in ${indexPath}`);
      }

      html = html.split(placeholder).join(fontFile);
    }
  }

  fs.writeFileSync(indexPath, html);
}

function ensureElmInstalled() {
  if (fs.existsSync(elmBinary)) {
    return;
  }

  console.log("[dev] Installing Elm 0.19.1...");
  const result = spawnSync("npm", ["install", "--no-save", "elm@0.19.1-5"], {
    cwd: rootDir,
    stdio: "inherit",
  });

  if (result.status !== 0) {
    throw new Error("Failed to install Elm.");
  }
}

function generateExamplesData() {
  const scriptPath = path.join(rootDir, "scripts", "generate_examples_data.py");
  if (!fs.existsSync(scriptPath)) {
    return;
  }

  const result = spawnSync("python3", [scriptPath], {
    cwd: rootDir,
    stdio: "inherit",
  });

  if (result.status !== 0) {
    throw new Error("generate_examples_data.py failed.");
  }
}

function compileElm() {
  const outputPath = path.join(distDir, "elm.js");
  const result = spawnSync(
    "npx",
    ["--no-install", "elm", "make", elmEntrypoint, "--output", outputPath],
    {
      cwd: rootDir,
      stdio: "inherit",
    },
  );

  if (result.status !== 0) {
    throw new Error("Elm compilation failed.");
  }
}

function buildSite(reason) {
  console.log(`[dev] Rebuilding (${reason})...`);
  ensureElmInstalled();

  fs.rmSync(distDir, { recursive: true, force: true });
  fs.mkdirSync(distDir, { recursive: true });
  fs.cpSync(staticDir, distDir, { recursive: true });
  generateExamplesData();
  compileElm();
  replacePlaceholders(path.join(distDir, "index.html"), "elm.js");
}

function runBuild(reason) {
  if (buildRunning) {
    buildPending = true;
    return;
  }

  buildRunning = true;

  try {
    buildSite(reason);

    if (hasBuiltOnce) {
      broadcast("reload");
    }

    hasBuiltOnce = true;
    console.log(`[dev] Ready at http://127.0.0.1:${port}`);
  } catch (error) {
    broadcast("build-error", { message: error.message });
    console.error(`[dev] ${error.message}`);
  } finally {
    buildRunning = false;

    if (buildPending) {
      buildPending = false;
      runBuild("queued change");
    }
  }
}

function scheduleBuild(reason) {
  if (buildTimer) {
    clearTimeout(buildTimer);
  }

  buildTimer = setTimeout(() => {
    buildTimer = null;
    runBuild(reason);
  }, 100);
}

function createServer() {
  server = http.createServer((req, res) => {
    if (!req.url) {
      sendText(res, 400, "Bad Request", "text/plain; charset=utf-8");
      return;
    }

    const requestUrl = new URL(req.url, `http://${req.headers.host || "127.0.0.1"}`);

    if (requestUrl.pathname === "/__dev_reload") {
      handleReloadStream(req, res);
      return;
    }

    const filePath = safePathname(requestUrl.pathname);

    if (!filePath) {
      sendText(res, 403, "Forbidden", "text/plain; charset=utf-8");
      return;
    }

    fs.stat(filePath, (err, stat) => {
      if (!err && stat.isFile()) {
        sendFile(req, res, filePath);
        return;
      }

      sendFile(req, res, path.join(distDir, "index.html"));
    });
  });

  server.listen(port, "127.0.0.1", () => {
    console.log(`[dev] Watching for changes on http://127.0.0.1:${port}`);
  });
}

function startWatcher() {
  const watchPaths = [
    path.join(rootDir, "elm.json"),
    path.join(rootDir, "src"),
    path.join(rootDir, "static"),
  ];
  const genScript = path.join(rootDir, "scripts", "generate_examples_data.py");
  if (fs.existsSync(genScript)) {
    watchPaths.push(path.join(rootDir, "snippets"));
    watchPaths.push(genScript);
  }

  watcher = chokidar.watch(watchPaths, {
    ignoreInitial: true,
  });

  watcher.on("all", (eventName, changedPath) => {
    const relativePath = path.relative(rootDir, changedPath);
    scheduleBuild(`${eventName} ${relativePath}`);
  });
}

function shutdown() {
  if (buildTimer) {
    clearTimeout(buildTimer);
    buildTimer = null;
  }

  if (watcher) {
    watcher.close();
  }

  for (const client of reloadClients) {
    client.end();
  }

  if (server) {
    server.close(() => process.exit(0));
    return;
  }

  process.exit(0);
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

runBuild("startup");
createServer();
startWatcher();
