import { test, expect } from "@playwright/test";

test.describe("Todos Example", () => {
  // Clear localStorage before each test to ensure clean state
  test.beforeEach(async ({ page }) => {
    await page.goto("/examples/todos/index.html?env=DEV");
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await page.waitForTimeout(3000);
  });

  test("should display todos app with initial todos", async ({ page }) => {
    // Check the page title
    await expect(page).toHaveTitle("Todos");

    // Check main heading
    await expect(page.locator("#app h1")).toHaveText("My TODOs");

    // Check new todo form elements
    await expect(page.locator('label[for="todo-input"]')).toHaveText(
      "New TODO"
    );
    await expect(page.locator("#todo-input")).toBeVisible();
    await expect(page.locator("button").first()).toHaveText("Add");

    // Check that initial todos are displayed (from component state)
    const todoItems = page.locator("li");
    await expect(todoItems).toHaveCount(3);

    // Check initial todo texts (these are generated with random IDs, so just check they exist)
    await expect(page.locator("li span")).toHaveCount(3);
  });

  test("should add new todo when form is submitted", async ({ page }) => {
    const todoInput = page.locator("#todo-input");
    const addButton = page.locator("button").first();

    // Initially the add button should be disabled (empty input)
    await expect(addButton).toBeDisabled();

    // Type a new todo (less than 3 characters should keep button disabled)
    await todoInput.fill("ab");
    await page.waitForTimeout(100);
    await expect(addButton).toBeDisabled();

    // Type 3 or more characters should enable the button
    await todoInput.fill("New test todo");
    await page.waitForTimeout(100);
    await expect(addButton).toBeEnabled();

    // Get initial todo count
    const initialTodoCount = await page.locator("li").count();

    // Add the todo
    await addButton.click();
    await page.waitForTimeout(100);

    // Should have one more todo
    await expect(page.locator("li")).toHaveCount(initialTodoCount + 1);

    // Input should be cleared
    await expect(todoInput).toHaveValue("");

    // Button should be disabled again
    await expect(addButton).toBeDisabled();

    // New todo should be visible in the list
    await expect(page.locator("li span").last()).toHaveText("New test todo");
  });

  test("should add todo using Enter key", async ({ page }) => {
    const todoInput = page.locator("#todo-input");

    // Type a new todo
    await todoInput.fill("Todo added with Enter");
    await page.waitForTimeout(100);

    // Get initial todo count
    const initialTodoCount = await page.locator("li").count();

    // Press Enter to add todo
    await todoInput.press("Enter");
    await page.waitForTimeout(100);

    // Should have one more todo
    await expect(page.locator("li")).toHaveCount(initialTodoCount + 1);

    // Input should be cleared
    await expect(todoInput).toHaveValue("");

    // New todo should be visible
    await expect(page.locator("li span").last()).toHaveText(
      "Todo added with Enter"
    );
  });

  test("should not add todo with less than 3 characters using Enter", async ({
    page,
  }) => {
    const todoInput = page.locator("#todo-input");

    // Type less than 3 characters
    await todoInput.fill("ab");
    await page.waitForTimeout(100);

    // Get initial todo count
    const initialTodoCount = await page.locator("li").count();

    // Press Enter
    await todoInput.press("Enter");
    await page.waitForTimeout(100);

    // Should not add a new todo
    await expect(page.locator("li")).toHaveCount(initialTodoCount);

    // Input should keep its value
    await expect(todoInput).toHaveValue("ab");
  });

  test("should remove todo when Done button is clicked", async ({ page }) => {
    // Get initial todo count
    const initialTodoCount = await page.locator("li").count();

    // Click the Done button on the first todo
    await page.locator("li button").first().click();
    await page.waitForTimeout(100);

    // Should have one less todo
    await expect(page.locator("li")).toHaveCount(initialTodoCount - 1);
  });

  test("should enter edit mode when double-clicking todo text", async ({
    page,
  }) => {
    // Double-click on the first todo text
    await page.locator("li span").first().dblclick();
    await page.waitForTimeout(100);

    // Should show edit input and buttons
    await expect(page.locator('li input[type="text"]').first()).toBeVisible();
    await expect(page.locator("li button").first()).toHaveText("Save");
    await expect(page.locator("li button").nth(1)).toHaveText("Cancel");

    // The span should not be visible (replaced by edit mode)
    const editInput = page.locator('li input[type="text"]').first();
    await expect(editInput).toBeVisible();
  });

  test("should save edited todo when Save button is clicked", async ({
    page,
  }) => {
    // Get the original text of the first todo
    const originalText = await page.locator("li span").first().textContent();

    // Double-click to enter edit mode
    await page.locator("li span").first().dblclick();
    await page.waitForTimeout(100);

    // Edit the todo text
    const editInput = page.locator('li input[type="text"]').first();
    await editInput.fill("Edited todo text");
    await page.waitForTimeout(100);

    // Click Save
    await page.locator("li button").first().click(); // Save button
    await page.waitForTimeout(100);

    // Should exit edit mode and show updated text
    await expect(page.locator("li span").first()).toHaveText(
      "Edited todo text"
    );
    await expect(
      page.locator('li input[type="text"]').first()
    ).not.toBeVisible();
  });

  test("should cancel edit when Cancel button is clicked", async ({ page }) => {
    // Get the original text of the first todo
    const originalText = await page.locator("li span").first().textContent();

    // Double-click to enter edit mode
    await page.locator("li span").first().dblclick();
    await page.waitForTimeout(100);

    // Edit the todo text
    const editInput = page.locator('li input[type="text"]').first();
    await editInput.fill("This should be cancelled");
    await page.waitForTimeout(100);

    // Click Cancel
    await page.locator("li button").nth(1).click(); // Cancel button
    await page.waitForTimeout(100);

    // Should exit edit mode and show original text
    await expect(page.locator("li span").first()).toHaveText(originalText);
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
