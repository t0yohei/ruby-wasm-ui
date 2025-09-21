import { test, expect } from "@playwright/test";

test.describe("Counter Example", () => {
  test("should display counter with initial value of 10", async ({ page }) => {
    await page.goto("/examples/counter/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("Counter");

    // Check the main heading
    await expect(page.locator("h1")).toHaveText("Counter");

    // Check that app-b is mounted with initial count of 10
    await expect(page.locator("#app-b > div > div:first-child")).toHaveText(
      "10"
    );

    // Verify increment and decrement buttons are present
    await expect(page.locator("#app-b button").first()).toHaveText("Increment");
    await expect(page.locator("#app-b button").last()).toHaveText("Decrement");
  });

  test("should handle multiple increment and decrement operations", async ({
    page,
  }) => {
    await page.goto("/examples/counter/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const incrementBtn = page.locator("#app-b button").first();
    const decrementBtn = page.locator("#app-b button").last();
    const counterDisplay = page.locator("#app-b > div > div:first-child");

    // Initial value should be 10
    await expect(counterDisplay).toHaveText("10");

    // Increment 3 times
    await incrementBtn.click();
    await incrementBtn.click();
    await incrementBtn.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toHaveText("13");

    // Decrement 5 times
    await decrementBtn.click();
    await decrementBtn.click();
    await decrementBtn.click();
    await decrementBtn.click();
    await decrementBtn.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toHaveText("8");
  });
});
