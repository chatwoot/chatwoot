import { declare } from '@babel/helper-plugin-utils';
import getTargets, { prettifyTargets, getInclusionReasons, isRequired } from '@babel/helper-compilation-targets';
import * as babel from '@babel/core';

const {
  types: t$1,
  template
} = babel.default || babel;
function intersection(a, b) {
  const result = new Set();
  a.forEach(v => b.has(v) && result.add(v));
  return result;
}
function has$1(object, key) {
  return Object.prototype.hasOwnProperty.call(object, key);
}

function getType(target) {
  return Object.prototype.toString.call(target).slice(8, -1);
}

function resolveId(path) {
  if (path.isIdentifier() && !path.scope.hasBinding(path.node.name,
  /* noGlobals */
  true)) {
    return path.node.name;
  }

  const {
    deopt
  } = path.evaluate();

  if (deopt && deopt.isIdentifier()) {
    return deopt.node.name;
  }
}

function resolveKey(path, computed = false) {
  const {
    node,
    parent,
    scope
  } = path;
  if (path.isStringLiteral()) return node.value;
  const {
    name
  } = node;
  const isIdentifier = path.isIdentifier();
  if (isIdentifier && !(computed || parent.computed)) return name;

  if (computed && path.isMemberExpression() && path.get("object").isIdentifier({
    name: "Symbol"
  }) && !scope.hasBinding("Symbol",
  /* noGlobals */
  true)) {
    const sym = resolveKey(path.get("property"), path.node.computed);
    if (sym) return "Symbol." + sym;
  }

  if (!isIdentifier || scope.hasBinding(name,
  /* noGlobals */
  true)) {
    const {
      value
    } = path.evaluate();
    if (typeof value === "string") return value;
  }
}
function resolveSource(obj) {
  if (obj.isMemberExpression() && obj.get("property").isIdentifier({
    name: "prototype"
  })) {
    const id = resolveId(obj.get("object"));

    if (id) {
      return {
        id,
        placement: "prototype"
      };
    }

    return {
      id: null,
      placement: null
    };
  }

  const id = resolveId(obj);

  if (id) {
    return {
      id,
      placement: "static"
    };
  }

  const {
    value
  } = obj.evaluate();

  if (value !== undefined) {
    return {
      id: getType(value),
      placement: "prototype"
    };
  } else if (obj.isRegExpLiteral()) {
    return {
      id: "RegExp",
      placement: "prototype"
    };
  } else if (obj.isFunction()) {
    return {
      id: "Function",
      placement: "prototype"
    };
  }

  return {
    id: null,
    placement: null
  };
}
function getImportSource({
  node
}) {
  if (node.specifiers.length === 0) return node.source.value;
}
function getRequireSource({
  node
}) {
  if (!t$1.isExpressionStatement(node)) return;
  const {
    expression
  } = node;
  const isRequire = t$1.isCallExpression(expression) && t$1.isIdentifier(expression.callee) && expression.callee.name === "require" && expression.arguments.length === 1 && t$1.isStringLiteral(expression.arguments[0]);
  if (isRequire) return expression.arguments[0].value;
}

function hoist(node) {
  node._blockHoist = 3;
  return node;
}

function createUtilsGetter(cache) {
  return path => {
    const prog = path.findParent(p => p.isProgram());
    return {
      injectGlobalImport(url) {
        cache.storeAnonymous(prog, url, (isScript, source) => {
          return isScript ? template.statement.ast`require(${source})` : t$1.importDeclaration([], source);
        });
      },

      injectNamedImport(url, name, hint = name) {
        return cache.storeNamed(prog, url, name, (isScript, source, name) => {
          const id = prog.scope.generateUidIdentifier(hint);
          return {
            node: isScript ? hoist(template.statement.ast`
                  var ${id} = require(${source}).${name}
                `) : t$1.importDeclaration([t$1.importSpecifier(id, name)], source),
            name: id.name
          };
        });
      },

      injectDefaultImport(url, hint = url) {
        return cache.storeNamed(prog, url, "default", (isScript, source) => {
          const id = prog.scope.generateUidIdentifier(hint);
          return {
            node: isScript ? hoist(template.statement.ast`var ${id} = require(${source})`) : t$1.importDeclaration([t$1.importDefaultSpecifier(id)], source),
            name: id.name
          };
        });
      }

    };
  };
}

