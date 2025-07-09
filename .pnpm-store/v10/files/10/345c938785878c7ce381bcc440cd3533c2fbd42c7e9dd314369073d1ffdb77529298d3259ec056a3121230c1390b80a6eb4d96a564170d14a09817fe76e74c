import { router } from "./router.js";
"use strict";
function setupPluginApi() {
  if (!import.meta.hot)
    return;
  const listeners = {};
  import.meta.hot.on("histoire:dev-event-result", ({ event, result }) => {
    const set = listeners[event];
    if (set) {
      for (const listener of set) {
        listener(result);
      }
    }
  });
  function addDevEventListener(event, listener) {
    let set = listeners[event];
    if (!set) {
      set = /* @__PURE__ */ new Set();
      listeners[event] = set;
    }
    set.add(listener);
    return () => {
      set.delete(listener);
    };
  }
  window.__HST_PLUGIN_API__ = {
    sendEvent: (event, payload) => {
      return new Promise((resolve) => {
        import.meta.hot.send(`histoire:dev-event`, {
          event,
          payload
        });
        if (event.startsWith("on")) {
          resolve(void 0);
        } else {
          const off = addDevEventListener(event, (result) => {
            off();
            resolve(result);
          });
        }
      });
    },
    openStory: (storyId) => {
      router.push({ name: "story", params: { storyId } });
    }
  };
}
export {
  setupPluginApi
};
