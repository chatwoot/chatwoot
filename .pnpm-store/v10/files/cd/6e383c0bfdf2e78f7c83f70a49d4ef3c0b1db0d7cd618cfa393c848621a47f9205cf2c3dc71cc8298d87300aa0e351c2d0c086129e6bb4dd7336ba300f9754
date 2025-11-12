import { defineComponent, computed, openBlock, createBlock, unref, withCtx, createElementVNode, createElementBlock, Fragment, renderList, mergeProps, renderSlot, createTextVNode, toDisplayString, createVNode } from "@histoire/vendors/vue";
import { Dropdown } from "@histoire/vendors/floating-vue";
import { Icon } from "@histoire/vendors/iconify";
"use strict";
const _hoisted_1 = { class: "htw-cursor-pointer htw-w-full htw-outline-none htw-px-2 htw-h-[27px] -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 hover:htw-border-primary-500 dark:hover:htw-border-primary-500 htw-rounded-sm htw-flex htw-gap-2 htw-items-center htw-leading-normal" };
const _hoisted_2 = { class: "htw-flex-1 htw-truncate" };
const _hoisted_3 = { class: "htw-flex htw-flex-col htw-bg-gray-50 dark:htw-bg-gray-700" };
const _hoisted_4 = ["onClick"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "BaseSelect",
  props: {
    modelValue: {},
    options: {}
  },
  emits: ["update:modelValue", "select"],
  setup(__props, { emit: __emit }) {
    const props = __props;
    const emit = __emit;
    const formattedOptions = computed(() => {
      if (Array.isArray(props.options)) {
        return Object.fromEntries(props.options.map((value) => [value, value]));
      }
      return props.options;
    });
    const selectedLabel = computed(() => formattedOptions.value[props.modelValue]);
    function selectValue(value, hide) {
      emit("update:modelValue", value);
      emit("select", value);
      hide();
    }
    return (_ctx, _cache) => {
      return openBlock(), createBlock(unref(Dropdown), {
        class: "histoire-base-select",
        "auto-size": "",
        "auto-boundary-max-size": ""
      }, {
        popper: withCtx(({ hide }) => [
          createElementVNode("div", _hoisted_3, [
            (openBlock(true), createElementBlock(Fragment, null, renderList(formattedOptions.value, (label, value) => {
              return openBlock(), createElementBlock("div", mergeProps({ ..._ctx.$attrs, class: null, style: null }, {
                key: label,
                class: ["htw-px-2 htw-py-1 htw-cursor-pointer hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700", {
                  "htw-bg-primary-200 dark:htw-bg-primary-800": props.modelValue === value
                }],
                onClick: ($event) => selectValue(value, hide)
              }), [
                renderSlot(_ctx.$slots, "option", {
                  label,
                  value
                }, () => [
                  createTextVNode(toDisplayString(label), 1)
                ])
              ], 16, _hoisted_4);
            }), 128))
          ])
        ]),
        default: withCtx(() => [
          createElementVNode("div", _hoisted_1, [
            createElementVNode("div", _hoisted_2, [
              renderSlot(_ctx.$slots, "default", { label: selectedLabel.value }, () => [
                createTextVNode(toDisplayString(selectedLabel.value), 1)
              ])
            ]),
            createVNode(unref(Icon), {
              icon: "carbon:chevron-sort",
              class: "htw-w-4 htw-h-4 htw-flex-none htw-ml-auto"
            })
          ])
        ]),
        _: 3
      });
    };
  }
});
export {
  _sfc_main as default
};
