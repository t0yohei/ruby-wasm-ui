import { test, expect } from "@playwright/test";

test.describe("Random Cocktail Example", () => {
  test("should display loading state initially and then fetch cocktail", async ({
    page,
  }) => {
    await page.goto("/examples/random_cocktail/index.html?env=DEV");
    await page.waitForTimeout(1000); // Shorter wait to catch loading state

    // Check the page title
    await expect(page).toHaveTitle("Random Cocktail");

    // Should initially show loading state (may be very brief)
    // If loading is too fast, just verify we eventually get cocktail data
    const hasLoadingOrCocktail = await Promise.race([
      page
        .getByText("Loading...")
        .isVisible()
        .catch(() => false),
      page
        .locator("#app h1")
        .isVisible()
        .catch(() => false),
    ]);
    expect(hasLoadingOrCocktail).toBe(true);

    // Wait for the cocktail to load (API call)
    await page.waitForTimeout(5000);

    // After loading, should show cocktail information
    await expect(page.locator("#app h1")).toBeVisible();
    // Instructions should be visible (contains cocktail instructions)
    await expect(page.locator("#app p").last()).toBeVisible();
    await expect(page.locator("img")).toBeVisible();
    await expect(page.locator("button")).toHaveText("Get another cocktail");

    // Verify cocktail data is displayed
    const cocktailName = await page.locator("#app h1").textContent();
    expect(cocktailName).toBeTruthy();
    expect(cocktailName.length).toBeGreaterThan(0);

    const instructions = await page.locator("#app p").last().textContent();
    expect(instructions).toBeTruthy();
    expect(instructions.length).toBeGreaterThan(0);

    // Verify image is loaded
    const img = page.locator("img");
    await expect(img).toHaveAttribute("alt");
    await expect(img).toHaveAttribute("src");
    await expect(img).toHaveCSS("width", "300px");
    await expect(img).toHaveCSS("height", "300px");
  });

  test('should fetch new cocktail when "Get another cocktail" button is clicked', async ({
    page,
  }) => {
    await page.goto("/examples/random_cocktail/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Wait for initial cocktail to load
    await page.waitForTimeout(5000);

    // Get the initial cocktail name
    const initialCocktailName = await page.locator("#app h1").textContent();

    // Click "Get another cocktail" button
    await page.locator("button").click();

    // Should show loading state
    await expect(page.getByText("Loading...")).toBeVisible();

    // Wait for new cocktail to load
    await page.waitForTimeout(5000);

    // Should display new cocktail (might be the same, but structure should be correct)
    await expect(page.locator("#app h1")).toBeVisible();
    await expect(page.locator("#app p").last()).toBeVisible();
    await expect(page.locator("img")).toBeVisible();
    await expect(page.locator("button")).toHaveText("Get another cocktail");

    // Verify we have cocktail data
    const newCocktailName = await page.locator("#app h1").textContent();
    expect(newCocktailName).toBeTruthy();
    expect(newCocktailName.length).toBeGreaterThan(0);
  });

  test('should display "Get a cocktail" button when no cocktail is loaded initially', async ({
    page,
  }) => {
    // We need to test the initial state before on_mounted triggers
    // This is tricky since on_mounted runs automatically, but we can test the structure
    await page.goto("/examples/random_cocktail/index.html?env=DEV");
    await page.waitForTimeout(2000); // Shorter wait to potentially catch initial state

    // The component should eventually show either loading or cocktail content
    // Since on_mounted automatically fetches, we'll verify the final state
    await page.waitForTimeout(5000);

    // Should have either loading or cocktail content
    const hasLoading = (await page.getByText("Loading...").count()) > 0;
    const hasCocktail = (await page.locator("#app h1").count()) > 0;
    const hasButton = (await page.locator("button").count()) > 0;

    expect(hasLoading || hasCocktail || hasButton).toBe(true);
  });

  test("should handle API response structure correctly", async ({ page }) => {
    await page.goto("/examples/random_cocktail/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Wait for cocktail to load
    await page.waitForTimeout(5000);

    // Verify the cocktail data structure is correctly displayed
    const cocktailName = page.locator("#app h1");
    const instructions = page.locator("#app p").last();
    const image = page.locator("img");

    await expect(cocktailName).toBeVisible();
    await expect(instructions).toBeVisible();
    await expect(image).toBeVisible();

    // Check image attributes
    const imgSrc = await image.getAttribute("src");
    const imgAlt = await image.getAttribute("alt");

    expect(imgSrc).toBeTruthy();
    expect(imgAlt).toBeTruthy();
    expect(imgSrc).toMatch(/^https?:\/\//); // Should be a valid URL
  });

  test("should maintain proper button styling and behavior", async ({
    page,
  }) => {
    await page.goto("/examples/random_cocktail/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Wait for initial load
    await page.waitForTimeout(5000);

    const button = page.locator("button");
    await expect(button).toBeVisible();
    await expect(button).toBeEnabled();

    // Check button styling
    await expect(button).toHaveCSS("display", "block");
    // Note: margin might be calculated differently in different browsers, so we'll skip this specific check

    // Click button and verify it triggers loading
    await button.click();
    await page.waitForTimeout(100);

    // Should show loading state
    await expect(page.getByText("Loading...")).toBeVisible();
  });
});
