require "js"

# SearchField component definition
SearchField = RubyWasmUi.define_component(
  render: ->(component) {
    RubyWasmUi::Vdom.h('input', {
      type: 'text',
      placeholder: 'Search...',
      value: component.props[:value],
      on: {
        input: ->(event) { component.emit('search', event[:target][:value].to_s) }
      }
    })
  }
)

# Demo component to show the search functionality
SearchDemo = RubyWasmUi.define_component(
  state: ->(props) {
    { search_term: '' }
  },
  render: ->(component) {
    RubyWasmUi::Vdom.h_fragment([
      RubyWasmUi::Vdom.h('div', {}, [
        RubyWasmUi::Vdom.h('h2', {}, ['Search Demo']),
        RubyWasmUi::Vdom.h(SearchField, { on: { search: ->(search_term) { component.update_state({ search_term: search_term }) } }, value: component.state[:search_term] }, []),
        RubyWasmUi::Vdom.h('p', {}, ["Current search term: #{component.state[:search_term]}"])
      ])
    ])
  }
)

app_element = JS.global[:document].getElementById("app")
search_demo = SearchDemo.new({}, {})
search_demo.mount(app_element)
