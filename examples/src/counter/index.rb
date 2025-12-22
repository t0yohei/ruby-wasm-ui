# Counter component using the latest component-based API with TemplateParser
CounterComponent = Ruwi.define_component(
  # Initialize component state
  state: ->(props) {
    { count: props[:count] || 0 }
  },

  # Render the counter component
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <div>{state[:count]}</div>
        <!-- Both ButtonComponent and button-component are valid -->
        <ButtonComponent
          label="Increment"
          on="{ click_button: -> { increment } }">
        </ButtonComponent>
        <button-component
          label="Decrement"
          on="{ click_button: -> { decrement } }"
        />
      </div>
    HTML
},

  # Component methods
  methods: {
    # Increment the counter
    increment: ->() {
      update_state(count: state[:count] + 1)
    },

    # Decrement the counter
    decrement: ->() {
      update_state(count: state[:count] - 1)
    }
  }
)

# Button component - reusable button with click handler
ButtonComponent = Ruwi.define_component(
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <button on="{ click: ->() { emit('click_button') } }">
        {props[:label]}
      </button>
    HTML
  }
)

# app_a to be destroyed
app_a = Ruwi::App.create(CounterComponent, count: 0)
app_element_a = JS.global[:document].getElementById("app-a")
app_a.mount(app_element_a)
app_a.unmount

# app_b to be mounted
app_b = Ruwi::App.create(CounterComponent, count: 10)
app_element_b = JS.global[:document].getElementById("app-b")
app_b.mount(app_element_b)
