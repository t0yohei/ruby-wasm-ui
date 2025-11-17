const userDefinedRubyScript = document.querySelector(
  "script[type='text/ruby']"
);

const scriptElement = document.createElement("script");
scriptElement.src =
  "https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@latest/dist/browser.script.iife.js";
scriptElement.setAttribute("defer", "");
userDefinedRubyScript.before(scriptElement);

function loadRubyScript(filePath) {
  let baseUrl;
  if (window.RUBY_WASM_UI_ENV === "production") {
    baseUrl = "https://unpkg.com/ruby-wasm-ui@latest/dist";
  } else {
    baseUrl = "../../../../packages/npm-packages/runtime/dist";
  }
  let rubyScriptElement = document.createElement("script");
  rubyScriptElement.type = "text/ruby";
  rubyScriptElement.charset = "utf-8";
  rubyScriptElement.src = `${baseUrl}/${filePath}`;
  rubyScriptElement.setAttribute("defer", "");
  userDefinedRubyScript.before(rubyScriptElement);
}

// Load ruby_wasm_ui.rb
loadRubyScript("ruby_wasm_ui.rb");

// Load all Ruby files in ruby_wasm_ui directory
const rubyFiles = window.RUBY_WASM_UI_FILES;
if (rubyFiles === undefined) {
  throw new Error(
    "RUBY_WASM_UI_FILES is not defined. This file should be built with rollup."
  );
}

rubyFiles.forEach((file) => loadRubyScript(file));
