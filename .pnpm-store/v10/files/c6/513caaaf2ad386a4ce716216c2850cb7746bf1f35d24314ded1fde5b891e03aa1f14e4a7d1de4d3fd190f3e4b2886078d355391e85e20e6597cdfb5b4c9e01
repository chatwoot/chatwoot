import _sfc_main from "./BaseOverflowTab.vue2.js";
import { resolveComponent, openBlock, mergeProps, renderSlot, Transition, createElementBlock, createCommentVNode, withCtx, createVNode, createElementVNode, createBlock } from "@histoire/vendors/vue";
import _export_sfc from "../../_virtual/_plugin-vue_export-helper.js";
"use strict";
const _hoisted_1 = ["href", "onClick"];
const _hoisted_2 = {
  key: 0,
  class: "htw-absolute htw-top-0 htw-left-0 htw-h-full htw-w-[2px] htw-bg-primary-500 dark:htw-bg-primary-400"
};
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_router_link = resolveComponent("router-link");
  return openBlock(), createBlock(_component_router_link, mergeProps({ class: "histoire-base-overflow-tab" }, _ctx.$attrs, { custom: "" }), {
    default: withCtx(({ isActive, isExactActive, href, navigate }) => [
      createElementVNode("a", mergeProps(_ctx.$attrs, {
        href,
        class: ["htw-px-4 htw-h-10 htw-min-w-[150px] htw-inline-flex htw-items-center hover:htw-bg-primary-50 dark:hover:htw-bg-primary-900 htw-relative htw-text-gray-900 dark:htw-text-gray-100", {
          "htw-text-primary-500 dark:htw-text-primary-400": _ctx.matched != null ? _ctx.matched : _ctx.exact && isExactActive || !_ctx.exact && isActive
        }],
        onClick: navigate
      }), [
        renderSlot(_ctx.$slots, "default"),
        createVNode(Transition, { name: "__histoire-scale-y" }, {
          default: withCtx(() => [
            (_ctx.matched != null ? _ctx.matched : _ctx.exact && isExactActive || !_ctx.exact && isActive) ? (openBlock(), createElementBlock("div", _hoisted_2)) : createCommentVNode("", true)
          ]),
          _: 2
        }, 1024)
      ], 16, _hoisted_1)
    ]),
    _: 3
  }, 16);
}
const BaseOverflowTab = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  BaseOverflowTab as default
};
