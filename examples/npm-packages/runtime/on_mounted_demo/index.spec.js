import { test, expect } from "@playwright/test";

test.describe("On Mounted Demo Example", () => {
  test("should display components and verify on_mounted hooks execute correctly", async ({
    page,
  }) => {
    await page.goto("/examples/npm-packages/runtime/on_mounted_demo/index.html?env=DEV");
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

    // Verify on_mounted hooks have executed and updated the messages
    const simpleComponentMessage = page
      .locator("h2")
      .first()
      .locator("..")
      .locator("p");
    await expect(simpleComponentMessage).toHaveText(
      "Mounted and state updated without component argument!"
    );

    const advancedComponentMessage = page
      .locator("h2")
      .last()
      .locator("..")
      .locator("p");
    await expect(advancedComponentMessage).toHaveText(
      "Mounted and state updated!"
    );

    // Neither component should show the initial "Not mounted yet" message
    const paragraphs = page.locator("p");
    for (let i = 0; i < (await paragraphs.count()); i++) {
      const text = await paragraphs.nth(i).textContent();
      expect(text).not.toBe("Not mounted yet");
    }
  });
});
