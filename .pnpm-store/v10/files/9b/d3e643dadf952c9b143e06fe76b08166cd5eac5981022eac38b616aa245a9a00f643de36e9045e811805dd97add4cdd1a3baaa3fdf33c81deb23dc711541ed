import "virtual:$histoire-theme";
import { createApp } from "@histoire/vendors/vue";
import { createPinia } from "@histoire/vendors/pinia";
import FloatingVue from "@histoire/vendors/floating-vue";
import "./App.vue.js";
import { router } from "./router.js";
import { setupPluginApi } from "./plugin.js";
import _sfc_main from "./App.vue2.js";
"use strict";
async function mountMainApp() {
  const app = createApp(_sfc_main);
  app.use(createPinia());
  app.use(FloatingVue, {
    overflowPadding: 4,
    arrowPadding: 8,
    themes: {
      tooltip: {
        distance: 8
      },
      dropdown: {
        computeTransformOrigin: true,
        distance: 8
      }
    }
  });
  app.use(router);
  app.mount("#app");
  if (import.meta.hot) {
    import.meta.hot.send("histoire:mount", {});
    /* @__PURE__ */ setupPluginApi();
  }
}
export {
  mountMainApp
};
