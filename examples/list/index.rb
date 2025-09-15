require "js"

ListItem = RubyWasmUi.define_component(
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>{component.props[:todo]}</li>
    HTML
  }
)

List = RubyWasmUi.define_component(
  render: ->(component) {
    todos = component.props[:todos]
    list_items = todos.map { |todo| ListItem.new(todo: todo) }
    RubyWasmUi::Vdom.h("ul", {}, list_items.map { |item| item.render })
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(List, { todos: ['foo', 'bar', 'baz'] })
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
