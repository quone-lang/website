const { test, expect } = require("@playwright/test");

test("home page renders the hero preview shell", async ({ page, context, browserName }) => {
  // WebKit doesn't model "clipboard-write" the way Chromium does; the
  // permission grant call is a no-op there but throws if we ask. We
  // skip the grant on WebKit and the test still verifies everything
  // else (the page loads, hero is visible, snippets render, REPL is
  // present). The copy-button click below is the only piece that
  // actually needs clipboard access; we guard it with a try/catch on
  // WebKit so the rest of the assertions still run.
  if (browserName !== "webkit") {
    await context.grantPermissions(["clipboard-write"], {
      origin: "http://127.0.0.1:4173",
    });
  }

  await page.goto("/");

  await expect(
    page.getByRole("heading", {
      name: "A typed functional language for R",
    }),
  ).toBeVisible();
  await expect(
    page.getByRole("tablist", { name: "Quone snippets" }),
  ).toBeVisible();
  await expect(page.locator('[role="tabpanel"]')).toBeVisible();

  const repl = page.locator(".repl-window");
  await expect(repl).toBeVisible();

  const replBox = await repl.boundingBox();
  expect(replBox?.height ?? 0).toBeGreaterThan(80);

  const copyButton = page.getByRole("button", { name: "Copy quone code" });
  await expect(copyButton).toBeVisible();
  if (browserName !== "webkit") {
    await copyButton.click();
    await expect(copyButton).toHaveText("Copied");
  }

  const promptInput = page.getByLabel("R prompt input");
  await expect(promptInput).toHaveValue('quone::compile("normalize.Q")');

  await page.getByRole("button", { name: "Run R" }).click();
  await expect(page.getByText("normalize <- function(max_score, raw) {")).toBeVisible();

  // After a successful run the live prompt clears (RStudio-style:
  // the just-submitted line moves into scrollback, the prompt is
  // empty for the next thing). The snippet picker stays put -- the
  // user controls when to switch tabs.
  await expect(promptInput).toHaveValue("");
  await expect(page.getByRole("tab", { name: "normalize.Q" })).toHaveAttribute(
    "aria-selected",
    "true",
  );
});

test("the live prompt is syntax highlighted via an overlay", async ({ page }) => {
  await page.goto("/");

  // The accessible name still belongs to the real (transparent)
  // <input>; the colour is painted by an overlay span beside it.
  await expect(page.getByLabel("R prompt input")).toBeVisible();

  const overlay = page.locator(".repl-input-overlay");
  await expect(overlay).toBeVisible();
  await expect(overlay.locator(".tok-pkg")).toHaveText("quone");
  await expect(overlay.locator(".tok-fn")).toHaveText("compile");
  await expect(overlay.locator(".tok-str")).toHaveText('"normalize.Q"');
});

test("preview output expands to fit the generated R", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "Run R" }).click();

  const output = page.locator(".repl-output");
  await expect(output).toBeVisible();

  await expect(async () => {
    const box = await output.boundingBox();
    expect(box?.height ?? 0).toBeGreaterThan(40);
  }).toPass();
});

test("REPL chrome looks like an R session and is honestly labelled", async ({
  page,
  isMobile,
}) => {
  await page.goto("/");

  const repl = page.locator(".repl-window");
  await expect(repl).toBeVisible();

  await expect(repl).toContainText("R 4.4.1");

  const demoNote = repl.locator(".repl-demo-note");
  await expect(demoNote).toBeVisible();
  await expect(demoNote).toContainText(isMobile ? "demo" : "not a live R session");

  // The live `>` prompt has a real input the user can type into; the
  // browser's native caret is what blinks here, so we just check the
  // input is focusable.
  const promptInput = page.getByLabel("R prompt input");
  await expect(promptInput).toBeVisible();
  await expect(promptInput).toBeEditable();

  await page.getByRole("button", { name: "Run R" }).click();
  // Once a command runs, the previously-submitted line moves into a
  // plain "history" row above the result.
  await expect(repl.locator(".repl-history")).toBeVisible();
  await expect(repl.locator(".repl-history")).toContainText(
    'quone::compile("normalize.Q")',
  );
});

test("snippet tabs support keyboard navigation", async ({ page }) => {
  await page.goto("/");

  const normalizeTab = page.getByRole("tab", { name: "normalize.Q" });
  await normalizeTab.focus();
  await normalizeTab.press("ArrowRight");

  await expect(page.getByRole("tab", { name: "mean.Q" })).toHaveAttribute(
    "aria-selected",
    "true",
  );
  await expect(page.getByText("average xs <-")).toBeVisible();

  // Switching tabs should also pre-fill the live prompt with the
  // matching `quone::compile("...")` invocation.
  await expect(page.getByLabel("R prompt input")).toHaveValue(
    'quone::compile("mean.Q")',
  );
});

