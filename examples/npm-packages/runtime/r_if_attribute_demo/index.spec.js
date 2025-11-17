import { test, expect } from "@playwright/test";

test.describe("R-If Attribute Demo Example", () => {
  test("should display page layout and toggle message functionality", async ({
    page,
  }) => {
    await page.goto("/examples/npm-packages/runtime/r_if_attribute_demo/index.html?env=DEV");
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

    // Test message toggle functionality
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

  test("should handle counter operations and conditional message display", async ({
    page,
  }) => {
    await page.goto("/examples/npm-packages/runtime/r_if_attribute_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check counter buttons
    const incrementButton = page.locator("button").nth(1); // +1 button
    const decrementButton = page.locator("button").nth(2); // -1 button
    const resetButton = page.locator("button").nth(3); // Reset button
    const counterDisplay = page.locator("p").filter({ hasText: "Counter:" });

    await expect(incrementButton).toHaveText("+1");
    await expect(decrementButton).toHaveText("-1");
    await expect(resetButton).toHaveText("Reset");

    // Check initial counter display and zero message
    await expect(counterDisplay).toContainText("Counter:0");

    const positiveMessage = page
      .getByText("Counter is positive!")
      .locator("..");
    const negativeMessage = page
      .getByText("Counter is negative!")
      .locator("..");
    const zeroMessage = page.getByText("Counter is zero.").locator("..");

    await expect(zeroMessage).toBeVisible();
    await expect(positiveMessage).not.toBeVisible();
    await expect(negativeMessage).not.toBeVisible();

    // Test increment operations and positive message
    await incrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:1");
    await expect(positiveMessage).toBeVisible();
    await expect(positiveMessage.locator("p")).toHaveText(
      "Counter is positive! (1)"
    );
    await expect(zeroMessage).not.toBeVisible();
    await expect(negativeMessage).not.toBeVisible();

    // Test more increments
    await incrementButton.click();
    await incrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:3");
    await expect(positiveMessage.locator("p")).toHaveText(
      "Counter is positive! (3)"
    );

    // Test reset
    await resetButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:0");
    await expect(zeroMessage).toBeVisible();
    await expect(positiveMessage).not.toBeVisible();
    await expect(negativeMessage).not.toBeVisible();

    // Test decrement operations and negative message
    await decrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:-1");
    await expect(negativeMessage).toBeVisible();
    await expect(negativeMessage.locator("p")).toHaveText(
      "Counter is negative! (-1)"
    );
    await expect(zeroMessage).not.toBeVisible();
    await expect(positiveMessage).not.toBeVisible();

    // Test more decrements
    await decrementButton.click();
    await decrementButton.click();
    await page.waitForTimeout(100);
    await expect(counterDisplay).toContainText("Counter:-3");
    await expect(negativeMessage.locator("p")).toHaveText(
      "Counter is negative! (-3)"
    );

    // Verify styling for conditional messages
    await expect(negativeMessage).toHaveAttribute("style");

    // Reset and verify zero message styling
    await resetButton.click();
    await page.waitForTimeout(100);
    await expect(zeroMessage).toHaveAttribute("style");
  });
});
