import { defineComponent, openBlock, createElementBlock, createVNode, unref, createElementVNode, toDisplayString } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
"use strict";
const _hoisted_1 = { class: "htw-p-2 htw-flex htw-items-center htw-gap-x-2" };
const _hoisted_2 = { class: "htw-flex htw-flex-col htw-leading-none" };
const _hoisted_3 = { class: "htw-text-primary-500 htw-min-w-[80px] htw-font-bold" };
const _hoisted_4 = { class: "htw-text-sm htw-text-gray-900 dark:htw-text-gray-100" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "HomeCounter",
  props: {
    icon: {
      type: String,
      default: "carbon:cube"
    },
    title: {
      type: String,
      default: ""
    },
    count: {
      type: Number,
      default: 0
    }
  },
  setup(__props) {
    const props = __props;
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createVNode(unref(Icon), {
          icon: props.icon,
          class: "htw-text-2xl htw-text-gray-700 dark:htw-text-gray-300 htw-flex-none"
        }, null, 8, ["icon"]),
        createElementVNode("div", _hoisted_2, [
          createElementVNode("span", _hoisted_3, toDisplayString(__props.count), 1),
          createElementVNode("span", _hoisted_4, toDisplayString(__props.title), 1)
        ])
      ]);
    };
  }
});
export {
  _sfc_main as default
};
