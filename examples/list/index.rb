require "js"

ListItem = RubyWasmUi.define_component(
  render: ->(component) {
    template = <<~HTML
      <li>{component.props[:todo]}</li>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  }
)

List = RubyWasmUi.define_component(
  render: ->(component) {
    # Generate the full HTML including the ul and li elements
    todos = component.props[:todos]

    # Create the complete list HTML
    list_html = "<ul>"
    todos.each do |todo|
      list_html += "<li>#{todo}</li>"
    end
    list_html += "</ul>"

    # Parse the complete HTML structure
    vdom_code = RubyWasmUi::Template::Parser.parse(list_html)
    eval(vdom_code)
  }
)

app_element = JS.global[:document].getElementById("app")
todos = ['foo', 'bar', 'baz']
app = RubyWasmUi::App.create(List, { todos: todos })
app.mount(app_element)
