import { defineComponent, openBlock, createElementBlock, createVNode, unref, normalizeClass, createElementVNode, toDisplayString } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
"use strict";
const _hoisted_1 = { class: "histoire-toolbar-title htw-flex htw-items-center htw-gap-1 htw-text-gray-500 htw-flex-1 htw-truncate htw-min-w-0" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ToolbarTitle",
  props: {
    variant: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createVNode(unref(Icon), {
          icon: _ctx.variant.icon ?? "carbon:cube",
          class: normalizeClass(["htw-w-4 htw-h-4 htw-opacity-50", [
            _ctx.variant.iconColor ? "bind-icon-color" : "htw-text-gray-500"
          ]])
        }, null, 8, ["icon", "class"]),
        createElementVNode("span", null, toDisplayString(_ctx.variant.title), 1)
      ]);
    };
  }
});
export {
  _sfc_main as default
};
