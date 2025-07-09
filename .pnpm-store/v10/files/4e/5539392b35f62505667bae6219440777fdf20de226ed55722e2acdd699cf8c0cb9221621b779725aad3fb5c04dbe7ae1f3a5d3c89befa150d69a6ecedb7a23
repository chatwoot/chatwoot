import { defineComponent, computed, resolveDirective, openBlock, createBlock, resolveDynamicComponent, withCtx, withDirectives, createVNode, unref, normalizeClass, withModifiers, createCommentVNode } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { HstJson, HstCheckbox, HstNumber, HstText } from "@histoire/controls";
"use strict";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ControlsComponentPropItem",
  props: {
    variant: {},
    component: {},
    definition: {}
  },
  setup(__props) {
    const props = __props;
    const comp = computed(() => {
      var _a;
      switch ((_a = props.definition.types) == null ? void 0 : _a[0]) {
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
        var _a;
        return (_a = props.variant.state._hPropState[props.component.index]) == null ? void 0 : _a[props.definition.name];
      },
      set: (value) => {
        if (!props.variant.state._hPropState[props.component.index]) {
          props.variant.state._hPropState[props.component.index] = {};
        }
        props.variant.state._hPropState[props.component.index][props.definition.name] = value;
      }
    });
    function reset() {
      if (props.variant.state._hPropState[props.component.index]) {
        delete props.variant.state._hPropState[props.component.index][props.definition.name];
      }
    }
    const canReset = computed(() => {
      var _a, _b;
      return ((_b = (_a = props.variant.state) == null ? void 0 : _a._hPropState) == null ? void 0 : _b[props.component.index]) && props.definition.name in props.variant.state._hPropState[props.component.index];
    });
    return (_ctx, _cache) => {
      var _a;
      const _directive_tooltip = resolveDirective("tooltip");
      return comp.value ? (openBlock(), createBlock(resolveDynamicComponent(comp.value), {
        key: 0,
        modelValue: model.value,
        "onUpdate:modelValue": _cache[1] || (_cache[1] = ($event) => model.value = $event),
        placeholder: model.value === void 0 ? (_a = _ctx.definition) == null ? void 0 : _a.default : null,
        class: "histoire-controls-component-prop-item",
        title: `${_ctx.definition.name}${canReset.value ? " *" : ""}`
      }, {
        actions: withCtx(() => [
          withDirectives(createVNode(unref(Icon), {
            icon: "carbon:erase",
            class: normalizeClass(["htw-cursor-pointer htw-w-4 htw-h-4 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100", [
              canReset.value ? "htw-opacity-50 hover:htw-opacity-100" : "htw-opacity-25 htw-pointer-events-none"
            ]]),
            onClick: _cache[0] || (_cache[0] = withModifiers(($event) => reset(), ["stop"]))
          }, null, 8, ["class"]), [
            [_directive_tooltip, "Remove override"]
          ])
        ]),
        _: 1
      }, 8, ["modelValue", "placeholder", "title"])) : createCommentVNode("", true);
    };
  }
});
export {
  _sfc_main as default
};
