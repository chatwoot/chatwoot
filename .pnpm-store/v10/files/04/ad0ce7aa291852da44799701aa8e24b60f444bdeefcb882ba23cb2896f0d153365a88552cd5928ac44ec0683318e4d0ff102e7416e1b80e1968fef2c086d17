import { extend, camel, has, slugify, undefine, eq, token, clone, isObject, isPojo } from '@formkit/utils';
import { createMessage, warn, isConditional, isComponent, isDOM } from '@formkit/core';

// packages/inputs/src/plugin.ts
function createLibraryPlugin(...libraries) {
  const library = libraries.reduce(
    (merged, lib) => extend(merged, lib),
    {}
  );
  const plugin = () => {
  };
  plugin.library = function(node) {
    const type = camel(node.props.type);
    if (has(library, type)) {
      node.define(library[type]);
    }
  };
  return plugin;
}

// packages/inputs/src/props.ts
var runtimeProps = [
  "classes",
  "config",
  "delay",
  "errors",
  "id",
  "index",
  "inputErrors",
  "library",
  "modelValue",
  "onUpdate:modelValue",
  "name",
  "number",
  "parent",
  "plugins",
  "sectionsSchema",
  "type",
  "validation",
  "validationLabel",
  "validationMessages",
  "validationRules",
  // Runtime event props:
  "onInput",
  "onInputRaw",
  "onUpdate:modelValue",
  "onNode",
  "onSubmit",
  "onSubmitInvalid",
  "onSubmitRaw"
];
function isGroupOption(option2) {
  return option2 && typeof option2 === "object" && "group" in option2 && Array.isArray(option2.options);
}
function normalizeOptions(options2, i = { count: 1 }) {
  if (Array.isArray(options2)) {
    return options2.map(
      (option2) => {
        if (typeof option2 === "string" || typeof option2 === "number") {
          return {
            label: String(option2),
            value: String(option2)
          };
        }
        if (typeof option2 == "object") {
          if ("group" in option2) {
            option2.options = normalizeOptions(option2.options || [], i);
            return option2;
          } else if ("value" in option2 && typeof option2.value !== "string") {
            Object.assign(option2, {
              value: `__mask_${i.count++}`,
              __original: option2.value
            });
          }
        }
        return option2;
      }
    );
  }
  return Object.keys(options2).map((value) => {
    return {
      label: options2[value],
      value
    };
  });
}
function optionValue(options2, value, undefinedIfNotFound = false) {
  if (Array.isArray(options2)) {
    for (const option2 of options2) {
      if (typeof option2 !== "object" && option2)
        continue;
      if (isGroupOption(option2)) {
        const found = optionValue(option2.options, value, true);
        if (found !== void 0) {
          return found;
        }
      } else if (value == option2.value) {
        return "__original" in option2 ? option2.__original : option2.value;
      }
    }
  }
  return undefinedIfNotFound ? void 0 : value;
}
function shouldSelect(valueA, valueB) {
  if (valueA === null && valueB === void 0 || valueA === void 0 && valueB === null)
    return false;
  if (valueA == valueB)
    return true;
  if (isPojo(valueA) && isPojo(valueB))
    return eq(valueA, valueB);
  return false;
}
function options(node) {
  node.hook.prop((prop, next) => {
    var _a;
    if (prop.prop === "options") {
      if (typeof prop.value === "function") {
        node.props.optionsLoader = prop.value;
        prop.value = [];
      } else {
        (_a = node.props)._normalizeCounter ?? (_a._normalizeCounter = { count: 1 });
        prop.value = normalizeOptions(prop.value, node.props._normalizeCounter);
      }
    }
    return next(prop);
  });
}
// @__NO_SIDE_EFFECTS__
function createSection(section, el, fragment2 = false) {
  return (...children) => {
    const extendable = (extensions) => {
      const node = !el || typeof el === "string" ? { $el: el } : el();
      if (isDOM(node) || isComponent(node)) {
        if (!node.meta) {
          node.meta = { section };
        } else {
          node.meta.section = section;
        }
        if (children.length && !node.children) {
          node.children = [
            ...children.map(
              (child) => typeof child === "function" ? child(extensions) : child
            )
          ];
        }
        if (isDOM(node)) {
          node.attrs = {
            class: `$classes.${section}`,
            ...node.attrs || {}
          };
        }
      }
      return {
        if: `$slots.${section}`,
        then: `$slots.${section}`,
        else: section in extensions ? /* @__PURE__ */ extendSchema(node, extensions[section]) : node
      };
    };
    extendable._s = section;
    return fragment2 ? /* @__PURE__ */ createRoot(extendable) : extendable;
  };
}
// @__NO_SIDE_EFFECTS__
function createRoot(rootSection) {
  return (extensions) => {
    return [rootSection(extensions)];
  };
}
function isSchemaObject(schema) {
  return !!(schema && typeof schema === "object" && ("$el" in schema || "$cmp" in schema || "$formkit" in schema));
}
// @__NO_SIDE_EFFECTS__
function extendSchema(schema, extension = {}) {
  if (typeof schema === "string") {
    return isSchemaObject(extension) || typeof extension === "string" ? extension : schema;
  } else if (Array.isArray(schema)) {
    return isSchemaObject(extension) ? extension : schema;
  }
  return extend(schema, extension);
}

// packages/inputs/src/sections/actions.ts
var actions = createSection("actions", () => ({
  $el: "div",
  if: "$actions"
}));

// packages/inputs/src/sections/box.ts
var box = createSection("input", () => ({
  $el: "input",
  bind: "$attrs",
  attrs: {
    type: "$type",
    name: "$node.props.altName || $node.name",
    disabled: "$option.attrs.disabled || $disabled",
    onInput: "$handlers.toggleChecked",
    checked: "$fns.eq($_value, $onValue)",
    onBlur: "$handlers.blur",
    value: "$: true",
    id: "$id",
    "aria-describedby": {
      if: "$options.length",
      then: {
        if: "$option.help",
        then: '$: "help-" + $option.attrs.id',
        else: void 0
      },
      else: {
        if: "$help",
        then: '$: "help-" + $id',
        else: void 0
      }
    }
  }
}));