const {
  types: t
} = babel.default || babel;
class ImportsCache {
  constructor(resolver) {
    this._imports = new WeakMap();
    this._anonymousImports = new WeakMap();
    this._lastImports = new WeakMap();
    this._resolver = resolver;
  }

  storeAnonymous(programPath, url, // eslint-disable-next-line no-undef
  getVal) {
    const key = this._normalizeKey(programPath, url);

    const imports = this._ensure(this._anonymousImports, programPath, Set);

    if (imports.has(key)) return;
    const node = getVal(programPath.node.sourceType === "script", t.stringLiteral(this._resolver(url)));
    imports.add(key);

    this._injectImport(programPath, node);
  }

  storeNamed(programPath, url, name, getVal) {
    const key = this._normalizeKey(programPath, url, name);

    const imports = this._ensure(this._imports, programPath, Map);

    if (!imports.has(key)) {
      const {
        node,
        name: id
      } = getVal(programPath.node.sourceType === "script", t.stringLiteral(this._resolver(url)), t.identifier(name));
      imports.set(key, id);

      this._injectImport(programPath, node);
    }

    return t.identifier(imports.get(key));
  }

  _injectImport(programPath, node) {
    let lastImport = this._lastImports.get(programPath);

    if (lastImport && lastImport.node && // Sometimes the AST is modified and the "last import"
    // we have has been replaced
    lastImport.parent === programPath.node && lastImport.container === programPath.node.body) {
      lastImport = lastImport.insertAfter(node);
    } else {
      lastImport = programPath.unshiftContainer("body", node);
    }

    lastImport = lastImport[lastImport.length - 1];

    this._lastImports.set(programPath, lastImport);
    /*
    let lastImport;
     programPath.get("body").forEach(path => {
      if (path.isImportDeclaration()) lastImport = path;
      if (
        path.isExpressionStatement() &&
        isRequireCall(path.get("expression"))
      ) {
        lastImport = path;
      }
      if (
        path.isVariableDeclaration() &&
        path.get("declarations").length === 1 &&
        (isRequireCall(path.get("declarations.0.init")) ||
          (path.get("declarations.0.init").isMemberExpression() &&
            isRequireCall(path.get("declarations.0.init.object"))))
      ) {
        lastImport = path;
      }
    });*/

  }

  _ensure(map, programPath, Collection) {
    let collection = map.get(programPath);

    if (!collection) {
      collection = new Collection();
      map.set(programPath, collection);
    }

    return collection;
  }

  _normalizeKey(programPath, url, name = "") {
    const {
      sourceType
    } = programPath.node; // If we rely on the imported binding (the "name" parameter), we also need to cache
    // based on the sourceType. This is because the module transforms change the names
    // of the import variables.

    return `${name && sourceType}::${url}::${name}`;
  }

}

const presetEnvSilentDebugHeader = "#__secret_key__@babel/preset-env__don't_log_debug_header_and_resolved_targets";
function stringifyTargetsMultiline(targets) {
  return JSON.stringify(prettifyTargets(targets), null, 2);
}

function patternToRegExp(pattern) {
  if (pattern instanceof RegExp) return pattern;

  try {
    return new RegExp(`^${pattern}$`);
  } catch {
    return null;
  }
}

function buildUnusedError(label, unused) {
  if (!unused.length) return "";
  return `  - The following "${label}" patterns didn't match any polyfill:\n` + unused.map(original => `    ${String(original)}\n`).join("");
}

function buldDuplicatesError(duplicates) {
  if (!duplicates.size) return "";
  return `  - The following polyfills were matched both by "include" and "exclude" patterns:\n` + Array.from(duplicates, name => `    ${name}\n`).join("");
}

function validateIncludeExclude(provider, polyfills, includePatterns, excludePatterns) {
  let current;

  const filter = pattern => {
    const regexp = patternToRegExp(pattern);
    if (!regexp) return false;
    let matched = false;

    for (const polyfill of polyfills) {
      if (regexp.test(polyfill)) {
        matched = true;
        current.add(polyfill);
      }
    }

    return !matched;
  }; // prettier-ignore


  const include = current = new Set();
  const unusedInclude = Array.from(includePatterns).filter(filter); // prettier-ignore

  const exclude = current = new Set();
  const unusedExclude = Array.from(excludePatterns).filter(filter);
  const duplicates = intersection(include, exclude);

  if (duplicates.size > 0 || unusedInclude.length > 0 || unusedExclude.length > 0) {
    throw new Error(`Error while validating the "${provider}" provider options:\n` + buildUnusedError("include", unusedInclude) + buildUnusedError("exclude", unusedExclude) + buldDuplicatesError(duplicates));
  }

  return {
    include,
    exclude
  };
}
function applyMissingDependenciesDefaults(options, babelApi) {
  const {
    missingDependencies = {}
  } = options;
  if (missingDependencies === false) return false;
  const caller = babelApi.caller(caller => caller?.name);
  const {
    log = "deferred",
    inject = caller === "rollup-plugin-babel" ? "throw" : "import",
    all = false
  } = missingDependencies;
  return {
    log,
    inject,
    all
  };
}

