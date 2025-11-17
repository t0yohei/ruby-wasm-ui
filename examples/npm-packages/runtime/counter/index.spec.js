import { test, expect } from "@playwright/test";

test.describe("Counter Example", () => {
  test("should display counter and handle increment/decrement operations", async ({
    page,
  }) => {
    await page.goto("/examples/npm-packages/runtime/counter/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("Counter");

    // Check the main heading
    await expect(page.locator("h1")).toHaveText("Counter");

    // Check that app-b is mounted with initial count of 10
    const counterDisplay = page.locator("#app-b > div > div:first-child");
    await expect(counterDisplay).toHaveText("10");

    // Verify increment and decrement buttons are present
    const incrementBtn = page.locator("#app-b button").first();
    const decrementBtn = page.locator("#app-b button").last();
    await expect(incrementBtn).toHaveText("Increment");
    await expect(decrementBtn).toHaveText("Decrement");

    // Test increment operations
    await incrementBtn.click();
    await incrementBtn.click();
    await incrementBtn.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toHaveText("13");

    // Test decrement operations
    await decrementBtn.click();
    await decrementBtn.click();
    await decrementBtn.click();
    await decrementBtn.click();
    await decrementBtn.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toHaveText("8");
  });
});
