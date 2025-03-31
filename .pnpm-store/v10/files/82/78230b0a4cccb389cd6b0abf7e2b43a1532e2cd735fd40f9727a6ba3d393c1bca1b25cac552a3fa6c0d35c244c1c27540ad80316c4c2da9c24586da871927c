// src/index.ts
import { parseIconSet } from "@iconify/utils";
import plugin from "tailwindcss/plugin.js";

// types.ts
var collectionNames = ["material-symbols", "material-symbols-light", "ic", "mdi", "ph", "solar", "tabler", "hugeicons", "mingcute", "ri", "bi", "carbon", "iconamoon", "iconoir", "ion", "lucide", "uil", "tdesign", "teenyicons", "clarity", "bx", "bxs", "majesticons", "ant-design", "gg", "gravity-ui", "octicon", "memory", "cil", "flowbite", "mynaui", "basil", "pixelarticons", "akar-icons", "ci", "system-uicons", "typcn", "radix-icons", "zondicons", "ep", "circum", "mdi-light", "fe", "eos-icons", "bitcoin-icons", "charm", "prime", "humbleicons", "uiw", "uim", "uit", "uis", "maki", "gridicons", "mi", "quill", "gala", "lets-icons", "f7", "mage", "marketeq", "fluent", "icon-park-outline", "icon-park-solid", "icon-park-twotone", "icon-park", "vscode-icons", "jam", "heroicons", "codicon", "pajamas", "pepicons-pop", "pepicons-print", "pepicons-pencil", "bytesize", "ei", "streamline", "guidance", "fa6-solid", "fa6-regular", "ooui", "nimbus", "oui", "formkit", "line-md", "meteocons", "svg-spinners", "openmoji", "twemoji", "noto", "fluent-emoji", "fluent-emoji-flat", "fluent-emoji-high-contrast", "noto-v1", "emojione", "emojione-monotone", "emojione-v1", "fxemoji", "streamline-emojis", "bxl", "logos", "simple-icons", "cib", "fa6-brands", "nonicons", "arcticons", "cbi", "file-icons", "devicon", "devicon-plain", "skill-icons", "unjs", "brandico", "entypo-social", "token", "token-branded", "cryptocurrency", "cryptocurrency-color", "flag", "circle-flags", "flagpack", "cif", "gis", "map", "geo", "game-icons", "fad", "academicons", "wi", "healthicons", "medical-icon", "covid", "la", "eva", "dashicons", "flat-color-icons", "entypo", "foundation", "raphael", "icons8", "iwwa", "heroicons-outline", "heroicons-solid", "fa-solid", "fa-regular", "fa-brands", "fa", "fluent-mdl2", "fontisto", "icomoon-free", "subway", "oi", "wpf", "simple-line-icons", "et", "el", "vaadin", "grommet-icons", "whh", "si-glyph", "zmdi", "ls", "bpmn", "flat-ui", "vs", "topcoat", "il", "websymbol", "fontelico", "ps", "feather", "mono-icons", "pepicons"];

// src/core.ts
import fs from "fs";
import { createRequire } from "module";
import path from "path";
import { getIconCSS, getIconData } from "@iconify/utils";

// src/utils.ts
function callsites() {
  const _prepareStackTrace = Error.prepareStackTrace;
  try {
    let result = [];
    Error.prepareStackTrace = (_, callSites) => {
      const callSitesWithoutCurrent = callSites.slice(1);
      result = callSitesWithoutCurrent;
      return callSitesWithoutCurrent;
    };
    new Error().stack;
    return result;
  } finally {
    Error.prepareStackTrace = _prepareStackTrace;
  }
}
function callerPath1() {
  const callSites = callsites();
  if (!callSites[0]) return;
  return callSites[0].getFileName();
}
function callerPath2() {
  const error = new Error();
  const stack = error.stack?.split("\n");
  const data = stack.find(
    (line) => !line.trim().startsWith("Error") && !line.includes("(") && !line.includes(")")
  );
  if (!data) {
    return;
  }
  const filePathPattern = new RegExp(
    /\s*at (\/.*|[a-zA-Z]:\\(?:([^<>:"\/\\|?*]*[^<>:"\/\\|?*.]\\|..\\)*([^<>:"\/\\|?*]*[^<>:"\/\\|?*.]\\?|..\\))?):\d+:\d+/i
  );
  const result = filePathPattern.exec(data);
  if (!result) {
    return;
  }
  return result[1];
}
function callerPath() {
  return callerPath1() ?? callerPath2();
}

