require "js"

# search-field component definition
SearchField = Ruwi.define_component(
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <input
        type="text"
        placeholder="Search..."
        value="{props[:value]}"
        on="{ input: ->(event) { emit('search', event[:target][:value].to_s) } }"
      />
    HTML
  }
)

# search-demo component to show the search functionality
SearchDemo = Ruwi.define_component(
  state: ->() {
    { search_term: '' }
  },
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <template>
        <h2>Search Demo</h2>
        <search-field
          value="{state[:search_term]}"
          on="{ search: ->(search_term) { update_state({ search_term: search_term }) } }"
        />
        <p>Current search term: {state[:search_term]}</p>
      </template>
    HTML
  }
)

# Create and mount the app
app = Ruwi::App.create(SearchDemo)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
