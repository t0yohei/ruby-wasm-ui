# ruby-wasm-ui

A modern web frontend framework for Ruby using [ruby.wasm](https://github.com/ruby/ruby.wasm). Write reactive web applications using familiar Ruby syntax and patterns.

**Currently under active development.**

## Features

- **Reactive State Management**: Simple, predictable state updates with actions
- **Virtual DOM**: Efficient DOM updates using a virtual DOM implementation
- **Template Parser**: Write HTML templates with embedded Ruby expressions
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

# Define the view function using HTML templates
view = ->(state, emit) {
  template = <<~HTML
    <div>
      <h1>Count: {state[:count]}</h1>
      <button onclick="{->(e) { emit.call(:increment) }}">+</button>
      <button onclick="{->(e) { emit.call(:decrement) }}">-</button>
    </div>
  HTML
  eval RubyWasmUi::Template::Parser.parse(template)
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

## Template Syntax

Ruby expressions can be embedded in HTML templates using `{}`:

```ruby
# Display state values
<div>{state[:message]}</div>

# Conditional rendering
<p class="{state[:is_valid] ? 'text-green-500' : 'text-red-500'}">
  {state[:is_valid] ? 'Valid!' : 'Invalid input'}
</p>

# Event handlers
<button onclick="{->(e) { emit.call('handle_click', e[:target][:value]) }}">
  Click me
</button>

# Input binding
<input 
  type="text" 
  value="{state[:input_value]}"
  oninput="{->(e) { emit.call('update_input', e[:target][:value]) }}"
/>
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