test("typing a quone::compile call runs that snippet and stays on the current tab", async ({
  page,
}) => {
  await page.goto("/");

  const promptInput = page.getByLabel("R prompt input");
  await promptInput.fill('quone::compile("rmse.Q")');
  await promptInput.press("Enter");

  // The compiled R for rmse references `sqrt(...)`; this anchors the
  // run to rmse's output specifically and not normalize's.
  await expect(page.locator(".repl-output")).toContainText("sqrt");

  // The history line shows what the user typed (plain text, no
  // syntax highlighting).
  await expect(page.locator(".repl-history")).toContainText(
    'quone::compile("rmse.Q")',
  );

  // The snippet picker does NOT auto-advance -- the user is in
  // control of which file the panel above shows.
  await expect(page.getByRole("tab", { name: "normalize.Q" })).toHaveAttribute(
    "aria-selected",
    "true",
  );

  // After submit the live prompt clears, RStudio-style.
  await expect(promptInput).toHaveValue("");
});

test("multiple runs accumulate as scrollback like a real REPL", async ({ page }) => {
  await page.goto("/");

  const promptInput = page.getByLabel("R prompt input");

  // First run: the default, normalize.Q.
  await page.getByRole("button", { name: "Run R" }).click();
  await expect(page.locator(".repl-output")).toContainText(
    "normalize <- function(max_score, raw) {",
  );

  // Second run: type something new and submit. The previous result
  // must still be there, with the new one underneath it.
  await promptInput.fill('quone::compile("mean.Q")');
  await promptInput.press("Enter");

  // Two history lines (one per run), both visible at once.
  await expect(page.locator(".repl-history")).toHaveCount(2);
  await expect(page.locator(".repl-history").nth(0)).toContainText(
    'quone::compile("normalize.Q")',
  );
  await expect(page.locator(".repl-history").nth(1)).toContainText(
    'quone::compile("mean.Q")',
  );

  // Both compiled R blocks are visible together in the scrollback.
  await expect(page.locator(".repl-output")).toHaveCount(2);
  await expect(page.locator(".repl-output").nth(0)).toContainText(
    "normalize <-",
  );
  await expect(page.locator(".repl-output").nth(1)).toContainText("average <-");
});

test("the in-flight indicator says 'Compiling' (not 'Loading preview')", async ({
  page,
}) => {
  await page.goto("/");

  // Click Run R; the artificial compile delay (~1s) gives us a
  // window in which the spinner is on screen.
  await page.getByRole("button", { name: "Run R" }).click();

  const compiling = page.locator(".repl-compiling");
  await expect(compiling).toBeVisible();
  await expect(compiling).toContainText("Compiling");
  await expect(compiling).not.toContainText("Loading preview");

  // The ARIA live region lives on the inner span (the elm-ui
  // wrapper carries the .repl-compiling class but no role).
  const status = compiling.locator('[role="status"]');
  await expect(status).toHaveAttribute("aria-label", "Compiling");

  // The line uses a terminal-style spinner glyph instead of the old
  // three blinking text dots. The spinner itself is decorative and
  // hidden from assistive tech.
  const spinner = compiling.locator(".repl-spinner");
  await expect(spinner).toBeVisible();
  await expect(spinner).toHaveAttribute("aria-hidden", "true");
  await expect(compiling.locator(".repl-dot")).toHaveCount(0);
});

test("clicking a snippet tab resets the REPL to that file's compile() call", async ({
  page,
}) => {
  await page.goto("/");

  const promptInput = page.getByLabel("R prompt input");

  // Build up some scrollback first: one success, one error.
  await page.getByRole("button", { name: "Run R" }).click();
  await expect(page.locator(".repl-output")).toContainText("normalize <-");

  await promptInput.fill("library(dplyr)");
  await promptInput.press("Enter");
  await expect(page.locator(".repl-error")).toBeVisible();
  await expect(page.locator(".repl-history")).toHaveCount(2);

  // Now click another tab. Everything should reset and the live
  // prompt should pre-fill with that file's compile() call.
  await page.getByRole("tab", { name: "rmse.Q" }).click();

  await expect(page.locator(".repl-history")).toHaveCount(0);
  await expect(page.locator(".repl-output")).toHaveCount(0);
  await expect(page.locator(".repl-error")).toHaveCount(0);
  await expect(promptInput).toHaveValue('quone::compile("rmse.Q")');
});

