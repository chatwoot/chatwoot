import { createWebHistory, createWebHashHistory, createRouter } from "@histoire/vendors/vue-router";
import { histoireConfig } from "./util/config.js";
"use strict";
const base = import.meta.env.BASE_URL;
function createRouterHistory() {
  switch (histoireConfig.routerMode) {
    case "hash":
      return createWebHashHistory(base);
    case "history":
    default:
      return createWebHistory(base);
  }
}
const router = createRouter({
  history: createRouterHistory(),
  routes: [
    {
      path: "/",
      name: "home",
      component: () => import("./components/HomeView.vue.js")
    },
    {
      path: "/story/:storyId",
      name: "story",
      component: () => import("./components/story/StoryView.vue.js")
    }
  ]
});
export {
  base,
  router
};
