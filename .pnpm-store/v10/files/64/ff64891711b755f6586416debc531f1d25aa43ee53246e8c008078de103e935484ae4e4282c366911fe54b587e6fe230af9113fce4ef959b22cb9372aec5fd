import { h as s, createApp as d } from "vue";
import * as n from "virtual:$histoire-setup";
import * as e from "virtual:$histoire-generated-global-setup";
import f from "./Story.js";
import l from "./Variant.js";
async function h({ file: p, storyData: u, el: c }) {
  const { default: r } = await import(/* @vite-ignore */
    /* @vite-ignore */
    p.moduleId
  ), o = d({
    provide: {
      addStory(t) {
        u.push(t);
      }
    },
    render() {
      return s(r, {
        ref: "comp",
        data: p
      });
    }
  });
  o.component("Story", f), o.component("Variant", l);
  const a = {
    app: o,
    story: null,
    variant: null,
    addWrapper: () => {
    }
  };
  if (typeof (e == null ? void 0 : e.setupVue3) == "function") {
    const t = e.setupVue3;
    await t(a);
  }
  if (typeof (n == null ? void 0 : n.setupVue3) == "function") {
    const t = n.setupVue3;
    await t(a);
  }
  if (o.mount(c), r.doc) {
    const t = document.createElement("div");
    t.innerHTML = r.doc;
    const i = t.textContent;
    u.forEach((m) => {
      m.docsText = i;
    });
  }
  o.unmount();
}
export {
  h as run
};
