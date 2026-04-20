const { test, expect } = require("@playwright/test");

test("home page renders the hero preview shell", async ({ page, context }) => {
  await context.grantPermissions(["clipboard-write"], {
    origin: "http://127.0.0.1:4173",
  });

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
  expect(replBox?.height ?? 0).toBeGreaterThan(120);

  const copyButton = page.getByRole("button", { name: "Copy quone code" });
  await expect(copyButton).toBeVisible();
  await copyButton.click();
  await expect(copyButton).toHaveText("Copied");

  await page.getByRole("button", { name: "Preview generated R output" }).click();
  await expect(page.getByText("normalize <- function(max_score, raw) {")).toBeVisible();
});

test("preview output expands to fit the generated R", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "Preview generated R output" }).click();

  const output = page.locator(".repl-output");
  await expect(output).toBeVisible();

  await expect(async () => {
    const box = await output.boundingBox();
    expect(box?.height ?? 0).toBeGreaterThan(40);
  }).toPass();
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
  expect(replBox?.height ?? 0).toBeGreaterThan(140);

  await page.getByRole("button", { name: "Preview generated R output" }).click();
  await expect(page.getByText("normalize <- function(max_score, raw) {")).toBeVisible();

  await menuButton.click();
  await expect(page.getByRole("button", { name: "Close" })).toHaveAttribute(
    "aria-expanded",
    "true",
  );
  await expect(page.getByRole("link", { name: "Install", exact: true })).toBeVisible();
});
