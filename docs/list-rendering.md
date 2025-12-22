# List Rendering with r-for

ruwi provides the `r-for` directive for rendering lists of items. You can use `r-for` with both components and regular HTML elements:

```ruby
# Define a reusable list item component
ListItem = Ruwi.define_component(
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>{props[:todo]}</li>
    HTML
  }
)

# Main list component demonstrating r-for usage
List = Ruwi.define_component(
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
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
app = Ruwi::App.create(List, { todos: ['foo', 'bar', 'baz'] })
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
```

## r-for Syntax

The `r-for` directive uses the syntax `"item in collection"` where:

- `item` is the variable name for each iteration
- `collection` is the array or enumerable to iterate over

You can use `r-for` in two ways:

1. **With components**: Pass the current item as props to child components
2. **With HTML elements**: Directly render HTML elements for each item
