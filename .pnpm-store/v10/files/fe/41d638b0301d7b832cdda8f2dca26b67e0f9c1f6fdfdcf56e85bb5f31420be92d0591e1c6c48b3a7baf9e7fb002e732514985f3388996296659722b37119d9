import { defineComponent, ref, watchEffect, markRaw, shallowRef, watch, computed, onMounted, nextTick, resolveDirective, openBlock, createElementBlock, createElementVNode, withDirectives, normalizeClass, createVNode, unref, createCommentVNode, toDisplayString, createBlock, withCtx, pushScopeId, popScopeId } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { getHighlighter } from "shiki-es";
import { HstCopyIcon } from "@histoire/controls";
import { unindent } from "@histoire/shared";
import { clientSupportPlugins } from "virtual:$histoire-support-plugins-client";
import { isDark } from "../../util/dark.js";
import BaseEmpty from "../base/BaseEmpty.vue.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-f7d2e46a"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "histoire-story-source-code htw-bg-gray-50 dark:htw-bg-gray-750 htw-h-full htw-overflow-hidden htw-flex htw-flex-col" };
const _hoisted_2 = {
  key: 0,
  class: "htw-h-10 htw-flex-none htw-border-b htw-border-solid htw-border-gray-500/5 htw-px-4 htw-flex htw-items-center htw-gap-2"
};
const _hoisted_3 = /* @__PURE__ */ _withScopeId(() => /* @__PURE__ */ createElementVNode("div", { class: "htw-text-gray-900 dark:htw-text-gray-100" }, " Source ", -1));
const _hoisted_4 = /* @__PURE__ */ _withScopeId(() => /* @__PURE__ */ createElementVNode("div", { class: "htw-flex-1" }, null, -1));
const _hoisted_5 = { class: "htw-flex htw-flex-none htw-gap-px htw-h-full htw-py-2" };
const _hoisted_6 = {
  key: 1,
  class: "htw-text-red-500 htw-h-full htw-p-2 htw-overflow-auto htw-font-mono htw-text-sm"
};
const _hoisted_7 = /* @__PURE__ */ _withScopeId(() => /* @__PURE__ */ createElementVNode("span", null, "Not available", -1));
const _hoisted_8 = ["value"];
const _hoisted_9 = ["innerHTML"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StorySourceCode",
  props: {
    story: {},
    variant: {}
  },
  setup(__props) {
    const props = __props;
    const generateSourceCodeFn = ref(null);
    watchEffect(async () => {
      var _a;
      const clientPlugin = clientSupportPlugins[(_a = props.story.file) == null ? void 0 : _a.supportPluginId];
      if (clientPlugin) {
        const pluginModule = await clientPlugin();
        generateSourceCodeFn.value = markRaw(pluginModule.generateSourceCode);
      }
    });
    const highlighter = shallowRef();
    const dynamicSourceCode = ref("");
    const error = ref(null);
    watch(() => [props.variant, generateSourceCodeFn.value], async () => {
      var _a, _b, _c, _d;
      if (!generateSourceCodeFn.value)
        return;
      error.value = null;
      dynamicSourceCode.value = "";
      try {
        if (props.variant.source) {
          dynamicSourceCode.value = props.variant.source;
        } else if ((_b = (_a = props.variant).slots) == null ? void 0 : _b.call(_a).source) {
          const source = (_d = (_c = props.variant).slots) == null ? void 0 : _d.call(_c).source()[0].children;
          if (source) {
            dynamicSourceCode.value = await unindent(source);
          }
        } else {
          dynamicSourceCode.value = await generateSourceCodeFn.value(props.variant);
        }
      } catch (e) {
        console.error(e);
        error.value = e.message;
      }
      if (!dynamicSourceCode.value) {
        displayedSource.value = "static";
      }
    }, {
      deep: true,
      immediate: true
    });
    const staticSourceCode = ref("");
    watch(() => {
      var _a, _b;
      return [props.story, (_b = (_a = props.story) == null ? void 0 : _a.file) == null ? void 0 : _b.source];
    }, async () => {
      var _a;
      staticSourceCode.value = "";
      const sourceLoader = (_a = props.story.file) == null ? void 0 : _a.source;
      if (sourceLoader) {
        staticSourceCode.value = (await sourceLoader()).default;
      }
    }, {
      immediate: true
    });
    const displayedSource = ref("dynamic");
    const displayedSourceCode = computed(() => {
      if (displayedSource.value === "dynamic") {
        return dynamicSourceCode.value;
      }
      return staticSourceCode.value;
    });
    onMounted(async () => {
      highlighter.value = await getHighlighter({
        langs: [
          "html",
          "jsx"
        ],
        themes: [
          "github-light",
          "github-dark"
        ]
      });
    });
    const sourceHtml = computed(() => {
      var _a;
      return displayedSourceCode.value ? (_a = highlighter.value) == null ? void 0 : _a.codeToHtml(displayedSourceCode.value, {
        lang: "html",
        theme: isDark.value ? "github-dark" : "github-light"
      }) : "";
    });
    let lastScroll = 0;
    watch(() => props.variant, () => {
      lastScroll = 0;
    });
    const scroller = ref();
    function onScroll(event) {
      if (sourceHtml.value) {
        lastScroll = event.target.scrollTop;
      }
    }
    watch(sourceHtml, async () => {
      await nextTick();
      if (scroller.value) {
        scroller.value.scrollTop = lastScroll;
      }
    });
    return (_ctx, _cache) => {
      const _directive_tooltip = resolveDirective("tooltip");
      return openBlock(), createElementBlock("div", _hoisted_1, [
        !error.value ? (openBlock(), createElementBlock("div", _hoisted_2, [
          _hoisted_3,
          _hoisted_4,
          createElementVNode("div", _hoisted_5, [
            withDirectives((openBlock(), createElementBlock("button", {
              class: normalizeClass(["htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-1 htw-bg-gray-500/10 htw-rounded-l htw-transition-all htw-ease-[cubic-bezier(0,1,.6,1)] htw-duration-300 htw-overflow-hidden", [
                displayedSource.value !== "dynamic" ? "htw-max-w-6 htw-opacity-70" : "htw-max-w-[82px] htw-text-primary-600 dark:htw-text-primary-400",
                dynamicSourceCode.value ? "htw-cursor-pointer hover:htw-bg-gray-500/30 active:htw-bg-gray-600/50" : "htw-opacity-50"
              ]]),
              onClick: _cache[0] || (_cache[0] = ($event) => dynamicSourceCode.value && (displayedSource.value = "dynamic"))
            }, [
              createVNode(unref(Icon), {
                icon: "carbon:flash",
                class: "htw-w-4 htw-h-4 htw-flex-none"
              }),
              createElementVNode("span", {
                class: normalizeClass(["transition-opacity duration-300", {
                  "opacity-0": displayedSource.value !== "dynamic"
                }])
              }, " Dynamic ", 2)
            ], 2)), [
              [_directive_tooltip, !dynamicSourceCode.value ? "Dynamic source code is not available" : displayedSource.value !== "dynamic" ? "Switch to dynamic source" : null]
            ]),
            withDirectives((openBlock(), createElementBlock("button", {
              class: normalizeClass(["htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-1 htw-bg-gray-500/10 htw-rounded-r htw-transition-all htw-ease-[cubic-bezier(0,1,.6,1)] htw-duration-300 htw-overflow-hidden", [
                displayedSource.value !== "static" ? "htw-max-w-6 htw-opacity-70" : "htw-max-w-[63px] htw-text-primary-600 dark:htw-text-primary-400",
                staticSourceCode.value ? "htw-cursor-pointer hover:htw-bg-gray-500/30 active:htw-bg-gray-600/50" : "htw-opacity-50"
              ]]),
              onClick: _cache[1] || (_cache[1] = ($event) => staticSourceCode.value && (displayedSource.value = "static"))
            }, [
              createVNode(unref(Icon), {
                icon: "carbon:document",
                class: "htw-w-4 htw-h-4 htw-flex-none"
              }),
              createElementVNode("span", {
                class: normalizeClass(["transition-opacity duration-300", {
                  "opacity-0": displayedSource.value !== "static"
                }])
              }, " Static ", 2)
            ], 2)), [
              [_directive_tooltip, !staticSourceCode.value ? "Static source code is not available" : displayedSource.value !== "static" ? "Switch to static source" : null]
            ])
          ]),
          createVNode(unref(HstCopyIcon), {
            content: displayedSourceCode.value,
            class: "htw-flex-none"
          }, null, 8, ["content"])
        ])) : createCommentVNode("", true),
        error.value ? (openBlock(), createElementBlock("div", _hoisted_6, " Error: " + toDisplayString(error.value), 1)) : !displayedSourceCode.value ? (openBlock(), createBlock(BaseEmpty, { key: 2 }, {
          default: withCtx(() => [
            createVNode(unref(Icon), {
              icon: "carbon:code-hide",
              class: "htw-w-8 htw-h-8 htw-opacity-50 htw-mb-6"
            }),
            _hoisted_7
          ]),
          _: 1
        })) : !sourceHtml.value ? (openBlock(), createElementBlock("textarea", {
          key: 3,
          ref_key: "scroller",
          ref: scroller,
          class: "__histoire-code-placeholder htw-w-full htw-h-full htw-p-4 htw-outline-none htw-bg-transparent htw-resize-none htw-m-0",
          value: displayedSourceCode.value,
          readonly: "",
          "data-test-id": "story-source-code",
          onScroll
        }, null, 40, _hoisted_8)) : (openBlock(), createElementBlock("div", {
          key: 4,
          ref_key: "scroller",
          ref: scroller,
          class: "htw-w-full htw-h-full htw-overflow-auto",
          "data-test-id": "story-source-code",
          onScroll
        }, [
          createElementVNode("div", {
            class: "__histoire-code htw-p-4 htw-w-fit",
            innerHTML: sourceHtml.value
          }, null, 8, _hoisted_9)
        ], 544))
      ]);
    };
  }
});
export {
  _sfc_main as default
};
