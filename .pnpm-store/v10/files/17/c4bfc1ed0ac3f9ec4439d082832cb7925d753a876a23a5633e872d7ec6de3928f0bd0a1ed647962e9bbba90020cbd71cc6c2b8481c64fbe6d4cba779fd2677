import { defineComponent, computed, openBlock, createBlock, resolveDynamicComponent, createCommentVNode } from "@histoire/vendors/vue";
import { HstJson, HstCheckbox, HstNumber, HstText } from "@histoire/controls";
"use strict";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ControlsComponentStateItem",
  props: {
    variant: {},
    item: {}
  },
  setup(__props) {
    const props = __props;
    const comp = computed(() => {
      switch (typeof props.variant.state[props.item]) {
        case "string":
          return HstText;
        case "number":
          return HstNumber;
        case "boolean":
          return HstCheckbox;
        case "object":
        default:
          return HstJson;
      }
    });
    const model = computed({
      get: () => {
        return props.variant.state[props.item];
      },
      set: (value) => {
        props.variant.state[props.item] = value;
      }
    });
    return (_ctx, _cache) => {
      return comp.value ? (openBlock(), createBlock(resolveDynamicComponent(comp.value), {
        key: 0,
        modelValue: model.value,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => model.value = $event),
        class: "histoire-controls-component-prop-item",
        title: props.item
      }, null, 8, ["modelValue", "title"])) : createCommentVNode("", true);
    };
  }
});
export {
  _sfc_main as default
};
