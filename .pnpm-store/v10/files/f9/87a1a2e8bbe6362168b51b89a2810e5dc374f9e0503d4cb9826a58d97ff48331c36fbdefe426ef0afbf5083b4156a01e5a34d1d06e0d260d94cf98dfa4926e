import { pushScopeId, popScopeId, useCssVars, computed, ref, openBlock, unref, normalizeClass, createVNode, toDisplayString, createElementVNode, createElementBlock, createCommentVNode, withCtx, defineComponent } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useRoute } from "@histoire/vendors/vue-router";
import BaseListItemLink from "../base/BaseListItemLink.vue.js";
import { useScrollOnActive } from "../../util/scroll.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-c9b616b5"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "bind-tree-margin htw-flex htw-items-center htw-gap-2 htw-pl-4 htw-min-w-0" };
const _hoisted_2 = { class: "htw-truncate" };
const _hoisted_3 = {
  key: 0,
  class: "htw-opacity-40 htw-text-sm"
};
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryListItem",
  props: {
    story: {},
    depth: { default: 0 }
  },
  setup(__props) {
    useCssVars((_ctx) => ({
      "c4f9d186": filePadding.value,
      "7270060e": _ctx.story.iconColor
    }));
    const props = __props;
    const filePadding = computed(() => {
      return `${props.depth * 12}px`;
    });
    const route = useRoute();
    const isActive = computed(() => route.params.storyId === props.story.id);
    const el = ref();
    useScrollOnActive(isActive, el);
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", {
        ref_key: "el",
        ref: el,
        "data-test-id": "story-list-item",
        class: "histoire-story-list-item"
      }, [
        createVNode(BaseListItemLink, {
          to: {
            name: "story",
            params: {
              storyId: _ctx.story.id
            }
          },
          class: "htw-pl-0.5 htw-pr-2 htw-py-2 md:htw-py-1.5 htw-mx-1 htw-rounded-sm"
        }, {
          default: withCtx(({ active }) => [
            createElementVNode("span", _hoisted_1, [
              createVNode(unref(Icon), {
                icon: _ctx.story.icon ?? "carbon:cube",
                class: normalizeClass(["htw-w-5 htw-h-5 sm:htw-w-4 sm:htw-h-4 htw-flex-none", {
                  "htw-text-primary-500": !active && !_ctx.story.iconColor,
                  "bind-icon-color": !active && _ctx.story.iconColor
                }])
              }, null, 8, ["icon", "class"]),
              createElementVNode("span", _hoisted_2, toDisplayString(_ctx.story.title), 1)
            ]),
            !_ctx.story.docsOnly ? (openBlock(), createElementBlock("span", _hoisted_3, toDisplayString(_ctx.story.variants.length), 1)) : createCommentVNode("", true)
          ]),
          _: 1
        }, 8, ["to"])
      ], 512);
    };
  }
});
export {
  _sfc_main as default
};
