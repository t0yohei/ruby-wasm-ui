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

app_element = JS.global[:document].getElementById("app")
todos = ['foo', 'bar', 'baz']
list = List.new({ todos: todos })
list.mount(app_element)
