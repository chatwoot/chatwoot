import { defineComponent, ref, computed, watch, openBlock, createElementBlock, withKeys, withModifiers, createElementVNode, normalizeClass, renderSlot } from "@histoire/vendors/vue";
"use strict";
const _hoisted_1 = { class: "htw-text-white htw-w-[16px] htw-h-[16px] htw-relative" };
const _hoisted_2 = {
  width: "16",
  height: "16",
  viewBox: "0 0 24 24",
  class: "htw-relative htw-z-10"
};
const _hoisted_3 = ["stroke-dasharray", "stroke-dashoffset"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "BaseCheckbox",
  props: {
    modelValue: {
      type: Boolean,
      default: false
    }
  },
  emits: {
    "update:modelValue": (_newValue) => true
  },
  setup(__props, { emit: __emit }) {
    const props = __props;
    const emit = __emit;
    function toggle() {
      emit("update:modelValue", !props.modelValue);
      animationEnabled.value = true;
    }
    const path = ref();
    const dasharray = ref(0);
    const progress = computed(() => props.modelValue ? 1 : 0);
    const dashoffset = computed(() => (1 - progress.value) * dasharray.value);
    const animationEnabled = ref(false);
    watch(path, () => {
      var _a, _b;
      dasharray.value = ((_b = (_a = path.value).getTotalLength) == null ? void 0 : _b.call(_a)) ?? 21.21;
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", {
        role: "checkbox",
        tabindex: "0",
        class: "histoire-base-checkbox htw-flex htw-items-center htw-gap-2 htw-select-none htw-px-4 htw-py-3 htw-cursor-pointer hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700",
        onClick: _cache[0] || (_cache[0] = ($event) => toggle()),
        onKeydown: [
          _cache[1] || (_cache[1] = withKeys(withModifiers(($event) => toggle(), ["prevent"]), ["enter"])),
          _cache[2] || (_cache[2] = withKeys(withModifiers(($event) => toggle(), ["prevent"]), ["space"]))
        ]
      }, [
        createElementVNode("div", _hoisted_1, [
          createElementVNode("div", {
            class: normalizeClass(["htw-border group-active:htw-bg-gray-500/20 htw-rounded-sm htw-box-border htw-absolute htw-inset-0 htw-transition-border htw-duration-150 htw-ease-out", [
              __props.modelValue ? "htw-border-primary-500 htw-border-8" : "htw-border-black/25 dark:htw-border-white/25 htw-delay-150"
            ]])
          }, null, 2),
          (openBlock(), createElementBlock("svg", _hoisted_2, [
            createElementVNode("path", {
              ref_key: "path",
              ref: path,
              d: "m 4 12 l 5 5 l 10 -10",
              fill: "none",
              class: normalizeClass(["htw-stroke-white htw-stroke-2 htw-duration-200 htw-ease-in-out", [
                animationEnabled.value ? "htw-transition-all" : "htw-transition-none",
                {
                  "htw-delay-150": __props.modelValue
                }
              ]]),
              "stroke-dasharray": dasharray.value,
              "stroke-dashoffset": dashoffset.value
            }, null, 10, _hoisted_3)
          ]))
        ]),
        renderSlot(_ctx.$slots, "default")
      ], 32);
    };
  }
});
export {
  _sfc_main as default
};