// packages/inputs/src/sections/boxHelp.ts
var boxHelp = createSection("optionHelp", () => ({
  $el: "div",
  if: "$option.help",
  attrs: {
    id: '$: "help-" + $option.attrs.id'
  }
}));

// packages/inputs/src/sections/boxInner.ts
var boxInner = createSection("inner", "span");

// packages/inputs/src/sections/boxLabel.ts
var boxLabel = createSection("label", "span");

// packages/inputs/src/sections/boxOption.ts
var boxOption = createSection("option", () => ({
  $el: "li",
  for: ["option", "$options"],
  attrs: {
    "data-disabled": "$option.attrs.disabled || $disabled || undefined"
  }
}));

// packages/inputs/src/sections/boxOptions.ts
var boxOptions = createSection("options", "ul");

// packages/inputs/src/sections/boxWrapper.ts
var boxWrapper = createSection("wrapper", () => ({
  $el: "label",
  attrs: {
    "data-disabled": {
      if: "$options.length",
      then: void 0,
      else: "$disabled || undefined"
    },
    "data-checked": {
      if: "$options == undefined",
      then: "$fns.eq($_value, $onValue) || undefined",
      else: "$fns.isChecked($option.value) || undefined"
    }
  }
}));

// packages/inputs/src/sections/buttonInput.ts
var buttonInput = createSection("input", () => ({
  $el: "button",
  bind: "$attrs",
  attrs: {
    type: "$type",
    disabled: "$disabled",
    name: "$node.name",
    id: "$id"
  }
}));

// packages/inputs/src/sections/buttonLabel.ts
var buttonLabel = createSection("default", null);

// packages/inputs/src/sections/decorator.ts
var decorator = createSection("decorator", () => ({
  $el: "span",
  attrs: {
    "aria-hidden": "true"
  }
}));

// packages/inputs/src/sections/fieldset.ts
var fieldset = createSection("fieldset", () => ({
  $el: "fieldset",
  attrs: {
    id: "$id",
    "aria-describedby": {
      if: "$help",
      then: '$: "help-" + $id',
      else: void 0
    }
  }
}));

// packages/inputs/src/sections/fileInput.ts
var fileInput = createSection("input", () => ({
  $el: "input",
  bind: "$attrs",
  attrs: {
    type: "file",
    disabled: "$disabled",
    name: "$node.name",
    onChange: "$handlers.files",
    onBlur: "$handlers.blur",
    id: "$id",
    "aria-describedby": "$describedBy",
    "aria-required": "$state.required || undefined"
  }
}));

// packages/inputs/src/sections/fileItem.ts
var fileItem = createSection("fileItem", () => ({
  $el: "li",
  for: ["file", "$value"]
}));

// packages/inputs/src/sections/fileList.ts
var fileList = createSection("fileList", () => ({
  $el: "ul",
  if: "$value.length",
  attrs: {
    "data-has-multiple": "$_hasMultipleFiles"
  }
}));

// packages/inputs/src/sections/fileName.ts
var fileName = createSection("fileName", () => ({
  $el: "span",
  attrs: {
    class: "$classes.fileName"
  }
}));

// packages/inputs/src/sections/fileRemove.ts
var fileRemove = createSection("fileRemove", () => ({
  $el: "button",
  attrs: {
    type: "button",
    onClick: "$handlers.resetFiles"
  }
}));

// packages/inputs/src/sections/formInput.ts
var formInput = createSection("form", () => ({
  $el: "form",
  bind: "$attrs",
  meta: {
    autoAnimate: true
  },
  attrs: {
    id: "$id",
    name: "$node.name",
    onSubmit: "$handlers.submit",
    "data-loading": "$state.loading || undefined"
  }
}));

// packages/inputs/src/sections/fragment.ts
var fragment = createSection("wrapper", null, true);

// packages/inputs/src/sections/help.ts
var help = createSection("help", () => ({
  $el: "div",
  if: "$help",
  attrs: {
    id: '$: "help-" + $id'
  }
}));

// packages/inputs/src/sections/icon.ts
var icon = (sectionKey, el) => {
  return createSection(`${sectionKey}Icon`, () => {
    const rawIconProp = `_raw${sectionKey.charAt(0).toUpperCase()}${sectionKey.slice(1)}Icon`;
    return {
      if: `$${sectionKey}Icon && $${rawIconProp}`,
      $el: `${el ? el : "span"}`,
      attrs: {
        class: `$classes.${sectionKey}Icon + " " + $classes.icon`,
        innerHTML: `$${rawIconProp}`,
        onClick: `$handlers.iconClick(${sectionKey})`,
        role: `$fns.iconRole(${sectionKey})`,
        tabindex: `$fns.iconRole(${sectionKey}) === "button" && "0" || undefined`,
        for: {
          if: `${el === "label"}`,
          then: "$id"
        }
      }
    };
  })();
};

// packages/inputs/src/sections/inner.ts
var inner = createSection("inner", "div");

// packages/inputs/src/sections/label.ts
var label = createSection("label", () => ({
  $el: "label",
  if: "$label",
  attrs: {
    for: "$id"
  }
}));

// packages/inputs/src/sections/legend.ts
var legend = createSection("legend", () => ({
  $el: "legend",
  if: "$label"
}));

// packages/inputs/src/sections/message.ts
var message = createSection("message", () => ({
  $el: "li",
  for: ["message", "$messages"],
  attrs: {
    key: "$message.key",
    id: `$id + '-' + $message.key`,
    "data-message-type": "$message.type"
  }
}));

// packages/inputs/src/sections/messages.ts
var messages = createSection("messages", () => ({
  $el: "ul",
  if: "$defaultMessagePlacement && $fns.length($messages)"
}));

