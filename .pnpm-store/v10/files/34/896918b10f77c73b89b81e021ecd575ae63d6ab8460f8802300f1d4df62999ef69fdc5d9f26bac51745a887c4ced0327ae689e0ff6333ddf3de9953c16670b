import { defineComponent, computed, openBlock, createElementBlock, toDisplayString } from "@histoire/vendors/vue";
import { formatKey } from "../../util/keyboard.js";
"use strict";
const _hoisted_1 = { class: "histoire-base-keyboard-shortcut htw-border htw-border-current htw-opacity-50 htw-px-1 htw-rounded-sm" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "BaseKeyboardShortcut",
  props: {
    shortcut: {}
  },
  setup(__props) {
    const props = __props;
    const formatted = computed(() => props.shortcut.split("+").map((k) => formatKey(k.trim())).join(" "));
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("span", _hoisted_1, toDisplayString(formatted.value), 1);
    };
  }
});
export {
  _sfc_main as default
};
