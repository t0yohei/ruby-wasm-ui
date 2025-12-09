# Simple Hello World component
HelloComponent = RubyWasmUi.define_component(
  state: ->(props) {
    { message: props[:message] || "Hello, Ruby WASM UI!" }
  },
  template: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <h2>{state[:message]}</h2>
        <button on="{ click: -> { update_message } }">
          Click me!
        </button>
      </div>
    HTML
  },
  methods: {
    update_message: ->() {
      update_state(message: "You clicked the button!")
    }
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(HelloComponent, message: "Hello, Ruby WASM UI!")
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
