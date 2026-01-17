import { defineComponent, resolveComponent, resolveDirective, openBlock, createBlock, unref, withCtx, createElementVNode, createVNode, createTextVNode, withDirectives, vModelText, createElementBlock, Fragment, renderList, normalizeClass, toDisplayString, createCommentVNode } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { usePreviewSettingsStore } from "../../stores/preview-settings.js";
import { histoireConfig } from "../../util/config.js";
import "../base/BaseCheckbox.vue.js";
import _sfc_main$1 from "../base/BaseCheckbox.vue2.js";
"use strict";
const _hoisted_1 = { class: "htw-flex htw-flex-col htw-items-stretch" };
const _hoisted_2 = { class: "htw-flex htw-items-center htw-gap-2 htw-px-4 htw-py-3" };
const _hoisted_3 = /* @__PURE__ */ createElementVNode("span", { class: "htw-opacity-50" }, "×", -1);
const _hoisted_4 = ["onClick"];
const _hoisted_5 = { class: "htw-ml-auto htw-opacity-70 htw-flex htw-gap-1" };
const _hoisted_6 = { key: 0 };
const _hoisted_7 = { key: 0 };
const _hoisted_8 = { key: 1 };
const _hoisted_9 = { key: 2 };
const _hoisted_10 = { key: 0 };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ToolbarResponsiveSize",
  setup(__props) {
    const settings = usePreviewSettingsStore().currentSettings;
    return (_ctx, _cache) => {
      var _a;
      const _component_VDropdown = resolveComponent("VDropdown");
      const _directive_tooltip = resolveDirective("tooltip");
      return openBlock(), createBlock(_component_VDropdown, {
        placement: "bottom-end",
        skidding: 6,
        disabled: !((_a = unref(histoireConfig).responsivePresets) == null ? void 0 : _a.length),
        class: "histoire-toolbar-responsive-size htw-h-full htw-flex-none"
      }, {
        popper: withCtx(({ hide }) => [
          createElementVNode("div", _hoisted_1, [
            createVNode(_sfc_main$1, {
              modelValue: unref(settings).rotate,
              "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => unref(settings).rotate = $event)
            }, {
              default: withCtx(() => [
                createTextVNode(" Rotate ")
              ]),
              _: 1
            }, 8, ["modelValue"]),
            createElementVNode("div", _hoisted_2, [
              withDirectives(createElementVNode("input", {
                "onUpdate:modelValue": _cache[1] || (_cache[1] = ($event) => unref(settings).responsiveWidth = $event),
                type: "number",
                class: "htw-bg-transparent htw-border htw-border-gray-200 dark:htw-border-gray-850 htw-rounded htw-w-20 htw-opacity-50 focus:htw-opacity-100 htw-flex-1 htw-min-w-0",
                step: "16",
                placeholder: "Auto"
              }, null, 512), [
                [
                  vModelText,
                  unref(settings).responsiveWidth,
                  void 0,
                  { number: true }
                ],
                [_directive_tooltip, "Responsive width (px)"]
              ]),
              _hoisted_3,
              withDirectives(createElementVNode("input", {
                "onUpdate:modelValue": _cache[2] || (_cache[2] = ($event) => unref(settings).responsiveHeight = $event),
                type: "number",
                class: "htw-bg-transparent htw-border htw-border-gray-200 dark:htw-border-gray-850 htw-rounded htw-w-20 htw-opacity-50 focus:htw-opacity-100 htw-flex-1 htw-min-w-0",
                step: "16",
                placeholder: "Auto"
              }, null, 512), [
                [
                  vModelText,
                  unref(settings).responsiveHeight,
                  void 0,
                  { number: true }
                ],
                [_directive_tooltip, "Responsive height (px)"]
              ])
            ]),
            (openBlock(true), createElementBlock(Fragment, null, renderList(unref(histoireConfig).responsivePresets, (preset, index) => {
              return openBlock(), createElementBlock("button", {
                key: index,
                class: normalizeClass(["htw-px-4 htw-py-3 htw-cursor-pointer htw-text-left htw-flex htw-gap-4", [
                  unref(settings).responsiveWidth === preset.width && unref(settings).responsiveHeight === preset.height ? "htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black" : "htw-bg-transparent hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700"
                ]]),
                onClick: ($event) => {
                  unref(settings).responsiveWidth = preset.width;
                  unref(settings).responsiveHeight = preset.height;
                  hide();
                }
              }, [
                createTextVNode(toDisplayString(preset.label) + " ", 1),
                createElementVNode("span", _hoisted_5, [
                  preset.width ? (openBlock(), createElementBlock("span", _hoisted_6, [
                    createTextVNode(toDisplayString(preset.width), 1),
                    !preset.height ? (openBlock(), createElementBlock("span", _hoisted_7, "px")) : createCommentVNode("", true)
                  ])) : createCommentVNode("", true),
                  preset.width && preset.height ? (openBlock(), createElementBlock("span", _hoisted_8, "x")) : createCommentVNode("", true),
                  preset.height ? (openBlock(), createElementBlock("span", _hoisted_9, [
                    createTextVNode(toDisplayString(preset.height), 1),
                    !preset.width ? (openBlock(), createElementBlock("span", _hoisted_10, "px")) : createCommentVNode("", true)
                  ])) : createCommentVNode("", true)
                ])
              ], 10, _hoisted_4);
            }), 128))
          ])
        ]),
        default: withCtx(() => {
          var _a2;
          return [
            withDirectives((openBlock(), createElementBlock("div", {
              class: normalizeClass(["htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 htw-group", {
                "htw-cursor-pointer hover:htw-text-primary-500": (_a2 = unref(histoireConfig).responsivePresets) == null ? void 0 : _a2.length
              }])
            }, [
              createVNode(unref(Icon), {
                icon: "carbon:devices",
                class: "htw-w-4 htw-h-4 htw-opacity-50 group-hover:htw-opacity-100"
              }),
              createVNode(unref(Icon), {
                icon: "carbon:caret-down",
                class: "htw-w-4 htw-h-4 htw-opacity-50 group-hover:htw-opacity-100"
              })
            ], 2)), [
              [_directive_tooltip, "Responsive sizes"]
            ])
          ];
        }),
        _: 1
      }, 8, ["disabled"]);
    };
  }
});
export {
  _sfc_main as default
};
