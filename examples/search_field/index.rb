require "js"

# search-field component definition
SearchField = RubyWasmUi.define_component(
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <input
        type="text"
        placeholder="Search..."
        value="{component.props[:value]}"
        on="{ input: ->(event) { component.emit('search', event[:target][:value].to_s) } }"
      />
    HTML
  }
)

# search-demo component to show the search functionality
SearchDemo = RubyWasmUi.define_component(
  state: ->() {
    { search_term: '' }
  },
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <template>
        <h2>Search Demo</h2>
        <search-field
          value="{component.state[:search_term]}"
          on="{ search: ->(search_term) { component.update_state({ search_term: search_term }) } }"
        />
        <p>Current search term: {component.state[:search_term]}</p>
      </template>
    HTML
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(SearchDemo)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
