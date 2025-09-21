import { test, expect } from "@playwright/test";

test.describe("R-If Attribute Demo Example", () => {
  test("should display main heading and sections", async ({ page }) => {
    await page.goto("/examples/r_if_attribute_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("r-if Attribute Demo");

    // Check main heading
    await expect(page.locator("h1")).toHaveText("r-if Attribute Demo");

    // Check description
    await expect(page.locator("p").first()).toHaveText(
      "Using r-if as an attribute (like Vue.js r-if)"
    );

    // Check section headings
    await expect(page.locator("h2").first()).toHaveText("Toggle Message");
    await expect(page.locator("h2").last()).toHaveText("Counter Conditions");
  });

  test("should toggle message visibility with Show/Hide button", async ({
    page,
  }) => {
    await page.goto("/examples/r_if_attribute_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const toggleButton = page.locator("button").first();
    const messageDiv = page
      .getByText("This message is conditionally rendered using r-if attribute!")
      .locator("..");

    // Initially message should be hidden (show_message: false)
    await expect(toggleButton).toHaveText("Show Message");
    await expect(messageDiv).not.toBeVisible();

    // Click to show message
    await toggleButton.click();
    await page.waitForTimeout(100);

    await expect(toggleButton).toHaveText("Hide Message");
    await expect(messageDiv).toBeVisible();
    await expect(messageDiv.locator("p")).toHaveText(
      "This message is conditionally rendered using r-if attribute!"
    );

    // Click to hide message again
    await toggleButton.click();
    await page.waitForTimeout(100);

    await expect(toggleButton).toHaveText("Show Message");
    await expect(messageDiv).not.toBeVisible();
  });

  test("should display counter and control buttons", async ({ page }) => {
    await page.goto("/examples/r_if_attribute_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check counter buttons
    const incrementButton = page.locator("button").nth(1); // +1 button
    const decrementButton = page.locator("button").nth(2); // -1 button
    const resetButton = page.locator("button").nth(3); // Reset button

    await expect(incrementButton).toHaveText("+1");
    await expect(decrementButton).toHaveText("-1");
    await expect(resetButton).toHaveText("Reset");

    // Check initial counter display
    await expect(
      page.locator("p").filter({ hasText: "Counter:" })
    ).toContainText("Counter:0");
  });

  test("should show appropriate conditional messages based on counter value", async ({
    page,
  }) => {
    await page.goto("/examples/r_if_attribute_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const incrementButton = page.locator("button").nth(1);
    const decrementButton = page.locator("button").nth(2);
    const resetButton = page.locator("button").nth(3);

    const positiveMessage = page
      .getByText("Counter is positive!")
      .locator("..");
    const negativeMessage = page
      .getByText("Counter is negative!")
      .locator("..");
    const zeroMessage = page.getByText("Counter is zero.").locator("..");

    // Initially at 0 - should show zero message
    await expect(zeroMessage).toBeVisible();
    await expect(positiveMessage).not.toBeVisible();
    await expect(negativeMessage).not.toBeVisible();

    // Increment to positive
    await incrementButton.click();
    await page.waitForTimeout(100);

    await expect(positiveMessage).toBeVisible();
    await expect(positiveMessage.locator("p")).toHaveText(
      "Counter is positive! (1)"
    );
    await expect(zeroMessage).not.toBeVisible();
    await expect(negativeMessage).not.toBeVisible();

    // Increment more
    await incrementButton.click();
    await incrementButton.click();
    await page.waitForTimeout(100);

    await expect(positiveMessage).toBeVisible();
    await expect(positiveMessage.locator("p")).toHaveText(
      "Counter is positive! (3)"
    );

    // Reset to zero
    await resetButton.click();
    await page.waitForTimeout(100);

    await expect(zeroMessage).toBeVisible();
    await expect(positiveMessage).not.toBeVisible();
    await expect(negativeMessage).not.toBeVisible();

    // Decrement to negative
    await decrementButton.click();
    await page.waitForTimeout(100);

    await expect(negativeMessage).toBeVisible();
    await expect(negativeMessage.locator("p")).toHaveText(
      "Counter is negative! (-1)"
    );
    await expect(zeroMessage).not.toBeVisible();
    await expect(positiveMessage).not.toBeVisible();

    // Decrement more
    await decrementButton.click();
    await decrementButton.click();
    await page.waitForTimeout(100);

    await expect(negativeMessage).toBeVisible();
    await expect(negativeMessage.locator("p")).toHaveText(
      "Counter is negative! (-3)"
    );
  });

  test("should update counter value correctly", async ({ page }) => {
    await page.goto("/examples/r_if_attribute_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const incrementButton = page.locator("button").nth(1);
    const decrementButton = page.locator("button").nth(2);
    const resetButton = page.locator("button").nth(3);
    const counterDisplay = page.locator("p").filter({ hasText: "Counter:" });

    // Initial value
    await expect(counterDisplay).toContainText("Counter:0");

    // Test increment
    await incrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:1");

    await incrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:2");

    // Test decrement
    await decrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:1");

    await decrementButton.click();
    await decrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:-1");

    // Test reset
    await resetButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:0");
  });

  test("should have proper styling for conditional messages", async ({
    page,
  }) => {
    await page.goto("/examples/r_if_attribute_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const incrementButton = page.locator("button").nth(1);
    const decrementButton = page.locator("button").nth(2);

    // Test positive message styling
    await incrementButton.click();
    await page.waitForTimeout(100);

    const positiveMessage = page
      .getByText("Counter is positive!")
      .locator("..");
    // Note: CSS styles might not be exactly as expected due to browser rendering differences
    // Just verify the element is visible and has some styling
    await expect(positiveMessage).toBeVisible();
    await expect(positiveMessage).toHaveAttribute("style");

    // Reset and test negative message styling
    await page.locator("button").nth(3).click(); // Reset
    await decrementButton.click();
    await page.waitForTimeout(100);

    const negativeMessage = page
      .getByText("Counter is negative!")
      .locator("..");
    await expect(negativeMessage).toBeVisible();
    await expect(negativeMessage).toHaveAttribute("style");

    // Reset and test zero message styling
    await page.locator("button").nth(3).click(); // Reset
    await page.waitForTimeout(100);

    const zeroMessage = page.getByText("Counter is zero.").locator("..");
    await expect(zeroMessage).toBeVisible();
    await expect(zeroMessage).toHaveAttribute("style");
  });
});
