require "js"

CounterComponent = RubyWasmUi.define_component(
  state: -> { { count: 0 } },
  methods: {
    increment: -> {
      update_state(count: state[:count] + 1)
    }
  },
  render: -> (component) {
    template = <<~HTML
      <div>
        <p>Count: {component.state[:count]} .</p>
        <button on="{click: ->(_e) { component.increment }}">Increment</button>
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
