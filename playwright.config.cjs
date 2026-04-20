const { defineConfig, devices } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./tests",
  fullyParallel: true,
  timeout: 30000,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:4173",
    trace: "retain-on-failure",
  },
  projects: [
    {
      name: "desktop-chromium",
      use: {
        ...devices["Desktop Chrome"],
      },
    },
    {
      name: "mobile-chromium",
      use: {
        ...devices["Pixel 7"],
      },
    },
    // The iOS bugs we keep regressing on (R-output collapse, hero
    // pushing horizontal scroll) only reproduce against the WebKit
    // engine -- mobile-chromium is Blink and won't catch them. This
    // project runs the same suite against an iPhone-shaped WebKit so
    // the regression class is locked down for real.
    {
      name: "mobile-webkit",
      use: {
        ...devices["iPhone 13"],
      },
    },
  ],
  webServer: {
    command: "npm run build && npm run serve:dist",
    url: "http://127.0.0.1:4173",
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
