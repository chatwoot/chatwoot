import { defineComponent, computed, onMounted, watch, nextTick, ref, openBlock, createElementBlock, createBlock, withCtx, createVNode, unref, createTextVNode, Fragment, renderList } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import BaseEmpty from "../base/BaseEmpty.vue.js";
import { useEventsStore } from "../../stores/events.js";
import "./StoryEvent.vue.js";
import _sfc_main$1 from "./StoryEvent.vue2.js";
"use strict";
const _hoisted_1 = { key: 1 };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryEvents",
  setup(__props) {
    const eventsStore = useEventsStore();
    const hasEvents = computed(() => eventsStore.events.length);
    onMounted(resetUnseen);
    watch(() => eventsStore.unseen, resetUnseen);
    async function resetUnseen() {
      if (eventsStore.unseen > 0) {
        eventsStore.unseen = 0;
      }
      await nextTick();
      eventsElement.value.scrollTo({ top: eventsElement.value.scrollHeight });
    }
    const eventsElement = ref();
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", {
        ref_key: "eventsElement",
        ref: eventsElement,
        class: "histoire-story-events"
      }, [
        !hasEvents.value ? (openBlock(), createBlock(BaseEmpty, { key: 0 }, {
          default: withCtx(() => [
            createVNode(unref(Icon), {
              icon: "carbon:event-schedule",
              class: "htw-w-8 htw-h-8 htw-opacity-50 htw-mb-6"
            }),
            createTextVNode(" No event fired ")
          ]),
          _: 1
        })) : (openBlock(), createElementBlock("div", _hoisted_1, [
          (openBlock(true), createElementBlock(Fragment, null, renderList(unref(eventsStore).events, (event, key) => {
            return openBlock(), createBlock(_sfc_main$1, {
              key,
              event
            }, null, 8, ["event"]);
          }), 128))
        ]))
      ], 512);
    };
  }
});
export {
  _sfc_main as default
};
