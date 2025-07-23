require "js"

# h_a to be destroyed
h_a = RubyWasmUi::Vdom.h("div", {}, [RubyWasmUi::Vdom.h("h1", {}, ["Hello, world!"])])
h1_a_element = JS.global[:document].getElementById("h1-a")
RubyWasmUi::Dom::Events.add_event_listener("click", ->(e) { puts "clicked" }, h1_a_element)
RubyWasmUi::Dom::Attributes.set_attributes(h1_a_element, {
  class: "bg-red-500"
})
RubyWasmUi::Dom::Attributes.set_attribute(h1_a_element, "data-test", "test")
RubyWasmUi::Dom::Attributes.set_class(h1_a_element, "bg-blue-500")
RubyWasmUi::Dom::Attributes.set_style(h1_a_element, "background-color", "red")
RubyWasmUi::Dom::Attributes.remove_attribute(h1_a_element, "data-test")
RubyWasmUi::Dom::Attributes.remove_style(h1_a_element, "background-color")

RubyWasmUi::Dom::MountDom.execute(h_a, h1_a_element)
RubyWasmUi::Dom::DestroyDom.execute(h_a)

# h_b to be mounted
h_b = RubyWasmUi::Vdom.h("div", {}, [RubyWasmUi::Vdom.h("h1", {}, ["Hello, world!"])])
h1_b_element = JS.global[:document].getElementById("h1-b")
RubyWasmUi::Dom::Events.add_event_listener("click", ->(e) { puts "clicked" }, h1_b_element)
RubyWasmUi::Dom::Attributes.set_attributes(h1_b_element, {
  class: "bg-red-500"
})
RubyWasmUi::Dom::Attributes.set_attribute(h1_b_element, "data-test", "test")
RubyWasmUi::Dom::Attributes.set_class(h1_b_element, "bg-red-500")
RubyWasmUi::Dom::Attributes.set_style(h1_b_element, "background-color", "blue")
RubyWasmUi::Dom::MountDom.execute(h_b, h1_b_element)