// packages/inputs/src/sections/noFiles.ts
var noFiles = createSection("noFiles", () => ({
  $el: "span",
  if: "$value == null || $value.length == 0"
}));

// packages/inputs/src/sections/optGroup.ts
var optGroup = createSection("optGroup", () => ({
  $el: "optgroup",
  bind: "$option.attrs",
  attrs: {
    label: "$option.group"
  }
}));

// packages/inputs/src/sections/option.ts
var option = createSection("option", () => ({
  $el: "option",
  bind: "$option.attrs",
  attrs: {
    class: "$classes.option",
    value: "$option.value",
    selected: "$fns.isSelected($option)"
  }
}));

// packages/inputs/src/sections/optionSlot.ts
var optionSlot = createSection("options", () => ({
  $el: null,
  if: "$options.length",
  for: ["option", "$option.options || $options"]
}));

// packages/inputs/src/sections/outer.ts
var outer = createSection("outer", () => ({
  $el: "div",
  meta: {
    autoAnimate: true
  },
  attrs: {
    key: "$id",
    "data-family": "$family || undefined",
    "data-type": "$type",
    "data-multiple": '$attrs.multiple || ($type != "select" && $options != undefined) || undefined',
    "data-has-multiple": "$_hasMultipleFiles",
    "data-disabled": '$: ($disabled !== "false" && $disabled) || undefined',
    "data-empty": "$state.empty || undefined",
    "data-complete": "$state.complete || undefined",
    "data-invalid": "$state.invalid || undefined",
    "data-errors": "$state.errors || undefined",
    "data-submitted": "$state.submitted || undefined",
    "data-prefix-icon": "$_rawPrefixIcon !== undefined || undefined",
    "data-suffix-icon": "$_rawSuffixIcon !== undefined || undefined",
    "data-prefix-icon-click": "$onPrefixIconClick !== undefined || undefined",
    "data-suffix-icon-click": "$onSuffixIconClick !== undefined || undefined"
  }
}));

// packages/inputs/src/sections/prefix.ts
var prefix = createSection("prefix", null);

// packages/inputs/src/sections/selectInput.ts
var selectInput = createSection("input", () => ({
  $el: "select",
  bind: "$attrs",
  attrs: {
    id: "$id",
    "data-placeholder": "$fns.showPlaceholder($_value, $placeholder)",
    disabled: "$disabled",
    class: "$classes.input",
    name: "$node.name",
    onChange: "$handlers.onChange",
    onInput: "$handlers.selectInput",
    onBlur: "$handlers.blur",
    "aria-describedby": "$describedBy",
    "aria-required": "$state.required || undefined"
  }
}));

// packages/inputs/src/sections/submitInput.ts
var submitInput = createSection("submit", () => ({
  $cmp: "FormKit",
  bind: "$submitAttrs",
  props: {
    type: "submit",
    label: "$submitLabel"
  }
}));

// packages/inputs/src/sections/suffix.ts
var suffix = createSection("suffix", null);

// packages/inputs/src/sections/textInput.ts
var textInput = createSection("input", () => ({
  $el: "input",
  bind: "$attrs",
  attrs: {
    type: "$type",
    disabled: "$disabled",
    name: "$node.name",
    onInput: "$handlers.DOMInput",
    onBlur: "$handlers.blur",
    value: "$_value",
    id: "$id",
    "aria-describedby": "$describedBy",
    "aria-required": "$state.required || undefined"
  }
}));

// packages/inputs/src/sections/textareaInput.ts
var textareaInput = createSection("input", () => ({
  $el: "textarea",
  bind: "$attrs",
  attrs: {
    disabled: "$disabled",
    name: "$node.name",
    onInput: "$handlers.DOMInput",
    onBlur: "$handlers.blur",
    value: "$_value",
    id: "$id",
    "aria-describedby": "$describedBy",
    "aria-required": "$state.required || undefined"
  },
  children: "$initialValue"
}));

// packages/inputs/src/sections/wrapper.ts
var wrapper = createSection("wrapper", "div");

// packages/inputs/src/features/renamesRadios.ts
var radioInstance = 0;
function resetRadio() {
  radioInstance = 0;
}
function renamesRadios(node) {
  if (node.type === "group" || node.type === "list") {
    node.plugins.add(renamesRadiosPlugin);
  }
}
function renamesRadiosPlugin(node) {
  if (node.props.type === "radio") {
    node.addProps(["altName"]);
    node.props.altName = `${node.name}_${radioInstance++}`;
  }
}
function normalizeBoxes(node) {
  return function(prop, next) {
    if (prop.prop === "options" && Array.isArray(prop.value)) {
      prop.value = prop.value.map((option2) => {
        if (!option2.attrs?.id) {
          return extend(option2, {
            attrs: {
              id: `${node.props.id}-option-${slugify(String(option2.value))}`
            }
          });
        }
        return option2;
      });
      if (node.props.type === "checkbox" && !Array.isArray(node.value)) {
        if (node.isCreated) {
          node.input([], false);
        } else {
          node.on("created", () => {
            if (!Array.isArray(node.value)) {
              node.input([], false);
            }
          });
        }
      }
    }
    return next(prop);
  };
}

// packages/inputs/src/features/checkboxes.ts
function toggleChecked(node, e) {
  const el = e.target;
  if (el instanceof HTMLInputElement) {
    const value = Array.isArray(node.props.options) ? optionValue(node.props.options, el.value) : el.value;
    if (Array.isArray(node.props.options) && node.props.options.length) {
      if (!Array.isArray(node._value)) {
        node.input([value]);
      } else if (!node._value.some((existingValue) => shouldSelect(value, existingValue))) {
        node.input([...node._value, value]);
      } else {
        node.input(
          node._value.filter(
            (existingValue) => !shouldSelect(value, existingValue)
          )
        );
      }
    } else {
      if (el.checked) {
        node.input(node.props.onValue);
      } else {
        node.input(node.props.offValue);
      }
    }
  }
}
function isChecked(node, value) {
  node.context?.value;
  node.context?._value;
  if (Array.isArray(node._value)) {
    return node._value.some(
      (existingValue) => shouldSelect(optionValue(node.props.options, value), existingValue)
    );
  }
  return false;
}
function checkboxes(node) {
  node.on("created", () => {
    if (node.context?.handlers) {
      node.context.handlers.toggleChecked = toggleChecked.bind(null, node);
    }
    if (node.context?.fns) {
      node.context.fns.isChecked = isChecked.bind(null, node);
    }
    if (!has(node.props, "onValue"))
      node.props.onValue = true;
    if (!has(node.props, "offValue"))
      node.props.offValue = false;
  });
  node.hook.prop(normalizeBoxes(node));
}

