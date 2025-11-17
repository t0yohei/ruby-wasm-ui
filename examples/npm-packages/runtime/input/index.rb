require "js"

# input-form component using the latest component-based API
InputForm = RubyWasmUi.define_component(
  # Initialize component state
  state: ->() {
    {
      url_name: '',
      is_valid: false
    }
  },

  # Render the input component
  template: ->() {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <form class="w-full max-w-sm">
        <label class="block mb-2 text-sm font-medium text-700">User Name</label>
        <input
          type="text"
          value="{state[:url_name]}"
          class="{state[:is_valid] ? 'bg-green-50 border border-green-500 text-green-900 placeholder-green-700 text-sm rounded-lg focus:ring-green-500 focus:border-green-500 block w-full p-2.5 dark:bg-green-100 dark:border-green-400' : 'bg-red-50 border border-red-500 text-red-900 placeholder-red-700 text-sm rounded-lg focus:ring-red-500 focus:border-red-500 block w-full p-2.5 dark:bg-red-100 dark:border-red-400'}"
          on="{input: ->(e) { update_url_name(e[:target][:value].to_s) }}" />
        <p class="{state[:is_valid] ? 'mt-2 text-sm text-green-600 dark:text-green-500' : 'mt-2 text-sm text-red-600 dark:text-red-500'}">
          {state[:is_valid] ? "Valid" : "User name must be at least 4 characters"}
        </p>
        <p>*User name must be at least 4 characters</p>
      </form>
    HTML
  },

  # Component methods
  methods: {
    # Update the URL name and validation status
    # @param value [String] The new URL name value
    update_url_name: ->(value) {
      update_state(
        url_name: value,
        is_valid: value.length >= 4
      )
    }
  }
)

app = RubyWasmUi::App.create(InputForm)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
