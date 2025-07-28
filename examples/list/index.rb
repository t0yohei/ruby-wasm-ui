require "js"

ListItem = RubyWasmUi.define_component(
  render: ->(component) {
    todo = component.props[:todo]
    RubyWasmUi::Vdom.h("li", {}, [todo])
  }
)

List = RubyWasmUi.define_component(
  render: ->(component) {
    todos = component.props[:todos]
    list_items = todos.map { |todo| RubyWasmUi::Vdom.h(ListItem, { todo: todo }) }
    RubyWasmUi::Vdom.h("ul", {}, list_items)
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(List, { todos: ['foo', 'bar', 'baz'] })
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