// packages/inputs/src/features/icon.ts
function defaultIcon(sectionKey, defaultIcon2) {
  return (node) => {
    if (node.props[`${sectionKey}Icon`] === void 0) {
      node.props[`${sectionKey}Icon`] = defaultIcon2.startsWith("<svg") ? defaultIcon2 : `default:${defaultIcon2}`;
    }
  };
}
function disables(node) {
  node.on("created", () => {
    if ("disabled" in node.props) {
      node.props.disabled = undefine(node.props.disabled);
      node.config.disabled = undefine(node.props.disabled);
    }
  });
  node.hook.prop(({ prop, value }, next) => {
    value = prop === "disabled" ? undefine(value) : value;
    return next({ prop, value });
  });
  node.on("prop:disabled", ({ payload: value }) => {
    node.config.disabled = undefine(value);
  });
}
function localize(key, value) {
  return (node) => {
    node.store.set(
      /* @__PURE__ */ createMessage({
        key,
        type: "ui",
        value: value || key,
        meta: {
          localize: true,
          i18nArgs: [node]
        }
      })
    );
  };
}

// packages/inputs/src/features/files.ts
var isBrowser = typeof window !== "undefined";
function removeHover(e) {
  if (e.target instanceof HTMLElement && e.target.hasAttribute("data-file-hover")) {
    e.target.removeAttribute("data-file-hover");
  }
}
function preventStrayDrop(type, e) {
  if (!(e.target instanceof HTMLInputElement)) {
    e.preventDefault();
  } else if (type === "dragover") {
    e.target.setAttribute("data-file-hover", "true");
  }
  if (type === "drop") {
    removeHover(e);
  }
}
function files(node) {
  localize("noFiles", "Select file")(node);
  localize("removeAll", "Remove all")(node);
  localize("remove")(node);
  node.addProps(["_hasMultipleFiles"]);
  if (isBrowser) {
    if (!window._FormKit_File_Drop) {
      window.addEventListener(
        "dragover",
        preventStrayDrop.bind(null, "dragover")
      );
      window.addEventListener("drop", preventStrayDrop.bind(null, "drop"));
      window.addEventListener("dragleave", removeHover);
      window._FormKit_File_Drop = true;
    }
  }
  node.hook.input((value, next) => next(Array.isArray(value) ? value : []));
  node.on("input", ({ payload: value }) => {
    node.props._hasMultipleFiles = Array.isArray(value) && value.length > 1 ? true : void 0;
  });
  node.on("reset", () => {
    if (node.props.id && isBrowser) {
      const el = document.getElementById(node.props.id);
      if (el)
        el.value = "";
    }
  });
  node.on("created", () => {
    if (!Array.isArray(node.value))
      node.input([], false);
    if (!node.context)
      return;
    node.context.handlers.resetFiles = (e) => {
      e.preventDefault();
      node.input([]);
      if (node.props.id && isBrowser) {
        const el = document.getElementById(node.props.id);
        if (el)
          el.value = "";
        el?.focus();
      }
    };
    node.context.handlers.files = (e) => {
      const files2 = [];
      if (e.target instanceof HTMLInputElement && e.target.files) {
        for (let i = 0; i < e.target.files.length; i++) {
          let file2;
          if (file2 = e.target.files.item(i)) {
            files2.push({ name: file2.name, file: file2 });
          }
        }
        node.input(files2);
      }
      if (node.context)
        node.context.files = files2;
      if (typeof node.props.attrs?.onChange === "function") {
        node.props.attrs?.onChange(e);
      }
    };
  });
}
var loading = /* @__PURE__ */ createMessage({
  key: "loading",
  value: true,
  visible: false
});
async function handleSubmit(node, submitEvent) {
  const submitNonce = Math.random();
  node.props._submitNonce = submitNonce;
  submitEvent.preventDefault();
  await node.settled;
  if (node.ledger.value("validating")) {
    node.store.set(loading);
    await node.ledger.settled("validating");
    node.store.remove("loading");
    if (node.props._submitNonce !== submitNonce)
      return;
  }
  const setSubmitted = (n) => n.store.set(
    /* @__PURE__ */ createMessage({
      key: "submitted",
      value: true,
      visible: false
    })
  );
  node.walk(setSubmitted);
  setSubmitted(node);
  node.emit("submit-raw");
  if (typeof node.props.onSubmitRaw === "function") {
    node.props.onSubmitRaw(submitEvent, node);
  }
  if (node.ledger.value("blocking")) {
    if (typeof node.props.onSubmitInvalid === "function") {
      node.props.onSubmitInvalid(node);
    }
    if (node.props.incompleteMessage !== false) {
      setIncompleteMessage(node);
    }
  } else {
    if (typeof node.props.onSubmit === "function") {
      const retVal = node.props.onSubmit(
        node.hook.submit.dispatch(clone(node.value)),
        node
      );
      if (retVal instanceof Promise) {
        const autoDisable = node.props.disabled === void 0 && node.props.submitBehavior !== "live";
        if (autoDisable)
          node.props.disabled = true;
        node.store.set(loading);
        await retVal;
        if (autoDisable)
          node.props.disabled = false;
        node.store.remove("loading");
      }
    } else {
      if (submitEvent.target instanceof HTMLFormElement) {
        submitEvent.target.submit();
      }
    }
  }
}
function setIncompleteMessage(node) {
  node.store.set(
    /* @__PURE__ */ createMessage({
      blocking: false,
      key: `incomplete`,
      meta: {
        localize: node.props.incompleteMessage === void 0,
        i18nArgs: [{ node }],
        showAsMessage: true
      },
      type: "ui",
      value: node.props.incompleteMessage || "Form incomplete."
    })
  );
}
function form(node) {
  var _a;
  node.props.isForm = true;
  node.ledger.count("validating", (m) => m.key === "validating");
  (_a = node.props).submitAttrs ?? (_a.submitAttrs = {
    disabled: node.props.disabled
  });
  node.on("prop:disabled", ({ payload: disabled }) => {
    node.props.submitAttrs = { ...node.props.submitAttrs, disabled };
  });
  node.on("created", () => {
    if (node.context?.handlers) {
      node.context.handlers.submit = handleSubmit.bind(null, node);
    }
    if (!has(node.props, "actions")) {
      node.props.actions = true;
    }
  });
  node.on("prop:incompleteMessage", () => {
    if (node.store.incomplete)
      setIncompleteMessage(node);
  });
  node.on("settled:blocking", () => node.store.remove("incomplete"));
}

