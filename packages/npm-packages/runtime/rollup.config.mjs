import copy from "rollup-plugin-copy";
import cleanup from "rollup-plugin-cleanup";
import filesize from "rollup-plugin-filesize";
import replace from "@rollup/plugin-replace";
import { glob } from "glob";
import process from "process";
import {
  readFileSync,
  writeFileSync,
  lstatSync,
  unlinkSync,
  realpathSync,
} from "fs";
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

// Plugin to clean up existing symlinks in dist directory before copy
const cleanupSymlinks = () => {
  return {
    name: "cleanup-symlinks",
    buildStart() {
      const distRubyFilePath = join(__dirname, "dist/ruby_wasm_ui.rb");
      try {
        const stats = lstatSync(distRubyFilePath);
        if (stats.isSymbolicLink() || stats.isFile()) {
          // Remove existing file/symlink before copy plugin runs
          unlinkSync(distRubyFilePath);
        }
      } catch (e) {
        // Ignore errors (file might not exist)
      }
    },
  };
};

// Plugin to remove require_relative lines from Ruby files
const removeRequireRelative = () => {
  return {
    name: "remove-require-relative",
    writeBundle() {
      // Process all Ruby files in dist directory (including dist/ruby_wasm_ui.rb)
      // Ensure we only process files in dist/ directory, not lib/ or other source directories
      const distDir = join(__dirname, "dist");
      const distRubyFiles = glob.sync("dist/**/*.rb", {
        cwd: __dirname,
        absolute: false,
      });

      distRubyFiles.forEach((file) => {
        const filePath = join(__dirname, file);
        try {
          const stats = lstatSync(filePath);
          let content;
          // If it's a symlink to lib/, read from lib but write to dist
          if (stats.isSymbolicLink()) {
            const resolvedPath = realpathSync(filePath);
            const distDirResolved = realpathSync(distDir);
            if (!resolvedPath.startsWith(distDirResolved)) {
              // Read from lib, but write to dist (replacing the symlink)
              content = readFileSync(resolvedPath, "utf-8");
              unlinkSync(filePath);
            } else {
              // Symlink resolves within dist, read resolved path
              content = readFileSync(resolvedPath, "utf-8");
            }
          } else {
            // Regular file, read directly
            content = readFileSync(filePath, "utf-8");
          }
          // Remove lines that start with require_relative (with optional whitespace)
          content = content.replace(/^\s*require_relative\s+.*$/gm, "");
          // Remove multiple consecutive empty lines
          content = content.replace(/\n{3,}/g, "\n\n");
          writeFileSync(filePath, content, "utf-8");
        } catch (e) {
          // If read/write fails, skip this file
          console.warn(`Could not process file ${filePath}: ${e.message}`);
        }
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
    cleanupSymlinks(),
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
      // Resolve symbolic links when copying to ensure dist files are regular files
      // This allows us to process dist/ruby_wasm_ui.rb without affecting lib/ruby_wasm_ui.rb
      copySyncOptions: {
        dereference: true,
      },
    }),
    cleanup({
      comments: "none",
      extensions: ["js"],
    }),
    removeRequireRelative(),
    filesize(),
  ],
};
