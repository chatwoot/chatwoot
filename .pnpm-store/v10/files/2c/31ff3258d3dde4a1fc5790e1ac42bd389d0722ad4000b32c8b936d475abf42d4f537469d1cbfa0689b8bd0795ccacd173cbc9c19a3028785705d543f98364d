const defaultPort = 51204;
const defaultBrowserPort = 63315;
const defaultInspectPort = 9229;
const API_PATH = "/__vitest_api__";
const extraInlineDeps = [
  /^(?!.*node_modules).*\.mjs$/,
  /^(?!.*node_modules).*\.cjs\.js$/,
  // Vite client
  /vite\w*\/dist\/client\/env.mjs/
];
const CONFIG_NAMES = ["vitest.config", "vite.config"];
const WORKSPACES_NAMES = ["vitest.workspace", "vitest.projects"];
const CONFIG_EXTENSIONS = [".ts", ".mts", ".cts", ".js", ".mjs", ".cjs"];
const configFiles = CONFIG_NAMES.flatMap(
  (name) => CONFIG_EXTENSIONS.map((ext) => name + ext)
);
const WORKSPACES_EXTENSIONS = [...CONFIG_EXTENSIONS, ".json"];
const workspacesFiles = WORKSPACES_NAMES.flatMap(
  (name) => WORKSPACES_EXTENSIONS.map((ext) => name + ext)
);
const globalApis = [
  // suite
  "suite",
  "test",
  "describe",
  "it",
  // chai
  "chai",
  "expect",
  "assert",
  // typecheck
  "expectTypeOf",
  "assertType",
  // utils
  "vitest",
  "vi",
  // hooks
  "beforeAll",
  "afterAll",
  "beforeEach",
  "afterEach",
  "onTestFinished",
  "onTestFailed"
];

export { API_PATH as A, defaultBrowserPort as a, defaultInspectPort as b, configFiles as c, defaultPort as d, extraInlineDeps as e, globalApis as g, workspacesFiles as w };
