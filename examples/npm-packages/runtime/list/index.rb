require "js"

ListItem = Ruwi.define_component(
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>{props[:todo]}</li>
    HTML
  }
)

List = Ruwi.define_component(
  template: ->() {

    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <ul>
        <!-- component -->
        <ListItem
          r-for="{todo in props[:todos]}"
          todo="{todo}"
        />
        <!-- element -->
        <li r-for="todo in props[:todos]">
          { todo }
        </li>
      </ul>
    HTML
  }
)

# Create and mount the app
app = Ruwi::App.create(List, { todos: ['foo', 'bar', 'baz'] })
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
