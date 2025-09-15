require "js"

# Component with argument-less on_mounted that can call component methods directly
SimpleComponent = RubyWasmUi.define_component(
  state: -> { { message: "Not mounted yet" } },

  # on_mounted without arguments - can call update_state directly!
  on_mounted: -> {
    puts "SimpleComponent mounted without arguments!"
    update_state(message: "Mounted and state updated without component argument!")
  },

  render: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <h2>Simple Component (no args in on_mounted)</h2>
        <p>{state[:message]}</p>
      </div>
    HTML
  }
)

# Component with on_mounted that takes component argument (existing behavior)
AdvancedComponent = RubyWasmUi.define_component(
  state: -> { { message: "Not mounted yet" } },

  # on_mounted with component argument - existing behavior still works
  on_mounted: ->() {
    puts "AdvancedComponent mounted with component argument!"
    update_state(message: "Mounted and state updated!")
  },

  render: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <h2>Advanced Component (with args in on_mounted)</h2>
        <p>{state[:message]}</p>
      </div>
    HTML
  }
)

# Main App component
AppComponent = RubyWasmUi.define_component(
  render: -> {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <h1>on_mounted Demo</h1>
        <SimpleComponent />
        <AdvancedComponent />
      </div>
    HTML
  }
)

# Mount the app
app = RubyWasmUi::App.create(AppComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
