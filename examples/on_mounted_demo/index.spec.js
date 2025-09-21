import { test, expect } from "@playwright/test";

test.describe("On Mounted Demo Example", () => {
  test("should display main heading and both components", async ({ page }) => {
    await page.goto("/examples/on_mounted_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Check the page title
    await expect(page).toHaveTitle("on_mounted Demo");

    // Check main heading
    await expect(page.locator("h1")).toHaveText("on_mounted Demo");

    // Check both component headings are present
    await expect(page.locator("h2").first()).toHaveText(
      "Simple Component (no args in on_mounted)"
    );
    await expect(page.locator("h2").last()).toHaveText(
      "Advanced Component (with args in on_mounted)"
    );
  });

  test("should show updated messages after on_mounted hooks execute", async ({
    page,
  }) => {
    await page.goto("/examples/on_mounted_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // SimpleComponent should show updated message
    const simpleComponentMessage = page
      .locator("h2")
      .first()
      .locator("..")
      .locator("p");
    await expect(simpleComponentMessage).toHaveText(
      "Mounted and state updated without component argument!"
    );

    // AdvancedComponent should show updated message
    const advancedComponentMessage = page
      .locator("h2")
      .last()
      .locator("..")
      .locator("p");
    await expect(advancedComponentMessage).toHaveText(
      "Mounted and state updated!"
    );
  });

  test('should not show initial "Not mounted yet" messages', async ({
    page,
  }) => {
    await page.goto("/examples/on_mounted_demo/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Neither component should show the initial "Not mounted yet" message
    // since on_mounted should have updated the state
    const paragraphs = page.locator("p");

    for (let i = 0; i < (await paragraphs.count()); i++) {
      const text = await paragraphs.nth(i).textContent();
      expect(text).not.toBe("Not mounted yet");
    }
  });
});
