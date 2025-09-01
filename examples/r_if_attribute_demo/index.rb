require "js"

# R-If Attribute Demo component to demonstrate conditional rendering using r-if attribute
RIfAttributeDemo = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    {
      show_message: false,
      counter: 0
    }
  },

  # Render the component with r-if attribute examples
  render: ->(component) {
    state = component.state
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <h1>r-if Attribute Demo</h1>
        <p>Using r-if as an attribute (like Vue.js r-if)</p>

        <!-- Example 1: Simple boolean toggle -->
        <div style="border: 1px solid #ccc; margin: 10px 0; padding: 10px;">
          <h2>Toggle Message</h2>
          <button
            style="background: #007bff; color: white; padding: 8px 16px; border: none; cursor: pointer;"
            on="{click: ->(e) { component.toggle_message }}"
          >
            {state[:show_message] ? "Hide" : "Show"} Message
          </button>

          <div
            style="background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 10px; margin-top: 10px;"
            r-if="{state[:show_message]}"
          >
            <p>This message is conditionally rendered using r-if attribute!</p>
          </div>
        </div>

        <!-- Example 2: Counter-based condition -->
        <div style="border: 1px solid #ccc; margin: 10px 0; padding: 10px;">
          <h2>Counter Conditions</h2>
          <button
            style="background: #28a745; color: white; padding: 8px 16px; border: none; cursor: pointer; margin-right: 5px;"
            on="{click: ->(e) { component.increment_counter }}"
          >
            +1
          </button>
          <button
            style="background: #dc3545; color: white; padding: 8px 16px; border: none; cursor: pointer; margin-right: 5px;"
            on="{click: ->(e) { component.decrement_counter }}"
          >
            -1
          </button>
          <button
            style="background: #6c757d; color: white; padding: 8px 16px; border: none; cursor: pointer;"
            on="{click: ->(e) { component.reset_counter }}"
          >
            Reset
          </button>

          <p>Counter: <strong>{state[:counter]}</strong></p>

          <div
            style="background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 10px; margin: 5px 0;"
            r-if="{state[:counter] > 0}"
          >
            <p>Counter is positive! ({state[:counter]})</p>
          </div>

          <div
            style="background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 10px; margin: 5px 0;"
            r-if="{state[:counter] < 0}"
          >
            <p>Counter is negative! ({state[:counter]})</p>
          </div>

          <div
            style="background: #e2e3e5; border: 1px solid #d6d8db; color: #383d41; padding: 10px; margin: 5px 0;"
            r-if="{state[:counter] == 0}"
          >
            <p>Counter is zero.</p>
          </div>
        </div>
      </div>
    HTML
  },

  # Component methods
  methods: {
    # Toggle the message visibility
    toggle_message: ->() {
      self.update_state(show_message: !self.state[:show_message])
    },

    # Increment the counter
    increment_counter: ->() {
      self.update_state(counter: self.state[:counter] + 1)
    },

    # Decrement the counter
    decrement_counter: ->() {
      self.update_state(counter: self.state[:counter] - 1)
    },

    # Reset the counter to zero
    reset_counter: ->() {
      self.update_state(counter: 0)
    }
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(RIfAttributeDemo)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
