import { h as a, Suspense as h, createApp as v } from "vue";
import { ref as w, watch as y, onMounted as S, onUnmounted as b, h as M, defineComponent as V } from "@histoire/vendors/vue";
import * as r from "virtual:$histoire-setup";
import * as s from "virtual:$histoire-generated-global-setup";
import { registerGlobalComponents as x } from "./global-components.js";
import { RouterLinkStub as A } from "./RouterLinkStub.js";
const R = V({
  name: "MountStory",
  props: {
    story: {
      type: Object,
      required: !0
    }
  },
  setup(n) {
    const i = w();
    let t;
    async function p() {
      const u = [];
      t = v({
        name: "MountStorySubApp",
        render: () => {
          const e = a(n.story.file.component, {
            story: n.story
          }), o = [];
          o.push(e);
          for (const [d, l] of u.entries())
            o.push(
              a(
                l,
                {
                  story: n.story,
                  variant: null
                },
                () => o[d]
              )
            );
          return a(
            h,
            void 0,
            o.at(-1)
          );
        }
      }), x(t), t.component("RouterLink", A), y(() => n.story.variants, () => {
        t._instance.proxy.$forceUpdate();
      });
      const m = {
        app: t,
        story: n.story,
        variant: null,
        addWrapper: (e) => {
          u.push(e);
        }
      };
      if (typeof (s == null ? void 0 : s.setupVue3) == "function") {
        const e = s.setupVue3;
        await e(m);
      }
      if (typeof (r == null ? void 0 : r.setupVue3) == "function") {
        const e = r.setupVue3;
        await e(m);
      }
      u.reverse();
      const f = document.createElement("div");
      i.value.appendChild(f), t.mount(f);
    }
    function c() {
      t == null || t.unmount();
    }
    return y(() => n.story.id, async () => {
      c(), await p();
    }), S(async () => {
      await p();
    }), b(() => {
      c();
    }), {
      el: i
    };
  },
  render() {
    return M("div", {
      ref: "el"
    });
  }
});
export {
  R as default
};
