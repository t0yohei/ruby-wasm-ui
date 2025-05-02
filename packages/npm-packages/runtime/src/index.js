const userDefinedRubyScript = document.querySelector("script[type='text/ruby']");

const scriptElement = document.createElement("script");
scriptElement.src =
  "https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@latest/dist/browser.script.iife.js";
scriptElement.setAttribute("defer", "");
userDefinedRubyScript.before(scriptElement);

function loadRubyScript(filePath) {
  let baseUrl;
  if (window.RUBY_WASM_UI_ENV === "production") {
    baseUrl = "https://unpkg.com/ruby-wasm-ui@latest/dist/";
  } else {
    baseUrl = "../../packages/npm-packages/runtime/src";
  }
  let rubyScriptElement = document.createElement("script");
  rubyScriptElement.type = "text/ruby";
  rubyScriptElement.chrset = "utf-8";
  rubyScriptElement.src = `${baseUrl}/${filePath}`;
  rubyScriptElement.setAttribute("defer", "");
  userDefinedRubyScript.before(rubyScriptElement);
}

//Load ruby_wasm_ui.rb
loadRubyScript("ruby_wasm_ui.rb");
loadRubyScript("ruby_wasm_ui/vdom.rb");
loadRubyScript("ruby_wasm_ui/arrays.rb");
loadRubyScript("ruby_wasm_ui/dom.rb");
loadRubyScript("ruby_wasm_ui/dom/events.rb");
loadRubyScript("ruby_wasm_ui/dom/attributes.rb");
loadRubyScript("ruby_wasm_ui/dom/destroy_dom.rb");
loadRubyScript("ruby_wasm_ui/dom/mount_dom.rb");
loadRubyScript("ruby_wasm_ui/app.rb");
loadRubyScript("ruby_wasm_ui/dispatcher.rb");
