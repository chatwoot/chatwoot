import { defineComponent, useCssVars, unref, toRefs, ref, openBlock, createElementBlock, createVNode, withCtx, normalizeClass, createElementVNode, toDisplayString, pushScopeId, popScopeId } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useCurrentVariantRoute } from "../../util/variant.js";
import BaseListItemLink from "../base/BaseListItemLink.vue.js";
import { useScrollOnActive } from "../../util/scroll.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-f8e09a03"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "htw-truncate" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryVariantListItem",
  props: {
    variant: {
      type: Object,
      required: true
    }
  },
  setup(__props) {
    useCssVars((_ctx) => ({
      "2762f67a": unref(variant).iconColor
    }));
    const props = __props;
    const { variant } = toRefs(props);
    const { isActive, targetRoute } = useCurrentVariantRoute(variant);
    const el = ref();
    useScrollOnActive(isActive, el);
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", {
        ref_key: "el",
        ref: el,
        class: "histoire-story-variant-list-item",
        "data-test-id": "story-variant-list-item"
      }, [
        createVNode(BaseListItemLink, {
          to: unref(targetRoute),
          "is-active": unref(isActive),
          class: "htw-px-2 htw-py-2 md:htw-py-1.5 htw-m-1 htw-rounded-sm htw-flex htw-items-center htw-gap-2"
        }, {
          default: withCtx(({ active }) => [
            createVNode(unref(Icon), {
              icon: unref(variant).icon ?? "carbon:cube",
              class: normalizeClass(["htw-w-5 htw-h-5 sm:htw-w-4 sm:htw-h-4 htw-flex-none", {
                "htw-text-gray-500": !active && !unref(variant).iconColor,
                "bind-icon-color": !active && unref(variant).iconColor
              }])
            }, null, 8, ["icon", "class"]),
            createElementVNode("span", _hoisted_1, toDisplayString(unref(variant).title), 1)
          ]),
          _: 1
        }, 8, ["to", "is-active"])
      ], 512);
    };
  }
});
export {
  _sfc_main as default
};
