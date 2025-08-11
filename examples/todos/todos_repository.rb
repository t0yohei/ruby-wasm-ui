require "json"

# Repository class for managing todos in local storage
class TodosRepository
  class << self
    # Read todos from local storage
    # @return [Array] Array of todo items
    def read_todos
      todos_json = JS.global[:localStorage].getItem('todos') || '[]'
      JSON.parse(todos_json.to_s).map do |todo|
        { id: todo["id"], text: todo["text"] }
      end
    end

    # Write todos to local storage
    # @param todos [Array] Array of todo items to be stored
    # @return [void]
    def write_todos(todos)
      todos_json = JSON.generate(todos)
      JS.global[:localStorage].setItem('todos', todos_json)
    end
  end
end
