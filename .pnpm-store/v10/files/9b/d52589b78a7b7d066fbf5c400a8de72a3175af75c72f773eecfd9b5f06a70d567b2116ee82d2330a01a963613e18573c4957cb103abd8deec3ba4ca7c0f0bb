import { computed, ref, watch, openBlock, toDisplayString, createElementVNode, createElementBlock, createCommentVNode, vModelText, withDirectives, defineComponent } from "@histoire/vendors/vue";
"use strict";
const _hoisted_1 = { class: "histoire-prompt-text" };
const _hoisted_2 = { class: "htw-flex htw-flex-col htw-gap-2 htw-p-2" };
const _hoisted_3 = { class: "htw-px-2" };
const _hoisted_4 = {
  key: 0,
  class: "htw-opacity-70"
};
const _hoisted_5 = ["required"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "PromptText",
  props: {
    modelValue: {},
    prompt: {},
    answers: {}
  },
  emits: ["update:modelValue"],
  setup(__props, { expose: __expose, emit: __emit }) {
    const props = __props;
    const emit = __emit;
    const model = computed({
      get: () => props.modelValue,
      set: (value) => emit("update:modelValue", value)
    });
    const input = ref();
    function focus() {
      var _a, _b;
      (_a = input.value) == null ? void 0 : _a.focus();
      (_b = input.value) == null ? void 0 : _b.select();
    }
    __expose({
      focus
    });
    const defaultValue = computed(() => {
      if (typeof props.prompt.defaultValue === "function") {
        return props.prompt.defaultValue(props.answers);
      } else {
        return props.prompt.defaultValue;
      }
    });
    watch(defaultValue, (value) => {
      model.value = value;
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("label", _hoisted_2, [
          createElementVNode("span", _hoisted_3, [
            createElementVNode("span", null, toDisplayString(_ctx.prompt.label), 1),
            _ctx.prompt.required ? (openBlock(), createElementBlock("span", _hoisted_4, "*")) : createCommentVNode("", true)
          ]),
          withDirectives(createElementVNode("input", {
            ref_key: "input",
            ref: input,
            "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => model.value = $event),
            class: "htw-bg-transparent htw-w-full htw-p-2 htw-border htw-border-gray-500/50 focus:htw-border-primary-500/50 htw-rounded htw-outline-none",
            required: _ctx.prompt.required
          }, null, 8, _hoisted_5), [
            [vModelText, model.value]
          ])
        ])
      ]);
    };
  }
});
export {
  _sfc_main as default
};
