import { openBlock, Fragment, createBlock, createElementBlock, renderList, defineComponent } from "@histoire/vendors/vue";
import StoryListItem from "./StoryListItem.vue.js";
import StoryListFolder from "./StoryListFolder.vue.js";
import "./StoryGroup.vue.js";
import _sfc_main$1 from "./StoryGroup.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-story-list htw-overflow-y-auto" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryList",
  props: {
    tree: {},
    stories: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        (openBlock(true), createElementBlock(Fragment, null, renderList(_ctx.tree, (element) => {
          return openBlock(), createElementBlock(Fragment, {
            key: element.title
          }, [
            element.group ? (openBlock(), createBlock(_sfc_main$1, {
              key: 0,
              group: element,
              stories: _ctx.stories
            }, null, 8, ["group", "stories"])) : element.children ? (openBlock(), createBlock(StoryListFolder, {
              key: 1,
              folder: element,
              stories: _ctx.stories
            }, null, 8, ["folder", "stories"])) : (openBlock(), createBlock(StoryListItem, {
              key: 2,
              story: _ctx.stories[element.index]
            }, null, 8, ["story"]))
          ], 64);
        }), 128))
      ]);
    };
  }
});
export {
  _sfc_main as default
};