var usage = (callProvider => {
  function property(object, key, placement, path) {
    return callProvider({
      kind: "property",
      object,
      key,
      placement
    }, path);
  }

  return {
    // Symbol(), new Promise
    ReferencedIdentifier(path) {
      const {
        node: {
          name
        },
        scope
      } = path;
      if (scope.getBindingIdentifier(name)) return;
      callProvider({
        kind: "global",
        name
      }, path);
    },

    MemberExpression(path) {
      const key = resolveKey(path.get("property"), path.node.computed);
      if (!key || key === "prototype") return;
      const object = path.get("object");
      const binding = object.scope.getBinding(object.node.name);
      if (binding && binding.path.isImportNamespaceSpecifier()) return;
      const source = resolveSource(object);
      return property(source.id, key, source.placement, path);
    },

    ObjectPattern(path) {
      const {
        parentPath,
        parent
      } = path;
      let obj; // const { keys, values } = Object

      if (parentPath.isVariableDeclarator()) {
        obj = parentPath.get("init"); // ({ keys, values } = Object)
      } else if (parentPath.isAssignmentExpression()) {
        obj = parentPath.get("right"); // !function ({ keys, values }) {...} (Object)
        // resolution does not work after properties transform :-(
      } else if (parentPath.isFunction()) {
        const grand = parentPath.parentPath;

        if (grand.isCallExpression() || grand.isNewExpression()) {
          if (grand.node.callee === parent) {
            obj = grand.get("arguments")[path.key];
          }
        }
      }

      let id = null;
      let placement = null;
      if (obj) ({
        id,
        placement
      } = resolveSource(obj));

      for (const prop of path.get("properties")) {
        if (prop.isObjectProperty()) {
          const key = resolveKey(prop.get("key"));
          if (key) property(id, key, placement, prop);
        }
      }
    },

    BinaryExpression(path) {
      if (path.node.operator !== "in") return;
      const source = resolveSource(path.get("right"));
      const key = resolveKey(path.get("left"), true);
      if (!key) return;
      callProvider({
        kind: "in",
        object: source.id,
        key,
        placement: source.placement
      }, path);
    }

  };
});

var entry = (callProvider => ({
  ImportDeclaration(path) {
    const source = getImportSource(path);
    if (!source) return;
    callProvider({
      kind: "import",
      source
    }, path);
  },

  Program(path) {
    path.get("body").forEach(bodyPath => {
      const source = getRequireSource(bodyPath);
      if (!source) return;
      callProvider({
        kind: "import",
        source
      }, bodyPath);
    });
  }

}));

function resolve(dirname, moduleName, absoluteImports) {
  if (absoluteImports === false) return moduleName;
  throw new Error(`"absoluteImports" is not supported in bundles prepared for the browser.`);
} // eslint-disable-next-line no-unused-vars

function has(basedir, name) {
  return true;
} // eslint-disable-next-line no-unused-vars

function logMissing(missingDeps) {} // eslint-disable-next-line no-unused-vars

function laterLogMissing(missingDeps) {}

const PossibleGlobalObjects = new Set(["global", "globalThis", "self", "window"]);
function createMetaResolver(polyfills) {
  const {
    static: staticP,
    instance: instanceP,
    global: globalP
  } = polyfills;
  return meta => {
    if (meta.kind === "global" && globalP && has$1(globalP, meta.name)) {
      return {
        kind: "global",
        desc: globalP[meta.name],
        name: meta.name
      };
    }

    if (meta.kind === "property" || meta.kind === "in") {
      const {
        placement,
        object,
        key
      } = meta;

      if (object && placement === "static") {
        if (globalP && PossibleGlobalObjects.has(object) && has$1(globalP, key)) {
          return {
            kind: "global",
            desc: globalP[key],
            name: key
          };
        }

        if (staticP && has$1(staticP, object) && has$1(staticP[object], key)) {
          return {
            kind: "static",
            desc: staticP[object][key],
            name: `${object}$${key}`
          };
        }
      }

      if (instanceP && has$1(instanceP, key)) {
        return {
          kind: "instance",
          desc: instanceP[key],
          name: `${key}`
        };
      }
    }
  };
}

