import cleanup from "rollup-plugin-cleanup";
import filesize from "rollup-plugin-filesize";
import copy from "rollup-plugin-copy";

export default {
  input: "src/index.js",
  plugins: [
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