// packages/inputs/src/features/ignores.ts
function ignore(node) {
  if (node.props.ignore === void 0) {
    node.props.ignore = true;
    node.parent = null;
  }
}

// packages/inputs/src/features/initialValue.ts
function initialValue(node) {
  node.on("created", () => {
    if (node.context) {
      node.context.initialValue = node.value || "";
    }
  });
}

// packages/inputs/src/features/casts.ts
function casts(node) {
  if (typeof node.props.number === "undefined")
    return;
  const strict = ["number", "range", "hidden"].includes(node.props.type);
  node.hook.input((value, next) => {
    if (value === "")
      return next(void 0);
    const numericValue = node.props.number === "integer" ? parseInt(value) : parseFloat(value);
    if (!Number.isFinite(numericValue))
      return strict ? next(void 0) : next(value);
    return next(numericValue);
  });
}
function toggleChecked2(node, event) {
  if (event.target instanceof HTMLInputElement) {
    node.input(optionValue(node.props.options, event.target.value));
  }
}
function isChecked2(node, value) {
  node.context?.value;
  node.context?._value;
  return shouldSelect(optionValue(node.props.options, value), node._value);
}
function radios(node) {
  node.on("created", () => {
    if (!Array.isArray(node.props.options)) {
      warn(350, {
        node,
        inputType: "radio"
      });
    }
    if (node.context?.handlers) {
      node.context.handlers.toggleChecked = toggleChecked2.bind(null, node);
    }
    if (node.context?.fns) {
      node.context.fns.isChecked = isChecked2.bind(null, node);
    }
  });
  node.hook.prop(normalizeBoxes(node));
}
function isSelected(node, option2) {
  if (isGroupOption(option2))
    return false;
  node.context && node.context.value;
  const optionValue2 = "__original" in option2 ? option2.__original : option2.value;
  return Array.isArray(node._value) ? node._value.some((optionA) => shouldSelect(optionA, optionValue2)) : (node._value === void 0 || node._value === null && !containsValue(node.props.options, null)) && option2.attrs && option2.attrs["data-is-placeholder"] ? true : shouldSelect(optionValue2, node._value);
}
function containsValue(options2, value) {
  return options2.some((option2) => {
    if (isGroupOption(option2)) {
      return containsValue(option2.options, value);
    } else {
      return ("__original" in option2 ? option2.__original : option2.value) === value;
    }
  });
}
async function deferChange(node, e) {
  if (typeof node.props.attrs?.onChange === "function") {
    await new Promise((r) => setTimeout(r, 0));
    await node.settled;
    node.props.attrs.onChange(e);
  }
}
function selectInput2(node, e) {
  const target = e.target;
  const value = target.hasAttribute("multiple") ? Array.from(target.selectedOptions).map(
    (o) => optionValue(node.props.options, o.value)
  ) : optionValue(node.props.options, target.value);
  node.input(value);
}
function applyPlaceholder(options2, placeholder) {
  if (!options2.some(
    (option2) => option2.attrs && option2.attrs["data-is-placeholder"]
  )) {
    return [
      {
        label: placeholder,
        value: "",
        attrs: {
          hidden: true,
          disabled: true,
          "data-is-placeholder": "true"
        }
      },
      ...options2
    ];
  }
  return options2;
}
function firstValue(options2) {
  const option2 = options2.length > 0 ? options2[0] : void 0;
  if (!option2)
    return void 0;
  if (isGroupOption(option2))
    return firstValue(option2.options);
  return "__original" in option2 ? option2.__original : option2.value;
}
function select(node) {
  node.on("created", () => {
    const isMultiple = undefine(node.props.attrs?.multiple);
    if (!isMultiple && node.props.placeholder && Array.isArray(node.props.options)) {
      node.hook.prop(({ prop, value }, next) => {
        if (prop === "options") {
          value = applyPlaceholder(value, node.props.placeholder);
        }
        return next({ prop, value });
      });
      node.props.options = applyPlaceholder(
        node.props.options,
        node.props.placeholder
      );
    }
    if (isMultiple) {
      if (node.value === void 0) {
        node.input([], false);
      }
    } else if (node.context && !node.context.options) {
      node.props.attrs = Object.assign({}, node.props.attrs, {
        value: node._value
      });
      node.on("input", ({ payload }) => {
        node.props.attrs = Object.assign({}, node.props.attrs, {
          value: payload
        });
      });
    }
    if (node.context?.handlers) {
      node.context.handlers.selectInput = selectInput2.bind(null, node);
      node.context.handlers.onChange = deferChange.bind(null, node);
    }
    if (node.context?.fns) {
      node.context.fns.isSelected = isSelected.bind(null, node);
      node.context.fns.showPlaceholder = (value, placeholder) => {
        if (!Array.isArray(node.props.options))
          return false;
        const hasMatchingValue = node.props.options.some(
          (option2) => {
            if (option2.attrs && "data-is-placeholder" in option2.attrs)
              return false;
            const optionValue2 = "__original" in option2 ? option2.__original : option2.value;
            return eq(value, optionValue2);
          }
        );
        return placeholder && !hasMatchingValue ? true : void 0;
      };
    }
  });
  node.hook.input((value, next) => {
    if (!node.props.placeholder && value === void 0 && Array.isArray(node.props?.options) && node.props.options.length && !undefine(node.props?.attrs?.multiple)) {
      value = firstValue(node.props.options);
    }
    return next(value);
  });
}

