require "js"

RandomCocktail = RubyWasmUi.define_component(
  state: ->(props) {
    {
      is_loading: false,
      cocktail: nil
    }
  },

  render: ->(component) {
    is_loading = component.state[:is_loading]
    cocktail = component.state[:cocktail]

    if is_loading
      template = <<~HTML
        <p>Loading...</p>
      HTML

      vdom_code = RubyWasmUi::Template::Parser.parse(template)
      return eval(vdom_code)
    end

    if cocktail.nil?
      template = <<~HTML
        <button on="{click: ->(e) { component.fetch_cocktail }}">
          Get a cocktail
        </button>
      HTML

      vdom_code = RubyWasmUi::Template::Parser.parse(template)
      return eval(vdom_code)
    end

    str_drink = cocktail["strDrink"]
    str_drink_thumb = cocktail["strDrinkThumb"]
    str_instructions = cocktail["strInstructions"]

    # Generate HTML with actual values substituted
    cocktail_html = <<~HTML
      <div>
        <h1>#{str_drink}</h1>
        <p>#{str_instructions}</p>
        <img
          src="#{str_drink_thumb}"
          alt="#{str_drink}"
          style="width: 300px; height: 300px;" />
        <button
          on="{click: ->(e) { component.fetch_cocktail }}"
          style="display: block; margin: 1em auto;">
          Get another cocktail
        </button>
      </div>
    HTML

    vdom_code = RubyWasmUi::Template::Parser.parse(cocktail_html)
    eval(vdom_code)
  },

  methods: {
    fetch_cocktail: ->{
      # Set loading state
      update_state(is_loading: true, cocktail: nil)

      # Use Promise directly
      JS.global.fetch("https://www.thecocktaildb.com/api/json/v1/1/random.php").then(->(response) {
        response.call(:json)
      }).then(->(data) {
        cocktail_data = data[:drinks][0]
        update_state(is_loading: false, cocktail: cocktail_data)
      }).catch(->(error) {
        update_state(is_loading: false, cocktail: nil)
      })
    }
  }
)

app_element = JS.global[:document].getElementById("app")
app = RubyWasmUi::App.create(RandomCocktail)
app.mount(app_element)
