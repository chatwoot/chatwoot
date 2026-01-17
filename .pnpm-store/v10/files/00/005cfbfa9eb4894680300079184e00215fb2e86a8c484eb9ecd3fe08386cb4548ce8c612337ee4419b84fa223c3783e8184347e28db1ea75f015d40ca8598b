import { defineComponent, useCssVars, unref, computed, resolveComponent, resolveDirective, openBlock, createBlock, withCtx, createElementVNode, createVNode, createTextVNode, createElementBlock, Fragment, renderList, normalizeClass, toDisplayString, normalizeStyle, createCommentVNode, withDirectives, pushScopeId, popScopeId } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { usePreviewSettingsStore } from "../../stores/preview-settings.js";
import { histoireConfig } from "../../util/config.js";
import { getContrastColor } from "../../util/preview-settings.js";
import "../base/BaseCheckbox.vue.js";
import _sfc_main$1 from "../base/BaseCheckbox.vue2.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-c48fb2b2"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "htw-cursor-pointer hover:htw-text-primary-500 htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 htw-group" };
const _hoisted_2 = { class: "bind-preview-bg htw-w-4 htw-h-4 htw-rounded-full htw-border htw-border-black/50 dark:htw-border-white/50 htw-flex htw-items-center htw-justify-center htw-text-xs" };
const _hoisted_3 = { key: 0 };
const _hoisted_4 = {
  class: "htw-flex htw-flex-col htw-items-stretch",
  "data-test-id": "background-popper"
};
const _hoisted_5 = ["onClick"];
const _hoisted_6 = { class: "htw-mr-auto" };
const _hoisted_7 = { class: "htw-ml-auto htw-opacity-70" };
const _hoisted_8 = { key: 0 };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ToolbarBackground",
  setup(__props) {
    useCssVars((_ctx) => ({
      "627bec82": unref(settings).backgroundColor,
      "35068428": contrastColor.value
    }));
    const settings = usePreviewSettingsStore().currentSettings;
    const contrastColor = computed(() => getContrastColor(settings));
    return (_ctx, _cache) => {
      const _component_VDropdown = resolveComponent("VDropdown");
      const _directive_tooltip = resolveDirective("tooltip");
      return unref(histoireConfig).backgroundPresets.length ? (openBlock(), createBlock(_component_VDropdown, {
        key: 0,
        placement: "bottom-end",
        skidding: 6,
        class: "histoire-toolbar-background htw-h-full htw-flex-none",
        "data-test-id": "toolbar-background"
      }, {
        popper: withCtx(({ hide }) => [
          createElementVNode("div", _hoisted_4, [
            createVNode(_sfc_main$1, {
              modelValue: unref(settings).checkerboard,
              "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => unref(settings).checkerboard = $event)
            }, {
              default: withCtx(() => [
                createTextVNode(" Checkerboard ")
              ]),
              _: 1
            }, 8, ["modelValue"]),
            (openBlock(true), createElementBlock(Fragment, null, renderList(unref(histoireConfig).backgroundPresets, (option, index) => {
              return openBlock(), createElementBlock("button", {
                key: index,
                class: normalizeClass(["htw-px-4 htw-py-3 htw-cursor-pointer htw-text-left htw-flex htw-items-baseline htw-gap-4", [
                  unref(settings).backgroundColor === option.color ? "htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black" : "htw-bg-transparent hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700"
                ]]),
                onClick: ($event) => {
                  unref(settings).backgroundColor = option.color;
                  hide();
                }
              }, [
                createElementVNode("span", _hoisted_6, toDisplayString(option.label), 1),
                option.color !== "$checkerboard" ? (openBlock(), createElementBlock(Fragment, { key: 0 }, [
                  createElementVNode("span", _hoisted_7, toDisplayString(option.color), 1),
                  createElementVNode("div", {
                    class: "htw-w-4 htw-h-4 htw-rounded-full htw-border htw-border-black/20 dark:htw-border-white/20 htw-flex htw-items-center htw-justify-center htw-text-xs",
                    style: normalizeStyle({
                      backgroundColor: option.color,
                      color: option.contrastColor
                    })
                  }, [
                    option.contrastColor ? (openBlock(), createElementBlock("span", _hoisted_8, "a")) : createCommentVNode("", true)
                  ], 4)
                ], 64)) : createCommentVNode("", true)
              ], 10, _hoisted_5);
            }), 128))
          ])
        ]),
        default: withCtx(() => [
          withDirectives((openBlock(), createElementBlock("div", _hoisted_1, [
            createElementVNode("div", _hoisted_2, [
              contrastColor.value ? (openBlock(), createElementBlock("span", _hoisted_3, "a")) : createCommentVNode("", true)
            ]),
            createVNode(unref(Icon), {
              icon: "carbon:caret-down",
              class: "htw-w-4 htw-h-4 htw-opacity-50 group-hover:htw-opacity-100"
            })
          ])), [
            [_directive_tooltip, "Background color"]
          ])
        ]),
        _: 1
      })) : createCommentVNode("", true);
    };
  }
});
export {
  _sfc_main as default
};
