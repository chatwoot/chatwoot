import { defineComponent, toRefs, computed, openBlock, createBlock, withCtx, createVNode, createTextVNode, normalizeClass, unref, toDisplayString, createCommentVNode } from "@histoire/vendors/vue";
import BaseTab from "../base/BaseTab.vue.js";
import { useEventsStore } from "../../stores/events.js";
import "../base/BaseOverflowMenu.vue.js";
import BaseOverflowTab from "../base/BaseOverflowTab.vue.js";
import BaseTag from "../base/BaseTag.vue.js";
import "./StoryDocs.vue.js";
import { useStoryDoc } from "./StoryDocs.vue2.js";
import _sfc_main$1 from "../base/BaseOverflowMenu.vue2.js";
"use strict";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "PaneTabs",
  props: {
    story: {},
    variant: {}
  },
  setup(__props) {
    const props = __props;
    const { story } = toRefs(props);
    const { renderedDoc } = useStoryDoc(story);
    const eventsStore = useEventsStore();
    const hasEvents = computed(() => eventsStore.events.length);
    return (_ctx, _cache) => {
      return openBlock(), createBlock(_sfc_main$1, { class: "histoire-pane-tabs htw-h-10 htw-flex-none htw-border-b htw-border-gray-100 dark:htw-border-gray-750" }, {
        overflow: withCtx(() => [
          createVNode(BaseOverflowTab, {
            to: { ..._ctx.$route, query: { ..._ctx.$route.query, tab: "" } },
            matched: !_ctx.$route.query.tab
          }, {
            default: withCtx(() => [
              createTextVNode(" Controls ")
            ]),
            _: 1
          }, 8, ["to", "matched"]),
          createVNode(BaseOverflowTab, {
            to: { ..._ctx.$route, query: { ..._ctx.$route.query, tab: "docs" } },
            matched: _ctx.$route.query.tab === "docs",
            class: normalizeClass({
              "opacity-50": !unref(renderedDoc)
            })
          }, {
            default: withCtx(() => [
              createTextVNode(" Docs ")
            ]),
            _: 1
          }, 8, ["to", "matched", "class"]),
          createVNode(BaseOverflowTab, {
            to: { ..._ctx.$route, query: { ..._ctx.$route.query, tab: "events" } },
            matched: _ctx.$route.query.tab === "events",
            class: normalizeClass({
              "htw-opacity-50": !hasEvents.value
            })
          }, {
            default: withCtx(() => [
              createTextVNode(" Events "),
              unref(eventsStore).unseen ? (openBlock(), createBlock(BaseTag, { key: 0 }, {
                default: withCtx(() => [
                  createTextVNode(toDisplayString(unref(eventsStore).unseen <= 99 ? unref(eventsStore).unseen : "99+"), 1)
                ]),
                _: 1
              })) : createCommentVNode("", true)
            ]),
            _: 1
          }, 8, ["to", "matched", "class"])
        ]),
        default: withCtx(() => [
          createVNode(BaseTab, {
            to: { ..._ctx.$route, query: { ..._ctx.$route.query, tab: "" } },
            matched: !_ctx.$route.query.tab
          }, {
            default: withCtx(() => [
              createTextVNode(" Controls ")
            ]),
            _: 1
          }, 8, ["to", "matched"]),
          createVNode(BaseTab, {
            to: { ..._ctx.$route, query: { ..._ctx.$route.query, tab: "docs" } },
            matched: _ctx.$route.query.tab === "docs",
            class: normalizeClass({
              "htw-opacity-50": !unref(renderedDoc)
            })
          }, {
            default: withCtx(() => [
              createTextVNode(" Docs ")
            ]),
            _: 1
          }, 8, ["to", "matched", "class"]),
          createVNode(BaseTab, {
            to: { ..._ctx.$route, query: { ..._ctx.$route.query, tab: "events" } },
            matched: _ctx.$route.query.tab === "events",
            class: normalizeClass({
              "htw-opacity-50": !hasEvents.value
            })
          }, {
            default: withCtx(() => [
              createTextVNode(" Events "),
              unref(eventsStore).unseen ? (openBlock(), createBlock(BaseTag, { key: 0 }, {
                default: withCtx(() => [
                  createTextVNode(toDisplayString(unref(eventsStore).unseen <= 99 ? unref(eventsStore).unseen : "99+"), 1)
                ]),
                _: 1
              })) : createCommentVNode("", true)
            ]),
            _: 1
          }, 8, ["to", "matched", "class"])
        ]),
        _: 1
      });
    };
  }
});
export {
  _sfc_main as default
};
