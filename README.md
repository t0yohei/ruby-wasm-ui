# ruby-wasm-ui

A modern web frontend framework for Ruby using [ruby.wasm](https://github.com/ruby/ruby.wasm). Write reactive web applications using familiar Ruby syntax and patterns.

**⚠️ Warning: This library is currently under development and subject to frequent breaking changes. Please use with caution and expect API changes in future versions.**

## Features

- **Reactive State Management**: Simple, predictable state updates with actions
- **Virtual DOM**: Efficient DOM updates using a virtual DOM implementation
- **Event Handling**: Intuitive event system with Ruby lambdas
- **Component Architecture**: Build reusable components with clean separation of concerns
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
    state = component.state

    RubyWasmUi::Vdom.h("div", {}, [
      RubyWasmUi::Vdom.h("div", {}, [state[:count].to_s]),
      RubyWasmUi::Vdom.h(Button, {
        label: "Increment",
        on: { click_button: ->(_e) { component.increment } }
      }),
      RubyWasmUi::Vdom.h(Button, {
        label: "Decrement",
        on: { click_button: ->(_e) { component.decrement } }
      })
    ])
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
Button = RubyWasmUi.define_component(
  render: ->(component) {
    RubyWasmUi::Vdom.h("button", {
      on: { click: ->(e) { component.emit('click_button', e) } }
    }, [component.props[:label]])
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(CounterComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

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
