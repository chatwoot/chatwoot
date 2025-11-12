import { computed, resolveDirective, openBlock, unref, createVNode, createElementVNode, createElementBlock, withDirectives, createCommentVNode, defineComponent } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { isDark, toggleDark } from "../../util/dark.js";
import { onKeyboardShortcut } from "../../util/keyboard.js";
import { makeTooltip } from "../../util/tooltip.js";
import { histoireConfig } from "../../util/config.js";
import "./AppLogo.vue.js";
import _sfc_main$1 from "./AppLogo.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-app-header htw-px-4 htw-h-16 htw-flex htw-items-center htw-gap-2" };
const _hoisted_2 = { class: "htw-py-3 sm:htw-py-4 htw-flex-1 htw-h-full htw-flex htw-items-center htw-pr-2" };
const _hoisted_3 = ["href"];
const _hoisted_4 = { class: "htw-ml-auto htw-flex-none htw-flex" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "AppHeader",
  emits: {
    search: () => true
  },
  setup(__props) {
    const themeIcon = computed(() => {
      return isDark.value ? "carbon:moon" : "carbon:sun";
    });
    onKeyboardShortcut(["ctrl+shift+d", "meta+shift+d"], (event) => {
      event.preventDefault();
      toggleDark();
    });
    return (_ctx, _cache) => {
      var _a;
      const _directive_tooltip = resolveDirective("tooltip");
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", _hoisted_2, [
          createElementVNode("a", {
            href: (_a = unref(histoireConfig).theme) == null ? void 0 : _a.logoHref,
            target: "_blank",
            class: "htw-w-full htw-h-full htw-flex htw-items-center"
          }, [
            createVNode(_sfc_main$1, { class: "htw-max-w-full htw-max-h-full" })
          ], 8, _hoisted_3)
        ]),
        createElementVNode("div", _hoisted_4, [
          withDirectives((openBlock(), createElementBlock("a", {
            class: "htw-p-2 sm:htw-p-1 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-text-gray-900 dark:htw-text-gray-100",
            "data-test-id": "search-btn",
            onClick: _cache[0] || (_cache[0] = ($event) => _ctx.$emit("search"))
          }, [
            createVNode(unref(Icon), {
              icon: "carbon:search",
              class: "htw-w-6 htw-h-6 sm:htw-w-4 sm:htw-h-4"
            })
          ])), [
            [_directive_tooltip, unref(makeTooltip)("Search", ({ isMac }) => isMac ? "meta+k" : "ctrl+k")]
          ]),
          !unref(histoireConfig).theme.hideColorSchemeSwitch ? withDirectives((openBlock(), createElementBlock("a", {
            key: 0,
            class: "htw-p-2 sm:htw-p-1 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-text-gray-900 dark:htw-text-gray-100",
            onClick: _cache[1] || (_cache[1] = ($event) => unref(toggleDark)())
          }, [
            createVNode(unref(Icon), {
              icon: themeIcon.value,
              class: "htw-w-6 htw-h-6 sm:htw-w-4 sm:htw-h-4"
            }, null, 8, ["icon"])
          ])), [
            [_directive_tooltip, unref(makeTooltip)("Toggle dark mode", ({ isMac }) => isMac ? "meta+shift+d" : "ctrl+shift+d")]
          ]) : createCommentVNode("", true)
        ])
      ]);
    };
  }
});
export {
  _sfc_main as default
};
