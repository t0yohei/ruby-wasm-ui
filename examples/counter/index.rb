require "js"

# Counter component using the latest component-based API
CounterComponent = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    { count: 0 }
  },

  # Render the counter component
  render: ->(component) {
    state = component.state

    RubyWasmUi::Vdom.h("div", {}, [
      RubyWasmUi::Vdom.h("div", {}, [state[:count].to_s]),
      RubyWasmUi::Vdom.h("button", {
        on: { click: ->(_e) { component.increment } }
      }, ["Increment"]),
      RubyWasmUi::Vdom.h("button", {
        on: { click: ->(_e) { component.decrement } }
      }, ["Decrement"])
    ])
  },

  # Component methods
  methods: {
    # Increment the counter
    increment: ->() {
      state = self.state
      self.update_state(count: state[:count] + 1)
    },

    # Decrement the counter
    decrement: ->() {
      state = self.state
      self.update_state(count: state[:count] - 1)
    }
  }
)

# app_a to be destroyed
app_a = RubyWasmUi::App.create(CounterComponent)
app_element_a = JS.global[:document].getElementById("app-a")
app_a.mount(app_element_a)
app_a.unmount

# app_b to be mounted
app_b = RubyWasmUi::App.create(CounterComponent)
app_element_b = JS.global[:document].getElementById("app-b")
app_b.mount(app_element_b)
