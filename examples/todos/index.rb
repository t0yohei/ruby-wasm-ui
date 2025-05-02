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

def create_todo(state, emit)
  RubyWasmUi::Vdom.h("div", {}, [
    RubyWasmUi::Vdom.h("label", { for: "todo-input" }, ["New TODO"]),
    RubyWasmUi::Vdom.h("input", {
      type: "text",
      id: "todo-input",
      value: state[:current_todo],
      oninput: ->(e) { emit.call("update-current-todo", e[:target][:value]) },
      onkeydown: ->(e) {
        if e[:key] == "Enter" && state[:current_todo].length >= 3
          emit.call("add-todo")
        end
      }
    }, []),
    RubyWasmUi::Vdom.h("button", {
      disabled: state[:current_todo].length < 3,
      onclick: ->(_e) { emit.call("add-todo") }
    }, ["Add"])
  ])
end

def todo_item(todo, i, edit, emit)
  is_editing = edit[:idx] == i

  if is_editing
    RubyWasmUi::Vdom.h("li", {}, [
      RubyWasmUi::Vdom.h("input", {
        value: edit[:edited],
        oninput: ->(e) { emit.call("edit-todo", e[:target][:value]) }
      }, []),
      RubyWasmUi::Vdom.h("button", {
        onclick: ->(_e) { emit.call("save-edited-todo") }
      }, ["Save"]),
      RubyWasmUi::Vdom.h("button", {
        onclick: ->(_e) { emit.call("cancel-editing-todo") }
      }, ["Cancel"])
    ])
  else
    RubyWasmUi::Vdom.h("li", {}, [
      RubyWasmUi::Vdom.h("span", {
        ondblclick: ->(_e) { emit.call("start-editing-todo", i) }
      }, [todo]),
      RubyWasmUi::Vdom.h("button", {
        onclick: ->(_e) { emit.call("remove-todo", i) }
      }, ["Done"])
    ])
  end
end

def todo_list(state, emit)
  RubyWasmUi::Vdom.h("ul", {},
    state[:todos].map.with_index { |todo, i| todo_item(todo, i, state[:edit], emit) }
  )
end

view = ->(state, emit) {
  RubyWasmUi::Vdom.h_fragment([
    RubyWasmUi::Vdom.h("h1", {}, ["My TODOs"]),
    create_todo(state, emit),
    todo_list(state, emit)
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
