require "js"

actions = {
  "update-current-todo": ->(state, current_todo) {
    state.merge(current_todo: current_todo.to_s)
  },

  "add-todo": ->(state, _payload) {
    state.merge(
      current_todo: "",
      todos: state[:todos] + [state[:current_todo]]
    )
  },

  "start-editing-todo": ->(state, idx) {
    state.merge(
      edit: {
        idx: idx,
        original: state[:todos][idx],
        edited: state[:todos][idx]
      }
    )
  },

  "edit-todo": ->(state, edited) {
    state.merge(
      edit: state[:edit].merge(edited: edited)
    )
  },

  "save-edited-todo": ->(state, _payload) {
    todos = state[:todos].dup
    todos[state[:edit][:idx]] = state[:edit][:edited]

    state.merge(
      edit: { idx: nil, original: nil, edited: nil },
      todos: todos
    )
  },

  "cancel-editing-todo": ->(state, _payload) {
    state.merge(
      edit: { idx: nil, original: nil, edited: nil }
    )
  },

  "remove-todo": ->(state, idx) {
    state.merge(
      todos: state[:todos].reject.with_index { |_, i| i == idx }
    )
  }
}

def create_todo_template(state, emit)
  template = <<~HTML
    <div>
      <label for="todo-input">New TODO</label>
      <input
        type="text"
        id="todo-input"
        value="{state[:current_todo]}"
        oninput="{->(e) { emit.call('update-current-todo', e[:target][:value]) }}"
        onkeydown="{->(e) { emit.call('add-todo') if e[:key] == 'Enter' && state[:current_todo].length >= 3 }}"
      />
      <button
        disabled="{state[:current_todo].length < 3}"
        onclick="{->(_e) { emit.call('add-todo') }}"
      >
        Add
      </button>
    </div>
  HTML
  eval RubyWasmUi::Template::Parser.parse(template)
end

def todo_item_template(todo, i, is_editing, edit, emit)
  if is_editing
    template = <<~HTML
      <li>
        <input
          value="{edit[:edited]}"
          oninput="{->(e) { emit.call('edit-todo', e[:target][:value]) }}"
        />
        <button onclick="{->(_e) { emit.call('save-edited-todo') }}">Save</button>
        <button onclick="{->(_e) { emit.call('cancel-editing-todo') }}">Cancel</button>
      </li>
    HTML
  else
    template = <<~HTML
      <li>
        <span ondblclick="{->(_e) { emit.call('start-editing-todo', #{i}) }}">{todo}</span>
        <button onclick="{->(_e) { emit.call('remove-todo', #{i}) }}">Done</button>
      </li>
    HTML
  end
  eval RubyWasmUi::Template::Parser.parse(template)
end

def todo_list_template(state, emit)
  items = state[:todos].map.with_index do |todo, i|
    is_editing = state[:edit][:idx] == i
    todo_item_template(todo, i, is_editing, state[:edit], emit)
  end

  RubyWasmUi::Vdom.h("ul", {}, items)
end

view = ->(state, emit) {
  template = <<~HTML
    <template>
      <h1>My TODOs</h1>
    </template>
  HTML

  RubyWasmUi::Vdom.h_fragment([
    eval(RubyWasmUi::Template::Parser.parse(template)),
    create_todo_template(state, emit),
    todo_list_template(state, emit)
  ])
}

app = RubyWasmUi::App.create(
  state: {
    current_todo: "",
    edit: {
      idx: nil,
      original: nil,
      edited: nil
    },
    todos: ["Walk the dog", "Water the plants"]
  },
  view: view,
  actions: actions
)

app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
