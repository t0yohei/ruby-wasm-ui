require "js"

actions = {
  increment: ->(state, _payload) {
    { count: state[:count] + 1 }
  },
  decrement: ->(state, _payload) {
    { count: state[:count] - 1 }
  }
}

view = ->(state, emit) {
  RubyWasmUi::Vdom.h("div", {}, [
    RubyWasmUi::Vdom.h("div", {}, [state[:count]]),
    RubyWasmUi::Vdom.h("button", { onclick: ->(e) { emit.call(:increment) } }, ["Increment"]),
    RubyWasmUi::Vdom.h("button", { onclick: ->(e) { emit.call(:decrement) } }, ["Decrement"])
  ])
}

# app_a to be destroyed
app_a = RubyWasmUi::App.create(
  state: {
    count: 0
  },
  view:,
  actions:
)
app_element_a = JS.global[:document].getElementById("app-a")
app_a.mount(app_element_a)
app_a.unmount

# app_b to be mounted
app_b = RubyWasmUi::App.create(
  state: {
    count: 0
  },
  view:,
  actions:
)
app_element_b = JS.global[:document].getElementById("app-b")
app_b.mount(app_element_b)
