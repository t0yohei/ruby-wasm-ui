require "js"

# Main App component - coordinates all other components
AppComponent = RubyWasmUi.define_component(
  # Initialize application state
  state: ->(props) {
    {
      todos: [
        { id: rand(10000), text: "Walk the dog" },
        { id: rand(10000), text: "Water the plants" },
        { id: rand(10000), text: "Sand the chairs" }
      ]
    }
  },

  on_mounted: ->(component) {
    component.update_state(todos: TodosRepository.read_todos)
  },

  # Render the complete application
  render: ->(component) {
    state = component.state

    RubyWasmUi::Vdom.h_fragment([
      RubyWasmUi::Vdom.h("h1", {}, ["My TODOs"]),
      RubyWasmUi::Vdom.h(CreateTodoComponent, {
        on: {
          add: ->(text) { component.add_todo(text) }
        }
      }),
      RubyWasmUi::Vdom.h(TodoListComponent, {
        todos: state[:todos],
        on: {
          remove: ->(id) { component.remove_todo(id) },
          edit: ->(payload) { component.edit_todo(payload) }
        }
      })
    ])
  },

  # Component methods
  methods: {
    # Add a new TODO to the list
    # @param text [String] The TODO text
    add_todo: ->(text) {
      todo = { id: rand(10000), text: text }
      state = self.state
      self.update_state(todos: state[:todos] + [todo])
      TodosRepository.write_todos(state[:todos] + [todo])
    },

    # Remove a TODO from the list
    # @param id [Integer] Id of TODO to remove
    remove_todo: ->(id) {
      state = self.state
      new_todos = state[:todos].dup
      new_todos.delete_at(new_todos.index { |todo| todo[:id] == id })
      self.update_state(todos: new_todos)
      TodosRepository.write_todos(new_todos)
    },

    # Edit an existing TODO
    # @param payload [Hash] Contains edited text and index
    edit_todo: ->(payload) {
      edited = payload[:edited]
      id = payload[:id]
      state = self.state
      new_todos = state[:todos].dup
      new_todos[new_todos.index { |todo| todo[:id] == id }] = new_todos[new_todos.index { |todo| todo[:id] == id }].merge(text: edited)
      self.update_state(todos: new_todos)
      TodosRepository.write_todos(new_todos)
    }
  }
)

# CreateTodo component - handles new TODO input
CreateTodoComponent = RubyWasmUi.define_component(
  # Initialize component state
  state: ->(props) {
    { text: "" }
  },

  # Render the new TODO input form
  render: ->(component) {
    state = component.state

    RubyWasmUi::Vdom.h("div", {}, [
      RubyWasmUi::Vdom.h("label", { for: "todo-input", type: "text" }, ["New TODO"]),
      RubyWasmUi::Vdom.h("input", {
        type: "text",
        id: "todo-input",
        value: state[:text],
        on: {
          input: ->(e) { component.update_state(text: e[:target][:value]) },
          keydown: ->(e) {
            if e[:key] == "Enter" && state[:text].to_s.length >= 3
              component.add_todo
            end
          }
        }
      }),
      RubyWasmUi::Vdom.h("button", {
        disabled: state[:text].to_s.length < 3,
        on: { click: ->(_e) { component.add_todo } }
      }, ["Add"])
    ])
  },

  # Component methods
  methods: {
    # Add a new TODO and emit event to parent
    add_todo: ->() {
      self.emit("add", self.state[:text])
      self.update_state(text: "")
    }
  }
)

# TodoList component - manages the list of TODO items
TodoListComponent = RubyWasmUi.define_component(
  # Render the TODO list
  render: ->(component) {
    todos = component.props[:todos]

    item_components = todos.map.with_index do |todo, i|
      RubyWasmUi::Vdom.h(TodoItemComponent, {
        key: todo[:id],
        todo: todo[:text],
        id: todo[:id],
        on: {
          remove: ->(id) { component.emit("remove", id) },
          edit: ->(payload) { component.emit("edit", payload) }
        }
      })
    end

    RubyWasmUi::Vdom.h("ul", {}, item_components)
  },

  # Add empty methods hash to ensure proper component initialization
  methods: {}
)

# TodoItem component - handles individual TODO items
TodoItemComponent = RubyWasmUi.define_component(
  # Initialize component state with editing capabilities
  state: ->(props) {
    {
      original: props[:todo],
      edited: props[:todo],
      is_editing: false
    }
  },

  # Render TODO item using appropriate sub-component
  render: ->(component) {
    state = component.state
    id = component.props[:id]

    if state[:is_editing]
      RubyWasmUi::Vdom.h(TodoItemEditComponent, {
        edited: state[:edited],
        on: {
          input: ->(value) { component.update_state(edited: value) },
          save: ->(_payload) { component.save_edition },
          cancel: ->(_payload) { component.cancel_edition }
        }
      })
    else
      RubyWasmUi::Vdom.h(TodoItemViewComponent, {
        original: state[:original],
        id: id,
        on: {
          edit: ->(_payload) { component.update_state(is_editing: true) },
          remove: ->(id) { component.emit("remove", id) }
        }
      })
    end
  },

  # Component methods
  methods: {
    # Save the edited TODO
    save_edition: ->() {
      self.update_state(is_editing: false, original: self.state[:edited])
      self.emit("edit", { edited: self.state[:edited], id: self.props[:id] })
    },

    # Cancel editing and revert changes
    cancel_edition: ->() {
      self.update_state(edited: self.state[:original], is_editing: false)
    }
  }
)

# TodoItemEdit component - handles TODO editing mode
TodoItemEditComponent = RubyWasmUi.define_component(
  # Render TODO item in edit mode
  render: ->(component) {
    edited = component.props[:edited]

    RubyWasmUi::Vdom.h("li", {}, [
      RubyWasmUi::Vdom.h("input", {
        value: edited,
        type: "text",
        on: {
          input: ->(e) {
            component.emit("input", e[:target][:value])
          }
        }
      }),
      RubyWasmUi::Vdom.h("button", {
        on: {
          click: ->(_e) {
            component.emit("save", nil)
          }
        }
      }, ["Save"]),
      RubyWasmUi::Vdom.h("button", {
        on: {
          click: ->(_e) {
            component.emit("cancel", nil)
          }
        }
      }, ["Cancel"])
    ])
  },

  # Add empty methods hash to ensure proper component initialization
  methods: {}
)

# TodoItemView component - handles TODO display mode
TodoItemViewComponent = RubyWasmUi.define_component(
  # Render TODO item in view mode
  render: ->(component) {
    original = component.props[:original]
    id = component.props[:id]

    RubyWasmUi::Vdom.h("li", {}, [
      RubyWasmUi::Vdom.h("span", {
        on: {
          dblclick: ->(_e) {
            component.emit("edit", nil)
          }
        }
      }, [original]),
      RubyWasmUi::Vdom.h("button", {
        on: {
          click: ->(_e) {
            component.emit("remove", id)
          }
        }
      }, ["Done"])
    ])
  },

  # Add empty methods hash to ensure proper component initialization
  methods: {}
)

# Create and mount the application
app = RubyWasmUi::App.create(AppComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
