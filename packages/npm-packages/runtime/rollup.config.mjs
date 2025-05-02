import copy from 'rollup-plugin-copy';
import cleanup from 'rollup-plugin-cleanup';
import filesize from 'rollup-plugin-filesize';
import replace from '@rollup/plugin-replace';

export default {
  input: "src/index.js",
  output: {
    file: "dist/ruby-wasm-ui.js",
    format: "esm",
    sourcemap: true,
  },
  plugins: [
    replace({
      preventAssignment: true,
      values: {
        "window.RUBY_WASM_UI_ENV": JSON.stringify("production")
      }
    }),
    copy({
      targets: [
        {
          src: "src/ruby_wasm_ui/**/*",
          dest: "dist/ruby_wasm_ui",
          flatten: false,
        },
        {
          src: "src/ruby_wasm_ui.rb",
          dest: "dist",
        },
      ],
    }),
    cleanup({
      comments: "none",
      extensions: ["js"],
    }),
    filesize(),
  ],
};
