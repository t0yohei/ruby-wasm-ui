# Conditional Rendering with r-if

ruwi provides the `r-if` directive for conditional rendering of elements based on state or computed values:

```ruby
# Component demonstrating r-if conditional rendering
ConditionalComponent = Ruwi.define_component(
  state: ->() {
    {
      show_message: false,
      counter: 0
    }
  },

  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <!-- Simple boolean condition -->
        <div r-if="{state[:show_message]}">
          <p>This message is conditionally rendered!</p>
        </div>

        <!-- Using r-if, r-elsif, r-else for multiple conditions -->
        <div r-if="{state[:counter] > 0}">
          <p>Counter is positive: {state[:counter]}</p>
        </div>

        <div r-elsif="{state[:counter] < 0}">
          <p>Counter is negative: {state[:counter]}</p>
        </div>

        <div r-else>
          <p>Counter is zero</p>
        </div>

        <!-- Toggle button -->
        <button on="{click: ->() { toggle_message }}">
          {state[:show_message] ? "Hide" : "Show"} Message
        </button>
      </div>
    HTML
  },

  methods: {
    toggle_message: ->() {
      update_state(show_message: !state[:show_message])
    }
  }
)
```

## r-if, r-elsif, r-else Syntax

The conditional directives work together to create if-elsif-else chains:

### Basic Usage

- **`r-if="{condition}"`**: Renders the element when condition is truthy
- **`r-elsif="{condition}"`**: Renders when previous conditions are falsy and this condition is truthy
- **`r-else`**: Renders when all previous conditions are falsy (no condition needed)

### Expression Evaluation

All conditional expressions are evaluated as Ruby code within curly braces `{}`:

- Use any valid Ruby expression that returns a truthy or falsy value
- Access component state with `state[:key]`
- Access props with `props[:key]`
- Support for comparison operators (`>`, `<`, `==`, `!=`, etc.)
- Support for logical operators (`&&`, `||`, `!`)
- Support for method calls and complex expressions

### Conditional Chain Rules

1. **Sequential Processing**: Conditions are evaluated in order (r-if → r-elsif → r-else)
2. **Mutual Exclusivity**: Only one element in a conditional chain will render
3. **Grouping**: Consecutive conditional elements form a single conditional group
4. **Breaking**: A new `r-if` breaks the current conditional chain and starts a new one

### Advanced Example

```ruby
# Real-world example with loading states and data
LoadingComponent = Ruwi.define_component(
  state: ->() {
    {
      is_loading: false,
      data: nil,
      error: nil
    }
  },

  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <!-- Loading state -->
        <p r-if="{state[:is_loading]}">Loading...</p>

        <!-- Error state -->
        <div r-elsif="{state[:error]}" style="color: red;">
          <p>Error: {state[:error]}</p>
          <button on="{click: ->() { retry_load }}">Retry</button>
        </div>

        <!-- Success state with data -->
        <div r-elsif="{state[:data]}">
          <h2>{state[:data][:title]}</h2>
          <p>{state[:data][:description]}</p>
        </div>

        <!-- Initial state (no loading, no error, no data) -->
        <button r-else on="{click: ->() { load_data }}">
          Load Data
        </button>
      </div>
    HTML
  }
)
```
