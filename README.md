# ruby-wasm-ui

A modern web frontend framework for Ruby using [ruby.wasm](https://github.com/ruby/ruby.wasm). Write reactive web applications using familiar Ruby syntax and patterns.

**Currently under active development.**

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
    <script src="https://unpkg.com/ruby-wasm-ui@latest"></script>
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

# Define actions to handle state changes
actions = {
  increment: ->(state, _payload) {
    { count: state[:count] + 1 }
  },
  decrement: ->(state, _payload) {
    { count: state[:count] - 1 }
  }
}

# Define the view function
view = ->(state, emit) {
  RubyWasmUi::Vdom.h("div", {}, [
    RubyWasmUi::Vdom.h("h1", {}, ["Count: #{state[:count]}"]),
    RubyWasmUi::Vdom.h("button", {
      onclick: ->(e) { emit.call(:increment) }
    }, ["+"]),
    RubyWasmUi::Vdom.h("button", {
      onclick: ->(e) { emit.call(:decrement) }
    }, ["-"])
  ])
}

# Create and mount the app
app = RubyWasmUi::App.create(
  state: { count: 0 },
  view: view,
  actions: actions
)

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
