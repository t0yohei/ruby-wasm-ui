import copy from "rollup-plugin-copy";
import cleanup from "rollup-plugin-cleanup";
import filesize from "rollup-plugin-filesize";
import replace from "@rollup/plugin-replace";
import { glob } from "glob";
import process from "process";

// Find all Ruby files in ruby_wasm_ui directory
const rubyFiles = glob
  .sync("src/ruby_wasm_ui/**/*.rb")
  .map((file) => file.replace("src/", ""))
  .sort((a, b) => {
    // Files in root directory should be loaded first
    const aIsRoot = !a.includes("/");
    const bIsRoot = !b.includes("/");
    if (aIsRoot && !bIsRoot) return -1;
    if (!aIsRoot && bIsRoot) return 1;

    // Then sort by directory and filename
    return a.localeCompare(b);
  });

// Determine environment based on NODE_ENV
const isDevelopment = process.env.NODE_ENV === "development";

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
        "window.RUBY_WASM_UI_ENV": JSON.stringify(
          isDevelopment ? "development" : "production"
        ),
        "window.RUBY_WASM_UI_FILES": JSON.stringify(rubyFiles),
      },
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
