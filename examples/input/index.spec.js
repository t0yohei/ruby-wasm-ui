import { test, expect } from "@playwright/test";

test.describe("Input Example", () => {
  test("should display input form with validation", async ({ page }) => {
    await page.goto("/examples/input/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("Input");

    // Check form elements are present
    await expect(page.locator("label")).toHaveText("ユーザー名");
    await expect(page.locator('input[type="text"]')).toBeVisible();

    // Check initial validation message (invalid state)
    await expect(page.locator("p").first()).toHaveText(
      "ユーザー名は4文字以上にしてください"
    );
    await expect(page.locator("p").first()).toHaveClass(/text-red-600/);

    // Check help text
    await expect(page.locator("p").last()).toHaveText(
      "*ユーザー名は4文字以上です"
    );
  });

  test("should validate input length and show appropriate messages", async ({
    page,
  }) => {
    await page.goto("/examples/input/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const input = page.locator('input[type="text"]');
    const validationMessage = page.locator("p").first();

    // Initially invalid (empty)
    await expect(validationMessage).toHaveText(
      "ユーザー名は4文字以上にしてください"
    );
    await expect(validationMessage).toHaveClass(/text-red-600/);
    await expect(input).toHaveClass(/border-red-500/);

    // Type less than 4 characters - should still be invalid
    await input.fill("abc");
    await page.waitForTimeout(100);
    await expect(validationMessage).toHaveText(
      "ユーザー名は4文字以上にしてください"
    );
    await expect(validationMessage).toHaveClass(/text-red-600/);
    await expect(input).toHaveClass(/border-red-500/);

    // Type 4 or more characters - should become valid
    await input.fill("abcd");
    await page.waitForTimeout(100);
    await expect(validationMessage).toHaveText("有効です");
    await expect(validationMessage).toHaveClass(/text-green-600/);
    await expect(input).toHaveClass(/border-green-500/);

    // Clear input to make it invalid again
    await input.fill("ab");
    await page.waitForTimeout(100);

    // Should be invalid
    await expect(input).toHaveValue("ab");
    await expect(validationMessage).toHaveText(
      "ユーザー名は4文字以上にしてください"
    );
    await expect(validationMessage).toHaveClass(/text-red-600/);
  });
});
