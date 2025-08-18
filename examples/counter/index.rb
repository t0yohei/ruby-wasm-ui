require "js"

# Counter component using the latest component-based API with TemplateParser
CounterComponent = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    { count: props[:count] }
  },

  # Render the counter component
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <div>{component.state[:count]}</div>
        <button-component
          label="Increment"
          on="{ click_button: -> { component.increment } }">
        </button-component>
        <button-component
          label="Decrement"
          on="{ click_button: -> { component.decrement } }"
        />
      </div>
    HTML
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

# Button component - reusable button with click handler
ButtonComponent = RubyWasmUi.define_component(
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <button on="{ click: ->(e) { component.emit('click_button', e) } }">
        {component.props[:label]}
      </button>
    HTML
  }
)

# app_a to be destroyed
app_a = RubyWasmUi::App.create(CounterComponent, count: 0)
app_element_a = JS.global[:document].getElementById("app-a")
app_a.mount(app_element_a)
app_a.unmount

# app_b to be mounted
app_b = RubyWasmUi::App.create(CounterComponent, count: 10)
app_element_b = JS.global[:document].getElementById("app-b")
app_b.mount(app_element_b)
