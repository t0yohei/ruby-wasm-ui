require "js"

# h_a to be destroyed
h_a = RubyWasmUi::Vdom.h("div", {}, [RubyWasmUi::Vdom.h("h1", {}, ["Hello, world!"])])
h1_a_element = JS.global[:document].getElementById("h1-a")
RubyWasmUi::Dom::Events.add_event_listener("click", ->(e) { puts "clicked" }, h1_a_element)
attributes_a = RubyWasmUi::Dom::Attributes.new(h1_a_element)
attributes_a.set_attributes({
  class: "bg-red-500"
})
attributes_a.set_attribute("data-test", "test")
attributes_a.set_class("bg-blue-500")
attributes_a.set_styles({
  "background-color": "red"
})
attributes_a.remove_attribute("data-test")
attributes_a.remove_style("background-color")

RubyWasmUi::Dom::MountDom.execute(h_a, h1_a_element)
RubyWasmUi::Dom::DestroyDom.execute(h_a)

# h_b to be mounted
h_b = RubyWasmUi::Vdom.h("div", {}, [RubyWasmUi::Vdom.h("h1", {}, ["Hello, world!"])])
h1_b_element = JS.global[:document].getElementById("h1-b")
RubyWasmUi::Dom::Events.add_event_listener("click", ->(e) { puts "clicked" }, h1_b_element)
attributes_b = RubyWasmUi::Dom::Attributes.new(h1_b_element)
attributes_b.set_attributes({
  class: "bg-red-500"
})
attributes_b.set_attribute("data-test", "test")
attributes_b.set_class("bg-red-500")
attributes_b.set_styles({
  "background-color": "blue"
})
RubyWasmUi::Dom::MountDom.execute(h_b, h1_b_element)
