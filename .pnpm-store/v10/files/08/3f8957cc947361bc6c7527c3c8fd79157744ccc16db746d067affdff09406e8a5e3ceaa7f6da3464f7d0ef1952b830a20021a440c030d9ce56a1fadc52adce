import { pushScopeId, popScopeId, createElementVNode, useCssVars, computed, ref, watch, openBlock, Fragment, toDisplayString, createElementBlock, renderList, unref, normalizeClass, createVNode, createTextVNode, withCtx, defineComponent } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useStoryStore } from "../../stores/story.js";
import "../tree/StoryList.vue.js";
import "./MobileOverlay.vue.js";
import _sfc_main$1 from "./MobileOverlay.vue2.js";
import _sfc_main$2 from "../tree/StoryList.vue2.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-b8625753"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "histoire-breadcrumb" };
const _hoisted_2 = /* @__PURE__ */ _withScopeId(() => /* @__PURE__ */ createElementVNode("span", { class: "htw-opacity-40" }, " / ", -1));
const _hoisted_3 = { class: "htw-flex htw-items-center htw-gap-2" };
const _hoisted_4 = { class: "htw-opacity-40 htw-text-sm" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "Breadcrumb",
  props: {
    tree: {},
    stories: {}
  },
  setup(__props) {
    useCssVars((_ctx) => {
      var _a;
      return {
        "6509026e": (_a = story.value) == null ? void 0 : _a.iconColor
      };
    });
    const storyStore = useStoryStore();
    const story = computed(() => storyStore.currentStory);
    const folders = computed(() => {
      return story.value.file.path.slice(0, -1);
    });
    const isMenuOpened = ref(false);
    function openMenu() {
      isMenuOpened.value = true;
    }
    function closeMenu() {
      isMenuOpened.value = false;
    }
    watch(story, () => {
      isMenuOpened.value = false;
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock(Fragment, null, [
        createElementVNode("div", _hoisted_1, [
          createElementVNode("a", {
            class: "htw-px-6 htw-h-12 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-flex htw-gap-2 htw-flex-wrap htw-w-full htw-items-center",
            onClick: openMenu
          }, [
            story.value ? (openBlock(), createElementBlock(Fragment, { key: 0 }, [
              (openBlock(true), createElementBlock(Fragment, null, renderList(folders.value, (file, key) => {
                return openBlock(), createElementBlock(Fragment, { key }, [
                  createElementVNode("span", null, toDisplayString(file), 1),
                  _hoisted_2
                ], 64);
              }), 128)),
              createElementVNode("span", _hoisted_3, [
                createVNode(unref(Icon), {
                  icon: story.value.icon ?? "carbon:cube",
                  class: normalizeClass(["htw-w-5 htw-h-5 htw-flex-none", {
                    "htw-text-primary-500": !story.value.iconColor,
                    "bind-icon-color": story.value.iconColor
                  }])
                }, null, 8, ["icon", "class"]),
                createTextVNode(" " + toDisplayString(story.value.title) + " ", 1),
                createElementVNode("span", _hoisted_4, toDisplayString(story.value.variants.length), 1)
              ])
            ], 64)) : (openBlock(), createElementBlock(Fragment, { key: 1 }, [
              createTextVNode(" Select a story... ")
            ], 64)),
            createVNode(unref(Icon), {
              icon: "carbon:chevron-sort",
              class: "htw-w-5 htw-h-5 htw-shrink-0 htw-ml-auto"
            })
          ])
        ]),
        createVNode(_sfc_main$1, {
          title: "Select a story",
          opened: isMenuOpened.value,
          onClose: closeMenu
        }, {
          default: withCtx(() => [
            createVNode(_sfc_main$2, {
              tree: _ctx.tree,
              stories: _ctx.stories,
              class: "htw-flex-1 htw-overflow-y-scroll"
            }, null, 8, ["tree", "stories"])
          ]),
          _: 1
        }, 8, ["opened"])
      ], 64);
    };
  }
});
export {
  _sfc_main as default
};