function resolveOptions(options, babelApi) {
  const {
    method,
    targets: targetsOption,
    ignoreBrowserslistConfig,
    configPath,
    debug,
    shouldInjectPolyfill,
    absoluteImports,
    ...providerOptions
  } = options;
  let methodName;
  if (method === "usage-global") methodName = "usageGlobal";else if (method === "entry-global") methodName = "entryGlobal";else if (method === "usage-pure") methodName = "usagePure";else if (typeof method !== "string") {
    throw new Error(".method must be a string");
  } else {
    throw new Error(`.method must be one of "entry-global", "usage-global"` + ` or "usage-pure" (received ${JSON.stringify(method)})`);
  }

  if (typeof shouldInjectPolyfill === "function") {
    if (options.include || options.exclude) {
      throw new Error(`.include and .exclude are not supported when using the` + ` .shouldInjectPolyfill function.`);
    }
  } else if (shouldInjectPolyfill != null) {
    throw new Error(`.shouldInjectPolyfill must be a function, or undefined` + ` (received ${JSON.stringify(shouldInjectPolyfill)})`);
  }

  if (absoluteImports != null && typeof absoluteImports !== "boolean" && typeof absoluteImports !== "string") {
    throw new Error(`.absoluteImports must be a boolean, a string, or undefined` + ` (received ${JSON.stringify(absoluteImports)})`);
  }

  let targets;

  if ( // If any browserslist-related option is specified, fallback to the old
  // behavior of not using the targets specified in the top-level options.
  targetsOption || configPath || ignoreBrowserslistConfig) {
    const targetsObj = typeof targetsOption === "string" || Array.isArray(targetsOption) ? {
      browsers: targetsOption
    } : targetsOption;
    targets = getTargets(targetsObj, {
      ignoreBrowserslistConfig,
      configPath
    });
  } else {
    targets = babelApi.targets();
  }

  return {
    method,
    methodName,
    targets,
    absoluteImports: absoluteImports ?? false,
    shouldInjectPolyfill,
    debug: !!debug,
    providerOptions: providerOptions
  };
}

function instantiateProvider(factory, options, missingDependencies, dirname, debugLog, babelApi) {
  const {
    method,
    methodName,
    targets,
    debug,
    shouldInjectPolyfill,
    providerOptions,
    absoluteImports
  } = resolveOptions(options, babelApi);
  const getUtils = createUtilsGetter(new ImportsCache(moduleName => resolve(dirname, moduleName, absoluteImports))); // eslint-disable-next-line prefer-const

  let include, exclude;
  let polyfillsSupport;
  let polyfillsNames;
  let filterPolyfills;
  const depsCache = new Map();
  const api = {
    babel: babelApi,
    getUtils,
    method: options.method,
    targets,
    createMetaResolver,

    shouldInjectPolyfill(name) {
      if (polyfillsNames === undefined) {
        throw new Error(`Internal error in the ${factory.name} provider: ` + `shouldInjectPolyfill() can't be called during initialization.`);
      }

      if (!polyfillsNames.has(name)) {
        console.warn(`Internal error in the ${provider.name} provider: ` + `unknown polyfill "${name}".`);
      }

      if (filterPolyfills && !filterPolyfills(name)) return false;
      let shouldInject = isRequired(name, targets, {
        compatData: polyfillsSupport,
        includes: include,
        excludes: exclude
      });

      if (shouldInjectPolyfill) {
        shouldInject = shouldInjectPolyfill(name, shouldInject);

        if (typeof shouldInject !== "boolean") {
          throw new Error(`.shouldInjectPolyfill must return a boolean.`);
        }
      }

      return shouldInject;
    },

    debug(name) {
      debugLog().found = true;
      if (!debug || !name) return;
      if (debugLog().polyfills.has(provider.name)) return;
      debugLog().polyfills.set(name, polyfillsSupport && name && polyfillsSupport[name]);
    },

    assertDependency(name, version = "*") {
      if (missingDependencies === false) return;

      if (absoluteImports) {
        // If absoluteImports is not false, we will try resolving
        // the dependency and throw if it's not possible. We can
        // skip the check here.
        return;
      }

      const dep = version === "*" ? name : `${name}@^${version}`;
      const found = missingDependencies.all ? false : mapGetOr(depsCache, name, () => !has());

      if (!found) {
        debugLog().missingDeps.add(dep);
      }
    }

  };
  const provider = factory(api, providerOptions, dirname);

  if (typeof provider[methodName] !== "function") {
    throw new Error(`The "${provider.name || factory.name}" provider doesn't ` + `support the "${method}" polyfilling method.`);
  }

  if (Array.isArray(provider.polyfills)) {
    polyfillsNames = new Set(provider.polyfills);
    filterPolyfills = provider.filterPolyfills;
  } else if (provider.polyfills) {
    polyfillsNames = new Set(Object.keys(provider.polyfills));
    polyfillsSupport = provider.polyfills;
    filterPolyfills = provider.filterPolyfills;
  } else {
    polyfillsNames = new Set();
  }

  ({
    include,
    exclude
  } = validateIncludeExclude(provider.name || factory.name, polyfillsNames, providerOptions.include || [], providerOptions.exclude || []));
  return {
    debug,
    method,
    targets,
    provider,

    callProvider(payload, path) {
      const utils = getUtils(path); // $FlowIgnore

      provider[methodName](payload, utils, path);
    }

  };
}

