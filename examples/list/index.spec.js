import { test, expect } from "@playwright/test";

test.describe("List Example", () => {
  test("should display list with initial todos", async ({ page }) => {
    await page.goto("/examples/list/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("List");

    // Check that the list is rendered
    await expect(page.locator("ul")).toBeVisible();

    // Check that all initial todos are displayed
    const listItems = page.locator("li");
    await expect(listItems).toHaveCount(3);

    // Check the content of each list item
    await expect(listItems.nth(0)).toHaveText("foo");
    await expect(listItems.nth(1)).toHaveText("bar");
    await expect(listItems.nth(2)).toHaveText("baz");
  });
});
