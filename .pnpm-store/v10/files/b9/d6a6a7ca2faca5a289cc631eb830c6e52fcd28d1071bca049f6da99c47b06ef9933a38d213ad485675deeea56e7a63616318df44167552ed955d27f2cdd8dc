import { has, regexForFormat, eq, empty } from '@formkit/utils';

// packages/rules/src/accepted.ts
var accepted = function accepted2({ value }) {
  return ["yes", "on", "1", 1, true, "true"].includes(value);
};
accepted.skipEmpty = false;
var accepted_default = accepted;

// packages/rules/src/date_after.ts
var date_after = function({ value }, compare = false) {
  const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
  const fieldValue = Date.parse(String(value));
  return isNaN(fieldValue) ? false : fieldValue > timestamp;
};
var date_after_default = date_after;

// packages/rules/src/date_after_or_equal.ts
var date_after_or_equal = function({ value }, compare = false) {
  const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
  const fieldValue = Date.parse(String(value));
  return isNaN(fieldValue) ? false : fieldValue > timestamp || fieldValue === timestamp;
};
var date_after_or_equal_default = date_after_or_equal;

// packages/rules/src/date_after_node.ts
var date_after_node = function(node, address) {
  if (!address)
    return false;
  const fieldValue = Date.parse(String(node.value));
  const foreignValue = Date.parse(String(node.at(address)?.value));
  if (isNaN(foreignValue))
    return true;
  return isNaN(fieldValue) ? false : fieldValue > foreignValue;
};
var date_after_node_default = date_after_node;
var alpha = function({ value }, set = "default") {
  const sets = {
    default: /^\p{L}+$/u,
    latin: /^[a-z]+$/i
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var alpha_default = alpha;
var alpha_spaces = function({ value }, set = "default") {
  const sets = {
    default: /^[\p{L} ]+$/u,
    latin: /^[a-z ]+$/i
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var alpha_spaces_default = alpha_spaces;
var alphanumeric = function({ value }, set = "default") {
  const sets = {
    default: /^[0-9\p{L}]+$/u,
    latin: /^[0-9a-z]+$/i
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var alphanumeric_default = alphanumeric;

// packages/rules/src/date_before.ts
var date_before = function({ value }, compare = false) {
  const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
  const fieldValue = Date.parse(String(value));
  return isNaN(fieldValue) ? false : fieldValue < timestamp;
};
var date_before_default = date_before;

// packages/rules/src/date_before_node.ts
var date_before_node = function(node, address) {
  if (!address)
    return false;
  const fieldValue = Date.parse(String(node.value));
  const foreignValue = Date.parse(String(node.at(address)?.value));
  if (isNaN(foreignValue))
    return true;
  return isNaN(fieldValue) ? false : fieldValue < foreignValue;
};
var date_before_node_default = date_before_node;

// packages/rules/src/date_before_or_equal.ts
var date_before_or_equal = function({ value }, compare = false) {
  const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
  const fieldValue = Date.parse(String(value));
  return isNaN(fieldValue) ? false : fieldValue < timestamp || fieldValue === timestamp;
};
var date_before_or_equal_default = date_before_or_equal;

// packages/rules/src/between.ts
var between = function between2({ value }, from, to) {
  if (!isNaN(value) && !isNaN(from) && !isNaN(to)) {
    const val = 1 * value;
    from = Number(from);
    to = Number(to);
    const [a, b] = from <= to ? [from, to] : [to, from];
    return val >= 1 * a && val <= 1 * b;
  }
  return false;
};
var between_default = between;

// packages/rules/src/confirm.ts
var hasConfirm = /(_confirm(?:ed)?)$/;
var confirm = function confirm2(node, address, comparison = "loose") {
  if (!address) {
    address = hasConfirm.test(node.name) ? node.name.replace(hasConfirm, "") : `${node.name}_confirm`;
  }
  const foreignValue = node.at(address)?.value;
  return comparison === "strict" ? node.value === foreignValue : node.value == foreignValue;
};
var confirm_default = confirm;
var contains_alpha = function({ value }, set = "default") {
  const sets = {
    default: /\p{L}/u,
    latin: /[a-z]/i
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var contains_alpha_default = contains_alpha;
var contains_alpha_spaces = function({ value }, set = "default") {
  const sets = {
    default: /[\p{L} ]/u,
    latin: /[a-z ]/i
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var contains_alpha_spaces_default = contains_alpha_spaces;
var contains_alphanumeric = function({ value }, set = "default") {
  const sets = {
    default: /[0-9\p{L}]/u,
    latin: /[0-9a-z]/i
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var contains_alphanumeric_default = contains_alphanumeric;
var contains_lowercase = function({ value }, set = "default") {
  const sets = {
    default: /\p{Ll}/u,
    latin: /[a-z]/
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var contains_lowercase_default = contains_lowercase;

// packages/rules/src/contains_numeric.ts
var contains_numeric = function number({ value }) {
  return /[0-9]/.test(String(value));
};
var contains_numeric_default = contains_numeric;

// packages/rules/src/contains_symbol.ts
var contains_symbol = function({ value }) {
  return /[!-/:-@[-`{-~]/.test(String(value));
};
var contains_symbol_default = contains_symbol;
var contains_uppercase = function({ value }, set = "default") {
  const sets = {
    default: /\p{Lu}/u,
    latin: /[A-Z]/
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var contains_uppercase_default = contains_uppercase;

// packages/rules/src/date_between.ts
var date_between = function date_between2({ value }, dateA, dateB) {
  dateA = dateA instanceof Date ? dateA.getTime() : Date.parse(dateA);
  dateB = dateB instanceof Date ? dateB.getTime() : Date.parse(dateB);
  const compareTo = value instanceof Date ? value.getTime() : Date.parse(String(value));
  if (dateA && !dateB) {
    dateB = dateA;
    dateA = Date.now();
  } else if (!dateA || !compareTo) {
    return false;
  }
  return compareTo >= dateA && compareTo <= dateB;
};
var date_between_default = date_between;
var date_format = function date({ value }, format) {
  if (format && typeof format === "string") {
    return regexForFormat(format).test(String(value));
  }
  return !isNaN(Date.parse(String(value)));
};
var date_format_default = date_format;

// packages/rules/src/email.ts
var email = function email2({ value }) {
  const isEmail = /^(([^<>()\[\]\.,;:\s@\"]+(\.[^<>()\[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
  return isEmail.test(String(value));
};
var email_default = email;

// packages/rules/src/ends_with.ts
var ends_with = function ends_with2({ value }, ...stack) {
  if (typeof value === "string" && stack.length) {
    return stack.some((item) => {
      return value.endsWith(item);
    });
  } else if (typeof value === "string" && stack.length === 0) {
    return true;
  }
  return false;
};
var ends_with_default = ends_with;
var is = function is2({ value }, ...stack) {
  return stack.some((item) => {
    if (typeof item === "object") {
      return eq(item, value);
    }
    return item == value;
  });
};
var is_default = is;

// packages/rules/src/length.ts
var length = function length2({ value }, first = 0, second = Infinity) {
  first = parseInt(first);
  second = isNaN(parseInt(second)) ? Infinity : parseInt(second);
  const min3 = first <= second ? first : second;
  const max3 = second >= first ? second : first;
  if (typeof value === "string" || Array.isArray(value)) {
    return value.length >= min3 && value.length <= max3;
  } else if (value && typeof value === "object") {
    const length3 = Object.keys(value).length;
    return length3 >= min3 && length3 <= max3;
  }
  return false;
};
var length_default = length;
var lowercase = function({ value }, set = "default") {
  const sets = {
    default: /^\p{Ll}+$/u,
    allow_non_alpha: /^[0-9\p{Ll}!-/:-@[-`{-~]+$/u,
    allow_numeric: /^[0-9\p{Ll}]+$/u,
    allow_numeric_dashes: /^[0-9\p{Ll}-]+$/u,
    latin: /^[a-z]+$/
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var lowercase_default = lowercase;

// packages/rules/src/matches.ts
var matches = function matches2({ value }, ...stack) {
  return stack.some((pattern) => {
    if (typeof pattern === "string" && pattern.substr(0, 1) === "/" && pattern.substr(-1) === "/") {
      pattern = new RegExp(pattern.substr(1, pattern.length - 2));
    }
    if (pattern instanceof RegExp) {
      return pattern.test(String(value));
    }
    return pattern === value;
  });
};
var matches_default = matches;

// packages/rules/src/max.ts
var max = function max2({ value }, maximum = 10) {
  if (Array.isArray(value)) {
    return value.length <= maximum;
  }
  return Number(value) <= Number(maximum);
};
var max_default = max;

// packages/rules/src/min.ts
var min = function min2({ value }, minimum = 1) {
  if (Array.isArray(value)) {
    return value.length >= minimum;
  }
  return Number(value) >= Number(minimum);
};
var min_default = min;
var not = function not2({ value }, ...stack) {
  return !stack.some((item) => {
    if (typeof item === "object") {
      return eq(item, value);
    }
    return item === value;
  });
};
var not_default = not;

// packages/rules/src/number.ts
var number2 = function number3({ value }) {
  return !isNaN(value);
};
var number_default = number2;
var require_one = function(node, ...inputNames) {
  if (!empty(node.value))
    return true;
  const values = inputNames.map((name) => node.at(name)?.value);
  return values.some((value) => !empty(value));
};
require_one.skipEmpty = false;
var require_one_default = require_one;
var required = function required2({ value }, action = "default") {
  return action === "trim" && typeof value === "string" ? !empty(value.trim()) : !empty(value);
};
required.skipEmpty = false;
var required_default = required;

// packages/rules/src/starts_with.ts
var starts_with = function starts_with2({ value }, ...stack) {
  if (typeof value === "string" && stack.length) {
    return stack.some((item) => {
      return value.startsWith(item);
    });
  } else if (typeof value === "string" && stack.length === 0) {
    return true;
  }
  return false;
};
var starts_with_default = starts_with;

// packages/rules/src/symbol.ts
var symbol = function({ value }) {
  return /^[!-/:-@[-`{-~]+$/.test(String(value));
};
var symbol_default = symbol;
var uppercase = function({ value }, set = "default") {
  const sets = {
    default: /^\p{Lu}+$/u,
    latin: /^[A-Z]+$/
  };
  const selectedSet = has(sets, set) ? set : "default";
  return sets[selectedSet].test(String(value));
};
var uppercase_default = uppercase;

// packages/rules/src/url.ts
var url = function url2({ value }, ...stack) {
  try {
    const protocols = stack.length ? stack : ["http:", "https:"];
    const url3 = new URL(String(value));
    return protocols.includes(url3.protocol);
  } catch {
    return false;
  }
};
var url_default = url;

export { accepted_default as accepted, alpha_default as alpha, alpha_spaces_default as alpha_spaces, alphanumeric_default as alphanumeric, between_default as between, confirm_default as confirm, contains_alpha_default as contains_alpha, contains_alpha_spaces_default as contains_alpha_spaces, contains_alphanumeric_default as contains_alphanumeric, contains_lowercase_default as contains_lowercase, contains_numeric_default as contains_numeric, contains_symbol_default as contains_symbol, contains_uppercase_default as contains_uppercase, date_after_default as date_after, date_after_node_default as date_after_node, date_after_or_equal_default as date_after_or_equal, date_before_default as date_before, date_before_node_default as date_before_node, date_before_or_equal_default as date_before_or_equal, date_between_default as date_between, date_format_default as date_format, email_default as email, ends_with_default as ends_with, is_default as is, length_default as length, lowercase_default as lowercase, matches_default as matches, max_default as max, min_default as min, not_default as not, number_default as number, require_one_default as require_one, required_default as required, starts_with_default as starts_with, symbol_default as symbol, uppercase_default as uppercase, url_default as url };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.mjs.map