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
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <template>
        <h1>My TODOs</h1>
        <CreateTodoComponent
          on="{ add: ->(text) { component.add_todo(text) } }"
        />
        <TodoListComponent
          todos="{component.state[:todos]}"
          on="{
            remove: ->(id) { component.remove_todo(id) },
            edit: ->(payload) { component.edit_todo(payload) }
          }"
        />
      </template>
    HTML
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
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <label for="todo-input" type="text">New TODO</label>
        <input
          type="text"
          id="todo-input"
          value="{component.state[:text]}"
          on="{
            input: ->(e) { component.update_state(text: e[:target][:value]) },
            keydown: ->(e) {
              if e[:key] == 'Enter' && component.state[:text].to_s.length >= 3
                component.add_todo
              end
            }
          }"
        />
        <button disabled="{component.state[:text].to_s.length < 3}" on="{ click: ->() { component.add_todo } }">
          Add
        </button>
      </div>
    HTML
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

    item_components = todos.map do |todo|
      RubyWasmUi::Vdom.h(TodoItemComponent, {
        key: todo[:text],
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

  # Render TODO item using r-if and r-else for conditional rendering
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <template>
        <TodoItemEditComponent
          r-if="{component.state[:is_editing]}"
          edited="{component.state[:edited]}"
          on="{
            input: ->(value) { component.input_value(value) },
            save: ->() { component.save_edition },
            cancel: ->() { component.cancel_edition }
          }"
        />
        <TodoItemViewComponent
          r-else
          original="{component.state[:original]}"
          id="{component.props[:id]}"
          on="{
            editing: ->() { component.editing },
            remove: ->(id) { component.emit('remove', id) }
          }"
        />
      </template>
    HTML
  },

  # Component methods
  methods: {
    input_value: ->(value) {
      self.update_state(edited: value)
    },

    editing: ->() {
      self.update_state(is_editing: true)
    },

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
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>
        <input
          value="{component.props[:edited]}"
          type="text"
          on="{ input: ->(e) { component.emit('input', e[:target][:value]) } }"
        />
        <button on="{ click: ->() { component.emit('save') } }">
          Save
        </button>
        <button on="{ click: ->() { component.emit('cancel') } }">
          Cancel
        </button>
      </li>
    HTML
  },
)

# TodoItemView component - handles TODO display mode
TodoItemViewComponent = RubyWasmUi.define_component(
  # Render TODO item in view mode
  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>
        <span on="{ dblclick: ->() { component.emit('editing') } }">
          {component.props[:original]}
        </span>
        <button on="{ click: ->() { component.emit('remove', component.props[:id]) } }">
          Done
        </button>
      </li>
    HTML
  },
)

# Create and mount the application
app = RubyWasmUi::App.create(AppComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
