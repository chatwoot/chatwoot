import { reactive, openBlock, Transition, normalizeStyle, Fragment, normalizeClass, createElementVNode, createElementBlock, renderList, createCommentVNode, withCtx, createVNode, defineComponent } from "@histoire/vendors/vue";
"use strict";
const _hoisted_1 = { class: "histoire-initial-loading htw-fixed htw-inset-0 htw-bg-white dark:htw-bg-gray-700 htw-flex htw-flex-col htw-gap-6 htw-items-center htw-justify-center" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "InitialLoading",
  setup(__props) {
    const progress = reactive({
      loaded: 0,
      total: 0
    });
    const maxCols = window.innerWidth / 20;
    if (import.meta.hot) {
      import.meta.hot.on("histoire:stories-loading-progress", (data) => {
        progress.loaded = data.loadedFileCount;
        progress.total = data.totalFileCount;
      });
    }
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createVNode(Transition, { name: "__histoire-fade" }, {
          default: withCtx(() => [
            progress.total > 0 ? (openBlock(), createElementBlock("div", {
              key: 0,
              class: "htw-grid htw-gap-2",
              style: normalizeStyle({
                gridTemplateColumns: `repeat(${Math.min(Math.ceil(Math.sqrt(progress.total)), maxCols)}, minmax(0, 1fr))`
              })
            }, [
              (openBlock(true), createElementBlock(Fragment, null, renderList(progress.total, (n) => {
                return openBlock(), createElementBlock("div", {
                  key: n,
                  class: "htw-bg-primary-500/10 htw-rounded-full"
                }, [
                  createElementVNode("div", {
                    class: normalizeClass(["htw-w-3 htw-h-3 htw-bg-primary-500 htw-rounded-full htw-duration-150 htw-ease-out", {
                      "htw-transition-transform htw-scale-0": n >= progress.loaded
                    }])
                  }, null, 2)
                ]);
              }), 128))
            ], 4)) : createCommentVNode("", true)
          ]),
          _: 1
        })
      ]);
    };
  }
});
export {
  _sfc_main as default
};