// packages/inputs/src/compose.ts
// @__NO_SIDE_EFFECTS__
function isSlotCondition(node) {
  if (isConditional(node) && node.if && node.if.startsWith("$slots.") && typeof node.then === "string" && node.then.startsWith("$slots.") && "else" in node) {
    return true;
  }
  return false;
}
// @__NO_SIDE_EFFECTS__
function findSection(schema, target) {
  return eachSection(
    schema,
    (section, sectionCondition, parent) => {
      if (section.meta?.section === target) {
        return [parent, sectionCondition];
      }
      return;
    },
    true
  ) ?? [false, false];
}
function eachSection(schema, callback, stopOnCallbackReturn = false, schemaParent) {
  if (Array.isArray(schema)) {
    for (const node of schema) {
      const callbackReturn = eachSection(
        node,
        callback,
        stopOnCallbackReturn,
        schema
      );
      if (callbackReturn && stopOnCallbackReturn) {
        return callbackReturn;
      }
    }
    return;
  }
  if (isSection(schema)) {
    const callbackReturn = callback(schema.else, schema, schemaParent);
    if (callbackReturn && stopOnCallbackReturn) {
      return callbackReturn;
    }
    return eachSection(schema.else, callback, stopOnCallbackReturn, schema);
  } else if ((isComponent(schema) || isDOM(schema)) && schema.children) {
    return eachSection(
      schema.children,
      callback,
      stopOnCallbackReturn
    );
  } else if (isConditional(schema)) {
    let callbackReturn = void 0;
    if (schema.then && typeof schema.then !== "string") {
      callbackReturn = eachSection(
        schema.then,
        callback,
        stopOnCallbackReturn,
        schema
      );
    }
    if (!callbackReturn && schema.else && typeof schema.else !== "string") {
      callbackReturn = eachSection(
        schema.else,
        callback,
        stopOnCallbackReturn,
        schema
      );
    }
    if (callbackReturn && stopOnCallbackReturn) {
      return callbackReturn;
    }
  }
}
function isSection(section) {
  if (isConditional(section) && typeof section.then === "string" && section.else && typeof section.else !== "string" && !Array.isArray(section.else) && !isConditional(section.else) && section.else.meta?.section) {
    return true;
  }
  return false;
}
// @__NO_SIDE_EFFECTS__
function useSchema(inputSection, sectionsSchema = {}) {
  const schema = /* @__PURE__ */ outer(
    /* @__PURE__ */ wrapper(
      /* @__PURE__ */ label("$label"),
      /* @__PURE__ */ inner(/* @__PURE__ */ icon("prefix"), /* @__PURE__ */ prefix(), inputSection(), /* @__PURE__ */ suffix(), /* @__PURE__ */ icon("suffix"))
    ),
    /* @__PURE__ */ help("$help"),
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
  );
  return (propSectionsSchema = {}) => schema(extend(sectionsSchema, propSectionsSchema));
}
// @__NO_SIDE_EFFECTS__
function $attrs(attrs, section) {
  const extendable = (extensions) => {
    const node = section(extensions);
    const attributes = typeof attrs === "function" ? attrs() : attrs;
    if (!isObject(attributes))
      return node;
    if (/* @__PURE__ */ isSlotCondition(node) && isDOM(node.else)) {
      node.else.attrs = { ...node.else.attrs, ...attributes };
    } else if (isDOM(node)) {
      node.attrs = { ...node.attrs, ...attributes };
    }
    return node;
  };
  extendable._s = section._s;
  return extendable;
}
// @__NO_SIDE_EFFECTS__
function $if(condition, then, otherwise) {
  const extendable = (extensions) => {
    const node = then(extensions);
    if (otherwise || isSchemaObject(node) && "if" in node || /* @__PURE__ */ isSlotCondition(node)) {
      const conditionalNode = {
        if: condition,
        then: node
      };
      if (otherwise) {
        conditionalNode.else = otherwise(extensions);
      }
      return conditionalNode;
    } else if (/* @__PURE__ */ isSlotCondition(node)) {
      Object.assign(node.else, { if: condition });
    } else if (isSchemaObject(node)) {
      Object.assign(node, { if: condition });
    }
    return node;
  };
  extendable._s = token();
  return extendable;
}
// @__NO_SIDE_EFFECTS__
function $for(varName, inName, section) {
  return (extensions) => {
    const node = section(extensions);
    if (/* @__PURE__ */ isSlotCondition(node)) {
      Object.assign(node.else, { for: [varName, inName] });
    } else if (isSchemaObject(node)) {
      Object.assign(node, { for: [varName, inName] });
    }
    return node;
  };
}
// @__NO_SIDE_EFFECTS__
function $extend(section, extendWith) {
  const extendable = (extensions) => {
    const node = section({});
    if (/* @__PURE__ */ isSlotCondition(node)) {
      if (Array.isArray(node.else))
        return node;
      node.else = extendSchema(
        extendSchema(node.else, extendWith),
        section._s ? extensions[section._s] : {}
      );
      return node;
    }
    return extendSchema(
      extendSchema(node, extendWith),
      section._s ? extensions[section._s] : {}
    );
  };
  extendable._s = section._s;
  return extendable;
}
// @__NO_SIDE_EFFECTS__
function $root(section) {
  warn(800, "$root");
  return createRoot(section);
}
function resetCounts() {
  resetRadio();
}

