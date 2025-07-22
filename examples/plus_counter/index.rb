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

app_element = JS.global[:document].getElementById("app")
component = counter.new
component.mount(app_element)
