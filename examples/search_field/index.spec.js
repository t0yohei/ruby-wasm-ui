import { test, expect } from "@playwright/test";

test.describe("Search Field Example", () => {
  test("should display search demo with input field", async ({ page }) => {
    await page.goto("/examples/search_field/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("Search Field");

    // Check search demo heading
    await expect(page.locator("h2")).toHaveText("Search Demo");

    // Check search input field is present
    const searchInput = page.locator('input[type="text"]');
    await expect(searchInput).toBeVisible();
    await expect(searchInput).toHaveAttribute("placeholder", "Search...");

    // Check initial search term display
    await expect(page.locator("p")).toHaveText("Current search term: ");
  });

  test("should update search term when typing in input field", async ({
    page,
  }) => {
    await page.goto("/examples/search_field/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const searchInput = page.locator('input[type="text"]');
    const searchTermDisplay = page.locator("p");

    // Initially empty
    await expect(searchTermDisplay).toHaveText("Current search term: ");

    // Type in the search field
    await searchInput.fill("test");
    await page.waitForTimeout(100);

    // Should update the displayed search term
    await expect(searchTermDisplay).toHaveText("Current search term: test");
    await expect(searchInput).toHaveValue("test");
  });

  test("should handle multiple search term updates", async ({ page }) => {
    await page.goto("/examples/search_field/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const searchInput = page.locator('input[type="text"]');
    const searchTermDisplay = page.locator("p");

    // Test various search terms
    const searchTerms = ["hello", "world", "ruby", "wasm", ""];

    for (const term of searchTerms) {
      await searchInput.fill(term);
      await page.waitForTimeout(100);

      await expect(searchTermDisplay).toHaveText(
        `Current search term: ${term}`
      );
      await expect(searchInput).toHaveValue(term);
    }
  });

  test("should handle special characters in search input", async ({ page }) => {
    await page.goto("/examples/search_field/index.html?env=DEV");
    await page.waitForTimeout(3000);

    const searchInput = page.locator('input[type="text"]');
    const searchTermDisplay = page.locator("p");

    const specialSearchTerms = [
      "test@example.com",
      "123-456-789",
      "hello world!",
      "search with spaces",
      "special!@#$%^&*()",
    ];

    for (const term of specialSearchTerms) {
      await searchInput.fill(term);
      await page.waitForTimeout(100);

      await expect(searchTermDisplay).toHaveText(
        `Current search term: ${term}`
      );
      await expect(searchInput).toHaveValue(term);
    }
  });
});
