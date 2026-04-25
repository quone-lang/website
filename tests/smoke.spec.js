const { test, expect } = require("@playwright/test");

test("single page advertises the typed dataframe workflow", async ({ page }) => {
  await page.goto("/");

  await expect(
    page.getByRole("heading", { name: "Typed data pipelines that compile to R" }),
  ).toBeVisible();
  await expect(page.getByText("decode CSVs into known shapes")).toBeVisible();
  await expect(page.getByText("Typed CSV schemas")).toBeVisible();
  await expect(page.getByText("Checked dataframe verbs")).toBeVisible();
  await expect(page.getByText("explicit Maybe-based missingness")).toBeVisible();
  await expect(page.getByText("Pre-release: APIs and syntax may change before 1.0.")).toBeVisible();
});

test("getting started guide installs and starts the guided setup", async ({ page }) => {
  await page.goto("/#install");

  await expect(
    page.getByRole("heading", {
      name: "Install from R and compile a .Q file.",
    }),
  ).toBeVisible();
  await expect(page.getByText('pak::pak("quone-lang/quone")')).toBeVisible();
  await expect(page.getByText("quone::start()")).toBeVisible();
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
  await expect(page.getByRole("link", { name: "Examples", exact: true }).first()).toHaveAttribute(
    "href",
    "https://github.com/quone-lang/examples",
  );
  await expect(page.getByRole("link", { name: "GitHub", exact: true }).first()).toHaveAttribute(
    "href",
    "https://github.com/quone-lang",
  );
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

