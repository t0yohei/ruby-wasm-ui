import { test, expect } from "@playwright/test";

test.describe("Input Example", () => {
  test("should display input form and validate input length", async ({
    page,
  }) => {
    await page.goto("/examples/input/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("Input");

    // Check form elements are present
    await expect(page.locator("label")).toHaveText("User Name");
    const input = page.locator('input[type="text"]');
    await expect(input).toBeVisible();

    // Check help text
    await expect(page.locator("p").last()).toHaveText(
      "*User name must be at least 4 characters"
    );

    // Check initial validation message (invalid state)
    const validationMessage = page.locator("p").first();
    await expect(validationMessage).toHaveText(
      "User name must be at least 4 characters"
    );
    await expect(validationMessage).toHaveClass(/text-red-600/);
    await expect(input).toHaveClass(/border-red-500/);

    // Type less than 4 characters - should still be invalid
    await input.fill("abc");
    await page.waitForTimeout(100);
    await expect(validationMessage).toHaveText(
      "User name must be at least 4 characters"
    );
    await expect(validationMessage).toHaveClass(/text-red-600/);
    await expect(input).toHaveClass(/border-red-500/);

    // Type 4 or more characters - should become valid
    await input.fill("abcd");
    await page.waitForTimeout(100);
    await expect(validationMessage).toHaveText("Valid");
    await expect(validationMessage).toHaveClass(/text-green-600/);
    await expect(input).toHaveClass(/border-green-500/);

    // Clear input to make it invalid again
    await input.fill("ab");
    await page.waitForTimeout(100);

    // Should be invalid again
    await expect(input).toHaveValue("ab");
    await expect(validationMessage).toHaveText(
      "User name must be at least 4 characters"
    );
    await expect(validationMessage).toHaveClass(/text-red-600/);
  });
});
