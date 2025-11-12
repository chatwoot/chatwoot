import { defineComponent, computed, resolveDirective, openBlock, createElementBlock, createElementVNode, withDirectives, createVNode, unref, Fragment, renderList, createBlock } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import "./ControlsComponentStateItem.vue.js";
import _sfc_main$1 from "./ControlsComponentStateItem.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-controls-component-init-state" };
const _hoisted_2 = { class: "htw-p-2 htw-flex htw-items-center htw-gap-1" };
const _hoisted_3 = /* @__PURE__ */ createElementVNode("div", null, " State ", -1);
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ControlsComponentState",
  props: {
    variant: {}
  },
  setup(__props) {
    const props = __props;
    const stateKeys = computed(() => Object.keys(props.variant.state || {}).filter((key) => !key.startsWith("_h")));
    return (_ctx, _cache) => {
      const _directive_tooltip = resolveDirective("tooltip");
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", _hoisted_2, [
          withDirectives(createVNode(unref(Icon), {
            icon: "carbon:data-vis-1",
            class: "htw-w-4 htw-h-4 htw-text-primary-500 htw-flex-none"
          }, null, 512), [
            [_directive_tooltip, "Auto-detected state"]
          ]),
          _hoisted_3
        ]),
        (openBlock(true), createElementBlock(Fragment, null, renderList(stateKeys.value, (key) => {
          return openBlock(), createBlock(_sfc_main$1, {
            key,
            item: key,
            variant: _ctx.variant
          }, null, 8, ["item", "variant"]);
        }), 128))
      ]);
    };
  }
});
export {
  _sfc_main as default
};
