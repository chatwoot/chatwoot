'use strict';

// packages/utils/src/index.ts
var isBrowser = typeof window !== "undefined";
var explicitKeys = [
  "__key",
  "__init",
  "__shim",
  "__original",
  "__index",
  "__prevKey"
];
function token() {
  return Math.random().toString(36).substring(2, 15);
}
function setify(items) {
  return items instanceof Set ? items : new Set(items);
}
function dedupe(arr1, arr2) {
  const original = arr1 instanceof Set ? arr1 : new Set(arr1);
  if (arr2)
    arr2.forEach((item) => original.add(item));
  return [...original];
}
function has(obj, property) {
  return Object.prototype.hasOwnProperty.call(obj, property);
}
function eq(valA, valB, deep = true, explicit = ["__key"]) {
  if (valA === valB)
    return true;
  if (typeof valB === "object" && typeof valA === "object") {
    if (valA instanceof Map)
      return false;
    if (valA instanceof Set)
      return false;
    if (valA instanceof Date && valB instanceof Date)
      return valA.getTime() === valB.getTime();
    if (valA instanceof RegExp && valB instanceof RegExp)
      return eqRegExp(valA, valB);
    if (valA === null || valB === null)
      return false;
    if (Object.keys(valA).length !== Object.keys(valB).length)
      return false;
    for (const k of explicit) {
      if ((k in valA || k in valB) && valA[k] !== valB[k])
        return false;
    }
    for (const key in valA) {
      if (!(key in valB))
        return false;
      if (valA[key] !== valB[key] && !deep)
        return false;
      if (deep && !eq(valA[key], valB[key], deep, explicit))
        return false;
    }
    return true;
  }
  return false;
}
function eqRegExp(x, y) {
  return x.source === y.source && x.flags.split("").sort().join("") === y.flags.split("").sort().join("");
}
function empty(value) {
  const type = typeof value;
  if (type === "number")
    return false;
  if (value === void 0)
    return true;
  if (type === "string") {
    return value === "";
  }
  if (type === "object") {
    if (value === null)
      return true;
    for (const _i in value)
      return false;
    if (value instanceof RegExp)
      return false;
    if (value instanceof Date)
      return false;
    return true;
  }
  return false;
}
function escapeExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
function regexForFormat(format) {
  const escaped = `^${escapeExp(format)}$`;
  const formats = {
    MM: "(0[1-9]|1[012])",
    M: "([1-9]|1[012])",
    DD: "([012][0-9]|3[01])",
    D: "([012]?[0-9]|3[01])",
    YYYY: "\\d{4}",
    YY: "\\d{2}"
  };
  const tokens = Object.keys(formats);
  return new RegExp(
    tokens.reduce((regex, format2) => {
      return regex.replace(format2, formats[format2]);
    }, escaped)
  );
}
function nodeType(type) {
  const t = type.toLowerCase();
  if (t === "list")
    return "list";
  if (t === "group")
    return "group";
  return "input";
}
function isRecord(o) {
  return Object.prototype.toString.call(o) === "[object Object]";
}
function isObject(o) {
  return isRecord(o) || Array.isArray(o);
}
function isPojo(o) {
  if (isRecord(o) === false)
    return false;
  if (o.__FKNode__ || o.__POJO__ === false)
    return false;
  const ctor = o.constructor;
  if (ctor === void 0)
    return true;
  const prot = ctor.prototype;
  if (isRecord(prot) === false)
    return false;
  if (prot.hasOwnProperty("isPrototypeOf") === false) {
    return false;
  }
  return true;
}
var extend = /* @__NO_SIDE_EFFECTS__ */ (original, additional, extendArrays = false, ignoreUndefined = false) => {
  if (additional === null)
    return null;
  const merged = {};
  if (typeof additional === "string")
    return additional;
  for (const key in original) {
    if (has(additional, key) && (additional[key] !== void 0 || !ignoreUndefined)) {
      if (extendArrays && Array.isArray(original[key]) && Array.isArray(additional[key])) {
        merged[key] = original[key].concat(additional[key]);
        continue;
      }
      if (additional[key] === void 0) {
        continue;
      }
      if (isPojo(original[key]) && isPojo(additional[key])) {
        merged[key] = /* @__PURE__ */ extend(
          original[key],
          additional[key],
          extendArrays,
          ignoreUndefined
        );
      } else {
        merged[key] = additional[key];
      }
    } else {
      merged[key] = original[key];
    }
  }
  for (const key in additional) {
    if (!has(merged, key) && additional[key] !== void 0) {
      merged[key] = additional[key];
    }
  }
  return merged;
};
function isQuotedString(str) {
  if (str[0] !== '"' && str[0] !== "'")
    return false;
  if (str[0] !== str[str.length - 1])
    return false;
  const quoteType = str[0];
  for (let p = 1; p < str.length; p++) {
    if (str[p] === quoteType && (p === 1 || str[p - 1] !== "\\") && p !== str.length - 1) {
      return false;
    }
  }
  return true;
}
function rmEscapes(str) {
  if (!str.length)
    return "";
  let clean = "";
  let lastChar = "";
  for (let p = 0; p < str.length; p++) {
    const char = str.charAt(p);
    if (char !== "\\" || lastChar === "\\") {
      clean += char;
    }
    lastChar = char;
  }
  return clean;
}
function assignDeep(a, b) {
  for (const key in a) {
    if (has(b, key) && a[key] !== b[key] && !(isPojo(a[key]) && isPojo(b[key]))) {
      a[key] = b[key];
    } else if (isPojo(a[key]) && isPojo(b[key])) {
      assignDeep(a[key], b[key]);
    }
  }
  for (const key in b) {
    if (!has(a, key)) {
      a[key] = b[key];
    }
  }
  return a;
}
function nodeProps(...sets) {
  return sets.reduce((valid, props) => {
    const { value, name, modelValue, config, plugins, ...validProps } = props;
    return Object.assign(valid, validProps);
  }, {});
}
function parseArgs(str) {
  const args = [];
  let arg = "";
  let depth = 0;
  let quote = "";
  let lastChar = "";
  for (let p = 0; p < str.length; p++) {
    const char = str.charAt(p);
    if (char === quote && lastChar !== "\\") {
      quote = "";
    } else if ((char === "'" || char === '"') && !quote && lastChar !== "\\") {
      quote = char;
    } else if (char === "(" && !quote) {
      depth++;
    } else if (char === ")" && !quote) {
      depth--;
    }
    if (char === "," && !quote && depth === 0) {
      args.push(arg);
      arg = "";
    } else if (char !== " " || quote) {
      arg += char;
    }
    lastChar = char;
  }
  if (arg) {
    args.push(arg);
  }
  return args;
}
function except(obj, toRemove) {
  const clean = {};
  const exps = toRemove.filter((n) => n instanceof RegExp);
  const keysToRemove = new Set(toRemove);
  for (const key in obj) {
    if (!keysToRemove.has(key) && !exps.some((exp) => exp.test(key))) {
      clean[key] = obj[key];
    }
  }
  return clean;
}
function only(obj, include) {
  const clean = {};
  const exps = include.filter((n) => n instanceof RegExp);
  include.forEach((key) => {
    if (!(key instanceof RegExp)) {
      clean[key] = obj[key];
    }
  });
  Object.keys(obj).forEach((key) => {
    if (exps.some((exp) => exp.test(key))) {
      clean[key] = obj[key];
    }
  });
  return clean;
}
function camel(str) {
  return str.replace(
    /-([a-z0-9])/gi,
    (_s, g) => g.toUpperCase()
  );
}
function kebab(str) {
  return str.replace(
    /([a-z0-9])([A-Z])/g,
    (_s, trail, cap) => trail + "-" + cap.toLowerCase()
  ).replace(" ", "-").toLowerCase();
}
function shallowClone(obj, explicit = explicitKeys) {
  if (obj !== null && typeof obj === "object") {
    let returnObject;
    if (Array.isArray(obj))
      returnObject = [...obj];
    else if (isPojo(obj))
      returnObject = { ...obj };
    if (returnObject) {
      applyExplicit(obj, returnObject, explicit);
      return returnObject;
    }
  }
  return obj;
}
function clone(obj, explicit = explicitKeys) {
  if (obj === null || obj instanceof RegExp || obj instanceof Date || obj instanceof Map || obj instanceof Set || typeof File === "function" && obj instanceof File)
    return obj;
  let returnObject;
  if (Array.isArray(obj)) {
    returnObject = obj.map((value) => {
      if (typeof value === "object")
        return clone(value, explicit);
      return value;
    });
  } else {
    returnObject = Object.keys(obj).reduce((newObj, key) => {
      newObj[key] = typeof obj[key] === "object" ? clone(obj[key], explicit) : obj[key];
      return newObj;
    }, {});
  }
  for (const key of explicit) {
    if (key in obj) {
      Object.defineProperty(returnObject, key, {
        enumerable: false,
        value: obj[key]
      });
    }
  }
  return returnObject;
}
function cloneAny(obj) {
  return typeof obj === "object" ? clone(obj) : obj;
}
function getAt(obj, addr) {
  if (!obj || typeof obj !== "object")
    return null;
  const segments = addr.split(".");
  let o = obj;
  for (const i in segments) {
    const segment = segments[i];
    if (has(o, segment)) {
      o = o[segment];
    }
    if (+i === segments.length - 1)
      return o;
    if (!o || typeof o !== "object")
      return null;
  }
  return null;
}
function undefine(value) {
  return value !== void 0 && value !== "false" && value !== false ? true : void 0;
}
function init(obj) {
  return !Object.isFrozen(obj) ? Object.defineProperty(obj, "__init", {
    enumerable: false,
    value: true
  }) : obj;
}
function slugify(str) {
  return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]/g, " ").trim().replace(/\s+/g, "-");
}
function spread(obj, explicit = explicitKeys) {
  if (obj && typeof obj === "object") {
    if (obj instanceof RegExp)
      return obj;
    if (obj instanceof Date)
      return obj;
    let spread2;
    if (Array.isArray(obj)) {
      spread2 = [...obj];
    } else {
      spread2 = { ...obj };
    }
    return applyExplicit(
      obj,
      spread2,
      explicit
    );
  }
  return obj;
}
function applyExplicit(original, obj, explicit) {
  for (const key of explicit) {
    if (key in original) {
      Object.defineProperty(obj, key, {
        enumerable: false,
        value: original[key]
      });
    }
  }
  return obj;
}
function whenAvailable(childId, callback, root) {
  if (!isBrowser)
    return;
  if (!root)
    root = document;
  const el = root.getElementById(childId);
  if (el)
    return callback(el);
  const observer = new MutationObserver(() => {
    const el2 = root?.getElementById(childId);
    if (el2) {
      observer?.disconnect();
      callback(el2);
    }
  });
  observer.observe(root, { childList: true, subtree: true });
}
function oncePerTick(fn) {
  let called = false;
  return (...args) => {
    if (called)
      return;
    called = true;
    queueMicrotask(() => called = false);
    return fn(...args);
  };
}
function boolGetter(value) {
  if (value === "false" || value === false)
    return void 0;
  return true;
}

exports.assignDeep = assignDeep;
exports.boolGetter = boolGetter;
exports.camel = camel;
exports.clone = clone;
exports.cloneAny = cloneAny;
exports.dedupe = dedupe;
exports.empty = empty;
exports.eq = eq;
exports.eqRegExp = eqRegExp;
exports.escapeExp = escapeExp;
exports.except = except;
exports.extend = extend;
exports.getAt = getAt;
exports.has = has;
exports.init = init;
exports.isObject = isObject;
exports.isPojo = isPojo;
exports.isQuotedString = isQuotedString;
exports.isRecord = isRecord;
exports.kebab = kebab;
exports.nodeProps = nodeProps;
exports.nodeType = nodeType;
exports.oncePerTick = oncePerTick;
exports.only = only;
exports.parseArgs = parseArgs;
exports.regexForFormat = regexForFormat;
exports.rmEscapes = rmEscapes;
exports.setify = setify;
exports.shallowClone = shallowClone;
exports.slugify = slugify;
exports.spread = spread;
exports.token = token;
exports.undefine = undefine;
exports.whenAvailable = whenAvailable;
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.cjs.map