# ruwi

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
    <script src="https://unpkg.com/ruwi@0.9.1"></script>
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
CounterComponent = Ruwi.define_component(
  # Initialize component state
  state: ->(props) {
    { count: props[:count] || 0 }
  },

  # Render the counter component
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
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
ButtonComponent = Ruwi.define_component(
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <button on="{ click: ->() { emit('click_button') } }">
        {props[:label]}
      </button>
    HTML
  }
)

# Create and mount the app
app = Ruwi::App.create(CounterComponent, count: 5)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

## Using as a Gem

You can also use `ruwi` as a Ruby gem with `rbwasm` to build your application as a WASM file.

### Setup

1. Add `ruwi` to your `Gemfile`:

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gem "ruwi"
```

2. Install dependencies:

```bash
bundle install
```

### Building Your Application

Set up your project (first time only):

```bash
bundle exec ruwi setup
```

This command will:
- Configure excluded gems for WASM build
- Build Ruby WASM file
- Update `.gitignore`
- Create initial `src/index.html` and `src/index.rb` files

The setup command will configure your project structure as follows:

```
my-app/
├── Gemfile
└── src/
    ├── index.rb
    └── index.html
```


### Develop Your Application

- **Development server**: Start a development server with file watching and auto-build:
  ```bash
  bundle exec ruwi dev
  ```

Create an HTML file in the `src` directory that loads the WASM file:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>My App</title>
    <script type="module">
      import { DefaultRubyVM } from "https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.7.2/dist/browser/+esm";
      const response = await fetch("../src.wasm");
      const module = await WebAssembly.compileStreaming(response);
      const { vm } = await DefaultRubyVM(module);
      vm.evalAsync(`
        require "ruwi"
        require_relative './src/index.rb'
      `);
    </script>
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

Your `src/index.rb` file can use `ruwi` just like in the Quick Start example:

```ruby
CounterComponent = Ruwi.define_component(
  state: ->(props) {
    { count: props[:count] || 0 }
  },
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <div>{state[:count]}</div>
        <button on="{ click: -> { increment } }">Increment</button>
      </div>
    HTML
  },
  methods: {
    increment: ->() {
      update_state(count: state[:count] + 1)
    }
  }
)

app = Ruwi::App.create(CounterComponent, count: 0)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

See the [examples](examples) directory for a complete working example.


**Additional Commands:**

- **Rebuild Ruby WASM**: Rebuild the Ruby WASM file when you add new gems:
  ```bash
  bundle exec ruwi rebuild
  ```

### Deployment

Pack your application files for deployment:

```bash
bundle exec ruwi pack
```

This command packs your Ruby files from the `./src` directory into the WASM file and outputs to the `dist` directory for deployment.

## Documentation

- [Conditional Rendering with r-if](docs/conditional-rendering.md)
- [List Rendering with r-for](docs/list-rendering.md)
- [Lifecycle Hooks](docs/lifecycle-hooks.md)

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