function definePolyfillProvider(factory) {
  return declare((babelApi, options, dirname) => {
    babelApi.assertVersion(7);
    const {
      traverse
    } = babelApi;
    let debugLog;
    const missingDependencies = applyMissingDependenciesDefaults(options, babelApi);
    const {
      debug,
      method,
      targets,
      provider,
      callProvider
    } = instantiateProvider(factory, options, missingDependencies, dirname, () => debugLog, babelApi);
    const createVisitor = method === "entry-global" ? entry : usage;
    const visitor = provider.visitor ? traverse.visitors.merge([createVisitor(callProvider), provider.visitor]) : createVisitor(callProvider);

    if (debug && debug !== presetEnvSilentDebugHeader) {
      console.log(`${provider.name}: \`DEBUG\` option`);
      console.log(`\nUsing targets: ${stringifyTargetsMultiline(targets)}`);
      console.log(`\nUsing polyfills with \`${method}\` method:`);
    }

    return {
      name: "inject-polyfills",
      visitor,

      pre() {
        debugLog = {
          polyfills: new Map(),
          found: false,
          providers: new Set(),
          missingDeps: new Set()
        }; // $FlowIgnore - Flow doesn't support optional calls

        provider.pre?.apply(this, arguments);
      },

      post() {
        // $FlowIgnore - Flow doesn't support optional calls
        provider.post?.apply(this, arguments);

        if (missingDependencies !== false) {
          if (missingDependencies.log === "per-file") {
            logMissing(debugLog.missingDeps);
          } else {
            laterLogMissing(debugLog.missingDeps);
          }
        }

        if (!debug) return;
        if (this.filename) console.log(`\n[${this.filename}]`);

        if (debugLog.polyfills.size === 0) {
          console.log(method === "entry-global" ? debugLog.found ? `Based on your targets, the ${provider.name} polyfill did not add any polyfill.` : `The entry point for the ${provider.name} polyfill has not been found.` : `Based on your code and targets, the ${provider.name} polyfill did not add any polyfill.`);
          return;
        }

        if (method === "entry-global") {
          console.log(`The ${provider.name} polyfill entry has been replaced with ` + `the following polyfills:`);
        } else {
          console.log(`The ${provider.name} polyfill added the following polyfills:`);
        }

        for (const [name, support] of debugLog.polyfills) {
          if (support) {
            const filteredTargets = getInclusionReasons(name, targets, support);
            const formattedTargets = JSON.stringify(filteredTargets).replace(/,/g, ", ").replace(/^\{"/, '{ "').replace(/"\}$/, '" }');
            console.log(`  ${name} ${formattedTargets}`);
          } else {
            console.log(`  ${name}`);
          }
        }
      }

    };
  });
}

function mapGetOr(map, key, getDefault) {
  let val = map.get(key);

  if (val === undefined) {
    val = getDefault();
    map.set(key, val);
  }

  return val;
}

export default definePolyfillProvider;
//# sourceMappingURL=index.browser.mjs.map