// packages/inputs/src/inputs/button.ts
var button = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ outer(
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value")),
    /* @__PURE__ */ wrapper(
      /* @__PURE__ */ buttonInput(
        /* @__PURE__ */ icon("prefix"),
        /* @__PURE__ */ prefix(),
        /* @__PURE__ */ buttonLabel("$label || $ui.submit.value"),
        /* @__PURE__ */ suffix(),
        /* @__PURE__ */ icon("suffix")
      )
    ),
    /* @__PURE__ */ help("$help")
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: "button",
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [localize("submit"), ignore],
  /**
   * A key to use for memoizing the schema. This is used to prevent the schema
   * from needing to be stringified when performing a memo lookup.
   */
  schemaMemoKey: "h6st4epl3j8"
};

// packages/inputs/src/inputs/checkbox.ts
var checkbox = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ outer(
    $if(
      "$options == undefined",
      /**
       * Single checkbox structure.
       */
      /* @__PURE__ */ boxWrapper(
        /* @__PURE__ */ boxInner(/* @__PURE__ */ prefix(), /* @__PURE__ */ box(), /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")), /* @__PURE__ */ suffix()),
        $extend(/* @__PURE__ */ boxLabel("$label"), {
          if: "$label"
        })
      ),
      /**
       * Multi checkbox structure.
       */
      /* @__PURE__ */ fieldset(
        /* @__PURE__ */ legend("$label"),
        /* @__PURE__ */ help("$help"),
        /* @__PURE__ */ boxOptions(
          /* @__PURE__ */ boxOption(
            /* @__PURE__ */ boxWrapper(
              /* @__PURE__ */ boxInner(
                /* @__PURE__ */ prefix(),
                $extend(/* @__PURE__ */ box(), {
                  bind: "$option.attrs",
                  attrs: {
                    id: "$option.attrs.id",
                    value: "$option.value",
                    checked: "$fns.isChecked($option.value)"
                  }
                }),
                /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")),
                /* @__PURE__ */ suffix()
              ),
              $extend(/* @__PURE__ */ boxLabel("$option.label"), {
                if: "$option.label"
              })
            ),
            /* @__PURE__ */ boxHelp("$option.help")
          )
        )
      )
    ),
    // Help text only goes under the input when it is a single.
    $if("$options == undefined && $help", /* @__PURE__ */ help("$help")),
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: "box",
  /**
   * An array of extra props to accept for this input.
   */
  props: ["options", "onValue", "offValue", "optionsLoader"],
  /**
   * Additional features that should be added to your input
   */
  features: [
    options,
    checkboxes,
    defaultIcon("decorator", "checkboxDecorator")
  ],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: "qje02tb3gu8"
};

// packages/inputs/src/inputs/file.ts
var file = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ outer(
    /* @__PURE__ */ wrapper(
      /* @__PURE__ */ label("$label"),
      /* @__PURE__ */ inner(
        /* @__PURE__ */ icon("prefix", "label"),
        /* @__PURE__ */ prefix(),
        /* @__PURE__ */ fileInput(),
        /* @__PURE__ */ fileList(
          /* @__PURE__ */ fileItem(
            /* @__PURE__ */ icon("fileItem"),
            /* @__PURE__ */ fileName("$file.name"),
            $if(
              "$value.length === 1",
              /* @__PURE__ */ fileRemove(
                /* @__PURE__ */ icon("fileRemove"),
                '$ui.remove.value + " " + $file.name'
              )
            )
          )
        ),
        $if("$value.length > 1", /* @__PURE__ */ fileRemove("$ui.removeAll.value")),
        /* @__PURE__ */ noFiles(/* @__PURE__ */ icon("noFiles"), "$ui.noFiles.value"),
        /* @__PURE__ */ suffix(),
        /* @__PURE__ */ icon("suffix")
      )
    ),
    /* @__PURE__ */ help("$help"),
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: "text",
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [
    files,
    defaultIcon("fileItem", "fileItem"),
    defaultIcon("fileRemove", "fileRemove"),
    defaultIcon("noFiles", "noFiles")
  ],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: "9kqc4852fv8"
};

// packages/inputs/src/inputs/form.ts
var form2 = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ formInput(
    "$slots.default",
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value")),
    /* @__PURE__ */ actions(/* @__PURE__ */ submitInput())
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "group",
  /**
   * An array of extra props to accept for this input.
   */
  props: [
    "actions",
    "submit",
    "submitLabel",
    "submitAttrs",
    "submitBehavior",
    "incompleteMessage"
  ],
  /**
   * Additional features that should be added to your input
   */
  features: [form, disables],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: "5bg016redjo"
};

// packages/inputs/src/inputs/group.ts
var group = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ fragment("$slots.default"),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "group",
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [disables, renamesRadios]
};

// packages/inputs/src/inputs/hidden.ts
var hidden = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ textInput(),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [casts]
};

// packages/inputs/src/inputs/list.ts
var list = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ fragment("$slots.default"),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "list",
  /**
   * An array of extra props to accept for this input.
   */
  props: ["sync", "dynamic"],
  /**
   * Additional features that should be added to your input
   */
  features: [disables, renamesRadios]
};

// packages/inputs/src/inputs/meta.ts
var meta = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ fragment(),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: []
};

