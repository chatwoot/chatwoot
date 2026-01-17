import { defineComponent, toRefs, watch, ref, computed, openBlock, createElementBlock, unref, normalizeClass, createBlock, createCommentVNode, withCtx, createVNode, createTextVNode, watchEffect, nextTick } from "@histoire/vendors/vue";
import { markdownFiles } from "virtual:$histoire-markdown-files";
import { Icon } from "@histoire/vendors/iconify";
import { useRouter, useRoute } from "@histoire/vendors/vue-router";
import { histoireConfig } from "../../util/config.js";
import "../toolbar/DevOnlyToolbarOpenInEditor.vue.js";
import BaseEmpty from "../base/BaseEmpty.vue.js";
import _sfc_main$1 from "../toolbar/DevOnlyToolbarOpenInEditor.vue2.js";
"use strict";
const _hoisted_1 = ["innerHTML"];
function useStoryDoc(story) {
  const renderedDoc = ref("");
  watchEffect(async () => {
    var _a;
    const mdKey = story.value.file.filePath.replace(/\.(\w*?)$/, ".md");
    if (markdownFiles[mdKey]) {
      const md = await markdownFiles[mdKey]();
      renderedDoc.value = md.html;
      return;
    }
    let comp = (_a = story.value.file) == null ? void 0 : _a.component;
    if (comp) {
      if (comp.__asyncResolved) {
        comp = comp.__asyncResolved;
      } else if (comp.__asyncLoader) {
        comp = await comp.__asyncLoader();
      } else if (typeof comp === "function") {
        try {
          comp = await comp();
        } catch (e) {
        }
      }
      if (comp == null ? void 0 : comp.default) {
        comp = comp.default;
      }
      renderedDoc.value = comp.doc;
    }
  });
  return {
    renderedDoc
  };
}
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryDocs",
  props: {
    story: {
      type: Object,
      required: true
    },
    standalone: {
      type: Boolean,
      default: false
    }
  },
  emits: ["scrollTop"],
  setup(__props, { emit: __emit }) {
    const props = __props;
    const emit = __emit;
    const { story } = toRefs(props);
    const { renderedDoc } = useStoryDoc(story);
    const router = useRouter();
    const fakeHost = `http://a.com`;
    function onClick(e) {
      const link = e.target.closest("a");
      if (link && link.getAttribute("data-route") && !e.ctrlKey && !e.shiftKey && !e.altKey && !e.metaKey && link.target !== `_blank`) {
        e.preventDefault();
        const url = new URL(link.href, fakeHost);
        const targetHref = url.pathname + url.search + url.hash;
        router.push(targetHref);
      }
    }
    function getHash() {
      const hash = location.hash;
      if (histoireConfig.routerMode === "hash") {
        const index = hash.indexOf("#", 1);
        if (index !== -1) {
          return hash.slice(index);
        } else {
          return void 0;
        }
      }
      return hash;
    }
    async function scrollToAnchor() {
      await nextTick();
      const hash = getHash();
      if (hash) {
        const anchor = document.querySelector(decodeURIComponent(hash));
        if (anchor) {
          anchor.scrollIntoView();
          return;
        }
      }
      emit("scrollTop");
    }
    watch(renderedDoc, () => {
      scrollToAnchor();
    }, {
      immediate: true
    });
    const renderedEl = ref();
    const route = useRoute();
    async function patchAnchorLinks() {
      await nextTick();
      if (histoireConfig.routerMode === "hash" && renderedEl.value) {
        const links = renderedEl.value.querySelectorAll("a.header-anchor");
        for (const link of links) {
          const href = link.getAttribute("href");
          if (href) {
            link.setAttribute("href", `#${route.path + href}`);
          }
        }
      }
    }
    watch(renderedDoc, () => {
      patchAnchorLinks();
    }, {
      immediate: true
    });
    const filePath = computed(() => {
      var _a, _b;
      return ((_a = story.value.file) == null ? void 0 : _a.docsFilePath) ?? (props.standalone && ((_b = story.value.file) == null ? void 0 : _b.filePath));
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", {
        class: "histoire-story-docs",
        onClickCapture: onClick
      }, [
        _ctx.__HISTOIRE_DEV__ && unref(renderedDoc) && filePath.value ? (openBlock(), createElementBlock("div", {
          key: 0,
          class: normalizeClass(["htw-flex htw-items-center htw-gap-2 htw-p-2", {
            "htw-pt-4": !__props.standalone
          }])
        }, [
          filePath.value ? (openBlock(), createBlock(_sfc_main$1, {
            key: 0,
            file: filePath.value,
            tooltip: "Edit docs in editor"
          }, null, 8, ["file"])) : createCommentVNode("", true)
        ], 2)) : createCommentVNode("", true),
        !unref(renderedDoc) ? (openBlock(), createBlock(BaseEmpty, { key: 1 }, {
          default: withCtx(() => [
            createVNode(unref(Icon), {
              icon: "carbon:document-unknown",
              class: "htw-w-8 htw-h-8 htw-opacity-50 htw-mb-6"
            }),
            createTextVNode(" No documentation available ")
          ]),
          _: 1
        })) : (openBlock(), createElementBlock("div", {
          key: 2,
          ref_key: "renderedEl",
          ref: renderedEl,
          class: "htw-prose dark:htw-prose-invert htw-p-4 htw-max-w-none",
          "data-test-id": "story-docs",
          innerHTML: unref(renderedDoc)
        }, null, 8, _hoisted_1))
      ], 32);
    };
  }
});
export {
  _sfc_main as default,
  useStoryDoc
};
