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

  const commandPreview = page.locator(".repl-command-preview");
  await expect(commandPreview).toContainText('quone::compile("mean.Q")');

  await page.getByRole("button", { name: "Run R" }).click();

  await expect(page.locator(".repl-output")).toBeVisible();
  await expect(page.getByText("mean <- function(xs) {")).toBeVisible();
  await expect(commandPreview).toContainText('quone::compile("mean.Q")');
  await expect(page.getByRole("tab", { name: "mean.Q" })).toHaveAttribute(
    "aria-selected",
    "true",
  );
});

test("desktop shows all six snippet tabs", async ({ page, isMobile }) => {
  test.skip(isMobile, "Desktop-only check");

  await page.goto("/");

  await expect(page.getByRole("tab")).toHaveCount(6);
  await expect(page.getByRole("tab", { name: "site_rollup.Q" })).toBeVisible();
});

test("the preview command stays visible before and after a run", async ({ page }) => {
  await page.goto("/");

  const commandPreview = page.locator(".repl-command-preview");
  await expect(commandPreview).toContainText('quone::compile("mean.Q")');

  await page.getByRole("button", { name: "Run R" }).click();

  await expect(page.locator(".repl-output")).toContainText("mean <- function");
  await expect(commandPreview).toContainText('quone::compile("mean.Q")');
});

test("submitting builds up scrollback rows", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "Run R" }).click();

  await expect(page.locator(".repl-history")).toBeVisible();
  await expect(page.locator(".repl-output")).toBeVisible();
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
  await expect(demoNote).toContainText(/demo/i);

  const commandPreview = repl.locator(".repl-command-preview");
  await expect(commandPreview).toContainText('quone::compile("mean.Q")');
  await expect(page.getByLabel("R prompt input")).toHaveCount(0);

  await page.getByRole("button", { name: "Run R" }).click();
  await expect(repl.locator(".repl-history")).toBeVisible();
  await expect(repl.locator(".repl-history")).toContainText(
    'quone::compile("mean.Q")',
  );
});

test("multiple runs accumulate as scrollback like a real REPL", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("button", { name: "Run R" }).click();
  await expect(page.locator(".repl-history")).toHaveCount(1);

  await page.getByRole("button", { name: "Run R" }).click();

  await expect(page.locator(".repl-history")).toHaveCount(2);
  await expect(page.locator(".repl-history").nth(0)).toContainText(
    'quone::compile("mean.Q")',
  );
  await expect(page.locator(".repl-history").nth(1)).toContainText(
    'quone::compile("mean.Q")',
  );
  await expect(page.locator(".repl-output").nth(1)).toContainText("mean <- function");
});

test("clicking a snippet tab resets the REPL to that file's compile() call", async ({
  page,
}) => {
  await page.goto("/");

  await page.getByRole("button", { name: "Run R" }).click();
  await expect(page.locator(".repl-history")).toHaveCount(1);

  await page.getByRole("tab", { name: "rmse.Q" }).click();

  await expect(page.locator(".repl-history")).toHaveCount(0);
  await expect(page.locator(".repl-output")).toHaveCount(0);
  await expect(page.locator(".repl-error")).toHaveCount(0);
  await expect(page.locator(".repl-command-preview")).toContainText(
    'quone::compile("rmse.Q")',
  );
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
  await expect(page.getByText("mean <- function(xs) {")).toBeVisible();

  await menuButton.click();
  await expect(page.getByRole("button", { name: "Close" })).toHaveAttribute(
    "aria-expanded",
    "true",
  );
  await expect(page.getByRole("link", { name: "Install", exact: true })).toBeVisible();
});

test("mobile only shows the first three snippet tabs", async ({ page, isMobile }) => {
  test.skip(!isMobile, "Mobile-only check");

  await page.goto("/");

  await expect(page.getByRole("tab")).toHaveCount(3);
  await expect(page.getByRole("tab", { name: "mean.Q" })).toBeVisible();
  await expect(page.getByRole("tab", { name: "rmse.Q" })).toBeVisible();
  await expect(page.getByRole("tab", { name: "top_scores.Q" })).toBeVisible();
  await expect(page.getByRole("tab", { name: "score_bands.Q" })).toHaveCount(0);
  await expect(page.getByRole("tab", { name: "adsl_summary.Q" })).toHaveCount(0);
  await expect(page.getByRole("tab", { name: "site_rollup.Q" })).toHaveCount(0);
});
