#!/usr/bin/env node
/* Render the Quone social card to static/social-card-share-20260425.png.
 *
 * The card is built from src/SocialCard.elm so it shares the same
 * theme, font stack, and code highlighter as the marketing site
 * itself. This script compiles that Elm program with the same Elm
 * binary the production build uses, mounts it on a temporary HTML
 * page sized exactly 1200x630, then asks Playwright/Chromium to
 * snapshot the page.
 *
 * Run with:  node scripts/render-social-card.cjs
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");
const { chromium } = require("playwright");

const ROOT = path.resolve(__dirname, "..");
const STATIC = path.join(ROOT, "static");
const FONTS = path.join(STATIC, "fonts");
const SOCIAL_CARD_FILENAME = "social-card-share-20260425.png";
const PNG_PATH = path.join(STATIC, SOCIAL_CARD_FILENAME);
const LEGACY_PNG_PATH = path.join(STATIC, "social-card-share.png");
const ELM_BIN = path.join(ROOT, "node_modules", ".bin", "elm");

function ensureElm() {
  if (!fs.existsSync(ELM_BIN)) {
    console.log("Installing Elm 0.19.1 into node_modules...");
    const npmResult = spawnSync(
      "npm",
      ["install", "--no-save", "elm@0.19.1-5"],
      { cwd: ROOT, stdio: "inherit" }
    );
    if (npmResult.status !== 0) {
      throw new Error("Failed to install Elm");
    }
  }
}

function compileElm(outFile) {
  console.log("Compiling SocialCard.elm...");
  const elmResult = spawnSync(
    ELM_BIN,
    ["make", "src/SocialCard.elm", "--optimize", `--output=${outFile}`],
    { cwd: ROOT, stdio: "inherit" }
  );
  if (elmResult.status !== 0) {
    throw new Error("Elm compilation failed");
  }
}

function readFontDataUri(filename, mime) {
  const buf = fs.readFileSync(path.join(FONTS, filename));
  return `data:${mime};base64,${buf.toString("base64")}`;
}

function buildHostHtml(elmJs) {
  const inter = readFontDataUri("Inter.woff2", "font/woff2");
  const grotesk = readFontDataUri("SpaceGrotesk.woff2", "font/woff2");
  const mono = readFontDataUri("JetBrainsMono.woff2", "font/woff2");
  const bitcount = readFontDataUri("BitcountGridDouble.woff", "font/woff");

  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <style>
      @font-face {
        font-family: "Inter";
        src: url("${inter}") format("woff2");
        font-weight: 400 700;
        font-display: block;
      }
      @font-face {
        font-family: "Space Grotesk";
        src: url("${grotesk}") format("woff2");
        font-weight: 500 700;
        font-display: block;
      }
      @font-face {
        font-family: "JetBrains Mono";
        src: url("${mono}") format("woff2");
        font-weight: 400 600;
        font-display: block;
      }
      @font-face {
        font-family: "Bitcount Grid Double";
        src: url("${bitcount}") format("woff");
        font-weight: 400;
        font-display: block;
      }
      html, body {
        margin: 0;
        padding: 0;
        width: 1200px;
        height: 630px;
        background: #000000;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
        font-family:
          "Inter", system-ui, -apple-system, "Segoe UI",
          Roboto, "Helvetica Neue", Arial, sans-serif;
      }
      #root, .elm-app {
        width: 1200px;
        height: 630px;
      }
    </style>
  </head>
  <body>
    <div id="root"></div>
    <script>
${elmJs}
    </script>
    <script>
      Elm.SocialCard.init({ node: document.getElementById("root") });
    </script>
  </body>
</html>`;
}

async function render(html) {
  console.log("Launching Chromium...");
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 1200, height: 630 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();

  page.on("pageerror", (err) => console.log("  [browser:error]", err.message));

  await page.setContent(html, { waitUntil: "load" });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForFunction(
    () => document.body.querySelector(".s") !== null,
    { timeout: 10000 }
  );
  await page.waitForTimeout(400);

  await page.screenshot({
    path: PNG_PATH,
    type: "png",
    omitBackground: false,
    clip: { x: 0, y: 0, width: 1200, height: 630 },
  });

  await browser.close();
  fs.copyFileSync(PNG_PATH, LEGACY_PNG_PATH);
  console.log(`Wrote ${path.relative(ROOT, PNG_PATH)}`);
  console.log(`Updated ${path.relative(ROOT, LEGACY_PNG_PATH)} for local previews`);
}

async function main() {
  ensureElm();

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "quone-social-"));
  const elmOut = path.join(tmpDir, "social-card.js");

  try {
    compileElm(elmOut);
    const elmJs = fs.readFileSync(elmOut, "utf8");
    const html = buildHostHtml(elmJs);
    await render(html);
  } finally {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
