const userDefinedRubyScript = document.querySelector("script[type='text/ruby']");

const scriptElement = document.createElement("script");
scriptElement.src =
  "https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@latest/dist/browser.script.iife.js";
scriptElement.setAttribute("defer", "");
userDefinedRubyScript.before(scriptElement);

function loadRubyScript(filePath) {
  const baseUrl = "../../packages/npm-packages/runtime/src";
  let rubyScriptElement = document.createElement("script");
  rubyScriptElement.type = "text/ruby";
  rubyScriptElement.chrset = "utf-8";
  rubyScriptElement.src = `${baseUrl}/${filePath}`;
  rubyScriptElement.setAttribute("defer", "");
  userDefinedRubyScript.before(rubyScriptElement);
}

//Load ruby_wasm_ui.rb
loadRubyScript("ruby_wasm_ui.rb");
loadRubyScript("ruby_wasm_ui/h.rb");
loadRubyScript("ruby_wasm_ui/arrays.rb");
