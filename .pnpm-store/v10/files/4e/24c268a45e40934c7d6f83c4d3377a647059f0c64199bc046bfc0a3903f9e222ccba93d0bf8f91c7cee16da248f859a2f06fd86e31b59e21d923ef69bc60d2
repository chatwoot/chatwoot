import { defineComponent, openBlock, createBlock, Transition, withCtx, createElementBlock, createElementVNode, toDisplayString, createVNode, unref, renderSlot, createCommentVNode } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
"use strict";
const _hoisted_1 = {
  key: 0,
  class: "histoire-mobile-overlay htw-absolute htw-z-10 htw-bg-white dark:htw-bg-gray-700 htw-w-screen htw-h-screen htw-inset-0 htw-overflow-hidden htw-flex htw-flex-col"
};
const _hoisted_2 = { class: "htw-p-4 htw-h-16 htw-flex htw-border-b htw-border-gray-100 dark:htw-border-gray-800 htw-items-center htw-place-content-between" };
const _hoisted_3 = { class: "htw-text-gray-500" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "MobileOverlay",
  props: {
    title: {},
    opened: { type: Boolean }
  },
  emits: ["close"],
  setup(__props, { emit: __emit }) {
    const emit = __emit;
    return (_ctx, _cache) => {
      return openBlock(), createBlock(Transition, { name: "__histoire-fade-bottom" }, {
        default: withCtx(() => [
          _ctx.opened ? (openBlock(), createElementBlock("div", _hoisted_1, [
            createElementVNode("div", _hoisted_2, [
              createElementVNode("span", _hoisted_3, toDisplayString(_ctx.title), 1),
              createElementVNode("a", {
                class: "htw-p-1 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer",
                onClick: _cache[0] || (_cache[0] = ($event) => emit("close"))
              }, [
                createVNode(unref(Icon), {
                  icon: "carbon:close",
                  class: "htw-w-8 htw-h-8 htw-shrink-0"
                })
              ])
            ]),
            renderSlot(_ctx.$slots, "default")
          ])) : createCommentVNode("", true)
        ]),
        _: 3
      });
    };
  }
});
export {
  _sfc_main as default
};
