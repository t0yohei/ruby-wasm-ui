require "js"

CounterComponent = RubyWasmUi.define_component(
  methods: {
    increment: -> {
      update_state(count: state[:count] + 1)
    }
  },
  state: -> (props) { { count: 0 } },
  render: -> (component) {
    template = <<~HTML
      <div>
        <p>Count: {component.state[:count]} .</p>
        <button onclick="{->(_e) { component.increment }}">Increment</button>
      </div>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(CounterComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
