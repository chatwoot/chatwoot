import _sfc_main from "./BaseListItemLink.vue2.js";
import { resolveComponent, openBlock, mergeProps, normalizeClass, withKeys, renderSlot, createElementVNode, withCtx, createBlock } from "@histoire/vendors/vue";
import _export_sfc from "../../_virtual/_plugin-vue_export-helper.js";
"use strict";
const _hoisted_1 = ["href", "onClick", "onKeyup"];
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_RouterLink = resolveComponent("RouterLink");
  return openBlock(), createBlock(_component_RouterLink, mergeProps({ class: "histoire-base-list-item-link" }, _ctx.$attrs, { custom: "" }), {
    default: withCtx(({ isActive: linkIsActive, href, navigate }) => [
      createElementVNode("a", {
        href,
        class: normalizeClass(["htw-flex htw-items-center htw-gap-2 htw-text-gray-900 dark:htw-text-gray-100", [
          _ctx.$attrs.class,
          (_ctx.isActive != null ? _ctx.isActive : linkIsActive) ? "active htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black" : "hover:htw-bg-primary-100 dark:hover:htw-bg-primary-900"
        ]]),
        onClick: ($event) => _ctx.handleNavigate($event, navigate),
        onKeyup: [
          withKeys(($event) => _ctx.handleNavigate($event, navigate), ["enter"]),
          withKeys(($event) => _ctx.handleNavigate($event, navigate), ["space"])
        ]
      }, [
        renderSlot(_ctx.$slots, "default", {
          active: _ctx.isActive != null ? _ctx.isActive : linkIsActive
        })
      ], 42, _hoisted_1)
    ]),
    _: 3
  }, 16);
}
const BaseListItemLink = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  BaseListItemLink as default
};
