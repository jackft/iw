import { defineConfig } from "vite";

export default defineConfig({
  build: {
    lib: {
      entry: "src/index.ts",
      name: "cclTrajViz",      // global var name
      fileName: "ccl-traj-viz",  // output: cc-traj-viz.iife.js
      formats: ["iife"]
    }
  }
});