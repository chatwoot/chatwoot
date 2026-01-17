import { createElementVNode, computed, openBlock, Fragment, withKeys, unref, createVNode, toDisplayString, createElementBlock, createCommentVNode, createBlock, renderList, defineComponent } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useFolderStore } from "../../stores/folder.js";
import StoryListItem from "./StoryListItem.vue.js";
import StoryListFolder from "./StoryListFolder.vue.js";
"use strict";
const _hoisted_1 = {
  "data-test-id": "story-group",
  class: "histoire-story-group htw-my-2 first:htw-mt-0 last:htw-mb-0 htw-group"
};
const _hoisted_2 = /* @__PURE__ */ createElementVNode("div", { class: "htw-h-[1px] htw-bg-gray-500/10 htw-mx-6 htw-mb-2 group-first:htw-hidden" }, null, -1);
const _hoisted_3 = ["onKeyup"];
const _hoisted_4 = { class: "htw-truncate" };
const _hoisted_5 = { key: 1 };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryGroup",
  props: {
    path: { default: () => [] },
    group: {},
    stories: {}
  },
  setup(__props) {
    const props = __props;
    const folderStore = useFolderStore();
    const folderPath = computed(() => [...props.path, props.group.title]);
    const isFolderOpen = computed(() => folderStore.isFolderOpened(folderPath.value, true));
    function toggleOpen() {
      folderStore.toggleFolder(folderPath.value, false);
    }
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        _ctx.group.title ? (openBlock(), createElementBlock(Fragment, { key: 0 }, [
          _hoisted_2,
          createElementVNode("div", {
            role: "button",
            tabindex: "0",
            class: "htw-px-0.5 htw-py-2 md:htw-py-1.5 htw-mx-1 htw-rounded-sm hover:htw-bg-primary-100 dark:hover:htw-bg-primary-900 htw-cursor-pointer htw-select-none htw-flex htw-items-center htw-gap-2 htw-min-w-0 htw-opacity-50 hover:htw-opacity-100",
            onClick: toggleOpen,
            onKeyup: [
              withKeys(toggleOpen, ["enter"]),
              withKeys(toggleOpen, ["space"])
            ]
          }, [
            createVNode(unref(Icon), {
              icon: isFolderOpen.value ? "ri:subtract-line" : "ri:add-line",
              class: "htw-w-4 htw-h-4 htw-ml-4 htw-rounded-sm htw-border htw-border-gray-500/40"
            }, null, 8, ["icon"]),
            createElementVNode("span", _hoisted_4, toDisplayString(_ctx.group.title), 1)
          ], 40, _hoisted_3)
        ], 64)) : createCommentVNode("", true),
        isFolderOpen.value ? (openBlock(), createElementBlock("div", _hoisted_5, [
          (openBlock(true), createElementBlock(Fragment, null, renderList(_ctx.group.children, (element) => {
            return openBlock(), createElementBlock(Fragment, {
              key: element.title
            }, [
              element.children ? (openBlock(), createBlock(StoryListFolder, {
                key: 0,
                path: folderPath.value,
                folder: element,
                stories: _ctx.stories,
                depth: 0
              }, null, 8, ["path", "folder", "stories"])) : (openBlock(), createBlock(StoryListItem, {
                key: 1,
                story: _ctx.stories[element.index],
                depth: 0
              }, null, 8, ["story"]))
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
