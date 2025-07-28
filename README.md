# ruby-wasm-ui

A modern web frontend framework for Ruby using [ruby.wasm](https://github.com/ruby/ruby.wasm). Write reactive web applications using familiar Ruby syntax and component-based architecture.

**⚠️ Warning: This library is currently under development and subject to frequent breaking changes. Please use with caution and expect API changes in future versions.**

## Features

- **Component-Based Architecture**: Build reusable UI components with state and lifecycle methods
- **Template Parser**: Write HTML templates with embedded Ruby expressions and component support  
- **Virtual DOM**: Efficient DOM updates using a virtual DOM implementation
- **Reactive State Management**: Simple state updates with automatic re-rendering
- **Event Handling**: Intuitive event system using Ruby lambdas
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

# Define a counter component
CounterComponent = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    { count: 0 }
  },

  # Render the component using Template::Parser
  render: ->(component) {
    template = <<~HTML
      <div>
        <h1>Count: {component.state[:count]}</h1>
        <button on="{click: ->(_e) { component.increment }}">+</button>
        <button on="{click: ->(_e) { component.decrement }}">-</button>
      </div>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  },

  # Define component methods
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

# Create and mount the application
app = RubyWasmUi::App.create(CounterComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

## Component Architecture

### Defining Components

Components are defined using `RubyWasmUi.define_component`:

```ruby
MyComponent = RubyWasmUi.define_component(
  # Initial state (optional)
  state: ->(props) {
    { message: "Hello", count: 0 }
  },

  # Render method (required)
  render: ->(component) {
    # Return VDOM using Template::Parser or direct VDOM construction
  },

  # Component methods (optional)
  methods: {
    handle_click: ->() {
      # Update state
      self.update_state(count: self.state[:count] + 1)
    }
  }
)
```

### State Management

Components manage their own state using `update_state`:

```ruby
# Update single value
self.update_state(count: 10)

# Update multiple values
self.update_state(
  count: self.state[:count] + 1,
  message: "Updated!"
)
```

## Template Syntax

### Ruby Expressions

Embed Ruby expressions in HTML using `{}`:

```ruby
template = <<~HTML
  <div>
    <h1>{component.state[:title]}</h1>
    <p class="{component.state[:is_valid] ? 'text-green' : 'text-red'}">
      {component.state[:is_valid] ? 'Valid!' : 'Invalid'}
    </p>
  </div>
HTML
```

### Event Handling

Use the `on` attribute for event handlers:

```ruby
template = <<~HTML
  <button on="{click: ->(_e) { component.handle_click }}">
    Click me
  </button>
  
  <input 
    type="text"
    value="{component.state[:input_value]}"
    on="{input: ->(e) { component.update_input(e[:target][:value].to_s) }}" />
HTML
```

### Component Composition

Use other components within templates:

```ruby
template = <<~HTML
  <div>
    <h1>My App</h1>
    <MyButton text="Click me" on="{click: ->(data) { component.handle_button_click }}" />
    <UserCard user="{component.state[:current_user]}" />
  </div>
HTML
```

## Examples

The repository includes several examples demonstrating different features:

### Counter (`examples/counter`)
Basic increment/decrement counter showing state management and event handling.

### Input Validation (`examples/input`)
Form input with real-time validation and conditional styling.

### Search Field (`examples/search_field`)
Component composition with parent-child communication using events.

### TODO Application (`examples/todos`)
Complex application demonstrating:
- Multiple components
- State management
- Inline editing
- Dynamic lists
- Event handling

### Random Cocktail (`examples/random_cocktail`)
API integration example showing:
- Async operations with Promises
- Loading states
- Error handling
- Image display

## Advanced Usage

### Direct VDOM Construction

For complex scenarios, you can construct VDOM directly:

```ruby
render: ->(component) {
  RubyWasmUi::Vdom.h('div', {}, [
    RubyWasmUi::Vdom.h('h1', {}, ['My App']),
    RubyWasmUi::Vdom.h('button', {
      on: { click: ->(_e) { component.handle_click } }
    }, ['Click me'])
  ])
}
```

### Component Communication

Components can emit events to communicate with parents:

```ruby
# Child component
methods: {
  handle_click: ->() {
    self.emit('button_clicked', { data: 'some data' })
  }
}

# Parent component template
template = <<~HTML
  <ChildComponent on="{button_clicked: ->(data) { component.handle_child_event(data) }}" />
HTML
```

## Development

To run the examples locally:

```bash
# Install dependencies
npm install

# Run production examples
npm run serve:examples

# Run development examples (with local runtime)
npm run serve:examples:dev
```

## Contributing

This project is currently under active development. Contributions are welcome!

## License

MIT
