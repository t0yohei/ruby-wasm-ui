require "js"

# Counter component using the latest component-based API
CounterComponent = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    { count: 0 }
  },

  # Render the counter component
  render: ->(component) {
    template = <<~HTML
      <div>
        <div>{component.state[:count]}</div>
        <button on="{click: ->(_e) { component.increment }}">Increment</button>
        <button on="{click: ->(_e) { component.decrement }}">Decrement</button>
      </div>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
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
