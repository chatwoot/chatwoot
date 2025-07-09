import { EVENT_SEND } from "./const.js";
"use strict";
async function logEvent(name, argument) {
  var _a;
  console.log("[histoire] Event fired", { name, argument });
  const event = {
    name,
    argument: JSON.parse(stringifyEvent(argument))
    // Needed for HTMLEvent that can't be cloned
  };
  if (location.href.includes("__sandbox")) {
    (_a = window.parent) == null ? void 0 : _a.postMessage({
      type: EVENT_SEND,
      event
    });
  } else {
    const { useEventsStore } = await import("../stores/events.js");
    useEventsStore().addEvent(event);
  }
}
function stringifyEvent(e) {
  const obj = {};
  for (const k in e) {
    obj[k] = e[k];
  }
  return JSON.stringify(obj, (k, v) => {
    if (v instanceof Node)
      return "Node";
    if (v instanceof Window)
      return "Window";
    return v;
  }, " ");
}
export {
  logEvent
};
