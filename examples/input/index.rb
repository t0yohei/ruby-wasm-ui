require "js"

actions = {
  update_url_name: ->(state, value) { state.merge(url_name: value, is_valid: value.length >= 4) }
}

view = ->(state, emit) {
  template = <<~HTML
    <form class='w-full max-w-sm'>
      <label class="block mb-2 text-sm font-medium text-700">
        ユーザー名
      </label>
      <input
        type='text'
        class='{state[:is_valid] ? "bg-green-50 border border-green-500 text-green-900 placeholder-green-700 text-sm rounded-lg focus:ring-green-500 focus:border-green-500 block w-full p-2.5 dark:bg-green-100 dark:border-green-400" : "bg-red-50 border border-red-500 text-red-900 placeholder-red-700 text-sm rounded-lg focus:ring-red-500 focus:border-red-500 block w-full p-2.5 dark:bg-red-100 dark:border-red-400"}'
        oninput='{->(e) { emit.call("update_url_name", e[:target][:value].to_s) }}'
      >
      <template>
        <p class='{state[:is_valid] ? "mt-2 text-sm text-green-600 dark:text-green-500" : "mt-2 text-sm text-red-600 dark:text-red-500"}'>
          {state[:is_valid] ? "有効です" : "ユーザー名は4文字以上にしてください"}
        </p>
        <p>*ユーザー名は4文字以上です</p>
      </template>
    </form>
  HTML
  eval RubyWasmUi::Template::Parser.parse(template)
}

app = RubyWasmUi::App.create(
  state: {
    url_name: '',
    is_valid: false
  },
  view: view,
  actions: actions
)

app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
