import { computed, ref, watchEffect, openBlock, createElementVNode, vModelText, withDirectives, toDisplayString, createElementBlock, createCommentVNode, createTextVNode, createVNode, unref, withModifiers, withKeys, Fragment, normalizeClass, createBlock, renderList, defineComponent } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useSelection } from "../../util/select.js";
import "../base/BaseKeyboardShortcut.vue.js";
import _sfc_main$1 from "../base/BaseKeyboardShortcut.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-prompt-select htw-relative htw-group" };
const _hoisted_2 = ["required"];
const _hoisted_3 = { class: "htw-flex htw-flex-col htw-gap-2 htw-p-2" };
const _hoisted_4 = { class: "htw-px-2 htw-flex" };
const _hoisted_5 = {
  key: 0,
  class: "htw-opacity-70"
};
const _hoisted_6 = { class: "htw-opacity-40 htw-text-sm htw-ml-auto htw-invisible group-focus-within:htw-visible" };
const _hoisted_7 = { class: "htw-overflow-auto max-h-[300px] htw-mb-2" };
const _hoisted_8 = ["onClick"];
const _hoisted_9 = { class: "htw-flex-1" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "PromptSelect",
  props: {
    modelValue: {},
    prompt: {},
    answers: {}
  },
  emits: ["update:modelValue", "next"],
  setup(__props, { expose: __expose, emit: __emit }) {
    const props = __props;
    const emit = __emit;
    const model = computed({
      get: () => props.modelValue,
      set: (value) => {
        emit("update:modelValue", value);
        emit("next");
      }
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
    const search = ref("");
    const options = ref([]);
    let requestId = 0;
    watchEffect(async () => {
      if (typeof props.prompt.options === "function") {
        const rId = ++requestId;
        const result = await props.prompt.options(search.value, props.answers);
        if (rId === requestId) {
          options.value = result;
        }
      } else {
        options.value = props.prompt.options;
      }
    });
    const formattedOptions = computed(() => {
      return options.value.map((option) => {
        if (typeof option === "string") {
          return {
            value: option,
            label: option
          };
        } else {
          return option;
        }
      });
    });
    const {
      selectedIndex,
      selectNext,
      selectPrevious
    } = useSelection(formattedOptions);
    function selectIndex(index) {
      const result = formattedOptions.value[index].value;
      if (result) {
        model.value = result;
      }
    }
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        withDirectives(createElementVNode("input", {
          "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => model.value = $event),
          required: _ctx.prompt.required,
          tabindex: "-1",
          class: "htw-absolute htw-inset-0 htw-opacity-0 htw-pointer-events-none"
        }, null, 8, _hoisted_2), [
          [vModelText, model.value]
        ]),
        createElementVNode("label", _hoisted_3, [
          createElementVNode("span", _hoisted_4, [
            createElementVNode("span", null, toDisplayString(_ctx.prompt.label), 1),
            _ctx.prompt.required ? (openBlock(), createElementBlock("span", _hoisted_5, "*")) : createCommentVNode("", true),
            createElementVNode("span", _hoisted_6, [
              createTextVNode(" Press "),
              createVNode(_sfc_main$1, { shortcut: "Space" }),
              createTextVNode(" to select ")
            ])
          ]),
          withDirectives(createElementVNode("input", {
            ref_key: "input",
            ref: input,
            "onUpdate:modelValue": _cache[1] || (_cache[1] = ($event) => search.value = $event),
            class: "htw-bg-transparent htw-w-full htw-p-2 htw-border htw-border-gray-500/50 focus:htw-border-primary-500/50 htw-rounded htw-outline-none",
            onKeydown: [
              _cache[2] || (_cache[2] = withKeys(withModifiers(($event) => unref(selectNext)(), ["prevent"]), ["down"])),
              _cache[3] || (_cache[3] = withKeys(withModifiers(($event) => unref(selectPrevious)(), ["prevent"]), ["up"])),
              _cache[4] || (_cache[4] = withKeys(withModifiers(($event) => selectIndex(unref(selectedIndex)), ["prevent"]), ["space"]))
            ]
          }, null, 544), [
            [vModelText, search.value]
          ])
        ]),
        createElementVNode("div", _hoisted_7, [
          (openBlock(true), createElementBlock(Fragment, null, renderList(formattedOptions.value, (option, index) => {
            return openBlock(), createElementBlock("button", {
              key: option.value,
              type: "button",
              tabindex: "-1",
              class: normalizeClass([[
                model.value === option.value ? "htw-bg-primary-500/20" : index === unref(selectedIndex) ? "htw-bg-primary-500/10" : "htw-bg-transparent"
              ], "htw-w-full htw-text-left htw-px-4 htw-py-2 hover:htw-bg-primary-500/10 htw-flex htw-items-center"]),
              onClick: ($event) => model.value = option.value
            }, [
              createElementVNode("span", _hoisted_9, toDisplayString(option.label), 1),
              model.value === option.value ? (openBlock(), createBlock(unref(Icon), {
                key: 0,
                icon: "carbon:checkmark",
                class: "htw-w-4 htw-h-4 htw-text-primary-500"
              })) : createCommentVNode("", true)
            ], 10, _hoisted_8);
          }), 128))
        ])
      ]);
    };
  }
});
export {
  _sfc_main as default
};
