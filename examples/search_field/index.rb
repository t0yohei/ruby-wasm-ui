require "js"

# SearchField component definition
SearchField = RubyWasmUi.define_component(
  render: ->(component) {
    template = <<~HTML
      <input
        type="text"
        placeholder="Search..."
        value="{component.props[:value]}"
        on="{input: ->(event) { component.emit('search', event[:target][:value].to_s) }}" />
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  }
)

# Demo component to show the search functionality
SearchDemo = RubyWasmUi.define_component(
  state: ->(props) {
    { search_term: '' }
  },
  render: ->(component) {
    template = <<~HTML
      <div>
        <h2>Search Demo</h2>
        <SearchField on="{search: ->(search_term) { component.update_state({ search_term: search_term }) }}" value="{component.state[:search_term]}"></SearchField>
        <p>Current search term: {component.state[:search_term]}</p>
      </div>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  }
)

app_element = JS.global[:document].getElementById("app")
app = RubyWasmUi::App.create(SearchDemo)
app.mount(app_element)
