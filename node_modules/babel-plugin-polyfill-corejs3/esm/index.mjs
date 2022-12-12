import corejs3Polyfills from '../core-js-compat/data.js';
import getModulesListForTargetVersion from '../core-js-compat/get-modules-list-for-target-version.js';
import * as babel from '@babel/core';
import corejsEntries from '../core-js-compat/entries.js';
import defineProvider from '@babel/helper-define-polyfill-provider';

var corejs3ShippedProposalsList = new Set(["esnext.global-this", "esnext.string.match-all"]);

const polyfillsOrder = {};
Object.keys(corejs3Polyfills).forEach((name, index) => {
  polyfillsOrder[name] = index;
});

const define = (pure, global, name = global[0], exclude) => {
  return {
    name,
    pure,
    global: global.sort((a, b) => polyfillsOrder[a] - polyfillsOrder[b]),
    exclude
  };
};

const typed = name => define(null, [name, ...TypedArrayDependencies]);

const ArrayNatureIterators = ["es.array.iterator", "web.dom-collections.iterator"];
const CommonIterators = ["es.string.iterator", ...ArrayNatureIterators];
const ArrayNatureIteratorsWithTag = ["es.object.to-string", ...ArrayNatureIterators];
const CommonIteratorsWithTag = ["es.object.to-string", ...CommonIterators];
const TypedArrayDependencies = ["es.typed-array.copy-within", "es.typed-array.every", "es.typed-array.fill", "es.typed-array.filter", "es.typed-array.find", "es.typed-array.find-index", "es.typed-array.for-each", "es.typed-array.includes", "es.typed-array.index-of", "es.typed-array.iterator", "es.typed-array.join", "es.typed-array.last-index-of", "es.typed-array.map", "es.typed-array.reduce", "es.typed-array.reduce-right", "es.typed-array.reverse", "es.typed-array.set", "es.typed-array.slice", "es.typed-array.some", "es.typed-array.sort", "es.typed-array.subarray", "es.typed-array.to-locale-string", "es.typed-array.to-string", "es.object.to-string", "es.array.iterator", "es.array-buffer.slice"];
const TypedArrayStaticMethods = {
  from: define(null, ["es.typed-array.from"]),
  of: define(null, ["es.typed-array.of"])
};
const PromiseDependencies = ["es.promise", "es.object.to-string"];
const PromiseDependenciesWithIterators = [...PromiseDependencies, ...CommonIterators];
const SymbolDependencies = ["es.symbol", "es.symbol.description", "es.object.to-string"];
const MapDependencies = ["es.map", "esnext.map.delete-all", "esnext.map.every", "esnext.map.filter", "esnext.map.find", "esnext.map.find-key", "esnext.map.includes", "esnext.map.key-of", "esnext.map.map-keys", "esnext.map.map-values", "esnext.map.merge", "esnext.map.reduce", "esnext.map.some", "esnext.map.update", ...CommonIteratorsWithTag];
const SetDependencies = ["es.set", "esnext.set.add-all", "esnext.set.delete-all", "esnext.set.difference", "esnext.set.every", "esnext.set.filter", "esnext.set.find", "esnext.set.intersection", "esnext.set.is-disjoint-from", "esnext.set.is-subset-of", "esnext.set.is-superset-of", "esnext.set.join", "esnext.set.map", "esnext.set.reduce", "esnext.set.some", "esnext.set.symmetric-difference", "esnext.set.union", ...CommonIteratorsWithTag];
const WeakMapDependencies = ["es.weak-map", "esnext.weak-map.delete-all", ...CommonIteratorsWithTag];
const WeakSetDependencies = ["es.weak-set", "esnext.weak-set.add-all", "esnext.weak-set.delete-all", ...CommonIteratorsWithTag];
const URLSearchParamsDependencies = ["web.url", ...CommonIteratorsWithTag];
const BuiltIns = {
  AggregateError: define("aggregate-error", ["esnext.aggregate-error", ...CommonIterators]),
  ArrayBuffer: define(null, ["es.array-buffer.constructor", "es.array-buffer.slice", "es.object.to-string"]),
  DataView: define(null, ["es.data-view", "es.array-buffer.slice", "es.object.to-string"]),
  Date: define(null, ["es.date.to-string"]),
  Float32Array: typed("es.typed-array.float32-array"),
  Float64Array: typed("es.typed-array.float64-array"),
  Int8Array: typed("es.typed-array.int8-array"),
  Int16Array: typed("es.typed-array.int16-array"),
  Int32Array: typed("es.typed-array.int32-array"),
  Uint8Array: typed("es.typed-array.uint8-array"),
  Uint8ClampedArray: typed("es.typed-array.uint8-clamped-array"),
  Uint16Array: typed("es.typed-array.uint16-array"),
  Uint32Array: typed("es.typed-array.uint32-array"),
  Map: define("map/index", MapDependencies),
  Number: define(null, ["es.number.constructor"]),
  Observable: define("observable/index", ["esnext.observable", "esnext.symbol.observable", "es.object.to-string", ...CommonIteratorsWithTag]),
  Promise: define("promise/index", PromiseDependencies),
  RegExp: define(null, ["es.regexp.constructor", "es.regexp.exec", "es.regexp.to-string"]),
  Set: define("set/index", SetDependencies),
  Symbol: define("symbol/index", SymbolDependencies),
  URL: define("url/index", ["web.url", ...URLSearchParamsDependencies]),
  URLSearchParams: define("url-search-params/index", URLSearchParamsDependencies),
  WeakMap: define("weak-map/index", WeakMapDependencies),
  WeakSet: define("weak-set/index", WeakSetDependencies),
  clearImmediate: define("clear-immediate", ["web.immediate"]),
  compositeKey: define("composite-key", ["esnext.composite-key"]),
  compositeSymbol: define("composite-symbol", ["esnext.composite-symbol"]),
  fetch: define(null, PromiseDependencies),
  globalThis: define("global-this", ["es.global-this"]),
  parseFloat: define("parse-float", ["es.parse-float"]),
  parseInt: define("parse-int", ["es.parse-int"]),
  queueMicrotask: define("queue-microtask", ["web.queue-microtask"]),
  setImmediate: define("set-immediate", ["web.immediate"]),
  setInterval: define("set-interval", ["web.timers"]),
  setTimeout: define("set-timeout", ["web.timers"])
};
const StaticProperties = {
  Array: {
    from: define("array/from", ["es.array.from", "es.string.iterator"]),
    isArray: define("array/is-array", ["es.array.is-array"]),
    of: define("array/of", ["es.array.of"])
  },
  ArrayBuffer: {
    isView: define(null, ["es.array-buffer.is-view"])
  },
  Date: {
    now: define("date/now", ["es.date.now"])
  },
  JSON: {
    stringify: define("json/stringify", [], "es.symbol")
  },
  Math: {
    DEG_PER_RAD: define("math/deg-per-rad", ["esnext.math.deg-per-rad"]),
    RAD_PER_DEG: define("math/rad-per-deg", ["esnext.math.rad-per-deg"]),
    acosh: define("math/acosh", ["es.math.acosh"]),
    asinh: define("math/asinh", ["es.math.asinh"]),
    atanh: define("math/atanh", ["es.math.atanh"]),
    cbrt: define("math/cbrt", ["es.math.cbrt"]),
    clamp: define("math/clamp", ["esnext.math.clamp"]),
    clz32: define("math/clz32", ["es.math.clz32"]),
    cosh: define("math/cosh", ["es.math.cosh"]),
    degrees: define("math/degrees", ["esnext.math.degrees"]),
    expm1: define("math/expm1", ["es.math.expm1"]),
    fround: define("math/fround", ["es.math.fround"]),
    fscale: define("math/fscale", ["esnext.math.fscale"]),
    hypot: define("math/hypot", ["es.math.hypot"]),
    iaddh: define("math/iaddh", ["esnext.math.iaddh"]),
    imul: define("math/imul", ["es.math.imul"]),
    imulh: define("math/imulh", ["esnext.math.imulh"]),
    isubh: define("math/isubh", ["esnext.math.isubh"]),
    log10: define("math/log10", ["es.math.log10"]),
    log1p: define("math/log1p", ["es.math.log1p"]),
    log2: define("math/log2", ["es.math.log2"]),
    radians: define("math/radians", ["esnext.math.radians"]),
    scale: define("math/scale", ["esnext.math.scale"]),
    seededPRNG: define("math/seeded-prng", ["esnext.math.seeded-prng"]),
    sign: define("math/sign", ["es.math.sign"]),
    signbit: define("math/signbit", ["esnext.math.signbit"]),
    sinh: define("math/sinh", ["es.math.sinh"]),
    tanh: define("math/tanh", ["es.math.tanh"]),
    trunc: define("math/trunc", ["es.math.trunc"]),
    umulh: define("math/umulh", ["esnext.math.umulh"])
  },
  Map: {
    from: define(null, ["esnext.map.from", ...MapDependencies]),
    groupBy: define(null, ["esnext.map.group-by", ...MapDependencies]),
    keyBy: define(null, ["esnext.map.key-by", ...MapDependencies]),
    of: define(null, ["esnext.map.of", ...MapDependencies])
  },
  Number: {
    EPSILON: define("number/epsilon", ["es.number.epsilon"]),
    MAX_SAFE_INTEGER: define("number/max-safe-integer", ["es.number.max-safe-integer"]),
    MIN_SAFE_INTEGER: define("number/min-safe-integer", ["es.number.min-safe-integer"]),
    fromString: define("number/from-string", ["esnext.number.from-string"]),
    isFinite: define("number/is-finite", ["es.number.is-finite"]),
    isInteger: define("number/is-integer", ["es.number.is-integer"]),
    isNaN: define("number/is-nan", ["es.number.is-nan"]),
    isSafeInteger: define("number/is-safe-integer", ["es.number.is-safe-integer"]),
    parseFloat: define("number/parse-float", ["es.number.parse-float"]),
    parseInt: define("number/parse-int", ["es.number.parse-int"])
  },
  Object: {
    assign: define("object/assign", ["es.object.assign"]),
    create: define("object/create", ["es.object.create"]),
    defineProperties: define("object/define-properties", ["es.object.define-properties"]),
    defineProperty: define("object/define-property", ["es.object.define-property"]),
    entries: define("object/entries", ["es.object.entries"]),
    freeze: define("object/freeze", ["es.object.freeze"]),
    fromEntries: define("object/from-entries", ["es.object.from-entries", "es.array.iterator"]),
    getOwnPropertyDescriptor: define("object/get-own-property-descriptor", ["es.object.get-own-property-descriptor"]),
    getOwnPropertyDescriptors: define("object/get-own-property-descriptors", ["es.object.get-own-property-descriptors"]),
    getOwnPropertyNames: define("object/get-own-property-names", ["es.object.get-own-property-names"]),
    getOwnPropertySymbols: define("object/get-own-property-symbols", ["es.symbol"]),
    getPrototypeOf: define("object/get-prototype-of", ["es.object.get-prototype-of"]),
    is: define("object/is", ["es.object.is"]),
    isExtensible: define("object/is-extensible", ["es.object.is-extensible"]),
    isFrozen: define("object/is-frozen", ["es.object.is-frozen"]),
    isSealed: define("object/is-sealed", ["es.object.is-sealed"]),
    keys: define("object/keys", ["es.object.keys"]),
    preventExtensions: define("object/prevent-extensions", ["es.object.prevent-extensions"]),
    seal: define("object/seal", ["es.object.seal"]),
    setPrototypeOf: define("object/set-prototype-of", ["es.object.set-prototype-of"]),
    values: define("object/values", ["es.object.values"])
  },
  Promise: {
    all: define(null, PromiseDependenciesWithIterators),
    allSettled: define(null, ["es.promise.all-settled", ...PromiseDependenciesWithIterators]),
    any: define(null, ["esnext.promise.any", ...PromiseDependenciesWithIterators]),
    race: define(null, PromiseDependenciesWithIterators),
    try: define(null, ["esnext.promise.try", ...PromiseDependenciesWithIterators])
  },
  Reflect: {
    apply: define("reflect/apply", ["es.reflect.apply"]),
    construct: define("reflect/construct", ["es.reflect.construct"]),
    defineMetadata: define("reflect/define-metadata", ["esnext.reflect.define-metadata"]),
    defineProperty: define("reflect/define-property", ["es.reflect.define-property"]),
    deleteMetadata: define("reflect/delete-metadata", ["esnext.reflect.delete-metadata"]),
    deleteProperty: define("reflect/delete-property", ["es.reflect.delete-property"]),
    get: define("reflect/get", ["es.reflect.get"]),
    getMetadata: define("reflect/get-metadata", ["esnext.reflect.get-metadata"]),
    getMetadataKeys: define("reflect/get-metadata-keys", ["esnext.reflect.get-metadata-keys"]),
    getOwnMetadata: define("reflect/get-own-metadata", ["esnext.reflect.get-own-metadata"]),
    getOwnMetadataKeys: define("reflect/get-own-metadata-keys", ["esnext.reflect.get-own-metadata-keys"]),
    getOwnPropertyDescriptor: define("reflect/get-own-property-descriptor", ["es.reflect.get-own-property-descriptor"]),
    getPrototypeOf: define("reflect/get-prototype-of", ["es.reflect.get-prototype-of"]),
    has: define("reflect/has", ["es.reflect.has"]),
    hasMetadata: define("reflect/has-metadata", ["esnext.reflect.has-metadata"]),
    hasOwnMetadata: define("reflect/has-own-metadata", ["esnext.reflect.has-own-metadata"]),
    isExtensible: define("reflect/is-extensible", ["es.reflect.is-extensible"]),
    metadata: define("reflect/metadata", ["esnext.reflect.metadata"]),
    ownKeys: define("reflect/own-keys", ["es.reflect.own-keys"]),
    preventExtensions: define("reflect/prevent-extensions", ["es.reflect.prevent-extensions"]),
    set: define("reflect/set", ["es.reflect.set"]),
    setPrototypeOf: define("reflect/set-prototype-of", ["es.reflect.set-prototype-of"])
  },
  Set: {
    from: define(null, ["esnext.set.from", ...SetDependencies]),
    of: define(null, ["esnext.set.of", ...SetDependencies])
  },
  String: {
    fromCodePoint: define("string/from-code-point", ["es.string.from-code-point"]),
    raw: define("string/raw", ["es.string.raw"])
  },
  Symbol: {
    asyncIterator: define("symbol/async-iterator", ["es.symbol.async-iterator"]),
    dispose: define("symbol/dispose", ["esnext.symbol.dispose"]),
    for: define("symbol/for", [], "es.symbol"),
    hasInstance: define("symbol/has-instance", ["es.symbol.has-instance", "es.function.has-instance"]),
    isConcatSpreadable: define("symbol/is-concat-spreadable", ["es.symbol.is-concat-spreadable", "es.array.concat"]),
    iterator: define("symbol/iterator", ["es.symbol.iterator", ...CommonIteratorsWithTag]),
    keyFor: define("symbol/key-for", [], "es.symbol"),
    match: define("symbol/match", ["es.symbol.match", "es.string.match"]),
    observable: define("symbol/observable", ["esnext.symbol.observable"]),
    patternMatch: define("symbol/pattern-match", ["esnext.symbol.pattern-match"]),
    replace: define("symbol/replace", ["es.symbol.replace", "es.string.replace"]),
    search: define("symbol/search", ["es.symbol.search", "es.string.search"]),
    species: define("symbol/species", ["es.symbol.species", "es.array.species"]),
    split: define("symbol/split", ["es.symbol.split", "es.string.split"]),
    toPrimitive: define("symbol/to-primitive", ["es.symbol.to-primitive", "es.date.to-primitive"]),
    toStringTag: define("symbol/to-string-tag", ["es.symbol.to-string-tag", "es.object.to-string", "es.math.to-string-tag", "es.json.to-string-tag"]),
    unscopables: define("symbol/unscopables", ["es.symbol.unscopables"])
  },
  WeakMap: {
    from: define(null, ["esnext.weak-map.from", ...WeakMapDependencies]),
    of: define(null, ["esnext.weak-map.of", ...WeakMapDependencies])
  },
  WeakSet: {
    from: define(null, ["esnext.weak-set.from", ...WeakSetDependencies]),
    of: define(null, ["esnext.weak-set.of", ...WeakSetDependencies])
  },
  Int8Array: TypedArrayStaticMethods,
  Uint8Array: TypedArrayStaticMethods,
  Uint8ClampedArray: TypedArrayStaticMethods,
  Int16Array: TypedArrayStaticMethods,
  Uint16Array: TypedArrayStaticMethods,
  Int32Array: TypedArrayStaticMethods,
  Uint32Array: TypedArrayStaticMethods,
  Float32Array: TypedArrayStaticMethods,
  Float64Array: TypedArrayStaticMethods
};
const InstanceProperties = {
  at: define("instance/at", ["esnext.string.at"]),
  anchor: define(null, ["es.string.anchor"]),
  big: define(null, ["es.string.big"]),
  bind: define("instance/bind", ["es.function.bind"]),
  blink: define(null, ["es.string.blink"]),
  bold: define(null, ["es.string.bold"]),
  codePointAt: define("instance/code-point-at", ["es.string.code-point-at"]),
  codePoints: define("instance/code-points", ["esnext.string.code-points"]),
  concat: define("instance/concat", ["es.array.concat"], undefined, ["String"]),
  copyWithin: define("instance/copy-within", ["es.array.copy-within"]),
  description: define(null, ["es.symbol", "es.symbol.description"]),
  endsWith: define("instance/ends-with", ["es.string.ends-with"]),
  entries: define("instance/entries", ArrayNatureIteratorsWithTag),
  every: define("instance/every", ["es.array.every"]),
  exec: define(null, ["es.regexp.exec"]),
  fill: define("instance/fill", ["es.array.fill"]),
  filter: define("instance/filter", ["es.array.filter"]),
  finally: define(null, ["es.promise.finally", ...PromiseDependencies]),
  find: define("instance/find", ["es.array.find"]),
  findIndex: define("instance/find-index", ["es.array.find-index"]),
  fixed: define(null, ["es.string.fixed"]),
  flags: define("instance/flags", ["es.regexp.flags"]),
  flatMap: define("instance/flat-map", ["es.array.flat-map", "es.array.unscopables.flat-map"]),
  flat: define("instance/flat", ["es.array.flat"]),
  fontcolor: define(null, ["es.string.fontcolor"]),
  fontsize: define(null, ["es.string.fontsize"]),
  forEach: define("instance/for-each", ["es.array.for-each", "web.dom-collections.for-each"]),
  includes: define("instance/includes", ["es.array.includes", "es.string.includes"]),
  indexOf: define("instance/index-of", ["es.array.index-of"]),
  italic: define(null, ["es.string.italics"]),
  join: define(null, ["es.array.join"]),
  keys: define("instance/keys", ArrayNatureIteratorsWithTag),
  lastIndex: define(null, ["esnext.array.last-index"]),
  lastIndexOf: define("instance/last-index-of", ["es.array.last-index-of"]),
  lastItem: define(null, ["esnext.array.last-item"]),
  link: define(null, ["es.string.link"]),
  map: define("instance/map", ["es.array.map"]),
  match: define(null, ["es.string.match", "es.regexp.exec"]),
  matchAll: define("instance/match-all", ["es.string.match-all"]),
  name: define(null, ["es.function.name"]),
  padEnd: define("instance/pad-end", ["es.string.pad-end"]),
  padStart: define("instance/pad-start", ["es.string.pad-start"]),
  reduce: define("instance/reduce", ["es.array.reduce"]),
  reduceRight: define("instance/reduce-right", ["es.array.reduce-right"]),
  repeat: define("instance/repeat", ["es.string.repeat"]),
  replace: define(null, ["es.string.replace", "es.regexp.exec"]),
  replaceAll: define("instance/replace-all", ["esnext.string.replace-all"]),
  reverse: define("instance/reverse", ["es.array.reverse"]),
  search: define(null, ["es.string.search", "es.regexp.exec"]),
  slice: define("instance/slice", ["es.array.slice"]),
  small: define(null, ["es.string.small"]),
  some: define("instance/some", ["es.array.some"]),
  sort: define("instance/sort", ["es.array.sort"]),
  splice: define("instance/splice", ["es.array.splice"]),
  split: define(null, ["es.string.split", "es.regexp.exec"]),
  startsWith: define("instance/starts-with", ["es.string.starts-with"]),
  strike: define(null, ["es.string.strike"]),
  sub: define(null, ["es.string.sub"]),
  sup: define(null, ["es.string.sup"]),
  toFixed: define(null, ["es.number.to-fixed"]),
  toISOString: define(null, ["es.date.to-iso-string"]),
  toJSON: define(null, ["es.date.to-json", "web.url.to-json"]),
  toPrecision: define(null, ["es.number.to-precision"]),
  toString: define(null, ["es.object.to-string", "es.regexp.to-string", "es.date.to-string"]),
  trim: define("instance/trim", ["es.string.trim"]),
  trimEnd: define("instance/trim-end", ["es.string.trim-end"]),
  trimLeft: define("instance/trim-left", ["es.string.trim-start"]),
  trimRight: define("instance/trim-right", ["es.string.trim-end"]),
  trimStart: define("instance/trim-start", ["es.string.trim-start"]),
  values: define("instance/values", ArrayNatureIteratorsWithTag),
  __defineGetter__: define(null, ["es.object.define-getter"]),
  __defineSetter__: define(null, ["es.object.define-setter"]),
  __lookupGetter__: define(null, ["es.object.lookup-getter"]),
  __lookupSetter__: define(null, ["es.object.lookup-setter"])
};
const CommonInstanceDependencies = new Set(["es.object.to-string", "es.object.define-getter", "es.object.define-setter", "es.object.lookup-getter", "es.object.lookup-setter", "es.regexp.exec"]);

