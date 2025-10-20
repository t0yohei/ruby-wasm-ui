require "js"

ListItem = RubyWasmUi.define_component(
  template: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>{props[:todo]}</li>
    HTML
  }
)

List = RubyWasmUi.define_component(
  template: ->() {

    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
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
app = RubyWasmUi::App.create(List, { todos: ['foo', 'bar', 'baz'] })
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
