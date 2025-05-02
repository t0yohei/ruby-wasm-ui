require "js"

h = RubyWasmUi::H.new("div", {}, [RubyWasmUi::H.new("h1", {}, ["Hello, world!"])])

element = JS.global[:document].getElementById("h1")

RubyWasmUi::Dom::Events.add_event_listener("click", ->(e) { puts "clicked" }, element)

attributes = RubyWasmUi::Dom::Attributes.new(element)
attributes.set_attributes({
  class: "bg-red-500"
})
attributes.set_attribute("data-test", "test")

attributes.set_class("bg-blue-500")
attributes.set_styles({
  "background-color": "red"
})
# attributes.remove_attribute("data-test")
# attributes.remove_style("background-color")

RubyWasmUi::Dom::MountDom.mount(h, element)

# RubyWasmUi::Dom::DestroyDom.destroy(h)

view = ->(state, emit) {
  RubyWasmUi::H.new("div", {}, [
    RubyWasmUi::H.new("div", {}, [state[:count]]),
    RubyWasmUi::H.new("button", { onclick: ->(e) { emit.call(:increment) } }, ["Increment"])
  ])
}

app = RubyWasmUi::App.create(
  state: {
    count: 0
  },
  view:,
  reducers: {
    increment: ->(state, payload) {
      { count: state[:count] + 1 }
    }
  }
)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
