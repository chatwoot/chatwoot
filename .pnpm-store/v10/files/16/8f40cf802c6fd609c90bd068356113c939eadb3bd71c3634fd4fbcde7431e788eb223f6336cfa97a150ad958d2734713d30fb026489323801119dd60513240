import { defineComponent, reactive, ref, onMounted, openBlock, createElementBlock, withModifiers, withKeys, createElementVNode, toDisplayString, Fragment, renderList, createBlock, resolveDynamicComponent, createVNode, withCtx, nextTick } from "@histoire/vendors/vue";
import { getCommandContext, executeCommand } from "../../util/commands.js";
import "../base/BaseButton.vue.js";
import "../base/BaseKeyboardShortcut.vue.js";
import "./PromptText.vue.js";
import "./PromptSelect.vue.js";
import _sfc_main$1 from "../base/BaseButton.vue2.js";
import _sfc_main$2 from "../base/BaseKeyboardShortcut.vue2.js";
import _sfc_main$3 from "./PromptText.vue2.js";
import _sfc_main$4 from "./PromptSelect.vue2.js";
"use strict";
const _hoisted_1 = { class: "htw-p-4 htw-opacity-70" };
const _hoisted_2 = { class: "htw-flex htw-justify-end htw-gap-2 htw-p-2" };
const _hoisted_3 = /* @__PURE__ */ createElementVNode("span", null, "Submit", -1);
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "CommandPrompts",
  props: {
    command: {}
  },
  emits: ["close"],
  setup(__props, { emit: __emit }) {
    const props = __props;
    const emit = __emit;
    const promptTypes = {
      text: _sfc_main$3,
      select: _sfc_main$4
    };
    const answers = reactive({});
    for (const prompt of props.command.prompts) {
      let defaultValue;
      if (typeof prompt.defaultValue === "function") {
        defaultValue = prompt.defaultValue(answers);
      } else {
        defaultValue = prompt.defaultValue;
      }
      answers[prompt.field] = defaultValue;
    }
    function submit() {
      const params = props.command.getParams ? props.command.getParams({
        ...getCommandContext(),
        answers
      }) : answers;
      executeCommand(props.command, params);
      emit("close");
    }
    const promptComps = ref([]);
    function focusPrompt(index) {
      nextTick(() => {
        var _a, _b;
        (_b = (_a = promptComps.value[index]) == null ? void 0 : _a.focus) == null ? void 0 : _b.call(_a);
      });
    }
    onMounted(() => {
      focusPrompt(0);
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("form", {
        class: "histoire-command-prompts htw-flex htw-flex-col",
        onSubmit: _cache[0] || (_cache[0] = withModifiers(($event) => submit(), ["prevent"])),
        onKeyup: _cache[1] || (_cache[1] = withKeys(($event) => _ctx.$emit("close"), ["escape"]))
      }, [
        createElementVNode("div", _hoisted_1, toDisplayString(_ctx.command.label), 1),
        (openBlock(true), createElementBlock(Fragment, null, renderList(_ctx.command.prompts, (prompt, index) => {
          return openBlock(), createBlock(resolveDynamicComponent(promptTypes[prompt.type]), {
            key: prompt.field,
            ref_for: true,
            ref_key: "promptComps",
            ref: promptComps,
            modelValue: answers[prompt.field],
            "onUpdate:modelValue": ($event) => answers[prompt.field] = $event,
            prompt,
            answers,
            index,
            class: "hover:htw-bg-gray-500/10 focus-within:htw-bg-gray-500/5",
            onNext: ($event) => focusPrompt(index + 1)
          }, null, 40, ["modelValue", "onUpdate:modelValue", "prompt", "answers", "index", "onNext"]);
        }), 128)),
        createElementVNode("div", _hoisted_2, [
          createVNode(_sfc_main$1, {
            type: "submit",
            class: "htw-px-4 htw-py-2 htw-flex htw-items-start htw-gap-2"
          }, {
            default: withCtx(() => [
              createVNode(_sfc_main$2, { shortcut: "Enter" }),
              _hoisted_3
            ]),
            _: 1
          })
        ])
      ], 32);
    };
  }
});
export {
  _sfc_main as default
};
