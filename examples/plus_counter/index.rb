require "js"

Counter = RubyWasmUi.define_component(
  methods: {
    increment: -> {
      update_state(count: state[:count] + 1)
    }
  },
  state: -> (props) { { count: 0 } },
  render: -> (component) {
    template = <<~HTML
      <div>
        <p>Count: {component.state[:count]}</p>
        <button on="{click: ->(e) { component.increment }}">Increment</button>
      </div>
    HTML
    
    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval("[#{vdom_code}]")[0]
  }
)

app_element = JS.global[:document].getElementById("app")
app = RubyWasmUi::App.create(Counter)
app.mount(app_element)
