require "js"

random_cocktail = RubyWasmUi.define_component(
  state: ->(props) {
    {
      is_loading: false,
      cocktail: nil
    }
  },

  render: ->(component) {
    is_loading = component.state[:is_loading] # Used in template
    cocktail = component.state[:cocktail] # Used in template

    template = <<~HTML
      <p r-if="{is_loading}">
        Loading...
      </p>
      <button-component r-elsif="{cocktail.nil?}" on="{click_button: ->() { component.fetch_cocktail }}" label="Get a cocktail"/>
      <template r-else>
        <h1>{cocktail['strDrink']}</h1>
        <p>{cocktail['strInstructions']}</p>
        <img src="{cocktail['strDrinkThumb']}" alt="{cocktail['strDrink']}" style="width: 300px; height: 300px" />
        <button-component on="{click_button: ->() { component.fetch_cocktail }}" label="Get another cocktail"/>
      </template>
    HTML

    RubyWasmUi::Template::Parser.parse_and_eval(template, binding)
  },

  methods: {
    fetch_cocktail: ->{
      # Set loading state
      update_state(is_loading: true, cocktail: nil)

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

  on_mounted: ->(component) {
    component.fetch_cocktail
  }
)

ButtonComponent = RubyWasmUi.define_component(
  state: ->(props) {
    { label: props[:label] }
  },

  render: ->(component) {
    RubyWasmUi::Template::Parser.parse_and_eval(<<~HTML, binding)
      <button on="{click: ->() { component.emit('click_button') }}" style="display: block; margin: 1em auto">
        {component.state[:label]}
      </button>
    HTML
  }
)

# Create and mount the app
app = RubyWasmUi::App.create(random_cocktail)
app_element = JS.global[:document].getElementById("app")
app.mount(app_element)
