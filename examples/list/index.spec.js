import { test, expect } from "@playwright/test";

test.describe("List Example", () => {
  test("should display list with initial todos", async ({ page }) => {
    await page.goto("/examples/list/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("List");

    // Check that the list is rendered
    await expect(page.locator("ul")).toBeVisible();

    // Check that all initial todos are displayed (both component and element versions)
    const listItems = page.locator("li");
    await expect(listItems).toHaveCount(6);

    // Check the content of each list item (component version first, then element version)
    await expect(listItems.nth(0)).toHaveText("foo");
    await expect(listItems.nth(1)).toHaveText("bar");
    await expect(listItems.nth(2)).toHaveText("baz");
    await expect(listItems.nth(3)).toHaveText("foo");
    await expect(listItems.nth(4)).toHaveText("bar");
    await expect(listItems.nth(5)).toHaveText("baz");
  });

  test("should render r-for with components correctly", async ({ page }) => {
    await page.goto("/examples/list/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check that ListItem components are rendered (first 3 items)
    const componentItems = page.locator("li").nth(0);
    await expect(componentItems).toBeVisible();
    await expect(componentItems).toHaveText("foo");
  });

  test("should render r-for with elements correctly", async ({ page }) => {
    await page.goto("/examples/list/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check that direct li elements are rendered (last 3 items)
    const elementItems = page.locator("li").nth(3);
    await expect(elementItems).toBeVisible();
    await expect(elementItems).toHaveText("foo");
  });
});
