import cleanup from "rollup-plugin-cleanup";
import filesize from "rollup-plugin-filesize";
import copy from "rollup-plugin-copy";
import replace from "@rollup/plugin-replace";

export default {
  input: "src/index.js",
  plugins: [
    replace({
      preventAssignment: true,
      values: {
        "window.RUBY_WASM_UI_ENV": JSON.stringify("production")
      }
    }),
    cleanup(),
    copy({
      targets: [
        {
          src: "src/ruby_wasm_ui/*.rb",
          dest: "dist/ruby_wasm_ui",
        },
        {
          src: "src/ruby_wasm_ui.rb",
          dest: "dist",
        },
      ],
    }),
  ],
  output: [
    {
      file: "dist/ruby-wasm-ui.js",
      format: "esm",
      plugins: [filesize()],
    },
  ],
};
