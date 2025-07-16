require "js"

random_cocktail = RubyWasmUi::Component.define_component(
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
      return RubyWasmUi::Vdom.h_fragment([
        RubyWasmUi::Vdom.h("p", {}, ["Loading..."])
      ])
    end

    if cocktail.nil?
      return RubyWasmUi::Vdom.h_fragment([
        RubyWasmUi::Vdom.h("button", {
          on: {
            click: ->(e) { component.fetch_cocktail },
          },
        }, [
          "Get a cocktail"
        ])
      ])
    end

    str_drink = cocktail["strDrink"]
    str_drink_thumb = cocktail["strDrinkThumb"]
    str_instructions = cocktail["strInstructions"]

    RubyWasmUi::Vdom.h_fragment([
      RubyWasmUi::Vdom.h("h1", {}, [str_drink]),
      RubyWasmUi::Vdom.h("p", {}, [str_instructions]),
      RubyWasmUi::Vdom.h("img", {
        src: str_drink_thumb,
        alt: str_drink,
        style: {
          width: "300px",
          height: "300px"
        }
      }, []),
      RubyWasmUi::Vdom.h(
        "button",
        {
          on: {
            click: ->(e) { component.fetch_cocktail },
          },
          style: {
            display: "block",
            margin: "1em auto"
          }
        },
        ["Get another cocktail"]
      )
    ])
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
  }
)

app_element = JS.global[:document].getElementById("app")
app = random_cocktail.new
app.mount(app_element)
