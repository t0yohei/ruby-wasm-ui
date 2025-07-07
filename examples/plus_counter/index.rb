require "js"

counter = RubyWasmUi::Component.define_component(
  state: -> (props) { { count: 0 } },
  render: -> (component) {
    RubyWasmUi::Vdom.h("div", {}, [
      RubyWasmUi::Vdom.h("p", {}, ["Count: #{component.state[:count]}"]),
      RubyWasmUi::Vdom.h(
        "button",
        {
          onclick: ->(e) { component.update_state(count: component.state[:count] + 1) }
        },
        ["Increment"]
      )
    ])
  }
)

app_element = JS.global[:document].getElementById("app")
component = counter.new
component.mount(app_element)
