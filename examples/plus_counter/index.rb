require "js"

# counter-component
Counter = RubyWasmUi.define_component(
  state: -> { { count: 0 } },
  methods: {
    increment: -> {
      update_state(count: state[:count] + 1)
    }
  },
  template: -> () {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <p>Count: {state[:count]}</p>
        <button on="{ click: -> { increment } }">Increment</button>
      </div>
    HTML
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(Counter)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
