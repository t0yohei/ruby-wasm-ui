# Main App component - coordinates all other components
AppComponent = Ruwi.define_component(
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

  on_mounted: -> {
    update_state(todos: TodosRepository.read_todos)
  },

  # Render the complete application
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <template>
        <h1>My TODOs</h1>
        <CreateTodoComponent
          on="{ add: ->(text) { add_todo(text) } }"
        />
        <TodoListComponent
          todos="{state[:todos]}"
          on="{
            remove: ->(id) { remove_todo(id) },
            edit: ->(payload) { edit_todo(payload) }
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
      new_todos = state[:todos] + [todo]
      update_state(todos: new_todos)
      TodosRepository.write_todos(new_todos)
    },

    # Remove a TODO from the list
    # @param id [Integer] Id of TODO to remove
    remove_todo: ->(id) {
      new_todos = state[:todos].dup
      new_todos.delete_at(new_todos.index { |todo| todo[:id] == id })
      update_state(todos: new_todos)
      TodosRepository.write_todos(new_todos)
    },

    # Edit an existing TODO
    # @param payload [Hash] Contains edited text and index
    edit_todo: ->(payload) {
      edited = payload[:edited]
      id = payload[:id]
      new_todos = state[:todos].dup
      new_todos[new_todos.index { |todo| todo[:id] == id }] = new_todos[new_todos.index { |todo| todo[:id] == id }].merge(text: edited)
      update_state(todos: new_todos)
      TodosRepository.write_todos(new_todos)
    }
  }
)

# CreateTodo component - handles new TODO input
CreateTodoComponent = Ruwi.define_component(
  # Initialize component state
  state: ->(props) {
    { text: "" }
  },

  # Render the new TODO input form
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <div>
        <label for="todo-input" type="text">New TODO</label>
        <input
          type="text"
          id="todo-input"
          value="{state[:text]}"
          on="{
            input: ->(e) { update_state(text: e[:target][:value]) },
            keydown: ->(e) {
              if e[:key] == 'Enter' && state[:text].to_s.length >= 3
                add_todo
              end
            }
          }"
        />
        <button disabled="{state[:text].to_s.length < 3}" on="{ click: ->() { add_todo } }">
          Add
        </button>
      </div>
    HTML
  },

  # Component methods
  methods: {
    # Add a new TODO and emit event to parent
    add_todo: ->() {
      emit("add", state[:text])
      update_state(text: "")
    }
  }
)

# TodoList component - manages the list of TODO items
TodoListComponent = Ruwi.define_component(
  # Render the TODO list
  template: ->() {
    todos = props[:todos]

    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <ul>
        <TodoItemComponent
          r-for="{todo in todos}"
          key="{todo[:id]}"
          todo="{todo[:text]}"
          id="{todo[:id]}"
          on="{
            remove: ->(id) { emit('remove', id) },
            edit: ->(payload) { emit('edit', payload) }
          }"
        />
      </ul>
    HTML
  },
)

# TodoItem component - handles individual TODO items
TodoItemComponent = Ruwi.define_component(
  # Initialize component state with editing capabilities
  state: ->(props) {
    {
      original: props[:todo],
      edited: props[:todo],
      is_editing: false
    }
  },

  # Render TODO item using r-if and r-else for conditional rendering
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <template>
        <TodoItemEditComponent
          r-if="{state[:is_editing]}"
          edited="{state[:edited]}"
          on="{
            input: ->(value) { input_value(value) },
            save: ->() { save_edition },
            cancel: ->() { cancel_edition }
          }"
        />
        <TodoItemViewComponent
          r-else
          original="{state[:original]}"
          id="{props[:id]}"
          on="{
            editing: ->() { editing },
            remove: ->(id) { emit('remove', id) }
          }"
        />
      </template>
    HTML
  },

  # Component methods
  methods: {
    input_value: ->(value) {
      update_state(edited: value)
    },

    editing: ->() {
      update_state(is_editing: true)
    },

    # Save the edited TODO
    save_edition: ->() {
      update_state(is_editing: false, original: state[:edited])
      emit("edit", { edited: state[:edited], id: props[:id] })
    },

    # Cancel editing and revert changes
    cancel_edition: ->() {
      update_state(edited: state[:original], is_editing: false)
    }
  }
)

# TodoItemEdit component - handles TODO editing mode
TodoItemEditComponent = Ruwi.define_component(
  # Render TODO item in edit mode
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>
        <input
          value="{props[:edited]}"
          type="text"
          on="{ input: ->(e) { emit('input', e[:target][:value]) } }"
        />
        <button on="{ click: ->() { emit('save') } }">
          Save
        </button>
        <button on="{ click: ->() { emit('cancel') } }">
          Cancel
        </button>
      </li>
    HTML
  },
)

# TodoItemView component - handles TODO display mode
TodoItemViewComponent = Ruwi.define_component(
  # Render TODO item in view mode
  template: ->() {
    Ruwi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <li>
        <span on="{ dblclick: ->() { emit('editing') } }">
          {props[:original]}
        </span>
        <button on="{ click: ->() { emit('remove', props[:id]) } }">
          Done
        </button>
      </li>
    HTML
  },
)

# Create and mount the application
app = Ruwi::App.create(AppComponent)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
