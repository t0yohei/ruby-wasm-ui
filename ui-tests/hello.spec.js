import { test, expect } from "@playwright/test";

test.describe("Hello Example", () => {
  test("should display hello world content", async ({ page }) => {
    // Navigate to the hello example
    await page.goto("/examples/hello/index.html?env=DEV");

    // Wait for Ruby WASM to load and initialize
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("Hello World");

    // Check the main heading (first h1 in body)
    await expect(page.locator("body > h1")).toHaveText("Hello World");

    // Check that the h1-b div contains the "Hello, world!" text
    await expect(page.locator("#h1-b h1")).toHaveText("Hello, world!");

    // Verify that h1-b element has the expected classes and styles
    const h1BElement = page.locator("#h1-b");
    await expect(h1BElement).toHaveClass(/bg-red-500/);
    await expect(h1BElement).toHaveAttribute("data-test", "test");

    // Check the inline style for background color
    const computedStyle = await h1BElement.evaluate(
      (el) => getComputedStyle(el).backgroundColor
    );
    expect(computedStyle).toBe("rgb(0, 0, 255)"); // blue color
  });

  test("should handle click events on h1-b element", async ({ page }) => {
    await page.goto("/examples/hello/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Set up console listener to capture click events
    const consoleMessages = [];
    page.on("console", (msg) => {
      if (msg.type() === "log") {
        consoleMessages.push(msg.text());
      }
    });

    // Click on the h1-b element
    await page.locator("#h1-b").click();

    // Wait a bit for the console log to appear
    await page.waitForTimeout(500);

    // Verify that the click event was logged (may have newline)
    const hasClickedMessage = consoleMessages.some((msg) =>
      msg.includes("clicked")
    );
    expect(hasClickedMessage).toBe(true);
  });
});