const {
  types: t$1
} = babel.default || babel;
function callMethod(path, id) {
  const {
    object
  } = path.node;
  let context1, context2;

  if (t$1.isIdentifier(object)) {
    context1 = object;
    context2 = t$1.cloneNode(object);
  } else {
    context1 = path.scope.generateDeclaredUidIdentifier("context");
    context2 = t$1.assignmentExpression("=", t$1.cloneNode(context1), object);
  }

  path.replaceWith(t$1.memberExpression(t$1.callExpression(id, [context2]), t$1.identifier("call")));
  path.parentPath.unshiftContainer("arguments", context1);
}
function isCoreJSSource(source) {
  if (typeof source === "string") {
    source = source.replace(/\\/g, "/").replace(/(\/(index)?)?(\.js)?$/i, "").toLowerCase();
  }

  return hasOwnProperty.call(corejsEntries, source) && corejsEntries[source];
}
function coreJSModule(name) {
  return `core-js/modules/${name}.js`;
}
function coreJSPureHelper(name, useBabelRuntime, ext) {
  return useBabelRuntime ? `${useBabelRuntime}/core-js/${name}${ext}` : `core-js-pure/features/${name}.js`;
}

const {
  types: t
} = babel.default || babel;
const runtimeCompat = "#__secret_key__@babel/runtime__compatibility";

