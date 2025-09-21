import { test, expect } from "@playwright/test";

test.describe("Search Field Example", () => {
  test("should display search demo and handle various input scenarios", async ({
    page,
  }) => {
    await page.goto("/examples/search_field/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("Search Field");

    // Check search demo heading
    await expect(page.locator("h2")).toHaveText("Search Demo");

    // Check search input field is present
    const searchInput = page.locator('input[type="text"]');
    const searchTermDisplay = page.locator("p");
    await expect(searchInput).toBeVisible();
    await expect(searchInput).toHaveAttribute("placeholder", "Search...");

    // Check initial search term display
    await expect(searchTermDisplay).toHaveText("Current search term: ");

    // Test basic search functionality
    await searchInput.fill("test");
    await page.waitForTimeout(100);
    await expect(searchTermDisplay).toHaveText("Current search term: test");
    await expect(searchInput).toHaveValue("test");

    // Test multiple search term updates
    const searchTerms = ["hello", "world", "ruby", "wasm", ""];
    for (const term of searchTerms) {
      await searchInput.fill(term);
      await page.waitForTimeout(100);
      await expect(searchTermDisplay).toHaveText(
        `Current search term: ${term}`
      );
      await expect(searchInput).toHaveValue(term);
    }

    // Test special characters in search input
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
