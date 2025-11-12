var __defProp = Object.defineProperty;
var __defProps = Object.defineProperties;
var __getOwnPropDescs = Object.getOwnPropertyDescriptors;
var __getOwnPropSymbols = Object.getOwnPropertySymbols;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __propIsEnum = Object.prototype.propertyIsEnumerable;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __spreadValues = (a, b) => {
  for (var prop in b || (b = {}))
    if (__hasOwnProp.call(b, prop))
      __defNormalProp(a, prop, b[prop]);
  if (__getOwnPropSymbols)
    for (var prop of __getOwnPropSymbols(b)) {
      if (__propIsEnum.call(b, prop))
        __defNormalProp(a, prop, b[prop]);
    }
  return a;
};
var __spreadProps = (a, b) => __defProps(a, __getOwnPropDescs(b));
var __objRest = (source, exclude) => {
  var target = {};
  for (var prop in source)
    if (__hasOwnProp.call(source, prop) && exclude.indexOf(prop) < 0)
      target[prop] = source[prop];
  if (source != null && __getOwnPropSymbols)
    for (var prop of __getOwnPropSymbols(source)) {
      if (exclude.indexOf(prop) < 0 && __propIsEnum.call(source, prop))
        target[prop] = source[prop];
    }
  return target;
};
import { inject, shallowRef, computed, provide, ref, watchEffect, createVNode, Teleport, Transition, openBlock, createElementBlock, createElementVNode, toRef, defineComponent, onMounted, onUnmounted, isVNode, watch, h } from "vue";
import { getWeek, format, parse } from "date-format-parse";
import en from "date-format-parse/es/locale/en";
const lang = {
  formatLocale: en,
  yearFormat: "YYYY",
  monthFormat: "MMM",
  monthBeforeYear: true
};
let defaultLocale = "en";
const locales = {};
locales[defaultLocale] = lang;
function locale(name, object, isLocal = false) {
  if (typeof name !== "string")
    return locales[defaultLocale];
  let l = defaultLocale;
  if (locales[name]) {
    l = name;
  }
  if (object) {
    locales[name] = object;
    l = name;
  }
  if (!isLocal) {
    defaultLocale = l;
  }
  return locales[name] || locales[defaultLocale];
}
function getLocale(name) {
  return locale(name, void 0, true);
}
function chunk(arr, size) {
  if (!Array.isArray(arr)) {
    return [];
  }
  const result = [];
  const len = arr.length;
  let i = 0;
  size = size || len;
  while (i < len) {
    result.push(arr.slice(i, i += size));
  }
  return result;
}
function last(array) {
  return Array.isArray(array) ? array[array.length - 1] : void 0;
}
function isPlainObject(obj) {
  return Object.prototype.toString.call(obj) === "[object Object]";
}
function pick(obj, props) {
  const res = {};
  if (!isPlainObject(obj))
    return res;
  if (!Array.isArray(props)) {
    props = [props];
  }
  props.forEach((prop) => {
    if (Object.prototype.hasOwnProperty.call(obj, prop)) {
      res[prop] = obj[prop];
    }
  });
  return res;
}
function mergeDeep(target, source) {
  if (!isPlainObject(target)) {
    return {};
  }
  let result = target;
  if (isPlainObject(source)) {
    Object.keys(source).forEach((key) => {
      let value = source[key];
      const targetValue = target[key];
      if (isPlainObject(value) && isPlainObject(targetValue)) {
        value = mergeDeep(targetValue, value);
      }
      result = __spreadProps(__spreadValues({}, result), { [key]: value });
    });
  }
  return result;
}
function padNumber(value) {
  const num = parseInt(String(value), 10);
  return num < 10 ? `0${num}` : `${num}`;
}
function camelcase(str) {
  const camelizeRE = /-(\w)/g;
  return str.replace(camelizeRE, (_, c) => c ? c.toUpperCase() : "");
}
const localeContextKey = "datepicker_locale";
const prefixClassKey = "datepicker_prefixClass";
const getWeekKey = "datepicker_getWeek";
function useLocale() {
  return inject(localeContextKey, shallowRef(getLocale()));
}
function provideLocale(lang2) {
  const locale2 = computed(() => {
    if (isPlainObject(lang2.value)) {
      return mergeDeep(getLocale(), lang2.value);
    }
    return getLocale(lang2.value);
  });
  provide(localeContextKey, locale2);
  return locale2;
}
function providePrefixClass(value) {
  provide(prefixClassKey, value);
}
function usePrefixClass() {
  return inject(prefixClassKey, "mx");
}
function provideGetWeek(value) {
  provide(getWeekKey, value);
}
function useGetWeek() {
  return inject(getWeekKey, getWeek);
}
function getPopupElementSize(element) {
  const originalDisplay = element.style.display;
  const originalVisibility = element.style.visibility;
  element.style.display = "block";
  element.style.visibility = "hidden";
  const styles = window.getComputedStyle(element);
  const width = element.offsetWidth + parseInt(styles.marginLeft, 10) + parseInt(styles.marginRight, 10);
  const height = element.offsetHeight + parseInt(styles.marginTop, 10) + parseInt(styles.marginBottom, 10);
  element.style.display = originalDisplay;
  element.style.visibility = originalVisibility;
  return { width, height };
}
function getRelativePosition(el, targetWidth, targetHeight, fixed) {
  let left = 0;
  let top = 0;
  let offsetX = 0;
  let offsetY = 0;
  const relativeRect = el.getBoundingClientRect();
  const dw = document.documentElement.clientWidth;
  const dh = document.documentElement.clientHeight;
  if (fixed) {
    offsetX = window.pageXOffset + relativeRect.left;
    offsetY = window.pageYOffset + relativeRect.top;
  }
  if (dw - relativeRect.left < targetWidth && relativeRect.right < targetWidth) {
    left = offsetX - relativeRect.left + 1;
  } else if (relativeRect.left + relativeRect.width / 2 <= dw / 2) {
    left = offsetX;
  } else {
    left = offsetX + relativeRect.width - targetWidth;
  }
  if (relativeRect.top <= targetHeight && dh - relativeRect.bottom <= targetHeight) {
    top = offsetY + dh - relativeRect.top - targetHeight;
  } else if (relativeRect.top + relativeRect.height / 2 <= dh / 2) {
    top = offsetY + relativeRect.height;
  } else {
    top = offsetY - targetHeight;
  }
  return { left: `${left}px`, top: `${top}px` };
}
function getScrollParent(node, until = document.body) {
  if (!node || node === until) {
    return null;
  }
  const style = (value, prop) => getComputedStyle(value, null).getPropertyValue(prop);
  const regex = /(auto|scroll)/;
  const scroll = regex.test(style(node, "overflow") + style(node, "overflow-y") + style(node, "overflow-x"));
  return scroll ? node : getScrollParent(node.parentElement, until);
}
let scrollBarWidth;
function getScrollbarWidth() {
  if (typeof window === "undefined")
    return 0;
  if (scrollBarWidth !== void 0)
    return scrollBarWidth;
  const outer = document.createElement("div");
  outer.style.visibility = "hidden";
  outer.style.overflow = "scroll";
  outer.style.width = "100px";
  outer.style.position = "absolute";
  outer.style.top = "-9999px";
  document.body.appendChild(outer);
  const inner = document.createElement("div");
  inner.style.width = "100%";
  outer.appendChild(inner);
  scrollBarWidth = outer.offsetWidth - inner.offsetWidth;
  outer.parentNode.removeChild(outer);
  return scrollBarWidth;
}
const mousedownEvent = "ontouchend" in document ? "touchstart" : "mousedown";
function rafThrottle(fn) {
  let isRunning = false;
  return function fnBinfRaf(...args) {
    if (isRunning)
      return;
    isRunning = true;
    requestAnimationFrame(() => {
      isRunning = false;
      fn.apply(this, args);
    });
  };
}
function defineVueComponent(setup, props) {
  return { setup, name: setup.name, props };
}
function withDefault(props, defaultProps) {
  const result = new Proxy(props, {
    get(target, key) {
      const value = target[key];
      if (value !== void 0) {
        return value;
      }
      return defaultProps[key];
    }
  });
  return result;
}
const keys = () => (props) => props;
const resolveProps = (obj, booleanKeys2) => {
  const props = {};
  for (const key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      const camelizeKey = camelcase(key);
      let value = obj[key];
      if (booleanKeys2.indexOf(camelizeKey) !== -1 && value === "") {
        value = true;
      }
      props[camelizeKey] = value;
    }
  }
  return props;
};
function Popup(originalProps, {
  slots
}) {
  const props = withDefault(originalProps, {
    appendToBody: true
  });
  const prefixClass = usePrefixClass();
  const popup = ref(null);
  const position = ref({
    left: "",
    top: ""
  });
  const displayPopup = () => {
    if (!props.visible || !popup.value)
      return;
    const relativeElement = props.getRelativeElement();
    if (!relativeElement)
      return;
    const {
      width,
      height
    } = getPopupElementSize(popup.value);
    position.value = getRelativePosition(relativeElement, width, height, props.appendToBody);
  };
  watchEffect(displayPopup, {
    flush: "post"
  });
  watchEffect((onInvalidate) => {
    const relativeElement = props.getRelativeElement();
    if (!relativeElement)
      return;
    const scrollElement = getScrollParent(relativeElement) || window;
    const handleMove = rafThrottle(displayPopup);
    scrollElement.addEventListener("scroll", handleMove);
    window.addEventListener("resize", handleMove);
    onInvalidate(() => {
      scrollElement.removeEventListener("scroll", handleMove);
      window.removeEventListener("resize", handleMove);
    });
  }, {
    flush: "post"
  });
  const handleClickOutside = (evt) => {
    if (!props.visible)
      return;
    const target = evt.target;
    const el = popup.value;
    const relativeElement = props.getRelativeElement();
    if (el && !el.contains(target) && relativeElement && !relativeElement.contains(target)) {
      props.onClickOutside(evt);
    }
  };
  watchEffect((onInvalidate) => {
    document.addEventListener(mousedownEvent, handleClickOutside);
    onInvalidate(() => {
      document.removeEventListener(mousedownEvent, handleClickOutside);
    });
  });
  return () => {
    return createVNode(Teleport, {
      "to": "body",
      "disabled": !props.appendToBody
    }, {
      default: () => [createVNode(Transition, {
        "name": `${prefixClass}-zoom-in-down`
      }, {
        default: () => {
          var _a;
          return [props.visible && createVNode("div", {
            "ref": popup,
            "class": `${prefixClass}-datepicker-main ${prefixClass}-datepicker-popup ${props.className}`,
            "style": [__spreadValues({
              position: "absolute"
            }, position.value), props.style || {}]
          }, [(_a = slots.default) == null ? void 0 : _a.call(slots)])];
        }
      })]
    });
  };
}
const popupProps = keys()(["style", "className", "visible", "appendToBody", "onClickOutside", "getRelativeElement"]);
var Popup$1 = defineVueComponent(Popup, popupProps);
const _hoisted_1$2 = {
  xmlns: "http://www.w3.org/2000/svg",
  viewBox: "0 0 1024 1024",
  width: "1em",
  height: "1em"
};
const _hoisted_2$2 = /* @__PURE__ */ createElementVNode("path", { d: "M940.218 107.055H730.764v-60.51H665.6v60.51H363.055v-60.51H297.89v60.51H83.78c-18.617 0-32.581 13.963-32.581 32.581v805.237c0 18.618 13.964 32.582 32.582 32.582h861.09c18.619 0 32.583-13.964 32.583-32.582V139.636c-4.655-18.618-18.619-32.581-37.237-32.581zm-642.327 65.163v60.51h65.164v-60.51h307.2v60.51h65.163v-60.51h176.873v204.8H116.364v-204.8H297.89zM116.364 912.291V442.18H912.29v470.11H116.364z" }, null, -1);
const _hoisted_3$2 = [
  _hoisted_2$2
];
function render$2(_ctx, _cache) {
  return openBlock(), createElementBlock("svg", _hoisted_1$2, _hoisted_3$2);
}
const _hoisted_1$1 = {
  xmlns: "http://www.w3.org/2000/svg",
  viewBox: "0 0 1024 1024",
  width: "1em",
  height: "1em"
};
const _hoisted_2$1 = /* @__PURE__ */ createElementVNode("path", { d: "M810.005 274.005 572.011 512l237.994 237.995-60.01 60.01L512 572.011 274.005 810.005l-60.01-60.01L451.989 512 213.995 274.005l60.01-60.01L512 451.989l237.995-237.994z" }, null, -1);
const _hoisted_3$1 = [
  _hoisted_2$1
];
function render$1(_ctx, _cache) {
  return openBlock(), createElementBlock("svg", _hoisted_1$1, _hoisted_3$1);
}
const _hoisted_1 = {
  xmlns: "http://www.w3.org/2000/svg",
  viewBox: "0 0 24 24",
  width: "1em",
  height: "1em"
};
const _hoisted_2 = /* @__PURE__ */ createElementVNode("path", {
  d: "M0 0h24v24H0z",
  fill: "none"
}, null, -1);
const _hoisted_3 = /* @__PURE__ */ createElementVNode("path", { d: "M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z" }, null, -1);
const _hoisted_4 = /* @__PURE__ */ createElementVNode("path", { d: "M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z" }, null, -1);
const _hoisted_5 = [
  _hoisted_2,
  _hoisted_3,
  _hoisted_4
];
function render(_ctx, _cache) {
  return openBlock(), createElementBlock("svg", _hoisted_1, _hoisted_5);
}
function createDate(y, M = 0, d = 1, h2 = 0, m = 0, s = 0, ms = 0) {
  const date = new Date(y, M, d, h2, m, s, ms);
  if (y < 100 && y >= 0) {
    date.setFullYear(y);
  }
  return date;
}
function isValidDate(date) {
  return date instanceof Date && !isNaN(date.getTime());
}
function isValidRangeDate(dates) {
  return Array.isArray(dates) && dates.length === 2 && dates.every(isValidDate) && dates[0] <= dates[1];
}
function isValidDates(dates) {
  return Array.isArray(dates) && dates.every(isValidDate);
}
function getValidDate(...values) {
  if (values[0] !== void 0 && values[0] !== null) {
    const date = new Date(values[0]);
    if (isValidDate(date)) {
      return date;
    }
  }
  const rest = values.slice(1);
  if (rest.length) {
    return getValidDate(...rest);
  }
  return new Date();
}
function startOfYear(value) {
  const date = new Date(value);
  date.setMonth(0, 1);
  date.setHours(0, 0, 0, 0);
  return date;
}
function startOfMonth(value) {
  const date = new Date(value);
  date.setDate(1);
  date.setHours(0, 0, 0, 0);
  return date;
}
function startOfDay(value) {
  const date = new Date(value);
  date.setHours(0, 0, 0, 0);
  return date;
}
function getCalendar({
  firstDayOfWeek,
  year,
  month
}) {
  const arr = [];
  const calendar = createDate(year, month, 0);
  const lastDayInLastMonth = calendar.getDate();
  const firstDayInLastMonth = lastDayInLastMonth - (calendar.getDay() + 7 - firstDayOfWeek) % 7;
  for (let i = firstDayInLastMonth; i <= lastDayInLastMonth; i++) {
    arr.push(createDate(year, month, i - lastDayInLastMonth));
  }
  calendar.setMonth(month + 1, 0);
  const lastDayInCurrentMonth = calendar.getDate();
  for (let i = 1; i <= lastDayInCurrentMonth; i++) {
    arr.push(createDate(year, month, i));
  }
  const lastMonthLength = lastDayInLastMonth - firstDayInLastMonth + 1;
  const nextMonthLength = 6 * 7 - lastMonthLength - lastDayInCurrentMonth;
  for (let i = 1; i <= nextMonthLength; i++) {
    arr.push(createDate(year, month, lastDayInCurrentMonth + i));
  }
  return arr;
}
function setMonth(dirtyDate, dirtyMonth) {
  const date = new Date(dirtyDate);
  const month = typeof dirtyMonth === "function" ? dirtyMonth(date.getMonth()) : Number(dirtyMonth);
  const year = date.getFullYear();
  const daysInMonth = createDate(year, month + 1, 0).getDate();
  const day = date.getDate();
  date.setMonth(month, Math.min(day, daysInMonth));
  return date;
}
function setYear(dirtyDate, dirtyYear) {
  const date = new Date(dirtyDate);
  const year = typeof dirtyYear === "function" ? dirtyYear(date.getFullYear()) : dirtyYear;
  date.setFullYear(year);
  return date;
}
function diffCalendarMonths(dirtyDateLeft, dirtyDateRight) {
  const dateRight = new Date(dirtyDateRight);
  const dateLeft = new Date(dirtyDateLeft);
  const yearDiff = dateRight.getFullYear() - dateLeft.getFullYear();
  const monthDiff = dateRight.getMonth() - dateLeft.getMonth();
  return yearDiff * 12 + monthDiff;
}
function assignTime(target, source) {
  const date = new Date(target);
  const time = new Date(source);
  date.setHours(time.getHours(), time.getMinutes(), time.getSeconds());
  return date;
}
function PickerInput(originalProps, {
  slots
}) {
  const props = withDefault(originalProps, {
    editable: true,
    disabled: false,
    clearable: true,
    range: false,
    multiple: false
  });
  const prefixClass = usePrefixClass();
  const userInput = ref(null);
  const innerSeparator = computed(() => {
    return props.separator || (props.range ? " ~ " : ",");
  });
  const isValidValue = (value) => {
    if (props.range) {
      return isValidRangeDate(value);
    }
    if (props.multiple) {
      return isValidDates(value);
    }
    return isValidDate(value);
  };
  const isDisabledValue = (value) => {
    if (Array.isArray(value)) {
      return value.some((v) => props.disabledDate(v));
    }
    return props.disabledDate(value);
  };
  const text = computed(() => {
    if (userInput.value !== null) {
      return userInput.value;
    }
    if (typeof props.renderInputText === "function") {
      return props.renderInputText(props.value);
    }
    if (!isValidValue(props.value)) {
      return "";
    }
    if (Array.isArray(props.value)) {
      return props.value.map((v) => props.formatDate(v)).join(innerSeparator.value);
    }
    return props.formatDate(props.value);
  });
  const handleClear = (evt) => {
    var _a;
    if (evt) {
      evt.stopPropagation();
    }
    props.onChange(props.range ? [null, null] : null);
    (_a = props.onClear) == null ? void 0 : _a.call(props);
  };
  const handleChange = () => {
    var _a;
    if (!props.editable || userInput.value === null)
      return;
    const text2 = userInput.value.trim();
    userInput.value = null;
    if (text2 === "") {
      handleClear();
      return;
    }
    let date;
    if (props.range) {
      let arr = text2.split(innerSeparator.value);
      if (arr.length !== 2) {
        arr = text2.split(innerSeparator.value.trim());
      }
      date = arr.map((v) => props.parseDate(v.trim()));
    } else if (props.multiple) {
      date = text2.split(innerSeparator.value).map((v) => props.parseDate(v.trim()));
    } else {
      date = props.parseDate(text2);
    }
    if (isValidValue(date) && !isDisabledValue(date)) {
      props.onChange(date);
    } else {
      (_a = props.onInputError) == null ? void 0 : _a.call(props, text2);
    }
  };
  const handleInput = (evt) => {
    userInput.value = typeof evt === "string" ? evt : evt.target.value;
  };
  const handleKeydown = (evt) => {
    const {
      keyCode
    } = evt;
    if (keyCode === 9) {
      props.onBlur();
    } else if (keyCode === 13) {
      handleChange();
    }
  };
  return () => {
    var _a, _b, _c;
    const showClearIcon = !props.disabled && props.clearable && text.value;
    const inputProps = __spreadProps(__spreadValues({
      name: "date",
      type: "text",
      autocomplete: "off",
      value: text.value,
      class: props.inputClass || `${prefixClass}-input`,
      readonly: !props.editable,
      disabled: props.disabled,
      placeholder: props.placeholder
    }, props.inputAttr), {
      onFocus: props.onFocus,
      onKeydown: handleKeydown,
      onInput: handleInput,
      onChange: handleChange
    });
    return createVNode("div", {
      "class": `${prefixClass}-input-wrapper`,
      "onClick": props.onClick
    }, [((_a = slots.input) == null ? void 0 : _a.call(slots, inputProps)) || createVNode("input", inputProps, null), showClearIcon ? createVNode("i", {
      "class": `${prefixClass}-icon-clear`,
      "onClick": handleClear
    }, [((_b = slots["icon-clear"]) == null ? void 0 : _b.call(slots)) || createVNode(render$1, null, null)]) : null, createVNode("i", {
      "class": `${prefixClass}-icon-calendar`
    }, [((_c = slots["icon-calendar"]) == null ? void 0 : _c.call(slots)) || createVNode(render$2, null, null)])]);
  };
}
const pickerInputBaseProps = keys()(["placeholder", "editable", "disabled", "clearable", "inputClass", "inputAttr", "range", "multiple", "separator", "renderInputText", "onInputError", "onClear"]);
const pickerInputProps = keys()(["value", "formatDate", "parseDate", "disabledDate", "onChange", "onFocus", "onBlur", "onClick", ...pickerInputBaseProps]);
var PickerInput$1 = defineVueComponent(PickerInput, pickerInputProps);
function Picker(originalProps, {
  slots
}) {
  var _a;
  const props = withDefault(originalProps, {
    prefixClass: "mx",
    valueType: "date",
    format: "YYYY-MM-DD",
    type: "date",
    disabledDate: () => false,
    disabledTime: () => false,
    confirmText: "OK"
  });
  providePrefixClass(props.prefixClass);
  provideGetWeek(((_a = props.formatter) == null ? void 0 : _a.getWeek) || getWeek);
  const locale2 = provideLocale(toRef(originalProps, "lang"));
  const container = ref();
  const getContainer = () => container.value;
  const defaultOpen = ref(false);
  const popupVisible = computed(() => {
    return !props.disabled && (typeof props.open === "boolean" ? props.open : defaultOpen.value);
  });
  const openPopup = () => {
    var _a2, _b;
    if (props.disabled || popupVisible.value)
      return;
    defaultOpen.value = true;
    (_a2 = props["onUpdate:open"]) == null ? void 0 : _a2.call(props, true);
    (_b = props.onOpen) == null ? void 0 : _b.call(props);
  };
  const closePopup = () => {
    var _a2, _b;
    if (!popupVisible.value)
      return;
    defaultOpen.value = false;
    (_a2 = props["onUpdate:open"]) == null ? void 0 : _a2.call(props, false);
    (_b = props.onClose) == null ? void 0 : _b.call(props);
  };
  const formatDate = (date, fmt) => {
    fmt = fmt || props.format;
    if (isPlainObject(props.formatter) && typeof props.formatter.stringify === "function") {
      return props.formatter.stringify(date, fmt);
    }
    return format(date, fmt, {
      locale: locale2.value.formatLocale
    });
  };
  const parseDate = (value, fmt) => {
    fmt = fmt || props.format;
    if (isPlainObject(props.formatter) && typeof props.formatter.parse === "function") {
      return props.formatter.parse(value, fmt);
    }
    const backupDate = new Date();
    return parse(value, fmt, {
      locale: locale2.value.formatLocale,
      backupDate
    });
  };
  const value2date = (value) => {
    switch (props.valueType) {
      case "date":
        return value instanceof Date ? new Date(value.getTime()) : new Date(NaN);
      case "timestamp":
        return typeof value === "number" ? new Date(value) : new Date(NaN);
      case "format":
        return typeof value === "string" ? parseDate(value) : new Date(NaN);
      default:
        return typeof value === "string" ? parseDate(value, props.valueType) : new Date(NaN);
    }
  };
  const date2value = (date) => {
    if (!isValidDate(date))
      return null;
    switch (props.valueType) {
      case "date":
        return date;
      case "timestamp":
        return date.getTime();
      case "format":
        return formatDate(date);
      default:
        return formatDate(date, props.valueType);
    }
  };
  const innerValue = computed(() => {
    const value = props.value;
    if (props.range) {
      return (Array.isArray(value) ? value.slice(0, 2) : [null, null]).map(value2date);
    }
    if (props.multiple) {
      return (Array.isArray(value) ? value : []).map(value2date);
    }
    return value2date(value);
  });
  const emitValue = (date, type, close = true) => {
    var _a2, _b;
    const value = Array.isArray(date) ? date.map(date2value) : date2value(date);
    (_a2 = props["onUpdate:value"]) == null ? void 0 : _a2.call(props, value);
    (_b = props.onChange) == null ? void 0 : _b.call(props, value, type);
    if (close) {
      closePopup();
    }
    return value;
  };
  const currentValue = ref(new Date());
  watchEffect(() => {
    if (popupVisible.value) {
      currentValue.value = innerValue.value;
    }
  });
  const handleSelect = (val, type) => {
    if (props.confirm) {
      currentValue.value = val;
    } else {
      emitValue(val, type, !props.multiple && (type === props.type || type === "time"));
    }
  };
  const handleConfirm = () => {
    var _a2;
    const value = emitValue(currentValue.value);
    (_a2 = props.onConfirm) == null ? void 0 : _a2.call(props, value);
  };
  const disabledDateTime = (v) => {
    return props.disabledDate(v) || props.disabledTime(v);
  };
  const renderSidebar = (slotProps) => {
    var _a2;
    const {
      prefixClass
    } = props;
    return createVNode("div", {
      "class": `${prefixClass}-datepicker-sidebar`
    }, [(_a2 = slots.sidebar) == null ? void 0 : _a2.call(slots, slotProps), (props.shortcuts || []).map((v, i) => createVNode("button", {
      "key": i,
      "data-index": i,
      "type": "button",
      "class": `${prefixClass}-btn ${prefixClass}-btn-text ${prefixClass}-btn-shortcut`,
      "onClick": () => {
        var _a3;
        const date = (_a3 = v.onClick) == null ? void 0 : _a3.call(v);
        if (date) {
          emitValue(date);
        }
      }
    }, [v.text]))]);
  };
  return () => {
    var _a2, _b;
    const {
      prefixClass,
      disabled,
      confirm,
      range,
      popupClass,
      popupStyle,
      appendToBody
    } = props;
    const slotProps = {
      value: currentValue.value,
      ["onUpdate:value"]: handleSelect,
      emit: emitValue
    };
    const header = slots.header && createVNode("div", {
      "class": `${prefixClass}-datepicker-header`
    }, [slots.header(slotProps)]);
    const footer = (slots.footer || confirm) && createVNode("div", {
      "class": `${prefixClass}-datepicker-footer`
    }, [(_a2 = slots.footer) == null ? void 0 : _a2.call(slots, slotProps), confirm && createVNode("button", {
      "type": "button",
      "class": `${prefixClass}-btn ${prefixClass}-datepicker-btn-confirm`,
      "onClick": handleConfirm
    }, [props.confirmText])]);
    const content = (_b = slots.content) == null ? void 0 : _b.call(slots, slotProps);
    const sidedar = (slots.sidebar || props.shortcuts) && renderSidebar(slotProps);
    return createVNode("div", {
      "ref": container,
      "class": {
        [`${prefixClass}-datepicker`]: true,
        [`${prefixClass}-datepicker-range`]: range,
        disabled
      }
    }, [createVNode(PickerInput$1, __spreadProps(__spreadValues({}, pick(props, pickerInputBaseProps)), {
      "value": innerValue.value,
      "formatDate": formatDate,
      "parseDate": parseDate,
      "disabledDate": disabledDateTime,
      "onChange": emitValue,
      "onClick": openPopup,
      "onFocus": openPopup,
      "onBlur": closePopup
    }), pick(slots, ["icon-calendar", "icon-clear", "input"])), createVNode(Popup$1, {
      "className": popupClass,
      "style": popupStyle,
      "visible": popupVisible.value,
      "appendToBody": appendToBody,
      "getRelativeElement": getContainer,
      "onClickOutside": closePopup
    }, {
      default: () => [sidedar, createVNode("div", {
        "class": `${prefixClass}-datepicker-content`
      }, [header, content, footer])]
    })]);
  };
}
const pickerbaseProps = keys()(["value", "valueType", "type", "format", "formatter", "lang", "prefixClass", "appendToBody", "open", "popupClass", "popupStyle", "confirm", "confirmText", "shortcuts", "disabledDate", "disabledTime", "onOpen", "onClose", "onConfirm", "onChange", "onUpdate:open", "onUpdate:value"]);
const pickerProps = [...pickerbaseProps, ...pickerInputBaseProps];
var Picker$1 = defineVueComponent(Picker, pickerProps);
function ButtonIcon(_a) {
  var _b = _a, {
    value
  } = _b, rest = __objRest(_b, [
    "value"
  ]);
  const prefixClass = usePrefixClass();
  return createVNode("button", __spreadProps(__spreadValues({}, rest), {
    "type": "button",
    "class": `${prefixClass}-btn ${prefixClass}-btn-text ${prefixClass}-btn-icon-${value}`
  }), [createVNode("i", {
    "class": `${prefixClass}-icon-${value}`
  }, null)]);
}
function TableHeader({
  type,
  calendar,
  onUpdateCalendar
}, {
  slots
}) {
  var _a;
  const prefixClass = usePrefixClass();
  const lastMonth = () => {
    onUpdateCalendar(setMonth(calendar, (v) => v - 1));
  };
  const nextMonth = () => {
    onUpdateCalendar(setMonth(calendar, (v) => v + 1));
  };
  const lastYear = () => {
    onUpdateCalendar(setYear(calendar, (v) => v - 1));
  };
  const nextYear = () => {
    onUpdateCalendar(setYear(calendar, (v) => v + 1));
  };
  const lastDecade = () => {
    onUpdateCalendar(setYear(calendar, (v) => v - 10));
  };
  const nextDecade = () => {
    onUpdateCalendar(setYear(calendar, (v) => v + 10));
  };
  return createVNode("div", {
    "class": `${prefixClass}-calendar-header`
  }, [createVNode(ButtonIcon, {
    "value": "double-left",
    "onClick": type === "year" ? lastDecade : lastYear
  }, null), type === "date" && createVNode(ButtonIcon, {
    "value": "left",
    "onClick": lastMonth
  }, null), createVNode(ButtonIcon, {
    "value": "double-right",
    "onClick": type === "year" ? nextDecade : nextYear
  }, null), type === "date" && createVNode(ButtonIcon, {
    "value": "right",
    "onClick": nextMonth
  }, null), createVNode("span", {
    "class": `${prefixClass}-calendar-header-label`
  }, [(_a = slots.default) == null ? void 0 : _a.call(slots)])]);
}
function TableDate({
  calendar,
  isWeekMode,
  showWeekNumber,
  titleFormat,
  getWeekActive,
  getCellClasses,
  onSelect,
  onUpdatePanel,
  onUpdateCalendar,
  onDateMouseEnter,
  onDateMouseLeave
}) {
  const prefixClass = usePrefixClass();
  const getWeekNumber = useGetWeek();
  const locale2 = useLocale().value;
  const {
    yearFormat,
    monthBeforeYear,
    monthFormat = "MMM",
    formatLocale
  } = locale2;
  const firstDayOfWeek = formatLocale.firstDayOfWeek || 0;
  let days = locale2.days || formatLocale.weekdaysMin;
  days = days.concat(days).slice(firstDayOfWeek, firstDayOfWeek + 7);
  const year = calendar.getFullYear();
  const month = calendar.getMonth();
  const dates = chunk(getCalendar({
    firstDayOfWeek,
    year,
    month
  }), 7);
  const formatDate = (date, fmt) => {
    return format(date, fmt, {
      locale: locale2.formatLocale
    });
  };
  const handlePanelChange = (panel) => {
    onUpdatePanel(panel);
  };
  const getCellDate = (el) => {
    const index2 = el.getAttribute("data-index");
    const [row, col] = index2.split(",").map((v) => parseInt(v, 10));
    const value = dates[row][col];
    return new Date(value);
  };
  const handleCellClick = (evt) => {
    onSelect(getCellDate(evt.currentTarget));
  };
  const handleMouseEnter = (evt) => {
    if (onDateMouseEnter) {
      onDateMouseEnter(getCellDate(evt.currentTarget));
    }
  };
  const handleMouseLeave = (evt) => {
    if (onDateMouseLeave) {
      onDateMouseLeave(getCellDate(evt.currentTarget));
    }
  };
  const yearLabel = createVNode("button", {
    "type": "button",
    "class": `${prefixClass}-btn ${prefixClass}-btn-text ${prefixClass}-btn-current-year`,
    "onClick": () => handlePanelChange("year")
  }, [formatDate(calendar, yearFormat)]);
  const monthLabel = createVNode("button", {
    "type": "button",
    "class": `${prefixClass}-btn ${prefixClass}-btn-text ${prefixClass}-btn-current-month`,
    "onClick": () => handlePanelChange("month")
  }, [formatDate(calendar, monthFormat)]);
  showWeekNumber = typeof showWeekNumber === "boolean" ? showWeekNumber : isWeekMode;
  return createVNode("div", {
    "class": [`${prefixClass}-calendar ${prefixClass}-calendar-panel-date`, {
      [`${prefixClass}-calendar-week-mode`]: isWeekMode
    }]
  }, [createVNode(TableHeader, {
    "type": "date",
    "calendar": calendar,
    "onUpdateCalendar": onUpdateCalendar
  }, {
    default: () => [monthBeforeYear ? [monthLabel, yearLabel] : [yearLabel, monthLabel]]
  }), createVNode("div", {
    "class": `${prefixClass}-calendar-content`
  }, [createVNode("table", {
    "class": `${prefixClass}-table ${prefixClass}-table-date`
  }, [createVNode("thead", null, [createVNode("tr", null, [showWeekNumber && createVNode("th", {
    "class": `${prefixClass}-week-number-header`
  }, null), days.map((day) => createVNode("th", {
    "key": day
  }, [day]))])]), createVNode("tbody", null, [dates.map((row, i) => createVNode("tr", {
    "key": i,
    "class": [`${prefixClass}-date-row`, {
      [`${prefixClass}-active-week`]: getWeekActive(row)
    }]
  }, [showWeekNumber && createVNode("td", {
    "class": `${prefixClass}-week-number`,
    "data-index": `${i},0`,
    "onClick": handleCellClick
  }, [createVNode("div", null, [getWeekNumber(row[0])])]), row.map((cell, j) => createVNode("td", {
    "key": j,
    "class": ["cell", getCellClasses(cell)],
    "title": formatDate(cell, titleFormat),
    "data-index": `${i},${j}`,
    "onClick": handleCellClick,
    "onMouseenter": handleMouseEnter,
    "onMouseleave": handleMouseLeave
  }, [createVNode("div", null, [cell.getDate()])]))]))])])])]);
}
function TableMonth({
  calendar,
  getCellClasses,
  onSelect,
  onUpdateCalendar,
  onUpdatePanel
}) {
  const prefixClass = usePrefixClass();
  const locale2 = useLocale().value;
  const months = locale2.months || locale2.formatLocale.monthsShort;
  const getDate = (month) => {
    return createDate(calendar.getFullYear(), month);
  };
  const handleClick = (evt) => {
    const target = evt.currentTarget;
    const month = target.getAttribute("data-month");
    onSelect(getDate(parseInt(month, 10)));
  };
  return createVNode("div", {
    "class": `${prefixClass}-calendar ${prefixClass}-calendar-panel-month`
  }, [createVNode(TableHeader, {
    "type": "month",
    "calendar": calendar,
    "onUpdateCalendar": onUpdateCalendar
  }, {
    default: () => [createVNode("button", {
      "type": "button",
      "class": `${prefixClass}-btn ${prefixClass}-btn-text ${prefixClass}-btn-current-year`,
      "onClick": () => onUpdatePanel("year")
    }, [calendar.getFullYear()])]
  }), createVNode("div", {
    "class": `${prefixClass}-calendar-content`
  }, [createVNode("table", {
    "class": `${prefixClass}-table ${prefixClass}-table-month`
  }, [chunk(months, 3).map((row, i) => createVNode("tr", {
    "key": i
  }, [row.map((cell, j) => {
    const month = i * 3 + j;
    return createVNode("td", {
      "key": j,
      "class": ["cell", getCellClasses(getDate(month))],
      "data-month": month,
      "onClick": handleClick
    }, [createVNode("div", null, [cell])]);
  })]))])])]);
}
const getDefaultYears = (calendar) => {
  const firstYear = Math.floor(calendar.getFullYear() / 10) * 10;
  const years = [];
  for (let i = 0; i < 10; i++) {
    years.push(firstYear + i);
  }
  return chunk(years, 2);
};
function TableYear({
  calendar,
  getCellClasses = () => [],
  getYearPanel = getDefaultYears,
  onSelect,
  onUpdateCalendar
}) {
  const prefixClass = usePrefixClass();
  const getDate = (year) => {
    return createDate(year, 0);
  };
  const handleClick = (evt) => {
    const target = evt.currentTarget;
    const year = target.getAttribute("data-year");
    onSelect(getDate(parseInt(year, 10)));
  };
  const years = getYearPanel(new Date(calendar));
  const firstYear = years[0][0];
  const lastYear = last(last(years));
  return createVNode("div", {
    "class": `${prefixClass}-calendar ${prefixClass}-calendar-panel-year`
  }, [createVNode(TableHeader, {
    "type": "year",
    "calendar": calendar,
    "onUpdateCalendar": onUpdateCalendar
  }, {
    default: () => [createVNode("span", null, [firstYear]), createVNode("span", {
      "class": `${prefixClass}-calendar-decade-separator`
    }, null), createVNode("span", null, [lastYear])]
  }), createVNode("div", {
    "class": `${prefixClass}-calendar-content`
  }, [createVNode("table", {
    "class": `${prefixClass}-table ${prefixClass}-table-year`
  }, [years.map((row, i) => createVNode("tr", {
    "key": i
  }, [row.map((cell, j) => createVNode("td", {
    "key": j,
    "class": ["cell", getCellClasses(getDate(cell))],
    "data-year": cell,
    "onClick": handleClick
  }, [createVNode("div", null, [cell])]))]))])])]);
}
function Calendar(originalProps) {
  const props = withDefault(originalProps, {
    defaultValue: startOfDay(new Date()),
    type: "date",
    disabledDate: () => false,
    getClasses: () => [],
    titleFormat: "YYYY-MM-DD"
  });
  const innerValue = computed(() => {
    const value = Array.isArray(props.value) ? props.value : [props.value];
    return value.filter(isValidDate).map((v) => {
      if (props.type === "year")
        return startOfYear(v);
      if (props.type === "month")
        return startOfMonth(v);
      return startOfDay(v);
    });
  });
  const innerCalendar = ref(new Date());
  watchEffect(() => {
    let calendarDate = props.calendar;
    if (!isValidDate(calendarDate)) {
      const {
        length
      } = innerValue.value;
      calendarDate = getValidDate(length > 0 ? innerValue.value[length - 1] : props.defaultValue);
    }
    innerCalendar.value = startOfMonth(calendarDate);
  });
  const handleCalendarChange = (calendar) => {
    var _a;
    innerCalendar.value = calendar;
    (_a = props.onCalendarChange) == null ? void 0 : _a.call(props, calendar);
  };
  const panel = ref("date");
  watchEffect(() => {
    const panels = ["date", "month", "year"];
    const index2 = Math.max(panels.indexOf(props.type), panels.indexOf(props.defaultPanel));
    panel.value = index2 !== -1 ? panels[index2] : "date";
  });
  const handelPanelChange = (value) => {
    var _a;
    const oldPanel = panel.value;
    panel.value = value;
    (_a = props.onPanelChange) == null ? void 0 : _a.call(props, value, oldPanel);
  };
  const isDisabled = (date) => {
    return props.disabledDate(new Date(date), innerValue.value);
  };
  const emitDate = (date, type) => {
    var _a, _b, _c;
    if (!isDisabled(date)) {
      (_a = props.onPick) == null ? void 0 : _a.call(props, date);
      if (props.multiple === true) {
        const nextDates = innerValue.value.filter((v) => v.getTime() !== date.getTime());
        if (nextDates.length === innerValue.value.length) {
          nextDates.push(date);
        }
        (_b = props["onUpdate:value"]) == null ? void 0 : _b.call(props, nextDates, type);
      } else {
        (_c = props["onUpdate:value"]) == null ? void 0 : _c.call(props, date, type);
      }
    }
  };
  const handleSelectDate = (date) => {
    emitDate(date, props.type === "week" ? "week" : "date");
  };
  const handleSelectYear = (date) => {
    if (props.type === "year") {
      emitDate(date, "year");
    } else {
      handleCalendarChange(date);
      handelPanelChange("month");
      if (props.partialUpdate && innerValue.value.length === 1) {
        const value = setYear(innerValue.value[0], date.getFullYear());
        emitDate(value, "year");
      }
    }
  };
  const handleSelectMonth = (date) => {
    if (props.type === "month") {
      emitDate(date, "month");
    } else {
      handleCalendarChange(date);
      handelPanelChange("date");
      if (props.partialUpdate && innerValue.value.length === 1) {
        const value = setMonth(setYear(innerValue.value[0], date.getFullYear()), date.getMonth());
        emitDate(value, "month");
      }
    }
  };
  const getCellClasses = (cellDate, classes = []) => {
    if (isDisabled(cellDate)) {
      classes.push("disabled");
    } else if (innerValue.value.some((v) => v.getTime() === cellDate.getTime())) {
      classes.push("active");
    }
    return classes.concat(props.getClasses(cellDate, innerValue.value, classes.join(" ")));
  };
  const getDateClasses = (cellDate) => {
    const notCurrentMonth = cellDate.getMonth() !== innerCalendar.value.getMonth();
    const classes = [];
    if (cellDate.getTime() === new Date().setHours(0, 0, 0, 0)) {
      classes.push("today");
    }
    if (notCurrentMonth) {
      classes.push("not-current-month");
    }
    return getCellClasses(cellDate, classes);
  };
  const getMonthClasses = (cellDate) => {
    if (props.type !== "month") {
      return innerCalendar.value.getMonth() === cellDate.getMonth() ? "active" : "";
    }
    return getCellClasses(cellDate);
  };
  const getYearClasses = (cellDate) => {
    if (props.type !== "year") {
      return innerCalendar.value.getFullYear() === cellDate.getFullYear() ? "active" : "";
    }
    return getCellClasses(cellDate);
  };
  const getWeekActive = (row) => {
    if (props.type !== "week")
      return false;
    const start = row[0].getTime();
    const end = row[6].getTime();
    return innerValue.value.some((v) => {
      const time = v.getTime();
      return time >= start && time <= end;
    });
  };
  return () => {
    if (panel.value === "year") {
      return createVNode(TableYear, {
        "calendar": innerCalendar.value,
        "getCellClasses": getYearClasses,
        "getYearPanel": props.getYearPanel,
        "onSelect": handleSelectYear,
        "onUpdateCalendar": handleCalendarChange
      }, null);
    }
    if (panel.value === "month") {
      return createVNode(TableMonth, {
        "calendar": innerCalendar.value,
        "getCellClasses": getMonthClasses,
        "onSelect": handleSelectMonth,
        "onUpdatePanel": handelPanelChange,
        "onUpdateCalendar": handleCalendarChange
      }, null);
    }
    return createVNode(TableDate, {
      "isWeekMode": props.type === "week",
      "showWeekNumber": props.showWeekNumber,
      "titleFormat": props.titleFormat,
      "calendar": innerCalendar.value,
      "getCellClasses": getDateClasses,
      "getWeekActive": getWeekActive,
      "onSelect": handleSelectDate,
      "onUpdatePanel": handelPanelChange,
      "onUpdateCalendar": handleCalendarChange,
      "onDateMouseEnter": props.onDateMouseEnter,
      "onDateMouseLeave": props.onDateMouseLeave
    }, null);
  };
}
const calendarProps = keys()(["type", "value", "defaultValue", "defaultPanel", "disabledDate", "getClasses", "calendar", "multiple", "partialUpdate", "showWeekNumber", "titleFormat", "getYearPanel", "onDateMouseEnter", "onDateMouseLeave", "onCalendarChange", "onPanelChange", "onUpdate:value", "onPick"]);
var Calendar$1 = defineVueComponent(Calendar, calendarProps);
const inRange = (date, range) => {
  const value = date.getTime();
  let [min, max] = range.map((v) => v.getTime());
  if (min > max) {
    [min, max] = [max, min];
  }
  return value > min && value < max;
};
function CalendarRange(originalProps) {
  const props = withDefault(originalProps, {
    defaultValue: new Date(),
    type: "date"
  });
  const prefixClass = usePrefixClass();
  const defaultValues = computed(() => {
    let values = Array.isArray(props.defaultValue) ? props.defaultValue : [props.defaultValue, props.defaultValue];
    values = values.map((v) => startOfDay(v));
    if (isValidRangeDate(values)) {
      return values;
    }
    return [new Date(), new Date()].map((v) => startOfDay(v));
  });
  const innerValue = ref([new Date(NaN), new Date(NaN)]);
  watchEffect(() => {
    if (isValidRangeDate(props.value)) {
      innerValue.value = props.value;
    }
  });
  const handlePick = (date, type) => {
    var _a;
    const [startValue, endValue] = innerValue.value;
    if (isValidDate(startValue) && !isValidDate(endValue)) {
      if (startValue.getTime() > date.getTime()) {
        innerValue.value = [date, startValue];
      } else {
        innerValue.value = [startValue, date];
      }
      (_a = props["onUpdate:value"]) == null ? void 0 : _a.call(props, innerValue.value, type);
    } else {
      innerValue.value = [date, new Date(NaN)];
    }
  };
  const defaultCalendars = ref([new Date(), new Date()]);
  const calendars = computed(() => {
    return isValidRangeDate(props.calendar) ? props.calendar : defaultCalendars.value;
  });
  const calendarMinDiff = computed(() => {
    if (props.type === "year")
      return 10 * 12;
    if (props.type === "month")
      return 1 * 12;
    return 1;
  });
  const updateCalendars = (dates, index2) => {
    var _a;
    const diff = diffCalendarMonths(dates[0], dates[1]);
    const gap = calendarMinDiff.value - diff;
    if (gap > 0) {
      const anotherIndex = index2 === 1 ? 0 : 1;
      dates[anotherIndex] = setMonth(dates[anotherIndex], (v) => v + (anotherIndex === 0 ? -gap : gap));
    }
    defaultCalendars.value = dates;
    (_a = props.onCalendarChange) == null ? void 0 : _a.call(props, dates, index2);
  };
  const updateCalendarStart = (date) => {
    updateCalendars([date, calendars.value[1]], 0);
  };
  const updateCalendarEnd = (date) => {
    updateCalendars([calendars.value[0], date], 1);
  };
  watchEffect(() => {
    const dates = isValidRangeDate(props.value) ? props.value : defaultValues.value;
    updateCalendars(dates.slice(0, 2));
  });
  const hoveredValue = ref(null);
  const handleMouseEnter = (v) => hoveredValue.value = v;
  const handleMouseLeave = () => hoveredValue.value = null;
  const getRangeClasses = (cellDate, currentDates, classnames) => {
    const outerClasses = props.getClasses ? props.getClasses(cellDate, currentDates, classnames) : [];
    const classes = Array.isArray(outerClasses) ? outerClasses : [outerClasses];
    if (/disabled|active/.test(classnames))
      return classes;
    if (currentDates.length === 2 && inRange(cellDate, currentDates)) {
      classes.push("in-range");
    }
    if (currentDates.length === 1 && hoveredValue.value && inRange(cellDate, [currentDates[0], hoveredValue.value])) {
      return classes.concat("hover-in-range");
    }
    return classes;
  };
  return () => {
    const calendarRange = calendars.value.map((calendar, index2) => {
      const calendarProps2 = __spreadProps(__spreadValues({}, props), {
        calendar,
        value: innerValue.value,
        defaultValue: defaultValues.value[index2],
        getClasses: getRangeClasses,
        partialUpdate: false,
        multiple: false,
        ["onUpdate:value"]: handlePick,
        onCalendarChange: index2 === 0 ? updateCalendarStart : updateCalendarEnd,
        onDateMouseLeave: handleMouseLeave,
        onDateMouseEnter: handleMouseEnter
      });
      return createVNode(Calendar$1, calendarProps2, null);
    });
    return createVNode("div", {
      "class": `${prefixClass}-calendar-range`
    }, [calendarRange]);
  };
}
const calendarRangeProps = calendarProps;
var CalendarRange$1 = defineVueComponent(CalendarRange, calendarRangeProps);
const ScrollbarVertical = defineComponent({
  setup(props, {
    slots
  }) {
    const prefixClass = usePrefixClass();
    const wrapper = ref();
    const thumbHeight = ref("");
    const thumbTop = ref("");
    const getThumbHeight = () => {
      if (!wrapper.value)
        return;
      const el = wrapper.value;
      const heightPercentage = el.clientHeight * 100 / el.scrollHeight;
      thumbHeight.value = heightPercentage < 100 ? `${heightPercentage}%` : "";
    };
    onMounted(getThumbHeight);
    const scrollbarWidth = getScrollbarWidth();
    const handleScroll = (evt) => {
      const el = evt.currentTarget;
      const {
        scrollHeight,
        scrollTop
      } = el;
      thumbTop.value = `${scrollTop * 100 / scrollHeight}%`;
    };
    let draggable = false;
    let prevY = 0;
    const handleDragstart = (evt) => {
      evt.stopImmediatePropagation();
      const el = evt.currentTarget;
      const {
        offsetTop
      } = el;
      draggable = true;
      prevY = evt.clientY - offsetTop;
    };
    const handleDraging = (evt) => {
      if (!draggable || !wrapper.value)
        return;
      const {
        clientY
      } = evt;
      const {
        scrollHeight,
        clientHeight
      } = wrapper.value;
      const offsetY = clientY - prevY;
      const top = offsetY * scrollHeight / clientHeight;
      wrapper.value.scrollTop = top;
    };
    const handleDragend = () => {
      draggable = false;
    };
    onMounted(() => {
      document.addEventListener("mousemove", handleDraging);
      document.addEventListener("mouseup", handleDragend);
    });
    onUnmounted(() => {
      document.addEventListener("mousemove", handleDraging);
      document.addEventListener("mouseup", handleDragend);
    });
    return () => {
      var _a;
      return createVNode("div", {
        "class": `${prefixClass}-scrollbar`,
        "style": {
          position: "relative",
          overflow: "hidden"
        }
      }, [createVNode("div", {
        "ref": wrapper,
        "class": `${prefixClass}-scrollbar-wrap`,
        "style": {
          marginRight: `-${scrollbarWidth}px`
        },
        "onScroll": handleScroll
      }, [(_a = slots.default) == null ? void 0 : _a.call(slots)]), createVNode("div", {
        "class": `${prefixClass}-scrollbar-track`
      }, [createVNode("div", {
        "class": `${prefixClass}-scrollbar-thumb`,
        "style": {
          height: thumbHeight.value,
          top: thumbTop.value
        },
        "onMousedown": handleDragstart
      }, null)])]);
    };
  }
});
function Columns({
  options,
  getClasses,
  onSelect
}) {
  const prefixClass = usePrefixClass();
  const handleSelect = (evt) => {
    const target = evt.target;
    const currentTarget = evt.currentTarget;
    if (target.tagName.toUpperCase() !== "LI")
      return;
    const type = currentTarget.getAttribute("data-type");
    const col = parseInt(currentTarget.getAttribute("data-index"), 10);
    const index2 = parseInt(target.getAttribute("data-index"), 10);
    const value = options[col].list[index2].value;
    onSelect(value, type);
  };
  return createVNode("div", {
    "class": `${prefixClass}-time-columns`
  }, [options.map((col, i) => createVNode(ScrollbarVertical, {
    "key": col.type,
    "class": `${prefixClass}-time-column`
  }, {
    default: () => [createVNode("ul", {
      "class": `${prefixClass}-time-list`,
      "data-index": i,
      "data-type": col.type,
      "onClick": handleSelect
    }, [col.list.map((item, j) => createVNode("li", {
      "key": item.text,
      "data-index": j,
      "class": [`${prefixClass}-time-item`, getClasses(item.value, col.type)]
    }, [item.text]))])]
  }))]);
}
function _isSlot(s) {
  return typeof s === "function" || Object.prototype.toString.call(s) === "[object Object]" && !isVNode(s);
}
function FixedList(props) {
  let _slot;
  const prefixClass = usePrefixClass();
  return createVNode(ScrollbarVertical, null, _isSlot(_slot = props.options.map((item) => createVNode("div", {
    "key": item.text,
    "class": [`${prefixClass}-time-option`, props.getClasses(item.value, "time")],
    "onClick": () => props.onSelect(item.value, "time")
  }, [item.text]))) ? _slot : {
    default: () => [_slot]
  });
}
function generateList({
  length,
  step = 1,
  options
}) {
  if (Array.isArray(options)) {
    return options.filter((v) => v >= 0 && v < length);
  }
  if (step <= 0) {
    step = 1;
  }
  const arr = [];
  for (let i = 0; i < length; i += step) {
    arr.push(i);
  }
  return arr;
}
function getColumnOptions(date, options) {
  let { showHour, showMinute, showSecond, use12h } = options;
  const format2 = options.format || "HH:mm:ss";
  showHour = typeof showHour === "boolean" ? showHour : /[HhKk]/.test(format2);
  showMinute = typeof showMinute === "boolean" ? showMinute : /m/.test(format2);
  showSecond = typeof showSecond === "boolean" ? showSecond : /s/.test(format2);
  use12h = typeof use12h === "boolean" ? use12h : /a/i.test(format2);
  const columns = [];
  const isPM = use12h && date.getHours() >= 12;
  if (showHour) {
    columns.push({
      type: "hour",
      list: generateList({
        length: use12h ? 12 : 24,
        step: options.hourStep,
        options: options.hourOptions
      }).map((num) => {
        const text = num === 0 && use12h ? "12" : padNumber(num);
        const value = new Date(date);
        value.setHours(isPM ? num + 12 : num);
        return { value, text };
      })
    });
  }
  if (showMinute) {
    columns.push({
      type: "minute",
      list: generateList({
        length: 60,
        step: options.minuteStep,
        options: options.minuteOptions
      }).map((num) => {
        const value = new Date(date);
        value.setMinutes(num);
        return { value, text: padNumber(num) };
      })
    });
  }
  if (showSecond) {
    columns.push({
      type: "second",
      list: generateList({
        length: 60,
        step: options.secondStep,
        options: options.secondOptions
      }).map((num) => {
        const value = new Date(date);
        value.setSeconds(num);
        return { value, text: padNumber(num) };
      })
    });
  }
  if (use12h) {
    columns.push({
      type: "ampm",
      list: ["AM", "PM"].map((text, i) => {
        const value = new Date(date);
        value.setHours(value.getHours() % 12 + i * 12);
        return { text, value };
      })
    });
  }
  return columns;
}
function parseOption(time = "") {
  const values = time.split(":");
  if (values.length >= 2) {
    const hours = parseInt(values[0], 10);
    const minutes = parseInt(values[1], 10);
    return {
      hours,
      minutes
    };
  }
  return null;
}
function getFixedOptions({
  date,
  option,
  format: format2,
  formatDate
}) {
  const result = [];
  if (typeof option === "function") {
    return option() || [];
  }
  const start = parseOption(option.start);
  const end = parseOption(option.end);
  const step = parseOption(option.step);
  const fmt = option.format || format2;
  if (start && end && step) {
    const startMinutes = start.minutes + start.hours * 60;
    const endMinutes = end.minutes + end.hours * 60;
    const stepMinutes = step.minutes + step.hours * 60;
    const len = Math.floor((endMinutes - startMinutes) / stepMinutes);
    for (let i = 0; i <= len; i++) {
      const timeMinutes = startMinutes + i * stepMinutes;
      const hours = Math.floor(timeMinutes / 60);
      const minutes = timeMinutes % 60;
      const value = new Date(date);
      value.setHours(hours, minutes, 0);
      result.push({
        value,
        text: formatDate(value, fmt)
      });
    }
  }
  return result;
}
const scrollTo = (element, to, duration = 0) => {
  if (duration <= 0) {
    requestAnimationFrame(() => {
      element.scrollTop = to;
    });
    return;
  }
  const difference = to - element.scrollTop;
  const tick = difference / duration * 10;
  requestAnimationFrame(() => {
    const scrollTop = element.scrollTop + tick;
    if (scrollTop >= to) {
      element.scrollTop = to;
      return;
    }
    element.scrollTop = scrollTop;
    scrollTo(element, to, duration - 10);
  });
};
function TimePanel(originalProps) {
  const props = withDefault(originalProps, {
    defaultValue: startOfDay(new Date()),
    format: "HH:mm:ss",
    timeTitleFormat: "YYYY-MM-DD",
    disabledTime: () => false,
    scrollDuration: 100
  });
  const prefixClass = usePrefixClass();
  const locale2 = useLocale();
  const formatDate = (date, fmt) => {
    return format(date, fmt, {
      locale: locale2.value.formatLocale
    });
  };
  const innerValue = ref(new Date());
  watchEffect(() => {
    innerValue.value = getValidDate(props.value, props.defaultValue);
  });
  const isDisabledTimes = (value) => {
    if (Array.isArray(value)) {
      return value.every((v) => props.disabledTime(new Date(v)));
    }
    return props.disabledTime(new Date(value));
  };
  const isDisabledHour = (date) => {
    const value = new Date(date);
    return isDisabledTimes([value.getTime(), value.setMinutes(0, 0, 0), value.setMinutes(59, 59, 999)]);
  };
  const isDisabledMinute = (date) => {
    const value = new Date(date);
    return isDisabledTimes([value.getTime(), value.setSeconds(0, 0), value.setSeconds(59, 999)]);
  };
  const isDisabledAMPM = (date) => {
    const value = new Date(date);
    const minHour = value.getHours() < 12 ? 0 : 12;
    const maxHour = minHour + 11;
    return isDisabledTimes([value.getTime(), value.setHours(minHour, 0, 0, 0), value.setHours(maxHour, 59, 59, 999)]);
  };
  const isDisabled = (date, type) => {
    if (type === "hour") {
      return isDisabledHour(date);
    }
    if (type === "minute") {
      return isDisabledMinute(date);
    }
    if (type === "ampm") {
      return isDisabledAMPM(date);
    }
    return isDisabledTimes(date);
  };
  const handleSelect = (value, type) => {
    var _a;
    if (!isDisabled(value, type)) {
      const date = new Date(value);
      innerValue.value = date;
      if (!isDisabledTimes(date)) {
        (_a = props["onUpdate:value"]) == null ? void 0 : _a.call(props, date, type);
      }
    }
  };
  const getClasses = (cellDate, type) => {
    if (isDisabled(cellDate, type)) {
      return "disabled";
    }
    if (cellDate.getTime() === innerValue.value.getTime()) {
      return "active";
    }
    return "";
  };
  const container = ref();
  const scrollToSelected = (duration) => {
    if (!container.value)
      return;
    const elements = container.value.querySelectorAll(".active");
    for (let i = 0; i < elements.length; i++) {
      const element = elements[i];
      const scrollElement = getScrollParent(element, container.value);
      if (scrollElement) {
        const to = element.offsetTop;
        scrollTo(scrollElement, to, duration);
      }
    }
  };
  onMounted(() => scrollToSelected(0));
  watch(innerValue, () => scrollToSelected(props.scrollDuration), {
    flush: "post"
  });
  return () => {
    let content;
    if (props.timePickerOptions) {
      content = createVNode(FixedList, {
        "onSelect": handleSelect,
        "getClasses": getClasses,
        "options": getFixedOptions({
          date: innerValue.value,
          format: props.format,
          option: props.timePickerOptions,
          formatDate
        })
      }, null);
    } else {
      content = createVNode(Columns, {
        "options": getColumnOptions(innerValue.value, props),
        "onSelect": handleSelect,
        "getClasses": getClasses
      }, null);
    }
    return createVNode("div", {
      "class": `${prefixClass}-time`,
      "ref": container
    }, [props.showTimeHeader && createVNode("div", {
      "class": `${prefixClass}-time-header`
    }, [createVNode("button", {
      "type": "button",
      "class": `${prefixClass}-btn ${prefixClass}-btn-text ${prefixClass}-time-header-title`,
      "onClick": props.onClickTitle
    }, [formatDate(innerValue.value, props.timeTitleFormat)])]), createVNode("div", {
      "class": `${prefixClass}-time-content`
    }, [content])]);
  };
}
const timePanelProps = keys()(["value", "defaultValue", "format", "timeTitleFormat", "showTimeHeader", "disabledTime", "timePickerOptions", "hourOptions", "minuteOptions", "secondOptions", "hourStep", "minuteStep", "secondStep", "showHour", "showMinute", "showSecond", "use12h", "scrollDuration", "onClickTitle", "onUpdate:value"]);
var TimePanel$1 = defineVueComponent(TimePanel, timePanelProps);
function TimeRange(originalProps) {
  const props = withDefault(originalProps, {
    defaultValue: startOfDay(new Date()),
    disabledTime: () => false
  });
  const prefixClass = usePrefixClass();
  const innerValue = ref([new Date(NaN), new Date(NaN)]);
  watchEffect(() => {
    if (isValidRangeDate(props.value)) {
      innerValue.value = props.value;
    } else {
      innerValue.value = [new Date(NaN), new Date(NaN)];
    }
  });
  const emitChange = (type, index2) => {
    var _a;
    (_a = props["onUpdate:value"]) == null ? void 0 : _a.call(props, innerValue.value, type === "time" ? "time-range" : type, index2);
  };
  const handleSelectStart = (date, type) => {
    innerValue.value[0] = date;
    if (!(innerValue.value[1].getTime() >= date.getTime())) {
      innerValue.value[1] = date;
    }
    emitChange(type, 0);
  };
  const handleSelectEnd = (date, type) => {
    innerValue.value[1] = date;
    if (!(innerValue.value[0].getTime() <= date.getTime())) {
      innerValue.value[0] = date;
    }
    emitChange(type, 1);
  };
  const disabledStartTime = (date) => {
    return props.disabledTime(date, 0);
  };
  const disabledEndTime = (date) => {
    return date.getTime() < innerValue.value[0].getTime() || props.disabledTime(date, 1);
  };
  return () => {
    const defaultValues = Array.isArray(props.defaultValue) ? props.defaultValue : [props.defaultValue, props.defaultValue];
    return createVNode("div", {
      "class": `${prefixClass}-time-range`
    }, [createVNode(TimePanel$1, __spreadProps(__spreadValues({}, props), {
      ["onUpdate:value"]: handleSelectStart,
      "value": innerValue.value[0],
      "defaultValue": defaultValues[0],
      "disabledTime": disabledStartTime
    }), null), createVNode(TimePanel$1, __spreadProps(__spreadValues({}, props), {
      ["onUpdate:value"]: handleSelectEnd,
      "value": innerValue.value[1],
      "defaultValue": defaultValues[1],
      "disabledTime": disabledEndTime
    }), null)]);
  };
}
const timeRangeProps = timePanelProps;
var TimeRange$1 = defineVueComponent(TimeRange, timeRangeProps);
function useTimePanelVisible(props) {
  const defaultTimeVisible = ref(false);
  const closeTimePanel = () => {
    var _a;
    defaultTimeVisible.value = false;
    (_a = props.onShowTimePanelChange) == null ? void 0 : _a.call(props, false);
  };
  const openTimePanel = () => {
    var _a;
    defaultTimeVisible.value = true;
    (_a = props.onShowTimePanelChange) == null ? void 0 : _a.call(props, true);
  };
  const timeVisible = computed(() => {
    return typeof props.showTimePanel === "boolean" ? props.showTimePanel : defaultTimeVisible.value;
  });
  return { timeVisible, openTimePanel, closeTimePanel };
}
function DateTime(originalProps) {
  const props = withDefault(originalProps, {
    disabledTime: () => false,
    defaultValue: startOfDay(new Date())
  });
  const currentValue = ref(props.value);
  watchEffect(() => {
    currentValue.value = props.value;
  });
  const {
    openTimePanel,
    closeTimePanel,
    timeVisible
  } = useTimePanelVisible(props);
  const handleSelect = (date, type) => {
    var _a;
    if (type === "date") {
      openTimePanel();
    }
    let datetime = assignTime(date, getValidDate(props.value, props.defaultValue));
    if (props.disabledTime(new Date(datetime))) {
      datetime = assignTime(date, props.defaultValue);
      if (props.disabledTime(new Date(datetime))) {
        currentValue.value = datetime;
        return;
      }
    }
    (_a = props["onUpdate:value"]) == null ? void 0 : _a.call(props, datetime, type);
  };
  return () => {
    const prefixClass = usePrefixClass();
    const calendarProp = __spreadProps(__spreadValues({}, pick(props, calendarProps)), {
      multiple: false,
      type: "date",
      value: currentValue.value,
      ["onUpdate:value"]: handleSelect
    });
    const timeProps = __spreadProps(__spreadValues({}, pick(props, timePanelProps)), {
      showTimeHeader: true,
      value: currentValue.value,
      ["onUpdate:value"]: props["onUpdate:value"],
      onClickTitle: closeTimePanel
    });
    return createVNode("div", {
      "class": `${prefixClass}-date-time`
    }, [createVNode(Calendar$1, calendarProp, null), timeVisible.value && createVNode(TimePanel$1, timeProps, null)]);
  };
}
const datetimeBaseProps = keys()(["showTimePanel", "onShowTimePanelChange"]);
const datetimeProps = [...datetimeBaseProps, ...calendarProps, ...timePanelProps];
var DateTime$1 = defineVueComponent(DateTime, datetimeProps);
function DateTimeRange(originalProps) {
  const props = withDefault(originalProps, {
    defaultValue: startOfDay(new Date()),
    disabledTime: () => false
  });
  const currentValue = ref(props.value);
  watchEffect(() => {
    currentValue.value = props.value;
  });
  const {
    openTimePanel,
    closeTimePanel,
    timeVisible
  } = useTimePanelVisible(props);
  const handleSelect = (dates, type) => {
    var _a;
    if (type === "date") {
      openTimePanel();
    }
    const defaultValues = Array.isArray(props.defaultValue) ? props.defaultValue : [props.defaultValue, props.defaultValue];
    let datetimes = dates.map((date, i) => {
      const time = isValidRangeDate(props.value) ? props.value[i] : defaultValues[i];
      return assignTime(date, time);
    });
    if (datetimes[1].getTime() < datetimes[0].getTime()) {
      datetimes = [datetimes[0], datetimes[0]];
    }
    if (datetimes.some(props.disabledTime)) {
      datetimes = dates.map((date, i) => assignTime(date, defaultValues[i]));
      if (datetimes.some(props.disabledTime)) {
        currentValue.value = datetimes;
        return;
      }
    }
    (_a = props["onUpdate:value"]) == null ? void 0 : _a.call(props, datetimes, type);
  };
  return () => {
    const prefixClass = usePrefixClass();
    const calendarProp = __spreadProps(__spreadValues({}, pick(props, calendarRangeProps)), {
      type: "date",
      value: currentValue.value,
      ["onUpdate:value"]: handleSelect
    });
    const timeProps = __spreadProps(__spreadValues({}, pick(props, timeRangeProps)), {
      showTimeHeader: true,
      value: currentValue.value,
      ["onUpdate:value"]: props["onUpdate:value"],
      onClickTitle: closeTimePanel
    });
    return createVNode("div", {
      "class": `${prefixClass}-date-time-range`
    }, [createVNode(CalendarRange$1, calendarProp, null), timeVisible.value && createVNode(TimeRange$1, timeProps, null)]);
  };
}
const datetimeRangeProps = [...datetimeBaseProps, ...timeRangeProps, ...calendarRangeProps];
var DateTimeRange$1 = defineVueComponent(DateTimeRange, datetimeRangeProps);
const booleanKeys = keys()(["range", "open", "appendToBody", "clearable", "confirm", "disabled", "editable", "multiple", "partialUpdate", "showHour", "showMinute", "showSecond", "showTimeHeader", "showTimePanel", "showWeekNumber", "use12h"]);
const formatMap = {
  date: "YYYY-MM-DD",
  datetime: "YYYY-MM-DD HH:mm:ss",
  year: "YYYY",
  month: "YYYY-MM",
  time: "HH:mm:ss",
  week: "w"
};
function DatePicker(originalProps, {
  slots
}) {
  const type = originalProps.type || "date";
  const format2 = originalProps.format || formatMap[type] || formatMap.date;
  const props = __spreadProps(__spreadValues({}, resolveProps(originalProps, booleanKeys)), {
    type,
    format: format2
  });
  return createVNode(Picker$1, pick(props, Picker$1.props), __spreadValues({
    content: (slotProps) => {
      if (props.range) {
        const Content = type === "time" ? TimeRange$1 : type === "datetime" ? DateTimeRange$1 : CalendarRange$1;
        return h(Content, pick(__spreadValues(__spreadValues({}, props), slotProps), Content.props));
      } else {
        const Content = type === "time" ? TimePanel$1 : type === "datetime" ? DateTime$1 : Calendar$1;
        return h(Content, pick(__spreadValues(__spreadValues({}, props), slotProps), Content.props));
      }
    },
    ["icon-calendar"]: () => type === "time" ? createVNode(render, null, null) : createVNode(render$2, null, null)
  }, slots));
}
const api = {
  locale,
  install: (app) => {
    app.component("DatePicker", DatePicker);
  }
};
var index = Object.assign(DatePicker, api, {
  Calendar: Calendar$1,
  CalendarRange: CalendarRange$1,
  TimePanel: TimePanel$1,
  TimeRange: TimeRange$1,
  DateTime: DateTime$1,
  DateTimeRange: DateTimeRange$1
});
export { index as default };
