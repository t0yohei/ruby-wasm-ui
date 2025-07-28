require "js"

Counter = RubyWasmUi.define_component(
  state: ->(props) {
    {
      count: 0
    }
  },

  render: ->(component) {
    template = <<~HTML
      <div>
        <h1>Counter</h1>
        <p>{component.state[:count]}</p>
        <button on="{click: ->(_e) { component.increment }}">+</button>
      </div>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  },

  methods: {
    increment: ->() {
      state = self.state
      self.update_state(count: state[:count] + 1)
    }
  }
)

app_element = JS.global[:document].getElementById("app")
app = RubyWasmUi::App.create(Counter)
app.mount(app_element)