// packages/inputs/src/inputs/radio.ts
var radio = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ outer(
    $if(
      "$options == undefined",
      /**
       * Single radio structure.
       */
      /* @__PURE__ */ boxWrapper(
        /* @__PURE__ */ boxInner(/* @__PURE__ */ prefix(), /* @__PURE__ */ box(), /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")), /* @__PURE__ */ suffix()),
        $extend(/* @__PURE__ */ boxLabel("$label"), {
          if: "$label"
        })
      ),
      /**
       * Multi radio structure.
       */
      /* @__PURE__ */ fieldset(
        /* @__PURE__ */ legend("$label"),
        /* @__PURE__ */ help("$help"),
        /* @__PURE__ */ boxOptions(
          /* @__PURE__ */ boxOption(
            /* @__PURE__ */ boxWrapper(
              /* @__PURE__ */ boxInner(
                /* @__PURE__ */ prefix(),
                $extend(/* @__PURE__ */ box(), {
                  bind: "$option.attrs",
                  attrs: {
                    id: "$option.attrs.id",
                    value: "$option.value",
                    checked: "$fns.isChecked($option.value)"
                  }
                }),
                /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")),
                /* @__PURE__ */ suffix()
              ),
              $extend(/* @__PURE__ */ boxLabel("$option.label"), {
                if: "$option.label"
              })
            ),
            /* @__PURE__ */ boxHelp("$option.help")
          )
        )
      )
    ),
    // Help text only goes under the input when it is a single.
    $if("$options == undefined && $help", /* @__PURE__ */ help("$help")),
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: "box",
  /**
   * An array of extra props to accept for this input.
   */
  props: ["options", "onValue", "offValue", "optionsLoader"],
  /**
   * Additional features that should be added to your input
   */
  features: [options, radios, defaultIcon("decorator", "radioDecorator")],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: "qje02tb3gu8"
};

// packages/inputs/src/inputs/select.ts
var select2 = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ outer(
    /* @__PURE__ */ wrapper(
      /* @__PURE__ */ label("$label"),
      /* @__PURE__ */ inner(
        /* @__PURE__ */ icon("prefix"),
        /* @__PURE__ */ prefix(),
        /* @__PURE__ */ selectInput(
          $if(
            "$slots.default",
            () => "$slots.default",
            /* @__PURE__ */ optionSlot(
              $if(
                "$option.group",
                /* @__PURE__ */ optGroup(/* @__PURE__ */ optionSlot(/* @__PURE__ */ option("$option.label"))),
                /* @__PURE__ */ option("$option.label")
              )
            )
          )
        ),
        $if("$attrs.multiple !== undefined", () => "", /* @__PURE__ */ icon("select")),
        /* @__PURE__ */ suffix(),
        /* @__PURE__ */ icon("suffix")
      )
    ),
    /* @__PURE__ */ help("$help"),
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * An array of extra props to accept for this input.
   */
  props: ["options", "placeholder", "optionsLoader"],
  /**
   * Additional features that should be added to your input
   */
  features: [options, select, defaultIcon("select", "select")],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: "cb119h43krg"
};

// packages/inputs/src/inputs/textarea.ts
var textarea = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ outer(
    /* @__PURE__ */ wrapper(
      /* @__PURE__ */ label("$label"),
      /* @__PURE__ */ inner(
        /* @__PURE__ */ icon("prefix", "label"),
        /* @__PURE__ */ prefix(),
        /* @__PURE__ */ textareaInput(),
        /* @__PURE__ */ suffix(),
        /* @__PURE__ */ icon("suffix")
      )
    ),
    /* @__PURE__ */ help("$help"),
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [initialValue],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: "b1n0td79m9g"
};

// packages/inputs/src/inputs/text.ts
var text = {
  /**
   * The actual schema of the input, or a function that returns the schema.
   */
  schema: /* @__PURE__ */ outer(
    /* @__PURE__ */ wrapper(
      /* @__PURE__ */ label("$label"),
      /* @__PURE__ */ inner(
        /* @__PURE__ */ icon("prefix", "label"),
        /* @__PURE__ */ prefix(),
        /* @__PURE__ */ textInput(),
        /* @__PURE__ */ suffix(),
        /* @__PURE__ */ icon("suffix")
      )
    ),
    /* @__PURE__ */ help("$help"),
    /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
  ),
  /**
   * The type of node, can be a list, group, or input.
   */
  type: "input",
  /**
   * The family of inputs this one belongs too. For example "text" and "email"
   * are both part of the "text" family. This is primary used for styling.
   */
  family: "text",
  /**
   * An array of extra props to accept for this input.
   */
  props: [],
  /**
   * Additional features that should be added to your input
   */
  features: [casts],
  /**
   * The key used to memoize the schema.
   */
  schemaMemoKey: "c3cc4kflsg"
};

// packages/inputs/src/index.ts
var inputs = {
  button,
  submit: button,
  checkbox,
  file,
  form: form2,
  group,
  hidden,
  list,
  meta,
  radio,
  select: select2,
  textarea,
  text,
  color: text,
  date: text,
  datetimeLocal: text,
  email: text,
  month: text,
  number: text,
  password: text,
  search: text,
  tel: text,
  time: text,
  url: text,
  week: text,
  range: text
};

export { $attrs, $extend, $for, $if, $root, actions, box, boxHelp, boxInner, boxLabel, boxOption, boxOptions, boxWrapper, button, buttonInput, buttonLabel, casts, checkbox, checkboxes, text as color, createLibraryPlugin, createSection, text as date, text as datetimeLocal, decorator, defaultIcon, disables as disablesChildren, eachSection, text as email, extendSchema, fieldset, file, fileInput, fileItem, fileList, fileName, fileRemove, files, findSection, form2 as form, formInput, form as forms, fragment, group, help, hidden, icon, ignore as ignores, initialValue, inner, inputs, isGroupOption, isSchemaObject, isSlotCondition, label, legend, list, localize, message, messages, meta, text as month, noFiles, normalizeBoxes, normalizeOptions, text as number, optGroup, option, optionSlot, options, outer, text as password, prefix, radio, radios, text as range, renamesRadios, resetCounts, resetRadio, runtimeProps, text as search, select2 as select, selectInput, select as selects, button as submit, submitInput, suffix, text as tel, text, textInput, textarea, textareaInput, text as time, text as url, useSchema, text as week, wrapper };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.dev.mjs.map