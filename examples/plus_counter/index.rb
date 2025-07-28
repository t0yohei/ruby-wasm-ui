require "js"

counter = RubyWasmUi.define_component(
  methods: {
    increment: -> {
      update_state(count: state[:count] + 1)
    }
  },
  state: -> (props) { { count: 0 } },
  render: -> (component) {
    RubyWasmUi::Vdom.h("div", {}, [
      RubyWasmUi::Vdom.h("p", {}, ["Count: #{component.state[:count]}"]),
      RubyWasmUi::Vdom.h(
        "button",
        {
          on: {
            click: ->(e) { component.increment }
          }
        },
        ["Increment"]
      )
    ])
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(counter)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
