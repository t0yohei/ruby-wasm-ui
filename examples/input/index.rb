require "js"

# Input component using the latest component-based API
InputComponent = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    {
      url_name: '',
      is_valid: false
    }
  },

  # Render the input component
  render: ->(component) {
    state = component.state
    
    valid_class = "bg-green-50 border border-green-500 text-green-900 placeholder-green-700 text-sm rounded-lg focus:ring-green-500 focus:border-green-500 block w-full p-2.5 dark:bg-green-100 dark:border-green-400"
    invalid_class = "bg-red-50 border border-red-500 text-red-900 placeholder-red-700 text-sm rounded-lg focus:ring-red-500 focus:border-red-500 block w-full p-2.5 dark:bg-red-100 dark:border-red-400"
    
    template = <<~HTML
      <form class="w-full max-w-sm">
        <label class="block mb-2 text-sm font-medium text-700">ユーザー名</label>
        <input
          type="text"
          value="{state[:url_name]}"
          class="{state[:is_valid] ? valid_class : invalid_class}"
          on="{input: ->(e) { component.update_url_name(e[:target][:value].to_s) }}" />
        <p class="{state[:is_valid] ? 'mt-2 text-sm text-green-600 dark:text-green-500' : 'mt-2 text-sm text-red-600 dark:text-red-500'}">
          {state[:is_valid] ? "有効です" : "ユーザー名は4文字以上にしてください"}
        </p>
        <p>*ユーザー名は4文字以上です</p>
      </form>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  },

  # Component methods
  methods: {
    # Update the URL name and validation status
    # @param value [String] The new URL name value
    update_url_name: ->(value) {
      self.update_state(
        url_name: value,
        is_valid: value.length >= 4
      )
    }
  }
)

app = RubyWasmUi::App.create(InputComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
