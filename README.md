# ruby-wasm-ui

A modern web frontend framework for Ruby using [ruby.wasm](https://github.com/ruby/ruby.wasm). Write reactive web applications using familiar Ruby syntax and patterns.

**⚠️ Warning: This library is currently under development and subject to frequent breaking changes. Please use with caution and expect API changes in future versions.**

## Features

- **Reactive State Management**: Simple, predictable state updates with actions
- **Virtual DOM**: Efficient DOM updates using a virtual DOM implementation
- **Event Handling**: Intuitive event system with Ruby lambdas
- **Component Architecture**: Build reusable components with clean separation of concerns
- **Lifecycle Hooks**: Manage component lifecycle with hooks like `on_mounted`
- **Ruby Syntax**: Write frontend applications using Ruby instead of JavaScript

## Quick Start

Create an HTML file:

```html
<!DOCTYPE html>
<html>
  <head>
    <script src="https://unpkg.com/ruby-wasm-ui@0.2.0"></script>
    <script defer type="text/ruby" src="app.rb"></script>
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

Create `app.rb`:

```ruby
require "js"

# Define a Counter component
CounterComponent = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    { count: 0 }
  },

  # Render the counter component
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <div>{component.state[:count]}</div>
        <button-component
          label="Increment"
          on="{ click_button: -> { component.increment } }">
        </button-component>
        <button-component
          label="Decrement"
          on="{ click_button: -> { component.decrement } }"
        />
      </div>
    HTML
  },

  # Component methods
  methods: {
    increment: ->() {
      state = self.state
      self.update_state(count: state[:count] + 1)
    },
    decrement: ->() {
      state = self.state
      self.update_state(count: state[:count] - 1)
    }
  }
)

# Button component - reusable button with click handler
ButtonComponent = RubyWasmUi.define_component(
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <button on="{ click: ->(e) { component.emit('click_button', e) } }">
        {component.props[:label]}
      </button>
    HTML
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(CounterComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

## Lifecycle Hooks

Components support lifecycle hooks to execute code at specific points in a component's lifecycle:

```ruby
RandomCocktailComponent = RubyWasmUi.define_component(
  state: ->(props) {
    { cocktail: nil }
  },

  methods: {
    fetch_cocktail: -> {
      # Use Fiber for asynchronous API call
      Fiber.new do
        response = JS.global.fetch("https://www.thecocktaildb.com/api/json/v1/1/random.php").await
        response.call(:json).then(->(data) {
          update_state(cocktail: data[:drinks][0])
        })
      end.transfer
    }
  },

  # Called after the component is mounted to the DOM
  on_mounted: ->(component) {
    component.fetch_cocktail
  },

  render: ->(component) {
    cocktail = component.state[:cocktail]

    if cocktail.nil?
      RubyWasmUi::Vdom.h("div", {}, ["Loading..."])
    else
      RubyWasmUi::Vdom.h("div", {}, [
        RubyWasmUi::Vdom.h("h2", {}, [cocktail["strDrink"]]),
        RubyWasmUi::Vdom.h("button", {
          on: { click: ->(e) { component.fetch_cocktail } }
        }, ["Get another cocktail"])
      ])
    end
  }
)
```

Note: Unlike JavaScript frameworks, asynchronous operations in ruby-wasm-ui are designed to use Ruby's Fiber system rather than Promises.

## Development

This project is currently under active development. To run the examples locally:

```bash
# Run production examples
npm run serve:examples

# Run development examples
npm run serve:examples:dev
```

## License

MIT