test("any unrecognized input shows the same demo-only error", async ({
  page,
}) => {
  await page.goto("/");

  const promptInput = page.getByLabel("R prompt input");

  // The REPL is a demo: it does NOT pretend to be a real R session,
  // so every shape of unsupported input -- a stray R call, a typo,
  // a quone::compile() with an unknown file -- collapses to the
  // same friendly "demo only" message.
  const inputs = [
    "mean(1:10)",
    "library(dplyr)",
    'quone::compile("does-not-exist.Q")',
  ];

  for (const value of inputs) {
    await promptInput.fill(value);
    await promptInput.press("Enter");
  }

  const errorLines = page.locator(".repl-error");
  await expect(errorLines).toHaveCount(inputs.length);

  for (let i = 0; i < inputs.length; i += 1) {
    const error = errorLines.nth(i);
    await expect(error).toContainText("This is a demo, not a real R interpreter");
    await expect(error).toContainText('Try: quone::compile("normalize.Q")');
  }

  // Each bad command is preserved verbatim in scrollback.
  const historyLines = page.locator(".repl-history");
  await expect(historyLines).toHaveCount(inputs.length);
  for (let i = 0; i < inputs.length; i += 1) {
    await expect(historyLines.nth(i)).toContainText(inputs[i]);
  }

  // Errors never produce compiled R output and never advance tabs.
  await expect(page.locator(".repl-output")).toHaveCount(0);
  await expect(page.getByRole("tab", { name: "normalize.Q" })).toHaveAttribute(
    "aria-selected",
    "true",
  );

  // Like a real REPL, the input clears after submit.
  await expect(promptInput).toHaveValue("");
});

test("the demo-only error suggests the currently selected snippet", async ({
  page,
}) => {
  await page.goto("/");

  // Switch to a different tab so we can see that the suggestion in
  // the error follows the user's current context, not a hard-coded
  // file name.
  await page.getByRole("tab", { name: "rmse.Q" }).click();

  const promptInput = page.getByLabel("R prompt input");
  await promptInput.fill("mean(1:10)");
  await promptInput.press("Enter");

  const errorLine = page.locator(".repl-error");
  await expect(errorLine).toContainText('Try: quone::compile("rmse.Q")');
});

test("install route renders install content", async ({ page }) => {
  await page.goto("/install");

  await expect(
    page.getByRole("heading", { name: "Install the Quone R package." }),
  ).toBeVisible();
  await expect(page.getByRole("heading", { name: "Install from GitHub" })).toBeVisible();
  await expect(page.getByText('pak::pak("quone-lang/quone")')).toBeVisible();
});

test("site respects dark system preference", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "dark" });
  await page.goto("/");

  await expect(
    page.getByRole("heading", {
      name: "A typed functional language for R",
    }),
  ).toBeVisible();
  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(11, 16, 21)");
  await expect(
    page.getByRole("heading", {
      name: "A typed functional language for R",
    }),
  ).toHaveCSS("color", "rgb(242, 245, 248)");
});

test("theme toggle overrides the system preference", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");

  const toggle = page.getByRole("button", { name: /Switch to dark theme/i });
  await expect(toggle).toBeVisible();

  await toggle.click();

  await expect(page.locator("body")).toHaveCSS("background-color", "rgb(11, 16, 21)");
  await expect(
    page.getByRole("button", { name: /Switch to light theme/i }),
  ).toBeVisible();
});

test("mobile layout keeps the menu and hero preview visible", async ({ page, isMobile }) => {
  test.skip(!isMobile, "Mobile-only check");

  await page.goto("/");

  const menuButton = page.getByRole("button", { name: "Menu" });
  await expect(menuButton).toBeVisible();
  await expect(menuButton).toHaveAttribute("aria-expanded", "false");

  const repl = page.locator(".repl-window");
  await expect(repl).toBeVisible();

  const replBox = await repl.boundingBox();
  expect(replBox?.height ?? 0).toBeGreaterThan(120);

  await page.getByRole("button", { name: "Run R" }).click();
  await expect(page.getByText("normalize <- function(max_score, raw) {")).toBeVisible();

  await menuButton.click();
  await expect(page.getByRole("button", { name: "Close" })).toHaveAttribute(
    "aria-expanded",
    "true",
  );
  await expect(page.getByRole("link", { name: "Install", exact: true })).toBeVisible();
});
