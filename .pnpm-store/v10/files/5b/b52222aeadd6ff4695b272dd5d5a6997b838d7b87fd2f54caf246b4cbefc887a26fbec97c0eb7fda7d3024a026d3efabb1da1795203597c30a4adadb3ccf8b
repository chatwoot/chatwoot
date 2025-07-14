import { ref as u, onBeforeUpdate as y, onMounted as E, onUpdated as g, onBeforeUnmount as $, h as d, defineComponent as w } from "vue";
import { reactive as U, h as v, createApp as b } from "@histoire/vendors/vue";
import { components as C } from "@histoire/controls";
import k from "./Story.js";
import q from "./Variant.js";
function M(e) {
  e.component("Story", k), e.component("Variant", q);
  for (const o in C)
    e.component(o, A(C[o]));
}
function A(e) {
  return w({
    name: e.name,
    inheritAttrs: !1,
    setup(o, { attrs: n }) {
      const a = u(), p = u(), m = U({});
      function c(l) {
        Object.assign(m, l);
      }
      c(n), y(() => {
        c(n);
      });
      let t = [];
      const r = u([]);
      function S() {
        r.value.forEach((l, f) => {
          const h = p.value.querySelector(`[renderslotid="${f}"]`);
          if (!h)
            return;
          const s = a.value.querySelector(`[slotid="${f}"]`);
          for (; s.firstChild; )
            s.removeChild(s.lastChild);
          s.appendChild(h);
        });
      }
      let i;
      return E(() => {
        i = b({
          mounted() {
            r.value = t, t = [];
          },
          updated() {
            r.value = t, t = [];
          },
          render() {
            return v(e, {
              ...m,
              key: "component"
            }, {
              default: (l) => (t.push(l), v("div", {
                slotId: t.length - 1
              }))
            });
          }
        }), i.mount(a.value);
      }), g(() => {
        S();
      }), $(() => {
        i.unmount();
      }), {
        el: a,
        slotEl: p,
        slotCalls: r
      };
    },
    render() {
      return [
        d("div", {
          ref: "el"
        }),
        d("div", {
          ref: "slotEl"
        }, this.slotCalls.map((o, n) => d("div", {
          renderSlotId: n
        }, this.$slots.default(o))))
      ];
    }
  });
}
export {
  M as registerGlobalComponents
};