// src/core.ts
var req = false ? __require : createRequire(import.meta.url);
var localResolve = (cwd, id) => {
  try {
    const resolved = req.resolve(id, { paths: [cwd] });
    return resolved;
  } catch {
    return null;
  }
};
var isPackageExists = (id) => {
  const p = callerPath();
  const cwd = p ? path.dirname(p) : process.cwd();
  return Boolean(localResolve(cwd, id));
};
function getIconCollections(include) {
  const p = callerPath();
  const cwd = p ? path.dirname(p) : process.cwd();
  const pkgPath = localResolve(cwd, "@iconify/json/package.json");
  if (!pkgPath) {
    if (Array.isArray(include)) {
      return include.reduce(
        (result, name) => {
          const jsonPath = localResolve(cwd, `@iconify-json/${name}/icons.json`);
          if (!jsonPath) {
            throw new Error(
              `Icon collection "${name}" not found. Please install @iconify-json/${name} or @iconify/json`
            );
          }
          return {
            ...result,
            [name]: req(jsonPath)
          };
        },
        {}
      );
    }
    return {};
  }
  const pkgDir = path.dirname(pkgPath);
  const files = fs.readdirSync(path.join(pkgDir, "json"));
  const collections = {};
  for (const file of files) {
    if (include === "all" || include.includes(file.replace(".json", ""))) {
      const json = req(path.join(pkgDir, "json", file));
      collections[json.prefix] = json;
    }
  }
  return collections;
}
var generateIconComponent = (data, options) => {
  if (options.strokeWidth) {
    const strokeWidthRegex = /stroke-width="\d+"/g;
    const match = data.body.match(strokeWidthRegex);
    const noStrokeWidth = !match;
    const isAllStrokeWidthAreEqual = match && match.every((strokeWidth) => strokeWidth === match[0]);
    if (isAllStrokeWidthAreEqual) {
      data.body = data.body.replace(
        strokeWidthRegex,
        `stroke-width="${options.strokeWidth}"`
      );
    }
    if (noStrokeWidth) {
      data.body = `<g stroke-width="${options.strokeWidth}">${data.body}</g>`;
    }
  }
  const css = getIconCSS(data, {});
  const rules = {};
  css.replace(/^\s+([^:]+):\s*(.+);$/gm, (_, prop, value) => {
    if (prop === "width" || prop === "height") {
      rules[prop] = `${options.scale}em`;
    } else {
      rules[prop] = value;
    }
    return "";
  });
  if (options.extraProperties) {
    Object.assign(rules, options.extraProperties);
  }
  return rules;
};
var generateComponent = ({
  name,
  icons
}, options) => {
  const data = getIconData(icons, name);
  if (!data) return null;
  return generateIconComponent(data, options);
};

// src/dynamic.ts
var cache = /* @__PURE__ */ new Map();
function getIconCollection(name) {
  const cached = cache.get(name);
  if (cached) return cached;
  const collection = getIconCollections([name])[name];
  if (collection) cache.set(name, collection);
  return collection;
}
function getDynamicCSSRules(icon, options) {
  const nameParts = icon.split(/--|\:/);
  if (nameParts.length !== 2) {
    throw new Error(`Invalid icon name: "${icon}"`);
  }
  const prefix = nameParts[0];
  const name = nameParts[1];
  if (!collectionNames.includes(prefix)) {
    throw new Error(`Invalid collection name: "${prefix}"`);
  }
  const icons = getIconCollection(prefix);
  const generated = generateComponent(
    {
      icons,
      name
    },
    options
  );
  if (!generated) {
    throw new Error(`Invalid icon name: "${icon}"`);
  }
  return generated;
}

// src/index.ts
var iconsPlugin = (iconsPluginOptions) => {
  const {
    collections: propsCollections,
    scale = 1,
    prefix = "i",
    extraProperties = {},
    strokeWidth,
    collectionNamesAlias = {}
  } = iconsPluginOptions ?? {};
  const collections = propsCollections ?? getIconCollections(
    collectionNames.filter(
      (name) => isPackageExists(`@iconify-json/${name}`)
    )
  );
  const components = {};
  for (const prefix2 of Object.keys(collections)) {
    const collection = {
      ...collections[prefix2],
      prefix: prefix2
    };
    parseIconSet(collection, (name, data) => {
      if (!data) return;
      const collectionName = collectionNamesAlias[prefix2] ?? prefix2;
      components[`${collectionName}-${name}`] = generateIconComponent(data, {
        scale,
        extraProperties,
        strokeWidth
      });
    });
  }
  return plugin(({ matchComponents }) => {
    matchComponents(
      {
        [prefix]: (value) => {
          if (typeof value === "string") return components[value] ?? null;
          return value;
        }
      },
      {
        values: components
      }
    );
  });
};
var dynamicIconsPlugin = (iconsPluginOptions) => {
  const {
    prefix = "i",
    scale = 1,
    strokeWidth,
    extraProperties = {}
  } = iconsPluginOptions ?? {};
  return plugin(({ matchComponents }) => {
    matchComponents({
      [prefix]: (value) => getDynamicCSSRules(value, { scale, extraProperties, strokeWidth })
    });
  });
};
export {
  collectionNames,
  dynamicIconsPlugin,
  getIconCollections,
  iconsPlugin
};
