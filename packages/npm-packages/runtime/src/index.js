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
  if (window.RUWI_ENV === "production") {
    baseUrl = "https://unpkg.com/ruwi@latest/dist";
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

// Load ruwi.rb
loadRubyScript("ruwi.rb");

// Load all Ruby files in ruwi directory
const rubyFiles = window.RUWI_FILES;
if (rubyFiles === undefined) {
  throw new Error(
    "RUWI_FILES is not defined. This file should be built with rollup."
  );
}

rubyFiles.forEach((file) => loadRubyScript(file));
