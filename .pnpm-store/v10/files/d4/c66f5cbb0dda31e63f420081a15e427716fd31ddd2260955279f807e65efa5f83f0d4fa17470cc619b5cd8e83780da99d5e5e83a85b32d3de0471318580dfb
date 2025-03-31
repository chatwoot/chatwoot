import { pushScopeId, popScopeId, useCssVars, computed, resolveComponent, openBlock, withKeys, unref, normalizeClass, createVNode, createElementVNode, toDisplayString, Fragment, createBlock, createElementBlock, renderList, createCommentVNode, defineComponent } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useFolderStore } from "../../stores/folder.js";
import StoryListItem from "./StoryListItem.vue.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-cace6303"), n = n(), popScopeId(), n);
const _hoisted_1 = {
  "data-test-id": "story-list-folder",
  class: "histoire-story-list-folder"
};
const _hoisted_2 = ["onKeyup"];
const _hoisted_3 = { class: "bind-tree-padding htw-flex htw-items-center htw-gap-2 htw-min-w-0" };
const _hoisted_4 = { class: "htw-flex htw-flex-none htw-items-center htw-opacity-30 [.histoire-story-list-folder-button:hover_&]:htw-opacity-100 htw-ml-4 htw-w-4 htw-h-4 htw-rounded-sm htw-border htw-border-gray-500/40" };
const _hoisted_5 = { class: "htw-truncate" };
const _hoisted_6 = { key: 0 };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryListFolder",
  props: {
    path: { default: () => [] },
    folder: {},
    stories: {},
    depth: { default: 0 }
  },
  setup(__props) {
    useCssVars((_ctx) => ({
      "1ee776cd": folderPadding.value
    }));
    const props = __props;
    const folderStore = useFolderStore();
    const folderPath = computed(() => [...props.path, props.folder.title]);
    const isFolderOpen = computed(() => folderStore.isFolderOpened(folderPath.value));
    function toggleOpen() {
      folderStore.toggleFolder(folderPath.value);
    }
    const folderPadding = computed(() => {
      return `${props.depth * 12}px`;
    });
    return (_ctx, _cache) => {
      const _component_StoryListFolder = resolveComponent("StoryListFolder", true);
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", {
          role: "button",
          tabindex: "0",
          class: "histoire-story-list-folder-button htw-px-0.5 htw-py-2 md:htw-py-1.5 htw-mx-1 htw-rounded-sm hover:htw-bg-primary-100 dark:hover:htw-bg-primary-900 htw-cursor-pointer htw-select-none htw-flex",
          onClick: toggleOpen,
          onKeyup: [
            withKeys(toggleOpen, ["enter"]),
            withKeys(toggleOpen, ["space"])
          ]
        }, [
          createElementVNode("span", _hoisted_3, [
            createElementVNode("span", _hoisted_4, [
              createVNode(unref(Icon), {
                icon: "carbon:caret-right",
                class: normalizeClass(["htw-w-full htw-h-full htw-transition-transform htw-duration-150", {
                  "htw-rotate-90": isFolderOpen.value
                }])
              }, null, 8, ["class"])
            ]),
            createElementVNode("span", _hoisted_5, toDisplayString(_ctx.folder.title), 1)
          ])
        ], 40, _hoisted_2),
        isFolderOpen.value ? (openBlock(), createElementBlock("div", _hoisted_6, [
          (openBlock(true), createElementBlock(Fragment, null, renderList(_ctx.folder.children, (element) => {
            return openBlock(), createElementBlock(Fragment, {
              key: element.title
            }, [
              element.children ? (openBlock(), createBlock(_component_StoryListFolder, {
                key: 0,
                path: folderPath.value,
                folder: element,
                stories: _ctx.stories,
                depth: _ctx.depth + 1
              }, null, 8, ["path", "folder", "stories", "depth"])) : (openBlock(), createBlock(StoryListItem, {
                key: 1,
                story: _ctx.stories[element.index],
                depth: _ctx.depth + 1
              }, null, 8, ["story", "depth"]))
            ], 64);
          }), 128))
        ])) : createCommentVNode("", true)
      ]);
    };
  }
});
export {
  _sfc_main as default
};
