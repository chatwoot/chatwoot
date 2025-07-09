import { base } from "../router.js";
"use strict";
function getSandboxUrl(story, variant) {
  const url = new URLSearchParams();
  url.append("storyId", story.id);
  url.append("variantId", variant.id);
  return `${base}__sandbox.html?${url.toString()}`;
}
export {
  getSandboxUrl
};
