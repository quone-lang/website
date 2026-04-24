const { test, expect } = require("@playwright/test");

test("single page advertises the initial release workflow", async ({ page }) => {
  await page.goto("/");

  await expect(
    page.getByRole("heading", { name: "Typed data pipelines that compile to R" }),
  ).toBeVisible();
  await expect(page.getByText("Validate CSV columns")).toBeVisible();
  await expect(page.getByText("Statically checked dplyr")).toBeVisible();
  await expect(page.getByText("explicit Maybe-based missingness")).toBeVisible();
});

test("getting started guide installs, writes, and compiles a demo", async ({ page }) => {
  await page.goto("/#install");

  await expect(
    page.getByRole("heading", {
      name: "Install Quone, write a demo file, and compile it.",
    }),
  ).toBeVisible();
  await expect(page.getByText('pak::pak("quone-lang/quone")')).toBeVisible();
  await expect(page.getByText("quone::install_lsp()")).toBeVisible();
  await expect(page.getByText('quone::write_demo()')).toBeVisible();
  await expect(page.getByText('quone::compile("mean_score.Q")')).toBeVisible();
  await expect(page.getByText('mean_score(c(10, 20, 30))')).toBeVisible();
  await expect(
    page.getByRole("link", { name: "R package details" }),
  ).toHaveAttribute("href", "https://github.com/quone-lang/quone");
});

test("single page keeps lean install and github navigation", async ({ page, isMobile }) => {
  await page.goto("/");

  if (isMobile) {
    await page.getByRole("button", { name: "Menu" }).click();
  }

  await expect(page.getByRole("link", { name: "Install", exact: true }).first()).toBeVisible();
  await expect(page.getByRole("link", { name: "GitHub", exact: true }).first()).toBeVisible();
  await expect(page.getByRole("link", { name: "Features", exact: true })).toHaveCount(0);
  await expect(page.getByRole("link", { name: "Spec", exact: true })).toHaveCount(0);
});

test("theme toggle works", async ({ page }) => {
  await page.goto("/");

  const toggle = page.getByRole("button", { name: /Switch to dark theme/i });
  await expect(toggle).toBeVisible();
  await toggle.click();
  await expect(
    page.getByRole("button", { name: /Switch to light theme/i }),
  ).toBeVisible();
});

