import { defineComponent, resolveDirective, openBlock, createElementBlock, createElementVNode, withDirectives, createVNode, unref, createTextVNode, toDisplayString, Fragment, renderList, createBlock } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import "./ControlsComponentPropItem.vue.js";
import _sfc_main$1 from "./ControlsComponentPropItem.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-controls-component-props" };
const _hoisted_2 = { class: "htw-font-mono htw-p-2 htw-flex htw-items-center htw-gap-1" };
const _hoisted_3 = /* @__PURE__ */ createElementVNode("span", { class: "htw-opacity-30" }, "<", -1);
const _hoisted_4 = /* @__PURE__ */ createElementVNode("span", { class: "htw-opacity-30" }, ">", -1);
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ControlsComponentProps",
  props: {
    variant: {},
    definition: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      const _directive_tooltip = resolveDirective("tooltip");
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", _hoisted_2, [
          withDirectives(createVNode(unref(Icon), {
            icon: "carbon:flash",
            class: "htw-w-4 htw-h-4 htw-text-primary-500 htw-flex-none"
          }, null, 512), [
            [_directive_tooltip, "Auto-detected props"]
          ]),
          createElementVNode("div", null, [
            _hoisted_3,
            createTextVNode(toDisplayString(_ctx.definition.name), 1),
            _hoisted_4
          ])
        ]),
        (openBlock(true), createElementBlock(Fragment, null, renderList(_ctx.definition.props, (prop) => {
          return openBlock(), createBlock(_sfc_main$1, {
            key: prop.name,
            variant: _ctx.variant,
            component: _ctx.definition,
            definition: prop
          }, null, 8, ["variant", "component", "definition"]);
        }), 128))
      ]);
    };
  }
});
export {
  _sfc_main as default
};
