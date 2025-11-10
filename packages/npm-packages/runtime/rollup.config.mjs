import copy from "rollup-plugin-copy";
import cleanup from "rollup-plugin-cleanup";
import filesize from "rollup-plugin-filesize";
import replace from "@rollup/plugin-replace";
import { glob } from "glob";
import process from "process";
import { readFileSync, writeFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

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

// Plugin to remove require_relative lines from Ruby files
const removeRequireRelative = () => {
  return {
    name: "remove-require-relative",
    writeBundle() {
      // Process all Ruby files in dist directory recursively
      const distRubyFiles = glob.sync("dist/**/*.rb");

      distRubyFiles.forEach((file) => {
        const filePath = join(__dirname, file);
        let content = readFileSync(filePath, "utf-8");
        // Remove lines that start with require_relative (with optional whitespace)
        content = content.replace(/^\s*require_relative\s+.*$/gm, "");
        // Remove multiple consecutive empty lines
        content = content.replace(/\n{3,}/g, "\n\n");
        writeFileSync(filePath, content, "utf-8");
      });
    },
  };
};

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
    removeRequireRelative(),
    filesize(),
  ],
};
