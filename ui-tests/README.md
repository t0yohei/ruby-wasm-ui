# UI Tests for Ruby WASM UI Examples

This directory contains End-to-End tests using Playwright for each example directory under the `examples/` folder.

## Test Coverage

The following UI tests are provided for each example:

- **hello.spec.js** - Hello World example (`examples/hello/`)
- **input.spec.js** - Input validation example (`examples/input/`)
- **search_field.spec.js** - Search field component example (`examples/search_field/`)
- **todos.spec.js** - Todo application example (`examples/todos/`)
- **random_cocktail.spec.js** - Random cocktail API example (`examples/random_cocktail/`)
- **list.spec.js** - List rendering example (`examples/list/`)
- **plus_counter.spec.js** - Simple counter example (`examples/plus_counter/`)
- **on_mounted_demo.spec.js** - Component lifecycle example (`examples/on_mounted_demo/`)
- **r_if_attribute_demo.spec.js** - Conditional rendering example (`examples/r_if_attribute_demo/`)

## Setup

Before running tests, ensure that the necessary dependencies are installed:

```bash
npm install
```

## Running Tests

### Run All Tests

```bash
npm run test:ui
```

### Run Tests in UI Mode (Recommended)

```bash
npm run test:ui:ui
```

### Run Specific Test File

```bash
npm run test:ui counter.spec.js
```

### Run Tests in Headed Mode (Show Browser)

```bash
npm run test:ui --headed
```

### Run Tests in Debug Mode

```bash
npm run test:ui --debug
```

## Test Reports

To view HTML reports after test execution:

```bash
npm run test:ui:report
```

## Test Configuration

- **playwright.config.js** - Playwright configuration file
- **webServer** - Automatically starts development server before tests
- **baseURL** - Set to `http://localhost:8080`
- **browsers** - Tests run on Chromium, Firefox, and WebKit
- **timeout** - Set to 2 minutes considering Ruby WASM loading time

## Test Features

### Common Patterns

1. **Initialization Wait**: Uses `page.waitForTimeout(3000)` to wait for Ruby WASM loading
2. **State Update Wait**: Uses short wait time `page.waitForTimeout(100)` after UI state updates
3. **Element Visibility**: Confirms that elements are displayed
4. **Text Content Verification**: Confirms that expected text is displayed
5. **Interactions**: Tests button clicks, input field entries, etc.

### Individual Test Features

- **counter.spec.js**: Tests component state management and event handling
- **input.spec.js**: Tests form validation and dynamic CSS class changes
- **todos.spec.js**: Tests CRUD operations and localStorage persistence
- **random_cocktail.spec.js**: Tests asynchronous API calls and loading states
- **r_if_attribute_demo.spec.js**: Tests conditional rendering and CSS styling

## Important Notes

- Tests run in development environment (`?env=DEV`)
- Sufficient wait time is set due to Ruby WASM loading time
- Some tests clear localStorage (todos.spec.js)
- Tests with API calls (random_cocktail.spec.js) may depend on network conditions

## Troubleshooting

### When Tests Fail

1. Confirm that the development server is running properly
2. Confirm that Ruby WASM loading time is sufficient (3+ seconds)
3. Check network connection (for API call tests)
4. Clear browser cache

### Debugging Methods

1. Run tests with `--headed` flag to display browser
2. Use `--debug` flag for debug mode
3. Take screenshots with `page.screenshot()`
4. Output debug information with `console.log()`