const esnextFallback = (name, cb) => {
  if (cb(name)) return true;
  if (!name.startsWith("es.")) return false;
  const fallback = `esnext.${name.slice(3)}`;
  if (!corejs3Polyfills[fallback]) return false;
  return cb(fallback);
};

var index = defineProvider(function ({
  getUtils,
  method,
  shouldInjectPolyfill,
  createMetaResolver,
  debug,
  babel
}, {
  version = 3,
  proposals,
  shippedProposals,
  [runtimeCompat]: {
    useBabelRuntime,
    ext = ".js"
  } = {}
}) {
  const isWebpack = babel.caller(caller => caller?.name === "babel-loader");
  const resolve = createMetaResolver({
    global: BuiltIns,
    static: StaticProperties,
    instance: InstanceProperties
  });
  const available = new Set(getModulesListForTargetVersion(version));
  const coreJSPureBase = useBabelRuntime ? proposals ? `${useBabelRuntime}/core-js` : `${useBabelRuntime}/core-js-stable` : proposals ? "core-js-pure/features" : "core-js-pure/stable";

  function maybeInjectGlobalImpl(name, utils) {
    if (shouldInjectPolyfill(name)) {
      debug(name);
      utils.injectGlobalImport(coreJSModule(name));
      return true;
    }

    return false;
  }

  function maybeInjectGlobal(names, utils, fallback = true) {
    for (const name of names) {
      if (fallback) {
        esnextFallback(name, name => maybeInjectGlobalImpl(name, utils));
      } else {
        maybeInjectGlobalImpl(name, utils);
      }
    }
  }

  function maybeInjectPure(desc, hint, utils, object) {
    if (desc.pure && !(object && desc.exclude && desc.exclude.includes(object)) && esnextFallback(desc.name, shouldInjectPolyfill)) {
      return utils.injectDefaultImport(`${coreJSPureBase}/${desc.pure}${ext}`, hint);
    }
  }

  return {
    name: "corejs3",
    polyfills: corejs3Polyfills,

    filterPolyfills(name) {
      if (!available.has(name)) return false;
      if (proposals || method === "entry-global") return true;

      if (shippedProposals && corejs3ShippedProposalsList.has(name)) {
        return true;
      }

      return !name.startsWith("esnext.");
    },

    entryGlobal(meta, utils, path) {
      if (meta.kind !== "import") return;
      const modules = isCoreJSSource(meta.source);
      if (!modules) return;

      if (modules.length === 1 && meta.source === coreJSModule(modules[0]) && shouldInjectPolyfill(modules[0])) {
        // Avoid infinite loop: do not replace imports with a new copy of
        // themselves.
        debug(null);
        return;
      }

      maybeInjectGlobal(modules, utils, false);
      path.remove();
    },

    usageGlobal(meta, utils) {
      const resolved = resolve(meta);
      if (!resolved) return;
      let deps = resolved.desc.global;

      if (resolved.kind !== "global" && meta.object && meta.placement === "prototype") {
        const low = meta.object.toLowerCase();
        deps = deps.filter(m => m.includes(low) || CommonInstanceDependencies.has(m));
      }

      maybeInjectGlobal(deps, utils);
    },

    usagePure(meta, utils, path) {
      if (meta.kind === "in") {
        if (meta.key === "Symbol.iterator") {
          path.replaceWith(t.callExpression(utils.injectDefaultImport(coreJSPureHelper("is-iterable", useBabelRuntime, ext), "isIterable"), [path.node.right]));
        }

        return;
      }

      if (path.parentPath.isUnaryExpression({
        operator: "delete"
      })) return;
      let isCall;

      if (meta.kind === "property") {
        // We can't compile destructuring.
        if (!path.isMemberExpression()) return;
        if (!path.isReferenced()) return;
        isCall = path.parentPath.isCallExpression({
          callee: path.node
        });

        if (meta.key === "Symbol.iterator") {
          if (!shouldInjectPolyfill("es.symbol.iterator")) return;

          if (isCall) {
            if (path.parent.arguments.length === 0) {
              path.parentPath.replaceWith(t.callExpression(utils.injectDefaultImport(coreJSPureHelper("get-iterator", useBabelRuntime, ext), "getIterator"), [path.node.object]));
              path.skip();
            } else {
              callMethod(path, utils.injectDefaultImport(coreJSPureHelper("get-iterator-method", useBabelRuntime, ext), "getIteratorMethod"));
            }
          } else {
            path.replaceWith(t.callExpression(utils.injectDefaultImport(coreJSPureHelper("get-iterator-method", useBabelRuntime, ext), "getIteratorMethod"), [path.node.object]));
          }

          return;
        }
      }

      let resolved = resolve(meta);
      if (!resolved) return;

      if (useBabelRuntime && resolved.desc.pure && resolved.desc.pure.slice(-6) === "/index") {
        // Remove /index, since it doesn't exist in @babel/runtime-corejs3s
        resolved = { ...resolved,
          desc: { ...resolved.desc,
            pure: resolved.desc.pure.slice(0, -6)
          }
        };
      }

      if (resolved.kind === "global") {
        const id = maybeInjectPure(resolved.desc, resolved.name, utils);
        if (id) path.replaceWith(id);
      } else if (resolved.kind === "static") {
        const id = maybeInjectPure(resolved.desc, resolved.name, utils, // $FlowIgnore
        meta.object);
        if (id) path.replaceWith(id);
      } else if (resolved.kind === "instance") {
        const id = maybeInjectPure(resolved.desc, `${resolved.name}InstanceProperty`, utils, // $FlowIgnore
        meta.object);
        if (!id) return;

        if (isCall) {
          callMethod(path, id);
        } else {
          path.replaceWith(t.callExpression(id, [path.node.object]));
        }
      }
    },

    visitor: method === "usage-global" && {
      // import("foo")
      CallExpression(path) {
        if (path.get("callee").isImport()) {
          const utils = getUtils(path);

          if (isWebpack) {
            // Webpack uses Promise.all to handle dynamic import.
            maybeInjectGlobal(PromiseDependenciesWithIterators, utils);
          } else {
            maybeInjectGlobal(PromiseDependencies, utils);
          }
        }
      },

      // (async function () { }).finally(...)
      Function(path) {
        if (path.node.async) {
          maybeInjectGlobal(PromiseDependencies, getUtils(path));
        }
      },

      // for-of, [a, b] = c
      "ForOfStatement|ArrayPattern"(path) {
        maybeInjectGlobal(CommonIterators, getUtils(path));
      },

      // [...spread]
      SpreadElement(path) {
        if (!path.parentPath.isObjectExpression()) {
          maybeInjectGlobal(CommonIterators, getUtils(path));
        }
      },

      // yield*
      YieldExpression(path) {
        if (path.node.delegate) {
          maybeInjectGlobal(CommonIterators, getUtils(path));
        }
      }

    }
  };
});

export default index;
//# sourceMappingURL=index.mjs.map
