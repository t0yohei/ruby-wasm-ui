# Lifecycle Hooks

Components support lifecycle hooks to execute code at specific points in a component's lifecycle:

```ruby
RandomCocktailComponent = Ruwi.define_component(
  state: ->() {
    {
      is_loading: false,
      cocktail: nil
    }
  },

  methods: {
    fetch_cocktail: -> {
      # Set loading state
      update_state(is_loading: true, cocktail: nil)

      # Use Fiber for asynchronous API call
      Fiber.new do
        response = JS.global.fetch("https://www.thecocktaildb.com/api/json/v1/1/random.php").await
        response.call(:json).then(->(data) {
          update_state(is_loading: false, cocktail: data[:drinks][0])
        }).catch(->(error) {
          update_state(is_loading: false, cocktail: nil)
        })
      end.transfer
    }
  },

  # Called after the component is mounted to the DOM
  on_mounted: ->() {
    fetch_cocktail
  },

  template: ->() {
    is_loading = state[:is_loading] # Used in template
    cocktail = state[:cocktail] # Used in template

    template = <<~HTML
      <div>
        <p r-if="{is_loading}">Loading...</p>
        <button r-elsif="{cocktail.nil?}" on="{click: ->() { fetch_cocktail }}">
          Get a cocktail
        </button>
        <template r-else>
          <h2>{cocktail['strDrink']}</h2>
          <p>{cocktail['strInstructions']}</p>
          <img src="{cocktail['strDrinkThumb']}" alt="{cocktail['strDrink']}" style="width: 300px; height: 300px" />
          <button on="{click: ->() { fetch_cocktail }}">
            Get another cocktail
          </button>
        </template>
      </div>
    HTML

    Ruwi::Template::Parser.parse_and_eval(template, binding)
  }
)
```

## Available Lifecycle Hooks

### on_mounted

The `on_mounted` hook is called after the component is mounted to the DOM. This is useful for:

- Making initial API calls
- Setting up event listeners
- Initializing third-party libraries
- Performing DOM manipulations that require the element to be in the document

## Asynchronous Operations

Note: Unlike JavaScript frameworks, asynchronous operations in ruwi are designed to use Ruby's Fiber system rather than Promises.
