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
    <script src="https://unpkg.com/ruby-wasm-ui@0.7.0"></script>
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
    { count: props[:count] || 0 }
  },

  # Render the counter component
  template: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <div>{state[:count]}</div>
        <!-- Both ButtonComponent and button-component are valid -->
        <ButtonComponent
          label="Increment"
          on="{ click_button: -> { increment } }">
        </ButtonComponent>
        <button-component
          label="Decrement"
          on="{ click_button: -> { decrement } }"
        />
      </div>
    HTML
  },

  # Component methods
  methods: {
    increment: ->() {
      update_state(count: state[:count] + 1)
    },
    decrement: ->() {
      update_state(count: state[:count] - 1)
    }
  }
)

# Button component - reusable button with click handler
ButtonComponent = RubyWasmUi.define_component(
  template: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <button on="{ click: ->() { emit('click_button') } }">
        {props[:label]}
      </button>
    HTML
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(CounterComponent, count: 5)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

## List Rendering with r-for

ruby-wasm-ui provides the `r-for` directive for rendering lists of items. You can use `r-for` with both components and regular HTML elements:

```ruby
# Define a reusable list item component
ListItem = RubyWasmUi.define_component(
  template: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>{props[:todo]}</li>
    HTML
  }
)

# Main list component demonstrating r-for usage
List = RubyWasmUi.define_component(
  template: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <ul>
        <!-- Using r-for with a component -->
        <ListItem
          r-for="{todo in props[:todos]}"
          todo="{todo}"
        />

        <!-- Using r-for with regular HTML elements -->
        <li r-for="todo in props[:todos]">
          { todo }
        </li>
      </ul>
    HTML
  }
)

# Create and mount the app with initial data
app = RubyWasmUi::App.create(List, { todos: ['foo', 'bar', 'baz'] })
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

### r-for Syntax

The `r-for` directive uses the syntax `"item in collection"` where:

- `item` is the variable name for each iteration
- `collection` is the array or enumerable to iterate over

You can use `r-for` in two ways:

1. **With components**: Pass the current item as props to child components
2. **With HTML elements**: Directly render HTML elements for each item

## Lifecycle Hooks

Components support lifecycle hooks to execute code at specific points in a component's lifecycle:

```ruby
RandomCocktailComponent = RubyWasmUi.define_component(
  state: ->() {
    {
      is_loading: false,
      cocktail: nil
    }
  },

  methods: {
    fetch_cocktail: -> {
      # Set loading state
      update_state(is_loading: true, cocktail: nil)

      # Use Fiber for asynchronous API call
      Fiber.new do
        response = JS.global.fetch("https://www.thecocktaildb.com/api/json/v1/1/random.php").await
        response.call(:json).then(->(data) {
          update_state(is_loading: false, cocktail: data[:drinks][0])
        }).catch(->(error) {
          update_state(is_loading: false, cocktail: nil)
        })
      end.transfer
    }
  },

  # Called after the component is mounted to the DOM
  on_mounted: ->() {
    fetch_cocktail
  },

  template: ->() {
    is_loading = state[:is_loading] # Used in template
    cocktail = state[:cocktail] # Used in template

    template = <<~HTML
      <div>
        <p r-if="{is_loading}">Loading...</p>
        <button r-elsif="{cocktail.nil?}" on="{click: ->() { fetch_cocktail }}">
          Get a cocktail
        </button>
        <template r-else>
          <h2>{cocktail['strDrink']}</h2>
          <p>{cocktail['strInstructions']}</p>
          <img src="{cocktail['strDrinkThumb']}" alt="{cocktail['strDrink']}" style="width: 300px; height: 300px" />
          <button on="{click: ->() { fetch_cocktail }}">
            Get another cocktail
          </button>
        </template>
      </div>
    HTML

    RubyWasmUi::Template::Parser.parse_and_eval(template, binding)
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
