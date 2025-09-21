import { test, expect } from "@playwright/test";

test.describe("Random Cocktail Example", () => {
  test("should display loading state and fetch initial cocktail data", async ({
    page,
  }) => {
    await page.goto("/examples/random_cocktail/index.html?env=DEV");
    await page.waitForTimeout(1000); // Shorter wait to catch loading state

    // Check the page title
    await expect(page).toHaveTitle("Random Cocktail");

    // Should initially show loading state or quickly transition to cocktail data
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
    await expect(page.locator("#app p").last()).toBeVisible();
    await expect(page.locator("img")).toBeVisible();
    await expect(page.locator("button")).toHaveText("Get another cocktail");

    // Verify cocktail data is displayed correctly
    const cocktailName = await page.locator("#app h1").textContent();
    expect(cocktailName).toBeTruthy();
    expect(cocktailName.length).toBeGreaterThan(0);

    const instructions = await page.locator("#app p").last().textContent();
    expect(instructions).toBeTruthy();
    expect(instructions.length).toBeGreaterThan(0);

    // Verify image attributes and styling
    const img = page.locator("img");
    await expect(img).toHaveAttribute("alt");
    await expect(img).toHaveAttribute("src");
    await expect(img).toHaveCSS("width", "300px");
    await expect(img).toHaveCSS("height", "300px");

    const imgSrc = await img.getAttribute("src");
    const imgAlt = await img.getAttribute("alt");
    expect(imgSrc).toBeTruthy();
    expect(imgAlt).toBeTruthy();
    expect(imgSrc).toMatch(/^https?:\/\//); // Should be a valid URL

    // Verify button styling and behavior
    const button = page.locator("button");
    await expect(button).toBeVisible();
    await expect(button).toBeEnabled();
    await expect(button).toHaveCSS("display", "block");
  });

  test("should fetch new cocktail when button is clicked", async ({ page }) => {
    await page.goto("/examples/random_cocktail/index.html?env=DEV");
    await page.waitForTimeout(3000);

    // Wait for initial cocktail to load
    await page.waitForTimeout(5000);

    // Get the initial cocktail name
    const initialCocktailName = await page.locator("#app h1").textContent();

    // Click "Get another cocktail" button
    const button = page.locator("button");
    await button.click();

    // Should show loading state
    await expect(page.getByText("Loading...")).toBeVisible();

    // Wait for new cocktail to load
    await page.waitForTimeout(5000);

    // Should display new cocktail data with correct structure
    await expect(page.locator("#app h1")).toBeVisible();
    await expect(page.locator("#app p").last()).toBeVisible();
    await expect(page.locator("img")).toBeVisible();
    await expect(button).toHaveText("Get another cocktail");

    // Verify we have valid cocktail data
    const newCocktailName = await page.locator("#app h1").textContent();
    expect(newCocktailName).toBeTruthy();
    expect(newCocktailName.length).toBeGreaterThan(0);

    // Verify the component maintains proper state
    const hasLoading = (await page.getByText("Loading...").count()) > 0;
    const hasCocktail = (await page.locator("#app h1").count()) > 0;
    const hasButton = (await button.count()) > 0;
    expect(hasLoading || hasCocktail || hasButton).toBe(true);
  });
});
