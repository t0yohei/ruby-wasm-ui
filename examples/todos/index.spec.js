import { test, expect } from "@playwright/test";

test.describe("Todos Example", () => {
  // Clear localStorage before each test to ensure clean state
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/todos/index.html?env=DEV");
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await page.waitForTimeout(3000);
  });

  test("should display todos app and handle basic add/remove operations", async ({
    page,
  }) => {
    // Check the page title and basic layout
    await expect(page).toHaveTitle("Todos");
    await expect(page.locator("#app h1")).toHaveText("My TODOs");

    // Check new todo form elements
    const todoInput = page.locator("#todo-input");
    const addButton = page.locator("button").first();
    await expect(page.locator('label[for="todo-input"]')).toHaveText(
      "New TODO"
    );
    await expect(todoInput).toBeVisible();
    await expect(addButton).toHaveText("Add");

    // Check that initial todos are displayed (from component state)
    const todoItems = page.locator("li");
    await expect(todoItems).toHaveCount(3);
    await expect(page.locator("li span")).toHaveCount(3);

    // Test add button validation - initially disabled (empty input)
    await expect(addButton).toBeDisabled();

    // Type less than 3 characters - should keep button disabled
    await todoInput.fill("ab");
    await page.waitForTimeout(100);
    await expect(addButton).toBeDisabled();

    // Type 3 or more characters - should enable the button
    await todoInput.fill("New test todo");
    await page.waitForTimeout(100);
    await expect(addButton).toBeEnabled();

    // Add the todo via button click
    const initialTodoCount = await page.locator("li").count();
    await addButton.click();
    await page.waitForTimeout(100);

    await expect(page.locator("li")).toHaveCount(initialTodoCount + 1);
    await expect(todoInput).toHaveValue("");
    await expect(addButton).toBeDisabled();
    await expect(page.locator("li span").last()).toHaveText("New test todo");

    // Test adding todo with Enter key
    await todoInput.fill("Todo added with Enter");
    await page.waitForTimeout(100);
    const currentTodoCount = await page.locator("li").count();

    await todoInput.press("Enter");
    await page.waitForTimeout(100);

    await expect(page.locator("li")).toHaveCount(currentTodoCount + 1);
    await expect(todoInput).toHaveValue("");
    await expect(page.locator("li span").last()).toHaveText(
      "Todo added with Enter"
    );

    // Test that Enter doesn't work with less than 3 characters
    await todoInput.fill("ab");
    await page.waitForTimeout(100);
    const countBeforeInvalidEnter = await page.locator("li").count();

    await todoInput.press("Enter");
    await page.waitForTimeout(100);

    await expect(page.locator("li")).toHaveCount(countBeforeInvalidEnter);
    await expect(todoInput).toHaveValue("ab");

    // Test remove todo functionality
    const countBeforeRemove = await page.locator("li").count();
    await page.locator("li button").first().click();
    await page.waitForTimeout(100);

    await expect(page.locator("li")).toHaveCount(countBeforeRemove - 1);
  });

  test("should handle todo editing operations", async ({ page }) => {
    // Get the original text of the first todo
    const originalText = await page.locator("li span").first().textContent();

    // Test entering edit mode by double-clicking
    await page.locator("li span").first().dblclick();
    await page.waitForTimeout(100);

    // Should show edit input and buttons
    await expect(page.locator('li input[type="text"]').first()).toBeVisible();
    await expect(page.locator("li button").first()).toHaveText("Save");
    await expect(page.locator("li button").nth(1)).toHaveText("Cancel");

    // Test saving edited todo
    const editInput = page.locator('li input[type="text"]').first();
    await editInput.fill("Edited todo text");
    await page.waitForTimeout(100);

    await page.locator("li button").first().click(); // Save button
    await page.waitForTimeout(100);

    // Should exit edit mode and show updated text
    await expect(page.locator("li span").first()).toHaveText(
      "Edited todo text"
    );
    await expect(
      page.locator('li input[type="text"]').first()
    ).not.toBeVisible();

    // Test canceling edit operation
    await page.locator("li span").first().dblclick();
    await page.waitForTimeout(100);

    const editInput2 = page.locator('li input[type="text"]').first();
    await editInput2.fill("This should be cancelled");
    await page.waitForTimeout(100);

    await page.locator("li button").nth(1).click(); // Cancel button
    await page.waitForTimeout(100);

    // Should exit edit mode and show previous text (not cancelled text)
    await expect(page.locator("li span").first()).toHaveText(
      "Edited todo text"
    );
    await expect(
      page.locator('li input[type="text"]').first()
    ).not.toBeVisible();
  });

  test("should persist todos in localStorage", async ({ page }) => {
    // Initial count should be 3 (from component state)
    await expect(page.locator("li")).toHaveCount(3);

    // Add a new todo
    const todoInput = page.locator("#todo-input");
    await todoInput.fill("Persistent todo");
    await page.locator("button").first().click();
    await page.waitForTimeout(100);

    // Should now have 4 todos
    await expect(page.locator("li")).toHaveCount(4);

    // Reload the page
    await page.reload();
    await page.waitForTimeout(3000);

    // Should still have 4 todos (loaded from localStorage)
    await expect(page.locator("li")).toHaveCount(4);

    // Should still contain the persistent todo
    await expect(page.locator("li span")).toContainText(["Persistent todo"]);
  });
});
