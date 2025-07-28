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
      ],
      new_todo_text: "",
      editing_todo_id: nil,
      editing_text: ""
    }
  },

  # Render the complete application
  render: ->(component) {
    state = component.state
    todos = state[:todos]
    current_value = state[:new_todo_text] || ""

    # Generate TODO items using direct VDOM construction
    editing_id = state[:editing_todo_id]
    editing_text = state[:editing_text] || ""

    todo_items = todos.map do |todo|
      is_editing = editing_id == todo[:id]
      display_text = is_editing ? editing_text : todo[:text]

      # Create each TODO item with fixed structure using VDOM
      RubyWasmUi::Vdom.h('li', {}, [
        # Display text (hidden when editing)
        RubyWasmUi::Vdom.h('span', {
          style: { display: is_editing ? 'none' : 'inline' },
          on: { dblclick: ->(_e) { component.edit_todo_item(todo[:id]) } }
        }, [todo[:text]]),

        # Edit input (hidden when not editing)
        RubyWasmUi::Vdom.h('input', {
          type: 'text',
          value: display_text,
          style: { display: is_editing ? 'inline' : 'none' },
          on: { input: ->(e) { component.update_editing_text(e[:target][:value].to_s) } }
        }, []),

        # Save button (hidden when not editing)
        RubyWasmUi::Vdom.h('button', {
          style: { display: is_editing ? 'inline' : 'none' },
          on: { click: ->(_e) { component.save_todo_edit } }
        }, ['Save']),

        # Cancel button (hidden when not editing)
        RubyWasmUi::Vdom.h('button', {
          style: { display: is_editing ? 'inline' : 'none' },
          on: { click: ->(_e) { component.cancel_todo_edit } }
        }, ['Cancel']),

        # Done button (hidden when editing)
        RubyWasmUi::Vdom.h('button', {
          style: { display: is_editing ? 'none' : 'inline' },
          on: { click: ->(_e) { component.remove_todo(todo[:id]) } }
        }, ['Done'])
      ])
    end

    # Build complete VDOM structure
    RubyWasmUi::Vdom.h('div', {}, [
      RubyWasmUi::Vdom.h('h1', {}, ['My TODOs']),

      # New TODO input section
      RubyWasmUi::Vdom.h('div', {}, [
        RubyWasmUi::Vdom.h('label', { for: 'todo-input' }, ['New TODO']),
        RubyWasmUi::Vdom.h('input', {
          type: 'text',
          id: 'todo-input',
          value: current_value,
          on: { input: ->(e) { component.handle_input_change(e[:target][:value].to_s) } }
        }, []),
        RubyWasmUi::Vdom.h('button', {
          disabled: (state[:new_todo_text] || '').length < 3,
          on: { click: ->(_e) { component.add_todo } }
        }, ['Add'])
      ]),

      # TODO list
      RubyWasmUi::Vdom.h('ul', {}, todo_items)
    ])
  },

    # Component methods
  methods: {

    # Handle input change for new TODO text
    handle_input_change: ->(value) {
      self.update_state(new_todo_text: value)
    },

    # Add a new TODO to the list
    add_todo: ->() {
      state = self.state
      text = state[:new_todo_text]

      if text && text.length >= 3
        todo = { id: rand(10000), text: text }
        self.update_state(
          todos: state[:todos] + [todo],
          new_todo_text: ""
        )
      end
    },

    # Start editing a TODO item
    # @param id [Integer] Id of TODO to edit
    edit_todo_item: ->(id) {
      state = self.state
      todo = state[:todos].find { |t| t[:id] == id }
      self.update_state(
        editing_todo_id: id,
        editing_text: todo ? todo[:text] : ""
      )
    },

    # Update editing text
    # @param text [String] New text value
    update_editing_text: ->(text) {
      self.update_state(editing_text: text)
    },

    # Save the edited TODO
    save_todo_edit: ->() {
      state = self.state
      editing_id = state[:editing_todo_id]
      new_text = state[:editing_text]

      if editing_id && new_text && new_text.to_s.strip.length >= 1
        new_todos = state[:todos].map do |todo|
          if todo[:id] == editing_id
            { id: todo[:id], text: new_text.to_s.strip }
          else
            todo
          end
        end

        self.update_state(
          todos: new_todos,
          editing_todo_id: nil,
          editing_text: ""
        )
      else
        self.update_state(
          editing_todo_id: nil,
          editing_text: ""
        )
      end
    },

    # Cancel editing
    cancel_todo_edit: ->() {
      self.update_state(
        editing_todo_id: nil,
        editing_text: ""
      )
    },

    # Remove a TODO from the list
    # @param id [Integer] Id of TODO to remove
    remove_todo: ->(id) {
      state = self.state
      new_todos = state[:todos].dup
      index = new_todos.index { |todo| todo[:id] == id }

      if index
        new_todos.delete_at(index)
        self.update_state(todos: new_todos)
      end
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

    template = <<~HTML
      <div>
        <label for="todo-input" type="text">New TODO</label>
        <input
          type="text"
          id="todo-input"
          value="{state[:text]}"
          on="{input: ->(e) { component.update_state(text: e[:target][:value]) }, keydown: ->(e) { component.add_todo if e[:key] == 'Enter' && state[:text].to_s.length >= 3 }}" />
        <button
          disabled="{state[:text].to_s.length < 3}"
          on="{click: ->(_e) { component.add_todo }}">
          Add
        </button>
      </div>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
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
    template = <<~HTML
      <ul>{component.render_todo_items}</ul>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  },

  methods: {
    render_todo_items: ->() {
      todos = self.props[:todos]

      # Generate each todo item
      todos.map.with_index do |todo, i|
        todo_item = TodoItemComponent.new({
          key: todo[:id],
          todo: todo[:text],
          id: todo[:id]
        }, {
          remove: ->(id) { self.emit("remove", id) },
          edit: ->(payload) { self.emit("edit", payload) }
        })

        todo_item.render
      end
    }
  }
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
      edit_component = TodoItemEditComponent.new({
        edited: state[:edited]
      }, {
        input: ->(value) { component.update_state(edited: value) },
        save: ->(_payload) { component.save_edition },
        cancel: ->(_payload) { component.cancel_edition }
      })

      edit_component.render
    else
      view_component = TodoItemViewComponent.new({
        original: state[:original],
        id: id
      }, {
        edit: ->(_payload) { component.update_state(is_editing: true) },
        remove: ->(id) { component.emit("remove", id) }
      })

      view_component.render
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

    template = <<~HTML
      <li>
        <input
          value="{edited}"
          type="text"
          on="{input: ->(e) { component.emit('input', e[:target][:value]) }}" />
        <button on="{click: ->(_e) { component.emit('save', nil) }}">Save</button>
        <button on="{click: ->(_e) { component.emit('cancel', nil) }}">Cancel</button>
      </li>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  },

  methods: {}
)

# TodoItemView component - handles TODO display mode
TodoItemViewComponent = RubyWasmUi.define_component(
  # Render TODO item in view mode
  render: ->(component) {
    original = component.props[:original]
    id = component.props[:id]

    template = <<~HTML
      <li>
        <span on="{dblclick: ->(_e) { component.emit('edit', nil) }}">{original}</span>
        <button on="{click: ->(_e) { component.emit('remove', id) }}">Done</button>
      </li>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(template)
    eval(vdom_code)
  },

  methods: {}
)

# Create and mount the application
app_element = JS.global[:document].getElementById("app")
app = RubyWasmUi::App.create(AppComponent)
app.mount(app_element)
