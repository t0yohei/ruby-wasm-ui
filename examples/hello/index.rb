require "js"
puts "Hello, world!"

h = RubyWasmUi::H.new("div", {}, [RubyWasmUi::H.new("h1", {}, ["Hello, world!"])])
puts h.to_s
puts h.inspect

element = JS.global[:document].getElementById("app")

RubyWasmUi::Dom::Events.add_event_listener("click", ->(e) { puts "clicked" }, element)

attributes = RubyWasmUi::Dom::Attributes.new(element)
attributes.set_attributes({
  class: "bg-red-500"
})
attributes.set_attribute("data-test", "test")

puts attributes.inspect
puts element.inspect
puts element[:className].inspect

attributes.set_class("bg-blue-500")
attributes.set_styles({
  "background-color": "red"
})
# attributes.remove_attribute("data-test")
# attributes.remove_style("background-color")

RubyWasmUi::Dom::MountDom.mount(h, element)

# RubyWasmUi::Dom::DestroyDom.destroy(h)

# state = {
#   url_name: '',
# }

# actions = {
#   update_url_name: ->(state, value) { state[:url_name] = value }
# }

# view = ->(state, actions) {
#   isvalid = state[:url_name].length >= 4

#   h(:form, { class: "w-full max-w-sm" }, [
#     h(:label, { class: "block mb-2 text-sm font-medium text-700 dark:text-500" }, ['ユーザー名']),
#     h(:input, {
#       type: 'text',
#       class: isvalid ? "bg-green-50 border border-green-500 text-green-900 placeholder-green-700 text-sm rounded-lg focus:ring-green-500 focus:border-green-500 block w-full p-2.5 dark:bg-green-100 dark:border-green-400" : "bg-red-50 border border-red-500 text-red-900 placeholder-red-700 text-sm rounded-lg focus:ring-red-500 focus:border-red-500 block w-full p-2.5 dark:bg-red-100 dark:border-red-400",
#       oninput: ->(e) { actions[:update_url_name].call(state, e[:target][:value].to_s) }
#     }, []),
#     h(:p, { class: isvalid ? "mt-2 text-sm text-green-600 dark:text-green-500" : "mt-2 text-sm text-red-600 dark:text-red-500" }, [isvalid ? "有効です" : "ユーザー名は4文字以上にしてください"])
#   ])
# }

# App.new(
#   el: "#app",
#   state:,
#   view:,
#   actions:
# )
