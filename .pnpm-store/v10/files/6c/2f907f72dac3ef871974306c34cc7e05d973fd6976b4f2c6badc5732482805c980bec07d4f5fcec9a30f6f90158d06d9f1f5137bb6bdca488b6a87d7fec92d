import { ref, computed, watch, onMounted, resolveComponent, openBlock, Fragment, unref, createBlock, createElementBlock, createCommentVNode, normalizeStyle, createVNode, createElementVNode, withCtx, Transition, defineComponent } from "@histoire/vendors/vue";
import { files, tree, onUpdate } from "virtual:$histoire-stories";
import { useTitle } from "@histoire/vendors/vue-use";
import "./components/tree/StoryList.vue.js";
import BaseSplitPane from "./components/base/BaseSplitPane.vue.js";
import "./components/app/AppHeader.vue.js";
import { useStoryStore } from "./stores/story.js";
import { mapFile } from "./util/mapping.js";
import { histoireConfig } from "./util/config.js";
import { onKeyboardShortcut } from "./util/keyboard.js";
import { isMobile } from "./util/responsive.js";
import { useCommandStore } from "./stores/command.js";
import Breadcrumb from "./components/app/Breadcrumb.vue.js";
import "./components/search/SearchModal.vue.js";
import "./components/command/CommandPromptsModal.vue.js";
import "./components/app/InitialLoading.vue.js";
import "./components/story/GenericMountStory.vue.js";
import _sfc_main$1 from "./components/story/GenericMountStory.vue2.js";
import _sfc_main$2 from "./components/app/AppHeader.vue2.js";
import _sfc_main$3 from "./components/tree/StoryList.vue2.js";
import _sfc_main$4 from "./components/search/SearchModal.vue2.js";
import _sfc_main$5 from "./components/command/CommandPromptsModal.vue2.js";
import _sfc_main$6 from "./components/app/InitialLoading.vue2.js";
"use strict";
const _hoisted_1 = {
  key: 0,
  class: "histoire-app htw-hidden"
};
const _hoisted_2 = {
  key: 0,
  class: "htw-h-full htw-flex htw-flex-col htw-divide-y htw-divide-gray-100 dark:htw-divide-gray-800"
};
const _hoisted_3 = { class: "htw-flex htw-flex-col htw-h-full htw-bg-gray-100 dark:htw-bg-gray-750 __histoire-pane-shadow-from-right" };
const __default__ = {
  name: "HistoireApp"
};
const _sfc_main = /* @__PURE__ */ defineComponent({
  ...__default__,
  setup(__props) {
    const files$1 = ref(files.map((file) => mapFile(file)));
    const tree$1 = ref(tree);
    onUpdate((newFiles, newTree) => {
      loading.value = false;
      files$1.value = newFiles.map((file) => {
        const existingFile = files$1.value.find((f) => f.id === file.id);
        return mapFile(file, existingFile);
      });
      tree$1.value = newTree;
    });
    const stories = computed(() => files$1.value.reduce((acc, file) => {
      acc.push(file.story);
      return acc;
    }, []));
    const storyStore = useStoryStore();
    watch(stories, (value) => {
      storyStore.setStories(value);
    }, {
      immediate: true
    });
    useTitle(computed(() => {
      if (storyStore.currentStory) {
        let title = storyStore.currentStory.title;
        if (storyStore.currentVariant) {
          title += ` › ${storyStore.currentVariant.title}`;
        }
        return `${title} | ${histoireConfig.theme.title}`;
      }
      return histoireConfig.theme.title;
    }));
    const loadSearch = ref(false);
    const isSearchOpen = ref(false);
    watch(isSearchOpen, (value) => {
      if (value) {
        loadSearch.value = true;
      }
    });
    onKeyboardShortcut(["ctrl+k", "meta+k"], (event) => {
      isSearchOpen.value = true;
      event.preventDefault();
    });
    const loading = ref(false);
    if (import.meta.hot && !files.length) {
      loading.value = true;
      import.meta.hot.on("histoire:all-stories-loaded", () => {
        loading.value = false;
      });
    }
    const mounted = ref(false);
    onMounted(() => {
      mounted.value = true;
    });
    const commandStore = useCommandStore();
    return (_ctx, _cache) => {
      const _component_RouterView = resolveComponent("RouterView");
      return openBlock(), createElementBlock(Fragment, null, [
        unref(storyStore).currentStory ? (openBlock(), createElementBlock("div", _hoisted_1, [
          (openBlock(), createBlock(_sfc_main$1, {
            key: unref(storyStore).currentStory.id,
            story: unref(storyStore).currentStory
          }, null, 8, ["story"]))
        ])) : createCommentVNode("", true),
        createElementVNode("div", {
          class: "htw-h-screen htw-bg-white dark:htw-bg-gray-700 dark:htw-text-gray-100",
          style: normalizeStyle({
            // Prevent flash of content
            opacity: mounted.value ? 1 : 0
          })
        }, [
          unref(isMobile) ? (openBlock(), createElementBlock("div", _hoisted_2, [
            createVNode(_sfc_main$2, {
              onSearch: _cache[0] || (_cache[0] = ($event) => isSearchOpen.value = true)
            }),
            createVNode(Breadcrumb, {
              tree: tree$1.value,
              stories: stories.value
            }, null, 8, ["tree", "stories"]),
            createVNode(_component_RouterView, { class: "htw-grow" })
          ])) : (openBlock(), createBlock(BaseSplitPane, {
            key: 1,
            "save-id": "main-horiz",
            min: 5,
            max: 50,
            "default-split": 15,
            class: "htw-h-full"
          }, {
            first: withCtx(() => [
              createElementVNode("div", _hoisted_3, [
                createVNode(_sfc_main$2, {
                  class: "htw-flex-none",
                  onSearch: _cache[1] || (_cache[1] = ($event) => isSearchOpen.value = true)
                }),
                createVNode(_sfc_main$3, {
                  tree: tree$1.value,
                  stories: stories.value,
                  class: "htw-flex-1"
                }, null, 8, ["tree", "stories"])
              ])
            ]),
            last: withCtx(() => [
              createVNode(_component_RouterView)
            ]),
            _: 1
          })),
          loadSearch.value ? (openBlock(), createBlock(_sfc_main$4, {
            key: 2,
            shown: isSearchOpen.value,
            onClose: _cache[2] || (_cache[2] = ($event) => isSearchOpen.value = false)
          }, null, 8, ["shown"])) : createCommentVNode("", true),
          _ctx.__HISTOIRE_DEV__ ? (openBlock(), createBlock(_sfc_main$5, {
            key: 3,
            shown: unref(commandStore).showPromptsModal,
            onClose: _cache[3] || (_cache[3] = ($event) => unref(commandStore).showPromptsModal = false)
          }, null, 8, ["shown"])) : createCommentVNode("", true)
        ], 4),
        createVNode(Transition, { name: "__histoire-fade" }, {
          default: withCtx(() => [
            loading.value ? (openBlock(), createBlock(_sfc_main$6, { key: 0 })) : createCommentVNode("", true)
          ]),
          _: 1
        })
      ], 64);
    };
  }
});
export {
  _sfc_main as default
};
