import { defineComponent as et, openBlock as D, createElementBlock as K, normalizeClass as dt, renderSlot as ht, createBlock as Q, resolveDynamicComponent as ma, withCtx as G, withDirectives as Et, createTextVNode as se, toDisplayString as Dt, unref as Ct, createElementVNode as B, computed as nt, Fragment as ge, renderList as Ve, watch as as, ref as lt, withKeys as Ue, withModifiers as Ye, createVNode as Ts, normalizeStyle as Pt, mergeProps as He, onUnmounted as wa, vModelText as qn, createCommentVNode as te, onMounted as ya, watchEffect as ba } from "@histoire/vendors/vue";
import { VTooltip as me, Dropdown as ka } from "@histoire/vendors/floating-vue";
import { Icon as Gn } from "@histoire/vendors/iconify";
import { useClipboard as xa } from "@histoire/vendors/vue-use";
const va = {
  name: "HstButton"
}, Zo = /* @__PURE__ */ et({
  ...va,
  props: {
    color: {}
  },
  setup(n) {
    const t = {
      default: "htw-bg-gray-200 dark:htw-bg-gray-750 htw-text-gray-900 dark:htw-text-gray-100 hover:htw-bg-primary-200 dark:hover:htw-bg-primary-900",
      primary: "htw-bg-primary-500 hover:htw-bg-primary-600 htw-text-white dark:htw-text-black",
      flat: "htw-bg-transparent hover:htw-bg-gray-500/20 htw-text-gray-900 dark:htw-text-gray-100"
    };
    return (e, i) => (D(), K("button", {
      class: dt(["histoire-button htw-cursor-pointer htw-rounded-sm", t[e.color ?? "default"]])
    }, [
      ht(e.$slots, "default")
    ], 2));
  }
}), Sa = { class: "htw-w-28 htw-whitespace-nowrap htw-text-ellipsis htw-overflow-hidden htw-shrink-0" }, Ca = { class: "htw-grow htw-max-w-full htw-flex htw-items-center htw-gap-1" }, Aa = { class: "htw-block htw-grow htw-max-w-full" }, Oa = {
  name: "HstWrapper"
}, Vt = /* @__PURE__ */ et({
  ...Oa,
  props: {
    title: { default: void 0 },
    tag: { default: "label" }
  },
  setup(n) {
    return (t, e) => (D(), Q(ma(t.tag), { class: "histoire-wrapper htw-p-2 hover:htw-bg-primary-100 dark:hover:htw-bg-primary-800 htw-flex htw-gap-2 htw-flex-wrap" }, {
      default: G(() => [
        Et((D(), K("span", Sa, [
          se(Dt(t.title), 1)
        ])), [
          [Ct(me), {
            content: t.title,
            placement: "left",
            distance: 12
          }]
        ]),
        B("span", Ca, [
          B("span", Aa, [
            ht(t.$slots, "default")
          ]),
          ht(t.$slots, "actions")
        ])
      ]),
      _: 3
    }));
  }
}), Ma = { class: "htw-flex htw-gap-px htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 htw-rounded-sm htw-p-px" }, Ta = {
  name: "HstButtonGroup"
}, Da = /* @__PURE__ */ et({
  ...Ta,
  props: {
    title: {},
    modelValue: {},
    options: {}
  },
  emits: ["update:modelValue"],
  setup(n, { emit: t }) {
    const e = n, i = nt(() => Array.isArray(e.options) ? e.options.map((o) => typeof o == "string" || typeof o == "number" ? { value: o, label: String(o) } : o) : Object.keys(e.options).map((o) => ({
      value: o,
      label: e.options[o]
    }))), s = t;
    function r(o) {
      s("update:modelValue", o);
    }
    return (o, l) => (D(), Q(Vt, {
      tag: "div",
      role: "group",
      title: o.title,
      class: "histoire-button-group htw-flex-nowrap htw-items-center"
    }, {
      actions: G(() => [
        ht(o.$slots, "actions")
      ]),
      default: G(() => [
        B("div", Ma, [
          (D(!0), K(ge, null, Ve(i.value, ({ label: h, value: a }) => (D(), Q(Zo, {
            key: a,
            class: "htw-px-1 htw-h-[22px] htw-flex-1 !htw-rounded-[3px]",
            color: a === o.modelValue ? "primary" : "flat",
            rounded: !1,
            onClick: (c) => r(a)
          }, {
            default: G(() => [
              se(Dt(h), 1)
            ]),
            _: 2
          }, 1032, ["color", "onClick"]))), 128))
        ])
      ]),
      _: 3
    }, 8, ["title"]));
  }
}), Pa = {
  width: "16",
  height: "16",
  viewBox: "0 0 24 24",
  class: "htw-relative htw-z-10"
}, Ba = ["stroke-dasharray", "stroke-dashoffset"], Ra = {
  name: "HstSimpleCheckbox"
}, tl = /* @__PURE__ */ et({
  ...Ra,
  props: {
    modelValue: { type: Boolean },
    withToggle: { type: Boolean }
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = n, i = t;
    function s() {
      e.withToggle && i("update:modelValue", !e.modelValue);
    }
    as(() => e.modelValue, () => {
      a.value = !0;
    });
    const r = lt(), o = lt(0), l = nt(() => e.modelValue ? 1 : 0), h = nt(() => (1 - l.value) * o.value), a = lt(!1);
    return as(r, () => {
      var c, f;
      o.value = ((f = (c = r.value).getTotalLength) == null ? void 0 : f.call(c)) ?? 21.21;
    }), (c, f) => (D(), K("div", {
      class: dt(["histoire-simple-checkbox htw-group htw-text-white htw-w-[16px] htw-h-[16px] htw-relative", { "htw-cursor-pointer": c.withToggle }]),
      onClick: s
    }, [
      B("div", {
        class: dt(["htw-border htw-border-solid group-active:htw-bg-gray-500/20 htw-rounded-sm htw-box-border htw-absolute htw-inset-0 htw-transition-border htw-duration-150 htw-ease-out group-hover:htw-border-primary-500 group-hover:dark:htw-border-primary-500", [
          c.modelValue ? "htw-border-primary-500 htw-border-8" : "htw-border-black/25 dark:htw-border-white/25 htw-delay-150"
        ]])
      }, null, 2),
      (D(), K("svg", Pa, [
        B("path", {
          ref_key: "path",
          ref: r,
          d: "m 4 12 l 5 5 l 10 -10",
          fill: "none",
          class: dt(["htw-stroke-white htw-stroke-2 htw-duration-200 htw-ease-in-out", [
            a.value ? "htw-transition-all" : "htw-transition-none",
            {
              "htw-delay-150": c.modelValue
            }
          ]]),
          "stroke-dasharray": o.value,
          "stroke-dashoffset": h.value
        }, null, 10, Ba)
      ]))
    ], 2));
  }
}), La = {
  name: "HstCheckbox"
}, Ea = /* @__PURE__ */ et({
  ...La,
  props: {
    modelValue: { type: [Boolean, String] },
    title: {}
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = n, i = t;
    function s() {
      if (typeof e.modelValue == "string") {
        i("update:modelValue", e.modelValue === "false" ? "true" : "false");
        return;
      }
      i("update:modelValue", !e.modelValue);
    }
    const r = nt(() => typeof e.modelValue == "string" ? e.modelValue !== "false" : e.modelValue);
    return (o, l) => (D(), Q(Vt, {
      role: "checkbox",
      tabindex: "0",
      class: "histoire-checkbox htw-cursor-pointer htw-items-center",
      title: o.title,
      onClick: l[0] || (l[0] = (h) => s()),
      onKeydown: [
        l[1] || (l[1] = Ue(Ye((h) => s(), ["prevent"]), ["enter"])),
        l[2] || (l[2] = Ue(Ye((h) => s(), ["prevent"]), ["space"]))
      ]
    }, {
      actions: G(() => [
        ht(o.$slots, "actions")
      ]),
      default: G(() => [
        Ts(tl, { "model-value": r.value }, null, 8, ["model-value"])
      ]),
      _: 3
    }, 8, ["title"]));
  }
}), Na = { class: "-htw-my-1" }, Ia = ["for", "onKeydown", "onClick"], Va = {
  name: "HstCheckboxList"
}, Ha = /* @__PURE__ */ et({
  ...Va,
  props: {
    title: {},
    modelValue: {},
    options: {}
  },
  emits: ["update:modelValue"],
  setup(n, { emit: t }) {
    const e = n, i = nt(() => Array.isArray(e.options) ? Object.fromEntries(e.options.map((o) => typeof o == "string" ? [o, o] : [o.value, o.label])) : e.options), s = t;
    function r(o) {
      e.modelValue.includes(o) ? s("update:modelValue", e.modelValue.filter((l) => l !== o)) : s("update:modelValue", [...e.modelValue, o]);
    }
    return (o, l) => (D(), Q(Vt, {
      role: "group",
      title: o.title,
      class: dt(["histoire-checkbox-list htw-cursor-text", o.$attrs.class]),
      style: Pt(o.$attrs.style)
    }, {
      actions: G(() => [
        ht(o.$slots, "actions")
      ]),
      default: G(() => [
        B("div", Na, [
          (D(!0), K(ge, null, Ve(i.value, (h, a) => (D(), K("label", {
            key: a,
            tabindex: "0",
            for: `${a}-radio`,
            class: "htw-cursor-pointer htw-flex htw-items-center htw-relative htw-py-1 htw-group",
            onKeydown: [
              Ue(Ye((c) => r(a), ["prevent"]), ["enter"]),
              Ue(Ye((c) => r(a), ["prevent"]), ["space"])
            ],
            onClick: (c) => r(a)
          }, [
            Ts(tl, {
              "model-value": o.modelValue.includes(a),
              class: "htw-mr-2"
            }, null, 8, ["model-value"]),
            se(" " + Dt(h), 1)
          ], 40, Ia))), 128))
        ])
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
}), $a = ["value"], Fa = {
  name: "HstText"
}, _a = /* @__PURE__ */ et({
  ...Fa,
  props: {
    title: {},
    modelValue: {}
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = t, i = lt();
    return (s, r) => (D(), Q(Vt, {
      title: s.title,
      class: dt(["histoire-text htw-cursor-text htw-items-center", s.$attrs.class]),
      style: Pt(s.$attrs.style),
      onClick: r[1] || (r[1] = (o) => i.value.focus())
    }, {
      actions: G(() => [
        ht(s.$slots, "actions")
      ]),
      default: G(() => [
        B("input", He({
          ref_key: "input",
          ref: i
        }, { ...s.$attrs, class: null, style: null }, {
          type: "text",
          value: s.modelValue,
          class: "htw-text-inherit htw-bg-transparent htw-w-full htw-outline-none htw-px-2 htw-py-1 -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 focus:htw-border-primary-500 dark:focus:htw-border-primary-500 htw-rounded-sm",
          onInput: r[0] || (r[0] = (o) => e("update:modelValue", o.target.value))
        }), null, 16, $a)
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
}), za = {
  name: "HstNumber",
  inheritAttrs: !1
}, Wa = /* @__PURE__ */ et({
  ...za,
  props: {
    title: {},
    modelValue: {}
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = n, i = t, s = nt({
      get: () => e.modelValue,
      set: (d) => {
        i("update:modelValue", d);
      }
    }), r = lt();
    function o() {
      r.value.focus(), r.value.select();
    }
    const l = lt(!1);
    let h, a;
    function c(d) {
      l.value = !0, h = d.clientX, a = s.value, window.addEventListener("mousemove", f), window.addEventListener("mouseup", u);
    }
    function f(d) {
      let p = Number.parseFloat(r.value.step);
      Number.isNaN(p) && (p = 1), s.value = a + Math.round((d.clientX - h) / 10 / p) * p;
    }
    function u() {
      l.value = !1, window.removeEventListener("mousemove", f), window.removeEventListener("mouseup", u);
    }
    return wa(() => {
      u();
    }), (d, p) => (D(), Q(Vt, {
      class: dt(["histoire-number htw-cursor-ew-resize htw-items-center", [
        d.$attrs.class,
        { "htw-select-none": l.value }
      ]]),
      title: d.title,
      style: Pt(d.$attrs.style),
      onClick: o,
      onMousedown: c
    }, {
      actions: G(() => [
        ht(d.$slots, "actions")
      ]),
      default: G(() => [
        Et(B("input", He({
          ref_key: "input",
          ref: r
        }, { ...d.$attrs, class: null, style: null }, {
          "onUpdate:modelValue": p[0] || (p[0] = (m) => s.value = m),
          type: "number",
          class: [{
            "htw-select-none": l.value
          }, "htw-text-inherit htw-bg-transparent htw-w-full htw-outline-none htw-pl-2 htw-py-1 -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 focus:htw-border-primary-500 dark:focus:htw-border-primary-500 htw-rounded-sm htw-cursor-ew-resize htw-box-border"]
        }), null, 16), [
          [
            qn,
            s.value,
            void 0,
            { number: !0 }
          ]
        ])
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
}), ja = { class: "htw-relative htw-w-full htw-flex htw-items-center" }, Ka = /* @__PURE__ */ B("div", { class: "htw-absolute htw-inset-0 htw-flex htw-items-center" }, [
  /* @__PURE__ */ B("div", { class: "htw-border htw-border-black/25 dark:htw-border-white/25 htw-h-1 htw-w-full htw-rounded-full" })
], -1), qa = {
  name: "HstSlider",
  inheritAttrs: !1
}, Ga = /* @__PURE__ */ et({
  ...qa,
  props: {
    title: {},
    modelValue: {},
    min: {},
    max: {}
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = n, i = t, s = lt(!1), r = lt(null), o = nt({
      get: () => e.modelValue,
      set: (a) => {
        i("update:modelValue", a);
      }
    }), l = nt(() => (e.modelValue - e.min) / (e.max - e.min)), h = nt(() => r.value ? {
      left: `${8 + (r.value.clientWidth - 16) * l.value}px`
    } : {});
    return (a, c) => (D(), Q(Vt, {
      class: dt(["histoire-slider htw-items-center", a.$attrs.class]),
      title: a.title,
      style: Pt(a.$attrs.style)
    }, {
      default: G(() => [
        B("div", ja, [
          Ka,
          Et(B("input", He({
            ref_key: "input",
            ref: r,
            "onUpdate:modelValue": c[0] || (c[0] = (f) => o.value = f),
            class: "htw-range-input htw-appearance-none htw-border-0 htw-bg-transparent htw-cursor-pointer htw-relative htw-w-full htw-m-0 htw-text-gray-700",
            type: "range"
          }, { ...a.$attrs, class: null, style: null, min: a.min, max: a.max }, {
            onMouseover: c[1] || (c[1] = (f) => s.value = !0),
            onMouseleave: c[2] || (c[2] = (f) => s.value = !1)
          }), null, 16), [
            [
              qn,
              o.value,
              void 0,
              { number: !0 }
            ]
          ]),
          s.value ? Et((D(), K("div", {
            key: 0,
            class: "htw-absolute",
            style: Pt(h.value)
          }, null, 4)), [
            [Ct(me), { content: a.modelValue.toString(), shown: !0, distance: 16, delay: 0 }]
          ]) : te("", !0)
        ])
      ]),
      _: 1
    }, 8, ["title", "class", "style"]));
  }
}), Ua = ["value"], Ya = {
  name: "HstTextarea",
  inheritAttrs: !1
}, Qa = /* @__PURE__ */ et({
  ...Ya,
  props: {
    title: {},
    modelValue: {}
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = t, i = lt();
    return (s, r) => (D(), Q(Vt, {
      title: s.title,
      class: dt(["histoire-textarea htw-cursor-text", s.$attrs.class]),
      style: Pt(s.$attrs.style),
      onClick: r[1] || (r[1] = (o) => i.value.focus())
    }, {
      actions: G(() => [
        ht(s.$slots, "actions")
      ]),
      default: G(() => [
        B("textarea", He({
          ref_key: "input",
          ref: i
        }, { ...s.$attrs, class: null, style: null }, {
          value: s.modelValue,
          class: "htw-text-inherit htw-bg-transparent htw-w-full htw-outline-none htw-px-2 htw-py-1 -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 focus:htw-border-primary-500 dark:focus:htw-border-primary-500 htw-rounded-sm htw-box-border htw-resize-y htw-min-h-[26px]",
          onInput: r[0] || (r[0] = (o) => e("update:modelValue", o.target.value))
        }), null, 16, Ua)
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
}), Ja = { class: "htw-cursor-pointer htw-w-full htw-outline-none htw-px-2 htw-h-[27px] -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 hover:htw-border-primary-500 dark:hover:htw-border-primary-500 htw-rounded-sm htw-flex htw-gap-2 htw-items-center htw-leading-normal" }, Xa = { class: "htw-flex-1 htw-truncate" }, Za = { class: "htw-flex htw-flex-col htw-bg-gray-50 dark:htw-bg-gray-700" }, tc = ["onClick"], ec = {
  name: "CustomSelect"
}, ic = /* @__PURE__ */ et({
  ...ec,
  props: {
    modelValue: {},
    options: {}
  },
  emits: ["update:modelValue"],
  setup(n, { emit: t }) {
    const e = n, i = t, s = nt(() => Array.isArray(e.options) ? e.options.map((l) => typeof l == "string" || typeof l == "number" ? [l, String(l)] : [l.value, l.label]) : Object.entries(e.options)), r = nt(() => {
      var l;
      return (l = s.value.find(([h]) => h === e.modelValue)) == null ? void 0 : l[1];
    });
    function o(l, h) {
      i("update:modelValue", l), h();
    }
    return (l, h) => (D(), Q(Ct(ka), {
      "auto-size": "",
      "auto-boundary-max-size": ""
    }, {
      popper: G(({ hide: a }) => [
        B("div", Za, [
          (D(!0), K(ge, null, Ve(s.value, ([c, f]) => (D(), K("div", He({ ...l.$attrs, class: null, style: null }, {
            key: f,
            class: ["htw-px-2 htw-py-1 htw-cursor-pointer hover:htw-bg-primary-100 dark:hover:htw-bg-primary-700", {
              "htw-bg-primary-200 dark:htw-bg-primary-800": e.modelValue === c
            }],
            onClick: (u) => o(c, a)
          }), Dt(f), 17, tc))), 128))
        ])
      ]),
      default: G(() => [
        B("div", Ja, [
          B("div", Xa, [
            ht(l.$slots, "default", { label: r.value }, () => [
              se(Dt(r.value), 1)
            ])
          ]),
          Ts(Ct(Gn), {
            icon: "carbon:chevron-sort",
            class: "htw-w-4 htw-h-4 htw-flex-none htw-ml-auto"
          })
        ])
      ]),
      _: 3
    }));
  }
}), sc = {
  name: "HstSelect"
}, nc = /* @__PURE__ */ et({
  ...sc,
  props: {
    title: {},
    modelValue: {},
    options: {}
  },
  emits: ["update:modelValue"],
  setup(n, { emit: t }) {
    const e = t;
    return (i, s) => (D(), Q(Vt, {
      title: i.title,
      class: dt(["histoire-select htw-cursor-text htw-items-center", i.$attrs.class]),
      style: Pt(i.$attrs.style)
    }, {
      actions: G(() => [
        ht(i.$slots, "actions")
      ]),
      default: G(() => [
        Ts(ic, {
          options: i.options,
          "model-value": i.modelValue,
          "onUpdate:modelValue": s[0] || (s[0] = (r) => e("update:modelValue", r))
        }, null, 8, ["options", "model-value"])
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
}), rc = {
  name: "HstCopyIcon"
}, Le = /* @__PURE__ */ et({
  ...rc,
  props: {
    content: { type: [String, Function] }
  },
  setup(n) {
    const t = n, { copy: e, copied: i } = xa();
    async function s() {
      const r = typeof t.content == "function" ? await t.content() : t.content;
      e(r);
    }
    return (r, o) => Et((D(), Q(Ct(Gn), {
      icon: "carbon:copy-file",
      class: "htw-w-4 htw-h-4 htw-opacity-50 hover:htw-opacity-100 hover:htw-text-primary-500 htw-cursor-pointer",
      onClick: o[0] || (o[0] = (l) => s())
    }, null, 512)), [
      [Ct(me), {
        content: "Copied!",
        triggers: [],
        shown: Ct(i),
        distance: 12,
        delay: 0
      }]
    ]);
  }
}), oc = {
  key: 0,
  class: "histoire-color-shades htw-grid htw-gap-4 htw-grid-cols-[repeat(auto-fill,minmax(200px,1fr))] htw-m-4"
}, lc = ["onMouseenter"], hc = { class: "htw-flex htw-gap-1" }, ac = { class: "htw-my-0 htw-truncate htw-shrink" }, cc = { class: "htw-flex htw-gap-1" }, fc = { class: "htw-my-0 htw-opacity-50 htw-truncate htw-shrink" }, uc = {
  name: "HstColorShades"
}, dc = /* @__PURE__ */ et({
  ...uc,
  props: {
    shades: {},
    getName: { type: Function },
    search: {}
  },
  setup(n) {
    const t = n;
    function e(o, l = "") {
      return Object.entries(o).reduce((h, [a, c]) => {
        const f = l ? a === "DEFAULT" ? l : `${l}-${a}` : a, u = typeof c == "object" ? e(c, f) : { [f]: c };
        return { ...h, ...u };
      }, {});
    }
    const i = nt(() => {
      const o = t.shades, l = t.getName, h = e(o);
      return Object.entries(h).map(([a, c]) => {
        const f = l ? l(a, c) : a;
        return {
          key: a,
          color: c,
          name: f
        };
      });
    }), s = nt(() => {
      let o = i.value;
      if (t.search) {
        const l = new RegExp(t.search, "i");
        o = o.filter(({ name: h }) => l.test(h));
      }
      return o;
    }), r = lt(null);
    return (o, l) => s.value.length ? (D(), K("div", oc, [
      (D(!0), K(ge, null, Ve(s.value, (h) => (D(), K("div", {
        key: h.key,
        class: "htw-flex htw-flex-col htw-gap-2",
        onMouseenter: (a) => r.value = h.key,
        onMouseleave: l[0] || (l[0] = (a) => r.value = null)
      }, [
        ht(o.$slots, "default", {
          color: h.color
        }, () => [
          B("div", {
            class: "htw-rounded-full htw-w-16 htw-h-16",
            style: Pt({
              backgroundColor: h.color
            })
          }, null, 4)
        ]),
        B("div", null, [
          B("div", hc, [
            Et((D(), K("pre", ac, [
              se(Dt(h.name), 1)
            ])), [
              [Ct(me), h.name.length > 23 ? h.name : ""]
            ]),
            r.value === h.key ? (D(), Q(Le, {
              key: 0,
              content: h.name,
              class: "htw-flex-none"
            }, null, 8, ["content"])) : te("", !0)
          ]),
          B("div", cc, [
            Et((D(), K("pre", fc, [
              se(Dt(h.color), 1)
            ])), [
              [Ct(me), h.color.length > 23 ? h.color : ""]
            ]),
            r.value === h.key ? (D(), Q(Le, {
              key: 0,
              content: h.color,
              class: "htw-flex-none"
            }, null, 8, ["content"])) : te("", !0)
          ])
        ])
      ], 40, lc))), 128))
    ])) : te("", !0);
  }
}), pc = ["onMouseenter"], gc = { class: "htw-mx-4" }, mc = { class: "htw-flex htw-gap-1" }, wc = { class: "htw-my-0 htw-truncate htw-shrink" }, yc = { class: "htw-flex htw-gap-1" }, bc = { class: "htw-my-0 htw-opacity-50 htw-truncate htw-shrink" }, kc = {
  name: "HstTokenList"
}, xc = /* @__PURE__ */ et({
  ...kc,
  props: {
    tokens: {},
    getName: { type: Function }
  },
  setup(n) {
    const t = n, e = nt(() => {
      const s = t.tokens, r = t.getName;
      return Object.entries(s).map(([o, l]) => {
        const h = r ? r(o, l) : o;
        return {
          key: o,
          name: h,
          value: typeof l == "number" ? l.toString() : l
        };
      });
    }), i = lt(null);
    return (s, r) => (D(!0), K(ge, null, Ve(e.value, (o) => (D(), K("div", {
      key: o.key,
      class: "histoire-token-list htw-flex htw-flex-col htw-gap-2 htw-my-8",
      onMouseenter: (l) => i.value = o.key,
      onMouseleave: r[0] || (r[0] = (l) => i.value = null)
    }, [
      ht(s.$slots, "default", { token: o }),
      B("div", gc, [
        B("div", mc, [
          B("pre", wc, Dt(o.name), 1),
          i.value === o.key ? (D(), Q(Le, {
            key: 0,
            content: o.name,
            class: "htw-flex-none"
          }, null, 8, ["content"])) : te("", !0)
        ]),
        B("div", yc, [
          B("pre", bc, Dt(o.value), 1),
          i.value === o.key ? (D(), Q(Le, {
            key: 0,
            content: typeof o.value == "string" ? o.value : JSON.stringify(o.value),
            class: "htw-flex-none"
          }, null, 8, ["content"])) : te("", !0)
        ])
      ])
    ], 40, pc))), 128));
  }
}), vc = ["onMouseenter"], Sc = { class: "htw-flex htw-gap-1" }, Cc = { class: "htw-my-0 htw-truncate htw-shrink" }, Ac = { class: "htw-flex htw-gap-1" }, Oc = { class: "htw-my-0 htw-opacity-50 htw-truncate htw-shrink" }, Mc = {
  name: "HstTokenGrid"
}, Tc = /* @__PURE__ */ et({
  ...Mc,
  props: {
    tokens: {},
    colSize: { default: 180 },
    getName: { type: Function, default: null }
  },
  setup(n) {
    const t = n, e = nt(() => {
      const r = t.tokens, o = t.getName;
      return Object.entries(r).map(([l, h]) => {
        const a = o ? o(l, h) : l;
        return {
          key: l,
          name: a,
          value: typeof h == "number" ? h.toString() : h
        };
      });
    }), i = nt(() => `${t.colSize}px`), s = lt(null);
    return (r, o) => (D(), K("div", {
      class: "histoire-token-grid htw-bind-col-size htw-grid htw-gap-4 htw-m-4",
      style: Pt({
        "--histoire-col-size": i.value
      })
    }, [
      (D(!0), K(ge, null, Ve(e.value, (l) => (D(), K("div", {
        key: l.key,
        class: "htw-flex htw-flex-col htw-gap-2",
        onMouseenter: (h) => s.value = l.key,
        onMouseleave: o[0] || (o[0] = (h) => s.value = null)
      }, [
        ht(r.$slots, "default", { token: l }),
        B("div", null, [
          B("div", Sc, [
            Et((D(), K("pre", Cc, [
              se(Dt(l.name), 1)
            ])), [
              [Ct(me), l.name.length > r.colSize / 8 ? l.name : ""]
            ]),
            s.value === l.key ? (D(), Q(Le, {
              key: 0,
              content: l.name,
              class: "htw-flex-none"
            }, null, 8, ["content"])) : te("", !0)
          ]),
          B("div", Ac, [
            Et((D(), K("pre", Oc, [
              se(Dt(l.value), 1)
            ])), [
              [Ct(me), l.value.length > r.colSize / 8 ? l.value : ""]
            ]),
            s.value === l.key ? (D(), Q(Le, {
              key: 0,
              content: typeof l.value == "string" ? l.value : JSON.stringify(l.value),
              class: "htw-flex-none"
            }, null, 8, ["content"])) : te("", !0)
          ])
        ])
      ], 40, vc))), 128))
    ], 4));
  }
}), Dc = { class: "-htw-my-1" }, Pc = ["id", "name", "value", "checked", "onChange"], Bc = ["for", "onKeydown"], Rc = {
  name: "HstRadio"
}, Lc = /* @__PURE__ */ et({
  ...Rc,
  props: {
    title: {},
    modelValue: {},
    options: {}
  },
  emits: ["update:modelValue"],
  setup(n, { emit: t }) {
    const e = n, i = nt(() => Array.isArray(e.options) ? Object.fromEntries(e.options.map((l) => typeof l == "string" ? [l, l] : [l.value, l.label])) : e.options), s = t;
    function r(l) {
      s("update:modelValue", l), o.value = !0;
    }
    const o = lt(!1);
    return (l, h) => (D(), Q(Vt, {
      role: "group",
      title: l.title,
      class: dt(["histoire-radio htw-cursor-text", l.$attrs.class]),
      style: Pt(l.$attrs.style)
    }, {
      actions: G(() => [
        ht(l.$slots, "actions")
      ]),
      default: G(() => [
        B("div", Dc, [
          (D(!0), K(ge, null, Ve(i.value, (a, c) => (D(), K(ge, { key: c }, [
            B("input", {
              id: `${c}-radio_${l.title}`,
              type: "radio",
              name: `${c}-radio_${l.title}`,
              value: c,
              checked: c === l.modelValue,
              class: "!htw-hidden",
              onChange: (f) => r(c)
            }, null, 40, Pc),
            B("label", {
              tabindex: "0",
              for: `${c}-radio_${l.title}`,
              class: "htw-cursor-pointer htw-flex htw-items-center htw-relative htw-py-1 htw-group",
              onKeydown: [
                Ue(Ye((f) => r(c), ["prevent"]), ["enter"]),
                Ue(Ye((f) => r(c), ["prevent"]), ["space"])
              ]
            }, [
              (D(), K("svg", {
                width: "16",
                height: "16",
                viewBox: "-12 -12 24 24",
                class: dt(["htw-relative htw-z-10 htw-border htw-border-solid htw-text-inherit htw-rounded-full htw-box-border htw-inset-0 htw-transition-border htw-duration-150 htw-ease-out htw-mr-2 group-hover:htw-border-primary-500", [
                  l.modelValue === c ? "htw-border-primary-500" : "htw-border-black/25 dark:htw-border-white/25"
                ]])
              }, [
                B("circle", {
                  r: "7",
                  class: dt(["htw-will-change-transform", [
                    o.value ? "htw-transition-all" : "htw-transition-none",
                    {
                      "htw-delay-150": l.modelValue === c
                    },
                    l.modelValue === c ? "htw-fill-primary-500" : "htw-fill-transparent htw-scale-0"
                  ]])
                }, null, 2)
              ], 2)),
              se(" " + Dt(a), 1)
            ], 40, Bc)
          ], 64))), 128))
        ])
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
});
class V {
  /**
  Get the line description around the given position.
  */
  lineAt(t) {
    if (t < 0 || t > this.length)
      throw new RangeError(`Invalid position ${t} in document of length ${this.length}`);
    return this.lineInner(t, !1, 1, 0);
  }
  /**
  Get the description for the given (1-based) line number.
  */
  line(t) {
    if (t < 1 || t > this.lines)
      throw new RangeError(`Invalid line number ${t} in ${this.lines}-line document`);
    return this.lineInner(t, !0, 1, 0);
  }
  /**
  Replace a range of the text with the given content.
  */
  replace(t, e, i) {
    let s = [];
    return this.decompose(
      0,
      t,
      s,
      2
      /* Open.To */
    ), i.length && i.decompose(
      0,
      i.length,
      s,
      3
      /* Open.To */
    ), this.decompose(
      e,
      this.length,
      s,
      1
      /* Open.From */
    ), qt.from(s, this.length - (e - t) + i.length);
  }
  /**
  Append another document to this one.
  */
  append(t) {
    return this.replace(this.length, this.length, t);
  }
  /**
  Retrieve the text between the given points.
  */
  slice(t, e = this.length) {
    let i = [];
    return this.decompose(t, e, i, 0), qt.from(i, e - t);
  }
  /**
  Test whether this text is equal to another instance.
  */
  eq(t) {
    if (t == this)
      return !0;
    if (t.length != this.length || t.lines != this.lines)
      return !1;
    let e = this.scanIdentical(t, 1), i = this.length - this.scanIdentical(t, -1), s = new ui(this), r = new ui(t);
    for (let o = e, l = e; ; ) {
      if (s.next(o), r.next(o), o = 0, s.lineBreak != r.lineBreak || s.done != r.done || s.value != r.value)
        return !1;
      if (l += s.value.length, s.done || l >= i)
        return !0;
    }
  }
  /**
  Iterate over the text. When `dir` is `-1`, iteration happens
  from end to start. This will return lines and the breaks between
  them as separate strings.
  */
  iter(t = 1) {
    return new ui(this, t);
  }
  /**
  Iterate over a range of the text. When `from` > `to`, the
  iterator will run in reverse.
  */
  iterRange(t, e = this.length) {
    return new el(this, t, e);
  }
  /**
  Return a cursor that iterates over the given range of lines,
  _without_ returning the line breaks between, and yielding empty
  strings for empty lines.
  
  When `from` and `to` are given, they should be 1-based line numbers.
  */
  iterLines(t, e) {
    let i;
    if (t == null)
      i = this.iter();
    else {
      e == null && (e = this.lines + 1);
      let s = this.line(t).from;
      i = this.iterRange(s, Math.max(s, e == this.lines + 1 ? this.length : e <= 1 ? 0 : this.line(e - 1).to));
    }
    return new il(i);
  }
  /**
  Return the document as a string, using newline characters to
  separate lines.
  */
  toString() {
    return this.sliceString(0);
  }
  /**
  Convert the document to an array of lines (which can be
  deserialized again via [`Text.of`](https://codemirror.net/6/docs/ref/#state.Text^of)).
  */
  toJSON() {
    let t = [];
    return this.flatten(t), t;
  }
  /**
  @internal
  */
  constructor() {
  }
  /**
  Create a `Text` instance for the given array of lines.
  */
  static of(t) {
    if (t.length == 0)
      throw new RangeError("A document must have at least one line");
    return t.length == 1 && !t[0] ? V.empty : t.length <= 32 ? new J(t) : qt.from(J.split(t, []));
  }
}
class J extends V {
  constructor(t, e = Ec(t)) {
    super(), this.text = t, this.length = e;
  }
  get lines() {
    return this.text.length;
  }
  get children() {
    return null;
  }
  lineInner(t, e, i, s) {
    for (let r = 0; ; r++) {
      let o = this.text[r], l = s + o.length;
      if ((e ? i : l) >= t)
        return new Nc(s, l, i, o);
      s = l + 1, i++;
    }
  }
  decompose(t, e, i, s) {
    let r = t <= 0 && e >= this.length ? this : new J(br(this.text, t, e), Math.min(e, this.length) - Math.max(0, t));
    if (s & 1) {
      let o = i.pop(), l = Xi(r.text, o.text.slice(), 0, r.length);
      if (l.length <= 32)
        i.push(new J(l, o.length + r.length));
      else {
        let h = l.length >> 1;
        i.push(new J(l.slice(0, h)), new J(l.slice(h)));
      }
    } else
      i.push(r);
  }
  replace(t, e, i) {
    if (!(i instanceof J))
      return super.replace(t, e, i);
    let s = Xi(this.text, Xi(i.text, br(this.text, 0, t)), e), r = this.length + i.length - (e - t);
    return s.length <= 32 ? new J(s, r) : qt.from(J.split(s, []), r);
  }
  sliceString(t, e = this.length, i = `
`) {
    let s = "";
    for (let r = 0, o = 0; r <= e && o < this.text.length; o++) {
      let l = this.text[o], h = r + l.length;
      r > t && o && (s += i), t < h && e > r && (s += l.slice(Math.max(0, t - r), e - r)), r = h + 1;
    }
    return s;
  }
  flatten(t) {
    for (let e of this.text)
      t.push(e);
  }
  scanIdentical() {
    return 0;
  }
  static split(t, e) {
    let i = [], s = -1;
    for (let r of t)
      i.push(r), s += r.length + 1, i.length == 32 && (e.push(new J(i, s)), i = [], s = -1);
    return s > -1 && e.push(new J(i, s)), e;
  }
}
class qt extends V {
  constructor(t, e) {
    super(), this.children = t, this.length = e, this.lines = 0;
    for (let i of t)
      this.lines += i.lines;
  }
  lineInner(t, e, i, s) {
    for (let r = 0; ; r++) {
      let o = this.children[r], l = s + o.length, h = i + o.lines - 1;
      if ((e ? h : l) >= t)
        return o.lineInner(t, e, i, s);
      s = l + 1, i = h + 1;
    }
  }
  decompose(t, e, i, s) {
    for (let r = 0, o = 0; o <= e && r < this.children.length; r++) {
      let l = this.children[r], h = o + l.length;
      if (t <= h && e >= o) {
        let a = s & ((o <= t ? 1 : 0) | (h >= e ? 2 : 0));
        o >= t && h <= e && !a ? i.push(l) : l.decompose(t - o, e - o, i, a);
      }
      o = h + 1;
    }
  }
  replace(t, e, i) {
    if (i.lines < this.lines)
      for (let s = 0, r = 0; s < this.children.length; s++) {
        let o = this.children[s], l = r + o.length;
        if (t >= r && e <= l) {
          let h = o.replace(t - r, e - r, i), a = this.lines - o.lines + h.lines;
          if (h.lines < a >> 4 && h.lines > a >> 6) {
            let c = this.children.slice();
            return c[s] = h, new qt(c, this.length - (e - t) + i.length);
          }
          return super.replace(r, l, h);
        }
        r = l + 1;
      }
    return super.replace(t, e, i);
  }
  sliceString(t, e = this.length, i = `
`) {
    let s = "";
    for (let r = 0, o = 0; r < this.children.length && o <= e; r++) {
      let l = this.children[r], h = o + l.length;
      o > t && r && (s += i), t < h && e > o && (s += l.sliceString(t - o, e - o, i)), o = h + 1;
    }
    return s;
  }
  flatten(t) {
    for (let e of this.children)
      e.flatten(t);
  }
  scanIdentical(t, e) {
    if (!(t instanceof qt))
      return 0;
    let i = 0, [s, r, o, l] = e > 0 ? [0, 0, this.children.length, t.children.length] : [this.children.length - 1, t.children.length - 1, -1, -1];
    for (; ; s += e, r += e) {
      if (s == o || r == l)
        return i;
      let h = this.children[s], a = t.children[r];
      if (h != a)
        return i + h.scanIdentical(a, e);
      i += h.length + 1;
    }
  }
  static from(t, e = t.reduce((i, s) => i + s.length + 1, -1)) {
    let i = 0;
    for (let d of t)
      i += d.lines;
    if (i < 32) {
      let d = [];
      for (let p of t)
        p.flatten(d);
      return new J(d, e);
    }
    let s = Math.max(
      32,
      i >> 5
      /* Tree.BranchShift */
    ), r = s << 1, o = s >> 1, l = [], h = 0, a = -1, c = [];
    function f(d) {
      let p;
      if (d.lines > r && d instanceof qt)
        for (let m of d.children)
          f(m);
      else
        d.lines > o && (h > o || !h) ? (u(), l.push(d)) : d instanceof J && h && (p = c[c.length - 1]) instanceof J && d.lines + p.lines <= 32 ? (h += d.lines, a += d.length + 1, c[c.length - 1] = new J(p.text.concat(d.text), p.length + 1 + d.length)) : (h + d.lines > s && u(), h += d.lines, a += d.length + 1, c.push(d));
    }
    function u() {
      h != 0 && (l.push(c.length == 1 ? c[0] : qt.from(c, a)), a = -1, h = c.length = 0);
    }
    for (let d of t)
      f(d);
    return u(), l.length == 1 ? l[0] : new qt(l, e);
  }
}
V.empty = /* @__PURE__ */ new J([""], 0);
function Ec(n) {
  let t = -1;
  for (let e of n)
    t += e.length + 1;
  return t;
}
function Xi(n, t, e = 0, i = 1e9) {
  for (let s = 0, r = 0, o = !0; r < n.length && s <= i; r++) {
    let l = n[r], h = s + l.length;
    h >= e && (h > i && (l = l.slice(0, i - s)), s < e && (l = l.slice(e - s)), o ? (t[t.length - 1] += l, o = !1) : t.push(l)), s = h + 1;
  }
  return t;
}
function br(n, t, e) {
  return Xi(n, [""], t, e);
}
class ui {
  constructor(t, e = 1) {
    this.dir = e, this.done = !1, this.lineBreak = !1, this.value = "", this.nodes = [t], this.offsets = [e > 0 ? 1 : (t instanceof J ? t.text.length : t.children.length) << 1];
  }
  nextInner(t, e) {
    for (this.done = this.lineBreak = !1; ; ) {
      let i = this.nodes.length - 1, s = this.nodes[i], r = this.offsets[i], o = r >> 1, l = s instanceof J ? s.text.length : s.children.length;
      if (o == (e > 0 ? l : 0)) {
        if (i == 0)
          return this.done = !0, this.value = "", this;
        e > 0 && this.offsets[i - 1]++, this.nodes.pop(), this.offsets.pop();
      } else if ((r & 1) == (e > 0 ? 0 : 1)) {
        if (this.offsets[i] += e, t == 0)
          return this.lineBreak = !0, this.value = `
`, this;
        t--;
      } else if (s instanceof J) {
        let h = s.text[o + (e < 0 ? -1 : 0)];
        if (this.offsets[i] += e, h.length > Math.max(0, t))
          return this.value = t == 0 ? h : e > 0 ? h.slice(t) : h.slice(0, h.length - t), this;
        t -= h.length;
      } else {
        let h = s.children[o + (e < 0 ? -1 : 0)];
        t > h.length ? (t -= h.length, this.offsets[i] += e) : (e < 0 && this.offsets[i]--, this.nodes.push(h), this.offsets.push(e > 0 ? 1 : (h instanceof J ? h.text.length : h.children.length) << 1));
      }
    }
  }
  next(t = 0) {
    return t < 0 && (this.nextInner(-t, -this.dir), t = this.value.length), this.nextInner(t, this.dir);
  }
}
class el {
  constructor(t, e, i) {
    this.value = "", this.done = !1, this.cursor = new ui(t, e > i ? -1 : 1), this.pos = e > i ? t.length : 0, this.from = Math.min(e, i), this.to = Math.max(e, i);
  }
  nextInner(t, e) {
    if (e < 0 ? this.pos <= this.from : this.pos >= this.to)
      return this.value = "", this.done = !0, this;
    t += Math.max(0, e < 0 ? this.pos - this.to : this.from - this.pos);
    let i = e < 0 ? this.pos - this.from : this.to - this.pos;
    t > i && (t = i), i -= t;
    let { value: s } = this.cursor.next(t);
    return this.pos += (s.length + t) * e, this.value = s.length <= i ? s : e < 0 ? s.slice(s.length - i) : s.slice(0, i), this.done = !this.value, this;
  }
  next(t = 0) {
    return t < 0 ? t = Math.max(t, this.from - this.pos) : t > 0 && (t = Math.min(t, this.to - this.pos)), this.nextInner(t, this.cursor.dir);
  }
  get lineBreak() {
    return this.cursor.lineBreak && this.value != "";
  }
}
class il {
  constructor(t) {
    this.inner = t, this.afterBreak = !0, this.value = "", this.done = !1;
  }
  next(t = 0) {
    let { done: e, lineBreak: i, value: s } = this.inner.next(t);
    return e ? (this.done = !0, this.value = "") : i ? this.afterBreak ? this.value = "" : (this.afterBreak = !0, this.next()) : (this.value = s, this.afterBreak = !1), this;
  }
  get lineBreak() {
    return !1;
  }
}
typeof Symbol < "u" && (V.prototype[Symbol.iterator] = function() {
  return this.iter();
}, ui.prototype[Symbol.iterator] = el.prototype[Symbol.iterator] = il.prototype[Symbol.iterator] = function() {
  return this;
});
class Nc {
  /**
  @internal
  */
  constructor(t, e, i, s) {
    this.from = t, this.to = e, this.number = i, this.text = s;
  }
  /**
  The length of the line (not including any line break after it).
  */
  get length() {
    return this.to - this.from;
  }
}
let We = /* @__PURE__ */ "lc,34,7n,7,7b,19,,,,2,,2,,,20,b,1c,l,g,,2t,7,2,6,2,2,,4,z,,u,r,2j,b,1m,9,9,,o,4,,9,,3,,5,17,3,3b,f,,w,1j,,,,4,8,4,,3,7,a,2,t,,1m,,,,2,4,8,,9,,a,2,q,,2,2,1l,,4,2,4,2,2,3,3,,u,2,3,,b,2,1l,,4,5,,2,4,,k,2,m,6,,,1m,,,2,,4,8,,7,3,a,2,u,,1n,,,,c,,9,,14,,3,,1l,3,5,3,,4,7,2,b,2,t,,1m,,2,,2,,3,,5,2,7,2,b,2,s,2,1l,2,,,2,4,8,,9,,a,2,t,,20,,4,,2,3,,,8,,29,,2,7,c,8,2q,,2,9,b,6,22,2,r,,,,,,1j,e,,5,,2,5,b,,10,9,,2u,4,,6,,2,2,2,p,2,4,3,g,4,d,,2,2,6,,f,,jj,3,qa,3,t,3,t,2,u,2,1s,2,,7,8,,2,b,9,,19,3,3b,2,y,,3a,3,4,2,9,,6,3,63,2,2,,1m,,,7,,,,,2,8,6,a,2,,1c,h,1r,4,1c,7,,,5,,14,9,c,2,w,4,2,2,,3,1k,,,2,3,,,3,1m,8,2,2,48,3,,d,,7,4,,6,,3,2,5i,1m,,5,ek,,5f,x,2da,3,3x,,2o,w,fe,6,2x,2,n9w,4,,a,w,2,28,2,7k,,3,,4,,p,2,5,,47,2,q,i,d,,12,8,p,b,1a,3,1c,,2,4,2,2,13,,1v,6,2,2,2,2,c,,8,,1b,,1f,,,3,2,2,5,2,,,16,2,8,,6m,,2,,4,,fn4,,kh,g,g,g,a6,2,gt,,6a,,45,5,1ae,3,,2,5,4,14,3,4,,4l,2,fx,4,ar,2,49,b,4w,,1i,f,1k,3,1d,4,2,2,1x,3,10,5,,8,1q,,c,2,1g,9,a,4,2,,2n,3,2,,,2,6,,4g,,3,8,l,2,1l,2,,,,,m,,e,7,3,5,5f,8,2,3,,,n,,29,,2,6,,,2,,,2,,2,6j,,2,4,6,2,,2,r,2,2d,8,2,,,2,2y,,,,2,6,,,2t,3,2,4,,5,77,9,,2,6t,,a,2,,,4,,40,4,2,2,4,,w,a,14,6,2,4,8,,9,6,2,3,1a,d,,2,ba,7,,6,,,2a,m,2,7,,2,,2,3e,6,3,,,2,,7,,,20,2,3,,,,9n,2,f0b,5,1n,7,t4,,1r,4,29,,f5k,2,43q,,,3,4,5,8,8,2,7,u,4,44,3,1iz,1j,4,1e,8,,e,,m,5,,f,11s,7,,h,2,7,,2,,5,79,7,c5,4,15s,7,31,7,240,5,gx7k,2o,3k,6o".split(",").map((n) => n ? parseInt(n, 36) : 1);
for (let n = 1; n < We.length; n++)
  We[n] += We[n - 1];
function Ic(n) {
  for (let t = 1; t < We.length; t += 2)
    if (We[t] > n)
      return We[t - 1] <= n;
  return !1;
}
function kr(n) {
  return n >= 127462 && n <= 127487;
}
const xr = 8205;
function wt(n, t, e = !0, i = !0) {
  return (e ? sl : Vc)(n, t, i);
}
function sl(n, t, e) {
  if (t == n.length)
    return t;
  t && nl(n.charCodeAt(t)) && rl(n.charCodeAt(t - 1)) && t--;
  let i = di(n, t);
  for (t += nn(i); t < n.length; ) {
    let s = di(n, t);
    if (i == xr || s == xr || e && Ic(s))
      t += nn(s), i = s;
    else if (kr(s)) {
      let r = 0, o = t - 2;
      for (; o >= 0 && kr(di(n, o)); )
        r++, o -= 2;
      if (r % 2 == 0)
        break;
      t += 2;
    } else
      break;
  }
  return t;
}
function Vc(n, t, e) {
  for (; t > 0; ) {
    let i = sl(n, t - 2, e);
    if (i < t)
      return i;
    t--;
  }
  return 0;
}
function nl(n) {
  return n >= 56320 && n < 57344;
}
function rl(n) {
  return n >= 55296 && n < 56320;
}
function di(n, t) {
  let e = n.charCodeAt(t);
  if (!rl(e) || t + 1 == n.length)
    return e;
  let i = n.charCodeAt(t + 1);
  return nl(i) ? (e - 55296 << 10) + (i - 56320) + 65536 : e;
}
function nn(n) {
  return n < 65536 ? 1 : 2;
}
const rn = /\r\n?|\n/;
var mt = /* @__PURE__ */ function(n) {
  return n[n.Simple = 0] = "Simple", n[n.TrackDel = 1] = "TrackDel", n[n.TrackBefore = 2] = "TrackBefore", n[n.TrackAfter = 3] = "TrackAfter", n;
}(mt || (mt = {}));
class ee {
  // Sections are encoded as pairs of integers. The first is the
  // length in the current document, and the second is -1 for
  // unaffected sections, and the length of the replacement content
  // otherwise. So an insertion would be (0, n>0), a deletion (n>0,
  // 0), and a replacement two positive numbers.
  /**
  @internal
  */
  constructor(t) {
    this.sections = t;
  }
  /**
  The length of the document before the change.
  */
  get length() {
    let t = 0;
    for (let e = 0; e < this.sections.length; e += 2)
      t += this.sections[e];
    return t;
  }
  /**
  The length of the document after the change.
  */
  get newLength() {
    let t = 0;
    for (let e = 0; e < this.sections.length; e += 2) {
      let i = this.sections[e + 1];
      t += i < 0 ? this.sections[e] : i;
    }
    return t;
  }
  /**
  False when there are actual changes in this set.
  */
  get empty() {
    return this.sections.length == 0 || this.sections.length == 2 && this.sections[1] < 0;
  }
  /**
  Iterate over the unchanged parts left by these changes. `posA`
  provides the position of the range in the old document, `posB`
  the new position in the changed document.
  */
  iterGaps(t) {
    for (let e = 0, i = 0, s = 0; e < this.sections.length; ) {
      let r = this.sections[e++], o = this.sections[e++];
      o < 0 ? (t(i, s, r), s += r) : s += o, i += r;
    }
  }
  /**
  Iterate over the ranges changed by these changes. (See
  [`ChangeSet.iterChanges`](https://codemirror.net/6/docs/ref/#state.ChangeSet.iterChanges) for a
  variant that also provides you with the inserted text.)
  `fromA`/`toA` provides the extent of the change in the starting
  document, `fromB`/`toB` the extent of the replacement in the
  changed document.
  
  When `individual` is true, adjacent changes (which are kept
  separate for [position mapping](https://codemirror.net/6/docs/ref/#state.ChangeDesc.mapPos)) are
  reported separately.
  */
  iterChangedRanges(t, e = !1) {
    on(this, t, e);
  }
  /**
  Get a description of the inverted form of these changes.
  */
  get invertedDesc() {
    let t = [];
    for (let e = 0; e < this.sections.length; ) {
      let i = this.sections[e++], s = this.sections[e++];
      s < 0 ? t.push(i, s) : t.push(s, i);
    }
    return new ee(t);
  }
  /**
  Compute the combined effect of applying another set of changes
  after this one. The length of the document after this set should
  match the length before `other`.
  */
  composeDesc(t) {
    return this.empty ? t : t.empty ? this : ol(this, t);
  }
  /**
  Map this description, which should start with the same document
  as `other`, over another set of changes, so that it can be
  applied after it. When `before` is true, map as if the changes
  in `other` happened before the ones in `this`.
  */
  mapDesc(t, e = !1) {
    return t.empty ? this : ln(this, t, e);
  }
  mapPos(t, e = -1, i = mt.Simple) {
    let s = 0, r = 0;
    for (let o = 0; o < this.sections.length; ) {
      let l = this.sections[o++], h = this.sections[o++], a = s + l;
      if (h < 0) {
        if (a > t)
          return r + (t - s);
        r += l;
      } else {
        if (i != mt.Simple && a >= t && (i == mt.TrackDel && s < t && a > t || i == mt.TrackBefore && s < t || i == mt.TrackAfter && a > t))
          return null;
        if (a > t || a == t && e < 0 && !l)
          return t == s || e < 0 ? r : r + h;
        r += h;
      }
      s = a;
    }
    if (t > s)
      throw new RangeError(`Position ${t} is out of range for changeset of length ${s}`);
    return r;
  }
  /**
  Check whether these changes touch a given range. When one of the
  changes entirely covers the range, the string `"cover"` is
  returned.
  */
  touchesRange(t, e = t) {
    for (let i = 0, s = 0; i < this.sections.length && s <= e; ) {
      let r = this.sections[i++], o = this.sections[i++], l = s + r;
      if (o >= 0 && s <= e && l >= t)
        return s < t && l > e ? "cover" : !0;
      s = l;
    }
    return !1;
  }
  /**
  @internal
  */
  toString() {
    let t = "";
    for (let e = 0; e < this.sections.length; ) {
      let i = this.sections[e++], s = this.sections[e++];
      t += (t ? " " : "") + i + (s >= 0 ? ":" + s : "");
    }
    return t;
  }
  /**
  Serialize this change desc to a JSON-representable value.
  */
  toJSON() {
    return this.sections;
  }
  /**
  Create a change desc from its JSON representation (as produced
  by [`toJSON`](https://codemirror.net/6/docs/ref/#state.ChangeDesc.toJSON).
  */
  static fromJSON(t) {
    if (!Array.isArray(t) || t.length % 2 || t.some((e) => typeof e != "number"))
      throw new RangeError("Invalid JSON representation of ChangeDesc");
    return new ee(t);
  }
  /**
  @internal
  */
  static create(t) {
    return new ee(t);
  }
}
class it extends ee {
  constructor(t, e) {
    super(t), this.inserted = e;
  }
  /**
  Apply the changes to a document, returning the modified
  document.
  */
  apply(t) {
    if (this.length != t.length)
      throw new RangeError("Applying change set to a document with the wrong length");
    return on(this, (e, i, s, r, o) => t = t.replace(s, s + (i - e), o), !1), t;
  }
  mapDesc(t, e = !1) {
    return ln(this, t, e, !0);
  }
  /**
  Given the document as it existed _before_ the changes, return a
  change set that represents the inverse of this set, which could
  be used to go from the document created by the changes back to
  the document as it existed before the changes.
  */
  invert(t) {
    let e = this.sections.slice(), i = [];
    for (let s = 0, r = 0; s < e.length; s += 2) {
      let o = e[s], l = e[s + 1];
      if (l >= 0) {
        e[s] = l, e[s + 1] = o;
        let h = s >> 1;
        for (; i.length < h; )
          i.push(V.empty);
        i.push(o ? t.slice(r, r + o) : V.empty);
      }
      r += o;
    }
    return new it(e, i);
  }
  /**
  Combine two subsequent change sets into a single set. `other`
  must start in the document produced by `this`. If `this` goes
  `docA` → `docB` and `other` represents `docB` → `docC`, the
  returned value will represent the change `docA` → `docC`.
  */
  compose(t) {
    return this.empty ? t : t.empty ? this : ol(this, t, !0);
  }
  /**
  Given another change set starting in the same document, maps this
  change set over the other, producing a new change set that can be
  applied to the document produced by applying `other`. When
  `before` is `true`, order changes as if `this` comes before
  `other`, otherwise (the default) treat `other` as coming first.
  
  Given two changes `A` and `B`, `A.compose(B.map(A))` and
  `B.compose(A.map(B, true))` will produce the same document. This
  provides a basic form of [operational
  transformation](https://en.wikipedia.org/wiki/Operational_transformation),
  and can be used for collaborative editing.
  */
  map(t, e = !1) {
    return t.empty ? this : ln(this, t, e, !0);
  }
  /**
  Iterate over the changed ranges in the document, calling `f` for
  each, with the range in the original document (`fromA`-`toA`)
  and the range that replaces it in the new document
  (`fromB`-`toB`).
  
  When `individual` is true, adjacent changes are reported
  separately.
  */
  iterChanges(t, e = !1) {
    on(this, t, e);
  }
  /**
  Get a [change description](https://codemirror.net/6/docs/ref/#state.ChangeDesc) for this change
  set.
  */
  get desc() {
    return ee.create(this.sections);
  }
  /**
  @internal
  */
  filter(t) {
    let e = [], i = [], s = [], r = new mi(this);
    t:
      for (let o = 0, l = 0; ; ) {
        let h = o == t.length ? 1e9 : t[o++];
        for (; l < h || l == h && r.len == 0; ) {
          if (r.done)
            break t;
          let c = Math.min(r.len, h - l);
          at(s, c, -1);
          let f = r.ins == -1 ? -1 : r.off == 0 ? r.ins : 0;
          at(e, c, f), f > 0 && ce(i, e, r.text), r.forward(c), l += c;
        }
        let a = t[o++];
        for (; l < a; ) {
          if (r.done)
            break t;
          let c = Math.min(r.len, a - l);
          at(e, c, -1), at(s, c, r.ins == -1 ? -1 : r.off == 0 ? r.ins : 0), r.forward(c), l += c;
        }
      }
    return {
      changes: new it(e, i),
      filtered: ee.create(s)
    };
  }
  /**
  Serialize this change set to a JSON-representable value.
  */
  toJSON() {
    let t = [];
    for (let e = 0; e < this.sections.length; e += 2) {
      let i = this.sections[e], s = this.sections[e + 1];
      s < 0 ? t.push(i) : s == 0 ? t.push([i]) : t.push([i].concat(this.inserted[e >> 1].toJSON()));
    }
    return t;
  }
  /**
  Create a change set for the given changes, for a document of the
  given length, using `lineSep` as line separator.
  */
  static of(t, e, i) {
    let s = [], r = [], o = 0, l = null;
    function h(c = !1) {
      if (!c && !s.length)
        return;
      o < e && at(s, e - o, -1);
      let f = new it(s, r);
      l = l ? l.compose(f.map(l)) : f, s = [], r = [], o = 0;
    }
    function a(c) {
      if (Array.isArray(c))
        for (let f of c)
          a(f);
      else if (c instanceof it) {
        if (c.length != e)
          throw new RangeError(`Mismatched change set length (got ${c.length}, expected ${e})`);
        h(), l = l ? l.compose(c.map(l)) : c;
      } else {
        let { from: f, to: u = f, insert: d } = c;
        if (f > u || f < 0 || u > e)
          throw new RangeError(`Invalid change range ${f} to ${u} (in doc of length ${e})`);
        let p = d ? typeof d == "string" ? V.of(d.split(i || rn)) : d : V.empty, m = p.length;
        if (f == u && m == 0)
          return;
        f < o && h(), f > o && at(s, f - o, -1), at(s, u - f, m), ce(r, s, p), o = u;
      }
    }
    return a(t), h(!l), l;
  }
  /**
  Create an empty changeset of the given length.
  */
  static empty(t) {
    return new it(t ? [t, -1] : [], []);
  }
  /**
  Create a changeset from its JSON representation (as produced by
  [`toJSON`](https://codemirror.net/6/docs/ref/#state.ChangeSet.toJSON).
  */
  static fromJSON(t) {
    if (!Array.isArray(t))
      throw new RangeError("Invalid JSON representation of ChangeSet");
    let e = [], i = [];
    for (let s = 0; s < t.length; s++) {
      let r = t[s];
      if (typeof r == "number")
        e.push(r, -1);
      else {
        if (!Array.isArray(r) || typeof r[0] != "number" || r.some((o, l) => l && typeof o != "string"))
          throw new RangeError("Invalid JSON representation of ChangeSet");
        if (r.length == 1)
          e.push(r[0], 0);
        else {
          for (; i.length < s; )
            i.push(V.empty);
          i[s] = V.of(r.slice(1)), e.push(r[0], i[s].length);
        }
      }
    }
    return new it(e, i);
  }
  /**
  @internal
  */
  static createSet(t, e) {
    return new it(t, e);
  }
}
function at(n, t, e, i = !1) {
  if (t == 0 && e <= 0)
    return;
  let s = n.length - 2;
  s >= 0 && e <= 0 && e == n[s + 1] ? n[s] += t : t == 0 && n[s] == 0 ? n[s + 1] += e : i ? (n[s] += t, n[s + 1] += e) : n.push(t, e);
}
function ce(n, t, e) {
  if (e.length == 0)
    return;
  let i = t.length - 2 >> 1;
  if (i < n.length)
    n[n.length - 1] = n[n.length - 1].append(e);
  else {
    for (; n.length < i; )
      n.push(V.empty);
    n.push(e);
  }
}
function on(n, t, e) {
  let i = n.inserted;
  for (let s = 0, r = 0, o = 0; o < n.sections.length; ) {
    let l = n.sections[o++], h = n.sections[o++];
    if (h < 0)
      s += l, r += l;
    else {
      let a = s, c = r, f = V.empty;
      for (; a += l, c += h, h && i && (f = f.append(i[o - 2 >> 1])), !(e || o == n.sections.length || n.sections[o + 1] < 0); )
        l = n.sections[o++], h = n.sections[o++];
      t(s, a, r, c, f), s = a, r = c;
    }
  }
}
function ln(n, t, e, i = !1) {
  let s = [], r = i ? [] : null, o = new mi(n), l = new mi(t);
  for (let h = -1; ; )
    if (o.ins == -1 && l.ins == -1) {
      let a = Math.min(o.len, l.len);
      at(s, a, -1), o.forward(a), l.forward(a);
    } else if (l.ins >= 0 && (o.ins < 0 || h == o.i || o.off == 0 && (l.len < o.len || l.len == o.len && !e))) {
      let a = l.len;
      for (at(s, l.ins, -1); a; ) {
        let c = Math.min(o.len, a);
        o.ins >= 0 && h < o.i && o.len <= c && (at(s, 0, o.ins), r && ce(r, s, o.text), h = o.i), o.forward(c), a -= c;
      }
      l.next();
    } else if (o.ins >= 0) {
      let a = 0, c = o.len;
      for (; c; )
        if (l.ins == -1) {
          let f = Math.min(c, l.len);
          a += f, c -= f, l.forward(f);
        } else if (l.ins == 0 && l.len < c)
          c -= l.len, l.next();
        else
          break;
      at(s, a, h < o.i ? o.ins : 0), r && h < o.i && ce(r, s, o.text), h = o.i, o.forward(o.len - c);
    } else {
      if (o.done && l.done)
        return r ? it.createSet(s, r) : ee.create(s);
      throw new Error("Mismatched change set lengths");
    }
}
function ol(n, t, e = !1) {
  let i = [], s = e ? [] : null, r = new mi(n), o = new mi(t);
  for (let l = !1; ; ) {
    if (r.done && o.done)
      return s ? it.createSet(i, s) : ee.create(i);
    if (r.ins == 0)
      at(i, r.len, 0, l), r.next();
    else if (o.len == 0 && !o.done)
      at(i, 0, o.ins, l), s && ce(s, i, o.text), o.next();
    else {
      if (r.done || o.done)
        throw new Error("Mismatched change set lengths");
      {
        let h = Math.min(r.len2, o.len), a = i.length;
        if (r.ins == -1) {
          let c = o.ins == -1 ? -1 : o.off ? 0 : o.ins;
          at(i, h, c, l), s && c && ce(s, i, o.text);
        } else
          o.ins == -1 ? (at(i, r.off ? 0 : r.len, h, l), s && ce(s, i, r.textBit(h))) : (at(i, r.off ? 0 : r.len, o.off ? 0 : o.ins, l), s && !o.off && ce(s, i, o.text));
        l = (r.ins > h || o.ins >= 0 && o.len > h) && (l || i.length > a), r.forward2(h), o.forward(h);
      }
    }
  }
}
class mi {
  constructor(t) {
    this.set = t, this.i = 0, this.next();
  }
  next() {
    let { sections: t } = this.set;
    this.i < t.length ? (this.len = t[this.i++], this.ins = t[this.i++]) : (this.len = 0, this.ins = -2), this.off = 0;
  }
  get done() {
    return this.ins == -2;
  }
  get len2() {
    return this.ins < 0 ? this.len : this.ins;
  }
  get text() {
    let { inserted: t } = this.set, e = this.i - 2 >> 1;
    return e >= t.length ? V.empty : t[e];
  }
  textBit(t) {
    let { inserted: e } = this.set, i = this.i - 2 >> 1;
    return i >= e.length && !t ? V.empty : e[i].slice(this.off, t == null ? void 0 : this.off + t);
  }
  forward(t) {
    t == this.len ? this.next() : (this.len -= t, this.off += t);
  }
  forward2(t) {
    this.ins == -1 ? this.forward(t) : t == this.ins ? this.next() : (this.ins -= t, this.off += t);
  }
}
class Be {
  constructor(t, e, i) {
    this.from = t, this.to = e, this.flags = i;
  }
  /**
  The anchor of the range—the side that doesn't move when you
  extend it.
  */
  get anchor() {
    return this.flags & 32 ? this.to : this.from;
  }
  /**
  The head of the range, which is moved when the range is
  [extended](https://codemirror.net/6/docs/ref/#state.SelectionRange.extend).
  */
  get head() {
    return this.flags & 32 ? this.from : this.to;
  }
  /**
  True when `anchor` and `head` are at the same position.
  */
  get empty() {
    return this.from == this.to;
  }
  /**
  If this is a cursor that is explicitly associated with the
  character on one of its sides, this returns the side. -1 means
  the character before its position, 1 the character after, and 0
  means no association.
  */
  get assoc() {
    return this.flags & 8 ? -1 : this.flags & 16 ? 1 : 0;
  }
  /**
  The bidirectional text level associated with this cursor, if
  any.
  */
  get bidiLevel() {
    let t = this.flags & 7;
    return t == 7 ? null : t;
  }
  /**
  The goal column (stored vertical offset) associated with a
  cursor. This is used to preserve the vertical position when
  [moving](https://codemirror.net/6/docs/ref/#view.EditorView.moveVertically) across
  lines of different length.
  */
  get goalColumn() {
    let t = this.flags >> 6;
    return t == 16777215 ? void 0 : t;
  }
  /**
  Map this range through a change, producing a valid range in the
  updated document.
  */
  map(t, e = -1) {
    let i, s;
    return this.empty ? i = s = t.mapPos(this.from, e) : (i = t.mapPos(this.from, 1), s = t.mapPos(this.to, -1)), i == this.from && s == this.to ? this : new Be(i, s, this.flags);
  }
  /**
  Extend this range to cover at least `from` to `to`.
  */
  extend(t, e = t) {
    if (t <= this.anchor && e >= this.anchor)
      return b.range(t, e);
    let i = Math.abs(t - this.anchor) > Math.abs(e - this.anchor) ? t : e;
    return b.range(this.anchor, i);
  }
  /**
  Compare this range to another range.
  */
  eq(t) {
    return this.anchor == t.anchor && this.head == t.head;
  }
  /**
  Return a JSON-serializable object representing the range.
  */
  toJSON() {
    return { anchor: this.anchor, head: this.head };
  }
  /**
  Convert a JSON representation of a range to a `SelectionRange`
  instance.
  */
  static fromJSON(t) {
    if (!t || typeof t.anchor != "number" || typeof t.head != "number")
      throw new RangeError("Invalid JSON representation for SelectionRange");
    return b.range(t.anchor, t.head);
  }
  /**
  @internal
  */
  static create(t, e, i) {
    return new Be(t, e, i);
  }
}
class b {
  constructor(t, e) {
    this.ranges = t, this.mainIndex = e;
  }
  /**
  Map a selection through a change. Used to adjust the selection
  position for changes.
  */
  map(t, e = -1) {
    return t.empty ? this : b.create(this.ranges.map((i) => i.map(t, e)), this.mainIndex);
  }
  /**
  Compare this selection to another selection.
  */
  eq(t) {
    if (this.ranges.length != t.ranges.length || this.mainIndex != t.mainIndex)
      return !1;
    for (let e = 0; e < this.ranges.length; e++)
      if (!this.ranges[e].eq(t.ranges[e]))
        return !1;
    return !0;
  }
  /**
  Get the primary selection range. Usually, you should make sure
  your code applies to _all_ ranges, by using methods like
  [`changeByRange`](https://codemirror.net/6/docs/ref/#state.EditorState.changeByRange).
  */
  get main() {
    return this.ranges[this.mainIndex];
  }
  /**
  Make sure the selection only has one range. Returns a selection
  holding only the main range from this selection.
  */
  asSingle() {
    return this.ranges.length == 1 ? this : new b([this.main], 0);
  }
  /**
  Extend this selection with an extra range.
  */
  addRange(t, e = !0) {
    return b.create([t].concat(this.ranges), e ? 0 : this.mainIndex + 1);
  }
  /**
  Replace a given range with another range, and then normalize the
  selection to merge and sort ranges if necessary.
  */
  replaceRange(t, e = this.mainIndex) {
    let i = this.ranges.slice();
    return i[e] = t, b.create(i, this.mainIndex);
  }
  /**
  Convert this selection to an object that can be serialized to
  JSON.
  */
  toJSON() {
    return { ranges: this.ranges.map((t) => t.toJSON()), main: this.mainIndex };
  }
  /**
  Create a selection from a JSON representation.
  */
  static fromJSON(t) {
    if (!t || !Array.isArray(t.ranges) || typeof t.main != "number" || t.main >= t.ranges.length)
      throw new RangeError("Invalid JSON representation for EditorSelection");
    return new b(t.ranges.map((e) => Be.fromJSON(e)), t.main);
  }
  /**
  Create a selection holding a single range.
  */
  static single(t, e = t) {
    return new b([b.range(t, e)], 0);
  }
  /**
  Sort and merge the given set of ranges, creating a valid
  selection.
  */
  static create(t, e = 0) {
    if (t.length == 0)
      throw new RangeError("A selection needs at least one range");
    for (let i = 0, s = 0; s < t.length; s++) {
      let r = t[s];
      if (r.empty ? r.from <= i : r.from < i)
        return b.normalized(t.slice(), e);
      i = r.to;
    }
    return new b(t, e);
  }
  /**
  Create a cursor selection range at the given position. You can
  safely ignore the optional arguments in most situations.
  */
  static cursor(t, e = 0, i, s) {
    return Be.create(t, t, (e == 0 ? 0 : e < 0 ? 8 : 16) | (i == null ? 7 : Math.min(6, i)) | (s ?? 16777215) << 6);
  }
  /**
  Create a selection range.
  */
  static range(t, e, i, s) {
    let r = (i ?? 16777215) << 6 | (s == null ? 7 : Math.min(6, s));
    return e < t ? Be.create(e, t, 48 | r) : Be.create(t, e, (e > t ? 8 : 0) | r);
  }
  /**
  @internal
  */
  static normalized(t, e = 0) {
    let i = t[e];
    t.sort((s, r) => s.from - r.from), e = t.indexOf(i);
    for (let s = 1; s < t.length; s++) {
      let r = t[s], o = t[s - 1];
      if (r.empty ? r.from <= o.to : r.from < o.to) {
        let l = o.from, h = Math.max(r.to, o.to);
        s <= e && e--, t.splice(--s, 2, r.anchor > r.head ? b.range(h, l) : b.range(l, h));
      }
    }
    return new b(t, e);
  }
}
function ll(n, t) {
  for (let e of n.ranges)
    if (e.to > t)
      throw new RangeError("Selection points outside of document");
}
let Un = 0;
class O {
  constructor(t, e, i, s, r) {
    this.combine = t, this.compareInput = e, this.compare = i, this.isStatic = s, this.id = Un++, this.default = t([]), this.extensions = typeof r == "function" ? r(this) : r;
  }
  /**
  Returns a facet reader for this facet, which can be used to
  [read](https://codemirror.net/6/docs/ref/#state.EditorState.facet) it but not to define values for it.
  */
  get reader() {
    return this;
  }
  /**
  Define a new facet.
  */
  static define(t = {}) {
    return new O(t.combine || ((e) => e), t.compareInput || ((e, i) => e === i), t.compare || (t.combine ? (e, i) => e === i : Yn), !!t.static, t.enables);
  }
  /**
  Returns an extension that adds the given value to this facet.
  */
  of(t) {
    return new Zi([], this, 0, t);
  }
  /**
  Create an extension that computes a value for the facet from a
  state. You must take care to declare the parts of the state that
  this value depends on, since your function is only called again
  for a new state when one of those parts changed.
  
  In cases where your value depends only on a single field, you'll
  want to use the [`from`](https://codemirror.net/6/docs/ref/#state.Facet.from) method instead.
  */
  compute(t, e) {
    if (this.isStatic)
      throw new Error("Can't compute a static facet");
    return new Zi(t, this, 1, e);
  }
  /**
  Create an extension that computes zero or more values for this
  facet from a state.
  */
  computeN(t, e) {
    if (this.isStatic)
      throw new Error("Can't compute a static facet");
    return new Zi(t, this, 2, e);
  }
  from(t, e) {
    return e || (e = (i) => i), this.compute([t], (i) => e(i.field(t)));
  }
}
function Yn(n, t) {
  return n == t || n.length == t.length && n.every((e, i) => e === t[i]);
}
class Zi {
  constructor(t, e, i, s) {
    this.dependencies = t, this.facet = e, this.type = i, this.value = s, this.id = Un++;
  }
  dynamicSlot(t) {
    var e;
    let i = this.value, s = this.facet.compareInput, r = this.id, o = t[r] >> 1, l = this.type == 2, h = !1, a = !1, c = [];
    for (let f of this.dependencies)
      f == "doc" ? h = !0 : f == "selection" ? a = !0 : ((e = t[f.id]) !== null && e !== void 0 ? e : 1) & 1 || c.push(t[f.id]);
    return {
      create(f) {
        return f.values[o] = i(f), 1;
      },
      update(f, u) {
        if (h && u.docChanged || a && (u.docChanged || u.selection) || hn(f, c)) {
          let d = i(f);
          if (l ? !vr(d, f.values[o], s) : !s(d, f.values[o]))
            return f.values[o] = d, 1;
        }
        return 0;
      },
      reconfigure: (f, u) => {
        let d, p = u.config.address[r];
        if (p != null) {
          let m = fs(u, p);
          if (this.dependencies.every((g) => g instanceof O ? u.facet(g) === f.facet(g) : g instanceof Ht ? u.field(g, !1) == f.field(g, !1) : !0) || (l ? vr(d = i(f), m, s) : s(d = i(f), m)))
            return f.values[o] = m, 0;
        } else
          d = i(f);
        return f.values[o] = d, 1;
      }
    };
  }
}
function vr(n, t, e) {
  if (n.length != t.length)
    return !1;
  for (let i = 0; i < n.length; i++)
    if (!e(n[i], t[i]))
      return !1;
  return !0;
}
function hn(n, t) {
  let e = !1;
  for (let i of t)
    pi(n, i) & 1 && (e = !0);
  return e;
}
function Hc(n, t, e) {
  let i = e.map((h) => n[h.id]), s = e.map((h) => h.type), r = i.filter((h) => !(h & 1)), o = n[t.id] >> 1;
  function l(h) {
    let a = [];
    for (let c = 0; c < i.length; c++) {
      let f = fs(h, i[c]);
      if (s[c] == 2)
        for (let u of f)
          a.push(u);
      else
        a.push(f);
    }
    return t.combine(a);
  }
  return {
    create(h) {
      for (let a of i)
        pi(h, a);
      return h.values[o] = l(h), 1;
    },
    update(h, a) {
      if (!hn(h, r))
        return 0;
      let c = l(h);
      return t.compare(c, h.values[o]) ? 0 : (h.values[o] = c, 1);
    },
    reconfigure(h, a) {
      let c = hn(h, i), f = a.config.facets[t.id], u = a.facet(t);
      if (f && !c && Yn(e, f))
        return h.values[o] = u, 0;
      let d = l(h);
      return t.compare(d, u) ? (h.values[o] = u, 0) : (h.values[o] = d, 1);
    }
  };
}
const Sr = /* @__PURE__ */ O.define({ static: !0 });
class Ht {
  constructor(t, e, i, s, r) {
    this.id = t, this.createF = e, this.updateF = i, this.compareF = s, this.spec = r, this.provides = void 0;
  }
  /**
  Define a state field.
  */
  static define(t) {
    let e = new Ht(Un++, t.create, t.update, t.compare || ((i, s) => i === s), t);
    return t.provide && (e.provides = t.provide(e)), e;
  }
  create(t) {
    let e = t.facet(Sr).find((i) => i.field == this);
    return ((e == null ? void 0 : e.create) || this.createF)(t);
  }
  /**
  @internal
  */
  slot(t) {
    let e = t[this.id] >> 1;
    return {
      create: (i) => (i.values[e] = this.create(i), 1),
      update: (i, s) => {
        let r = i.values[e], o = this.updateF(r, s);
        return this.compareF(r, o) ? 0 : (i.values[e] = o, 1);
      },
      reconfigure: (i, s) => s.config.address[this.id] != null ? (i.values[e] = s.field(this), 0) : (i.values[e] = this.create(i), 1)
    };
  }
  /**
  Returns an extension that enables this field and overrides the
  way it is initialized. Can be useful when you need to provide a
  non-default starting value for the field.
  */
  init(t) {
    return [this, Sr.of({ field: this, create: t })];
  }
  /**
  State field instances can be used as
  [`Extension`](https://codemirror.net/6/docs/ref/#state.Extension) values to enable the field in a
  given state.
  */
  get extension() {
    return this;
  }
}
const De = { lowest: 4, low: 3, default: 2, high: 1, highest: 0 };
function ii(n) {
  return (t) => new hl(t, n);
}
const Qn = {
  /**
  The highest precedence level, for extensions that should end up
  near the start of the precedence ordering.
  */
  highest: /* @__PURE__ */ ii(De.highest),
  /**
  A higher-than-default precedence, for extensions that should
  come before those with default precedence.
  */
  high: /* @__PURE__ */ ii(De.high),
  /**
  The default precedence, which is also used for extensions
  without an explicit precedence.
  */
  default: /* @__PURE__ */ ii(De.default),
  /**
  A lower-than-default precedence.
  */
  low: /* @__PURE__ */ ii(De.low),
  /**
  The lowest precedence level. Meant for things that should end up
  near the end of the extension order.
  */
  lowest: /* @__PURE__ */ ii(De.lowest)
};
class hl {
  constructor(t, e) {
    this.inner = t, this.prec = e;
  }
}
class Ai {
  /**
  Create an instance of this compartment to add to your [state
  configuration](https://codemirror.net/6/docs/ref/#state.EditorStateConfig.extensions).
  */
  of(t) {
    return new an(this, t);
  }
  /**
  Create an [effect](https://codemirror.net/6/docs/ref/#state.TransactionSpec.effects) that
  reconfigures this compartment.
  */
  reconfigure(t) {
    return Ai.reconfigure.of({ compartment: this, extension: t });
  }
  /**
  Get the current content of the compartment in the state, or
  `undefined` if it isn't present.
  */
  get(t) {
    return t.config.compartments.get(this);
  }
}
class an {
  constructor(t, e) {
    this.compartment = t, this.inner = e;
  }
}
class cs {
  constructor(t, e, i, s, r, o) {
    for (this.base = t, this.compartments = e, this.dynamicSlots = i, this.address = s, this.staticValues = r, this.facets = o, this.statusTemplate = []; this.statusTemplate.length < i.length; )
      this.statusTemplate.push(
        0
        /* SlotStatus.Unresolved */
      );
  }
  staticFacet(t) {
    let e = this.address[t.id];
    return e == null ? t.default : this.staticValues[e >> 1];
  }
  static resolve(t, e, i) {
    let s = [], r = /* @__PURE__ */ Object.create(null), o = /* @__PURE__ */ new Map();
    for (let u of $c(t, e, o))
      u instanceof Ht ? s.push(u) : (r[u.facet.id] || (r[u.facet.id] = [])).push(u);
    let l = /* @__PURE__ */ Object.create(null), h = [], a = [];
    for (let u of s)
      l[u.id] = a.length << 1, a.push((d) => u.slot(d));
    let c = i == null ? void 0 : i.config.facets;
    for (let u in r) {
      let d = r[u], p = d[0].facet, m = c && c[u] || [];
      if (d.every(
        (g) => g.type == 0
        /* Provider.Static */
      ))
        if (l[p.id] = h.length << 1 | 1, Yn(m, d))
          h.push(i.facet(p));
        else {
          let g = p.combine(d.map((y) => y.value));
          h.push(i && p.compare(g, i.facet(p)) ? i.facet(p) : g);
        }
      else {
        for (let g of d)
          g.type == 0 ? (l[g.id] = h.length << 1 | 1, h.push(g.value)) : (l[g.id] = a.length << 1, a.push((y) => g.dynamicSlot(y)));
        l[p.id] = a.length << 1, a.push((g) => Hc(g, p, d));
      }
    }
    let f = a.map((u) => u(l));
    return new cs(t, o, f, l, h, r);
  }
}
function $c(n, t, e) {
  let i = [[], [], [], [], []], s = /* @__PURE__ */ new Map();
  function r(o, l) {
    let h = s.get(o);
    if (h != null) {
      if (h <= l)
        return;
      let a = i[h].indexOf(o);
      a > -1 && i[h].splice(a, 1), o instanceof an && e.delete(o.compartment);
    }
    if (s.set(o, l), Array.isArray(o))
      for (let a of o)
        r(a, l);
    else if (o instanceof an) {
      if (e.has(o.compartment))
        throw new RangeError("Duplicate use of compartment in extensions");
      let a = t.get(o.compartment) || o.inner;
      e.set(o.compartment, a), r(a, l);
    } else if (o instanceof hl)
      r(o.inner, o.prec);
    else if (o instanceof Ht)
      i[l].push(o), o.provides && r(o.provides, l);
    else if (o instanceof Zi)
      i[l].push(o), o.facet.extensions && r(o.facet.extensions, De.default);
    else {
      let a = o.extension;
      if (!a)
        throw new Error(`Unrecognized extension value in extension set (${o}). This sometimes happens because multiple instances of @codemirror/state are loaded, breaking instanceof checks.`);
      r(a, l);
    }
  }
  return r(n, De.default), i.reduce((o, l) => o.concat(l));
}
function pi(n, t) {
  if (t & 1)
    return 2;
  let e = t >> 1, i = n.status[e];
  if (i == 4)
    throw new Error("Cyclic dependency between fields and/or facets");
  if (i & 2)
    return i;
  n.status[e] = 4;
  let s = n.computeSlot(n, n.config.dynamicSlots[e]);
  return n.status[e] = 2 | s;
}
function fs(n, t) {
  return t & 1 ? n.config.staticValues[t >> 1] : n.values[t >> 1];
}
const al = /* @__PURE__ */ O.define(), cl = /* @__PURE__ */ O.define({
  combine: (n) => n.some((t) => t),
  static: !0
}), fl = /* @__PURE__ */ O.define({
  combine: (n) => n.length ? n[0] : void 0,
  static: !0
}), ul = /* @__PURE__ */ O.define(), dl = /* @__PURE__ */ O.define(), pl = /* @__PURE__ */ O.define(), gl = /* @__PURE__ */ O.define({
  combine: (n) => n.length ? n[0] : !1
});
class ti {
  /**
  @internal
  */
  constructor(t, e) {
    this.type = t, this.value = e;
  }
  /**
  Define a new type of annotation.
  */
  static define() {
    return new Fc();
  }
}
class Fc {
  /**
  Create an instance of this annotation.
  */
  of(t) {
    return new ti(this, t);
  }
}
class _c {
  /**
  @internal
  */
  constructor(t) {
    this.map = t;
  }
  /**
  Create a [state effect](https://codemirror.net/6/docs/ref/#state.StateEffect) instance of this
  type.
  */
  of(t) {
    return new z(this, t);
  }
}
class z {
  /**
  @internal
  */
  constructor(t, e) {
    this.type = t, this.value = e;
  }
  /**
  Map this effect through a position mapping. Will return
  `undefined` when that ends up deleting the effect.
  */
  map(t) {
    let e = this.type.map(this.value, t);
    return e === void 0 ? void 0 : e == this.value ? this : new z(this.type, e);
  }
  /**
  Tells you whether this effect object is of a given
  [type](https://codemirror.net/6/docs/ref/#state.StateEffectType).
  */
  is(t) {
    return this.type == t;
  }
  /**
  Define a new effect type. The type parameter indicates the type
  of values that his effect holds. It should be a type that
  doesn't include `undefined`, since that is used in
  [mapping](https://codemirror.net/6/docs/ref/#state.StateEffect.map) to indicate that an effect is
  removed.
  */
  static define(t = {}) {
    return new _c(t.map || ((e) => e));
  }
  /**
  Map an array of effects through a change set.
  */
  static mapEffects(t, e) {
    if (!t.length)
      return t;
    let i = [];
    for (let s of t) {
      let r = s.map(e);
      r && i.push(r);
    }
    return i;
  }
}
z.reconfigure = /* @__PURE__ */ z.define();
z.appendConfig = /* @__PURE__ */ z.define();
class ft {
  constructor(t, e, i, s, r, o) {
    this.startState = t, this.changes = e, this.selection = i, this.effects = s, this.annotations = r, this.scrollIntoView = o, this._doc = null, this._state = null, i && ll(i, e.newLength), r.some((l) => l.type == ft.time) || (this.annotations = r.concat(ft.time.of(Date.now())));
  }
  /**
  @internal
  */
  static create(t, e, i, s, r, o) {
    return new ft(t, e, i, s, r, o);
  }
  /**
  The new document produced by the transaction. Contrary to
  [`.state`](https://codemirror.net/6/docs/ref/#state.Transaction.state)`.doc`, accessing this won't
  force the entire new state to be computed right away, so it is
  recommended that [transaction
  filters](https://codemirror.net/6/docs/ref/#state.EditorState^transactionFilter) use this getter
  when they need to look at the new document.
  */
  get newDoc() {
    return this._doc || (this._doc = this.changes.apply(this.startState.doc));
  }
  /**
  The new selection produced by the transaction. If
  [`this.selection`](https://codemirror.net/6/docs/ref/#state.Transaction.selection) is undefined,
  this will [map](https://codemirror.net/6/docs/ref/#state.EditorSelection.map) the start state's
  current selection through the changes made by the transaction.
  */
  get newSelection() {
    return this.selection || this.startState.selection.map(this.changes);
  }
  /**
  The new state created by the transaction. Computed on demand
  (but retained for subsequent access), so it is recommended not to
  access it in [transaction
  filters](https://codemirror.net/6/docs/ref/#state.EditorState^transactionFilter) when possible.
  */
  get state() {
    return this._state || this.startState.applyTransaction(this), this._state;
  }
  /**
  Get the value of the given annotation type, if any.
  */
  annotation(t) {
    for (let e of this.annotations)
      if (e.type == t)
        return e.value;
  }
  /**
  Indicates whether the transaction changed the document.
  */
  get docChanged() {
    return !this.changes.empty;
  }
  /**
  Indicates whether this transaction reconfigures the state
  (through a [configuration compartment](https://codemirror.net/6/docs/ref/#state.Compartment) or
  with a top-level configuration
  [effect](https://codemirror.net/6/docs/ref/#state.StateEffect^reconfigure).
  */
  get reconfigured() {
    return this.startState.config != this.state.config;
  }
  /**
  Returns true if the transaction has a [user
  event](https://codemirror.net/6/docs/ref/#state.Transaction^userEvent) annotation that is equal to
  or more specific than `event`. For example, if the transaction
  has `"select.pointer"` as user event, `"select"` and
  `"select.pointer"` will match it.
  */
  isUserEvent(t) {
    let e = this.annotation(ft.userEvent);
    return !!(e && (e == t || e.length > t.length && e.slice(0, t.length) == t && e[t.length] == "."));
  }
}
ft.time = /* @__PURE__ */ ti.define();
ft.userEvent = /* @__PURE__ */ ti.define();
ft.addToHistory = /* @__PURE__ */ ti.define();
ft.remote = /* @__PURE__ */ ti.define();
function zc(n, t) {
  let e = [];
  for (let i = 0, s = 0; ; ) {
    let r, o;
    if (i < n.length && (s == t.length || t[s] >= n[i]))
      r = n[i++], o = n[i++];
    else if (s < t.length)
      r = t[s++], o = t[s++];
    else
      return e;
    !e.length || e[e.length - 1] < r ? e.push(r, o) : e[e.length - 1] < o && (e[e.length - 1] = o);
  }
}
function ml(n, t, e) {
  var i;
  let s, r, o;
  return e ? (s = t.changes, r = it.empty(t.changes.length), o = n.changes.compose(t.changes)) : (s = t.changes.map(n.changes), r = n.changes.mapDesc(t.changes, !0), o = n.changes.compose(s)), {
    changes: o,
    selection: t.selection ? t.selection.map(r) : (i = n.selection) === null || i === void 0 ? void 0 : i.map(s),
    effects: z.mapEffects(n.effects, s).concat(z.mapEffects(t.effects, r)),
    annotations: n.annotations.length ? n.annotations.concat(t.annotations) : t.annotations,
    scrollIntoView: n.scrollIntoView || t.scrollIntoView
  };
}
function cn(n, t, e) {
  let i = t.selection, s = je(t.annotations);
  return t.userEvent && (s = s.concat(ft.userEvent.of(t.userEvent))), {
    changes: t.changes instanceof it ? t.changes : it.of(t.changes || [], e, n.facet(fl)),
    selection: i && (i instanceof b ? i : b.single(i.anchor, i.head)),
    effects: je(t.effects),
    annotations: s,
    scrollIntoView: !!t.scrollIntoView
  };
}
function wl(n, t, e) {
  let i = cn(n, t.length ? t[0] : {}, n.doc.length);
  t.length && t[0].filter === !1 && (e = !1);
  for (let r = 1; r < t.length; r++) {
    t[r].filter === !1 && (e = !1);
    let o = !!t[r].sequential;
    i = ml(i, cn(n, t[r], o ? i.changes.newLength : n.doc.length), o);
  }
  let s = ft.create(n, i.changes, i.selection, i.effects, i.annotations, i.scrollIntoView);
  return jc(e ? Wc(s) : s);
}
function Wc(n) {
  let t = n.startState, e = !0;
  for (let s of t.facet(ul)) {
    let r = s(n);
    if (r === !1) {
      e = !1;
      break;
    }
    Array.isArray(r) && (e = e === !0 ? r : zc(e, r));
  }
  if (e !== !0) {
    let s, r;
    if (e === !1)
      r = n.changes.invertedDesc, s = it.empty(t.doc.length);
    else {
      let o = n.changes.filter(e);
      s = o.changes, r = o.filtered.mapDesc(o.changes).invertedDesc;
    }
    n = ft.create(t, s, n.selection && n.selection.map(r), z.mapEffects(n.effects, r), n.annotations, n.scrollIntoView);
  }
  let i = t.facet(dl);
  for (let s = i.length - 1; s >= 0; s--) {
    let r = i[s](n);
    r instanceof ft ? n = r : Array.isArray(r) && r.length == 1 && r[0] instanceof ft ? n = r[0] : n = wl(t, je(r), !1);
  }
  return n;
}
function jc(n) {
  let t = n.startState, e = t.facet(pl), i = n;
  for (let s = e.length - 1; s >= 0; s--) {
    let r = e[s](n);
    r && Object.keys(r).length && (i = ml(i, cn(t, r, n.changes.newLength), !0));
  }
  return i == n ? n : ft.create(t, n.changes, n.selection, i.effects, i.annotations, i.scrollIntoView);
}
const Kc = [];
function je(n) {
  return n == null ? Kc : Array.isArray(n) ? n : [n];
}
var Zt = /* @__PURE__ */ function(n) {
  return n[n.Word = 0] = "Word", n[n.Space = 1] = "Space", n[n.Other = 2] = "Other", n;
}(Zt || (Zt = {}));
const qc = /[\u00df\u0587\u0590-\u05f4\u0600-\u06ff\u3040-\u309f\u30a0-\u30ff\u3400-\u4db5\u4e00-\u9fcc\uac00-\ud7af]/;
let fn;
try {
  fn = /* @__PURE__ */ new RegExp("[\\p{Alphabetic}\\p{Number}_]", "u");
} catch {
}
function Gc(n) {
  if (fn)
    return fn.test(n);
  for (let t = 0; t < n.length; t++) {
    let e = n[t];
    if (/\w/.test(e) || e > "" && (e.toUpperCase() != e.toLowerCase() || qc.test(e)))
      return !0;
  }
  return !1;
}
function Uc(n) {
  return (t) => {
    if (!/\S/.test(t))
      return Zt.Space;
    if (Gc(t))
      return Zt.Word;
    for (let e = 0; e < n.length; e++)
      if (t.indexOf(n[e]) > -1)
        return Zt.Word;
    return Zt.Other;
  };
}
class H {
  constructor(t, e, i, s, r, o) {
    this.config = t, this.doc = e, this.selection = i, this.values = s, this.status = t.statusTemplate.slice(), this.computeSlot = r, o && (o._state = this);
    for (let l = 0; l < this.config.dynamicSlots.length; l++)
      pi(this, l << 1);
    this.computeSlot = null;
  }
  field(t, e = !0) {
    let i = this.config.address[t.id];
    if (i == null) {
      if (e)
        throw new RangeError("Field is not present in this state");
      return;
    }
    return pi(this, i), fs(this, i);
  }
  /**
  Create a [transaction](https://codemirror.net/6/docs/ref/#state.Transaction) that updates this
  state. Any number of [transaction specs](https://codemirror.net/6/docs/ref/#state.TransactionSpec)
  can be passed. Unless
  [`sequential`](https://codemirror.net/6/docs/ref/#state.TransactionSpec.sequential) is set, the
  [changes](https://codemirror.net/6/docs/ref/#state.TransactionSpec.changes) (if any) of each spec
  are assumed to start in the _current_ document (not the document
  produced by previous specs), and its
  [selection](https://codemirror.net/6/docs/ref/#state.TransactionSpec.selection) and
  [effects](https://codemirror.net/6/docs/ref/#state.TransactionSpec.effects) are assumed to refer
  to the document created by its _own_ changes. The resulting
  transaction contains the combined effect of all the different
  specs. For [selection](https://codemirror.net/6/docs/ref/#state.TransactionSpec.selection), later
  specs take precedence over earlier ones.
  */
  update(...t) {
    return wl(this, t, !0);
  }
  /**
  @internal
  */
  applyTransaction(t) {
    let e = this.config, { base: i, compartments: s } = e;
    for (let o of t.effects)
      o.is(Ai.reconfigure) ? (e && (s = /* @__PURE__ */ new Map(), e.compartments.forEach((l, h) => s.set(h, l)), e = null), s.set(o.value.compartment, o.value.extension)) : o.is(z.reconfigure) ? (e = null, i = o.value) : o.is(z.appendConfig) && (e = null, i = je(i).concat(o.value));
    let r;
    e ? r = t.startState.values.slice() : (e = cs.resolve(i, s, this), r = new H(e, this.doc, this.selection, e.dynamicSlots.map(() => null), (l, h) => h.reconfigure(l, this), null).values), new H(e, t.newDoc, t.newSelection, r, (o, l) => l.update(o, t), t);
  }
  /**
  Create a [transaction spec](https://codemirror.net/6/docs/ref/#state.TransactionSpec) that
  replaces every selection range with the given content.
  */
  replaceSelection(t) {
    return typeof t == "string" && (t = this.toText(t)), this.changeByRange((e) => ({
      changes: { from: e.from, to: e.to, insert: t },
      range: b.cursor(e.from + t.length)
    }));
  }
  /**
  Create a set of changes and a new selection by running the given
  function for each range in the active selection. The function
  can return an optional set of changes (in the coordinate space
  of the start document), plus an updated range (in the coordinate
  space of the document produced by the call's own changes). This
  method will merge all the changes and ranges into a single
  changeset and selection, and return it as a [transaction
  spec](https://codemirror.net/6/docs/ref/#state.TransactionSpec), which can be passed to
  [`update`](https://codemirror.net/6/docs/ref/#state.EditorState.update).
  */
  changeByRange(t) {
    let e = this.selection, i = t(e.ranges[0]), s = this.changes(i.changes), r = [i.range], o = je(i.effects);
    for (let l = 1; l < e.ranges.length; l++) {
      let h = t(e.ranges[l]), a = this.changes(h.changes), c = a.map(s);
      for (let u = 0; u < l; u++)
        r[u] = r[u].map(c);
      let f = s.mapDesc(a, !0);
      r.push(h.range.map(f)), s = s.compose(c), o = z.mapEffects(o, c).concat(z.mapEffects(je(h.effects), f));
    }
    return {
      changes: s,
      selection: b.create(r, e.mainIndex),
      effects: o
    };
  }
  /**
  Create a [change set](https://codemirror.net/6/docs/ref/#state.ChangeSet) from the given change
  description, taking the state's document length and line
  separator into account.
  */
  changes(t = []) {
    return t instanceof it ? t : it.of(t, this.doc.length, this.facet(H.lineSeparator));
  }
  /**
  Using the state's [line
  separator](https://codemirror.net/6/docs/ref/#state.EditorState^lineSeparator), create a
  [`Text`](https://codemirror.net/6/docs/ref/#state.Text) instance from the given string.
  */
  toText(t) {
    return V.of(t.split(this.facet(H.lineSeparator) || rn));
  }
  /**
  Return the given range of the document as a string.
  */
  sliceDoc(t = 0, e = this.doc.length) {
    return this.doc.sliceString(t, e, this.lineBreak);
  }
  /**
  Get the value of a state [facet](https://codemirror.net/6/docs/ref/#state.Facet).
  */
  facet(t) {
    let e = this.config.address[t.id];
    return e == null ? t.default : (pi(this, e), fs(this, e));
  }
  /**
  Convert this state to a JSON-serializable object. When custom
  fields should be serialized, you can pass them in as an object
  mapping property names (in the resulting object, which should
  not use `doc` or `selection`) to fields.
  */
  toJSON(t) {
    let e = {
      doc: this.sliceDoc(),
      selection: this.selection.toJSON()
    };
    if (t)
      for (let i in t) {
        let s = t[i];
        s instanceof Ht && this.config.address[s.id] != null && (e[i] = s.spec.toJSON(this.field(t[i]), this));
      }
    return e;
  }
  /**
  Deserialize a state from its JSON representation. When custom
  fields should be deserialized, pass the same object you passed
  to [`toJSON`](https://codemirror.net/6/docs/ref/#state.EditorState.toJSON) when serializing as
  third argument.
  */
  static fromJSON(t, e = {}, i) {
    if (!t || typeof t.doc != "string")
      throw new RangeError("Invalid JSON representation for EditorState");
    let s = [];
    if (i) {
      for (let r in i)
        if (Object.prototype.hasOwnProperty.call(t, r)) {
          let o = i[r], l = t[r];
          s.push(o.init((h) => o.spec.fromJSON(l, h)));
        }
    }
    return H.create({
      doc: t.doc,
      selection: b.fromJSON(t.selection),
      extensions: e.extensions ? s.concat([e.extensions]) : s
    });
  }
  /**
  Create a new state. You'll usually only need this when
  initializing an editor—updated states are created by applying
  transactions.
  */
  static create(t = {}) {
    let e = cs.resolve(t.extensions || [], /* @__PURE__ */ new Map()), i = t.doc instanceof V ? t.doc : V.of((t.doc || "").split(e.staticFacet(H.lineSeparator) || rn)), s = t.selection ? t.selection instanceof b ? t.selection : b.single(t.selection.anchor, t.selection.head) : b.single(0);
    return ll(s, i.length), e.staticFacet(cl) || (s = s.asSingle()), new H(e, i, s, e.dynamicSlots.map(() => null), (r, o) => o.create(r), null);
  }
  /**
  The size (in columns) of a tab in the document, determined by
  the [`tabSize`](https://codemirror.net/6/docs/ref/#state.EditorState^tabSize) facet.
  */
  get tabSize() {
    return this.facet(H.tabSize);
  }
  /**
  Get the proper [line-break](https://codemirror.net/6/docs/ref/#state.EditorState^lineSeparator)
  string for this state.
  */
  get lineBreak() {
    return this.facet(H.lineSeparator) || `
`;
  }
  /**
  Returns true when the editor is
  [configured](https://codemirror.net/6/docs/ref/#state.EditorState^readOnly) to be read-only.
  */
  get readOnly() {
    return this.facet(gl);
  }
  /**
  Look up a translation for the given phrase (via the
  [`phrases`](https://codemirror.net/6/docs/ref/#state.EditorState^phrases) facet), or return the
  original string if no translation is found.
  
  If additional arguments are passed, they will be inserted in
  place of markers like `$1` (for the first value) and `$2`, etc.
  A single `$` is equivalent to `$1`, and `$$` will produce a
  literal dollar sign.
  */
  phrase(t, ...e) {
    for (let i of this.facet(H.phrases))
      if (Object.prototype.hasOwnProperty.call(i, t)) {
        t = i[t];
        break;
      }
    return e.length && (t = t.replace(/\$(\$|\d*)/g, (i, s) => {
      if (s == "$")
        return "$";
      let r = +(s || 1);
      return !r || r > e.length ? i : e[r - 1];
    })), t;
  }
  /**
  Find the values for a given language data field, provided by the
  the [`languageData`](https://codemirror.net/6/docs/ref/#state.EditorState^languageData) facet.
  
  Examples of language data fields are...
  
  - [`"commentTokens"`](https://codemirror.net/6/docs/ref/#commands.CommentTokens) for specifying
    comment syntax.
  - [`"autocomplete"`](https://codemirror.net/6/docs/ref/#autocomplete.autocompletion^config.override)
    for providing language-specific completion sources.
  - [`"wordChars"`](https://codemirror.net/6/docs/ref/#state.EditorState.charCategorizer) for adding
    characters that should be considered part of words in this
    language.
  - [`"closeBrackets"`](https://codemirror.net/6/docs/ref/#autocomplete.CloseBracketConfig) controls
    bracket closing behavior.
  */
  languageDataAt(t, e, i = -1) {
    let s = [];
    for (let r of this.facet(al))
      for (let o of r(this, e, i))
        Object.prototype.hasOwnProperty.call(o, t) && s.push(o[t]);
    return s;
  }
  /**
  Return a function that can categorize strings (expected to
  represent a single [grapheme cluster](https://codemirror.net/6/docs/ref/#state.findClusterBreak))
  into one of:
  
   - Word (contains an alphanumeric character or a character
     explicitly listed in the local language's `"wordChars"`
     language data, which should be a string)
   - Space (contains only whitespace)
   - Other (anything else)
  */
  charCategorizer(t) {
    return Uc(this.languageDataAt("wordChars", t).join(""));
  }
  /**
  Find the word at the given position, meaning the range
  containing all [word](https://codemirror.net/6/docs/ref/#state.CharCategory.Word) characters
  around it. If no word characters are adjacent to the position,
  this returns null.
  */
  wordAt(t) {
    let { text: e, from: i, length: s } = this.doc.lineAt(t), r = this.charCategorizer(t), o = t - i, l = t - i;
    for (; o > 0; ) {
      let h = wt(e, o, !1);
      if (r(e.slice(h, o)) != Zt.Word)
        break;
      o = h;
    }
    for (; l < s; ) {
      let h = wt(e, l);
      if (r(e.slice(l, h)) != Zt.Word)
        break;
      l = h;
    }
    return o == l ? null : b.range(o + i, l + i);
  }
}
H.allowMultipleSelections = cl;
H.tabSize = /* @__PURE__ */ O.define({
  combine: (n) => n.length ? n[0] : 4
});
H.lineSeparator = fl;
H.readOnly = gl;
H.phrases = /* @__PURE__ */ O.define({
  compare(n, t) {
    let e = Object.keys(n), i = Object.keys(t);
    return e.length == i.length && e.every((s) => n[s] == t[s]);
  }
});
H.languageData = al;
H.changeFilter = ul;
H.transactionFilter = dl;
H.transactionExtender = pl;
Ai.reconfigure = /* @__PURE__ */ z.define();
function Ds(n, t, e = {}) {
  let i = {};
  for (let s of n)
    for (let r of Object.keys(s)) {
      let o = s[r], l = i[r];
      if (l === void 0)
        i[r] = o;
      else if (!(l === o || o === void 0))
        if (Object.hasOwnProperty.call(e, r))
          i[r] = e[r](l, o);
        else
          throw new Error("Config merge conflict for field " + r);
    }
  for (let s in t)
    i[s] === void 0 && (i[s] = t[s]);
  return i;
}
class Qe {
  /**
  Compare this value with another value. Used when comparing
  rangesets. The default implementation compares by identity.
  Unless you are only creating a fixed number of unique instances
  of your value type, it is a good idea to implement this
  properly.
  */
  eq(t) {
    return this == t;
  }
  /**
  Create a [range](https://codemirror.net/6/docs/ref/#state.Range) with this value.
  */
  range(t, e = t) {
    return un.create(t, e, this);
  }
}
Qe.prototype.startSide = Qe.prototype.endSide = 0;
Qe.prototype.point = !1;
Qe.prototype.mapMode = mt.TrackDel;
let un = class yl {
  constructor(t, e, i) {
    this.from = t, this.to = e, this.value = i;
  }
  /**
  @internal
  */
  static create(t, e, i) {
    return new yl(t, e, i);
  }
};
function dn(n, t) {
  return n.from - t.from || n.value.startSide - t.value.startSide;
}
class Jn {
  constructor(t, e, i, s) {
    this.from = t, this.to = e, this.value = i, this.maxPoint = s;
  }
  get length() {
    return this.to[this.to.length - 1];
  }
  // Find the index of the given position and side. Use the ranges'
  // `from` pos when `end == false`, `to` when `end == true`.
  findIndex(t, e, i, s = 0) {
    let r = i ? this.to : this.from;
    for (let o = s, l = r.length; ; ) {
      if (o == l)
        return o;
      let h = o + l >> 1, a = r[h] - t || (i ? this.value[h].endSide : this.value[h].startSide) - e;
      if (h == o)
        return a >= 0 ? o : l;
      a >= 0 ? l = h : o = h + 1;
    }
  }
  between(t, e, i, s) {
    for (let r = this.findIndex(e, -1e9, !0), o = this.findIndex(i, 1e9, !1, r); r < o; r++)
      if (s(this.from[r] + t, this.to[r] + t, this.value[r]) === !1)
        return !1;
  }
  map(t, e) {
    let i = [], s = [], r = [], o = -1, l = -1;
    for (let h = 0; h < this.value.length; h++) {
      let a = this.value[h], c = this.from[h] + t, f = this.to[h] + t, u, d;
      if (c == f) {
        let p = e.mapPos(c, a.startSide, a.mapMode);
        if (p == null || (u = d = p, a.startSide != a.endSide && (d = e.mapPos(c, a.endSide), d < u)))
          continue;
      } else if (u = e.mapPos(c, a.startSide), d = e.mapPos(f, a.endSide), u > d || u == d && a.startSide > 0 && a.endSide <= 0)
        continue;
      (d - u || a.endSide - a.startSide) < 0 || (o < 0 && (o = u), a.point && (l = Math.max(l, d - u)), i.push(a), s.push(u - o), r.push(d - o));
    }
    return { mapped: i.length ? new Jn(s, r, i, l) : null, pos: o };
  }
}
class F {
  constructor(t, e, i, s) {
    this.chunkPos = t, this.chunk = e, this.nextLayer = i, this.maxPoint = s;
  }
  /**
  @internal
  */
  static create(t, e, i, s) {
    return new F(t, e, i, s);
  }
  /**
  @internal
  */
  get length() {
    let t = this.chunk.length - 1;
    return t < 0 ? 0 : Math.max(this.chunkEnd(t), this.nextLayer.length);
  }
  /**
  The number of ranges in the set.
  */
  get size() {
    if (this.isEmpty)
      return 0;
    let t = this.nextLayer.size;
    for (let e of this.chunk)
      t += e.value.length;
    return t;
  }
  /**
  @internal
  */
  chunkEnd(t) {
    return this.chunkPos[t] + this.chunk[t].length;
  }
  /**
  Update the range set, optionally adding new ranges or filtering
  out existing ones.
  
  (Note: The type parameter is just there as a kludge to work
  around TypeScript variance issues that prevented `RangeSet<X>`
  from being a subtype of `RangeSet<Y>` when `X` is a subtype of
  `Y`.)
  */
  update(t) {
    let { add: e = [], sort: i = !1, filterFrom: s = 0, filterTo: r = this.length } = t, o = t.filter;
    if (e.length == 0 && !o)
      return this;
    if (i && (e = e.slice().sort(dn)), this.isEmpty)
      return e.length ? F.of(e) : this;
    let l = new bl(this, null, -1).goto(0), h = 0, a = [], c = new Ee();
    for (; l.value || h < e.length; )
      if (h < e.length && (l.from - e[h].from || l.startSide - e[h].value.startSide) >= 0) {
        let f = e[h++];
        c.addInner(f.from, f.to, f.value) || a.push(f);
      } else
        l.rangeIndex == 1 && l.chunkIndex < this.chunk.length && (h == e.length || this.chunkEnd(l.chunkIndex) < e[h].from) && (!o || s > this.chunkEnd(l.chunkIndex) || r < this.chunkPos[l.chunkIndex]) && c.addChunk(this.chunkPos[l.chunkIndex], this.chunk[l.chunkIndex]) ? l.nextChunk() : ((!o || s > l.to || r < l.from || o(l.from, l.to, l.value)) && (c.addInner(l.from, l.to, l.value) || a.push(un.create(l.from, l.to, l.value))), l.next());
    return c.finishInner(this.nextLayer.isEmpty && !a.length ? F.empty : this.nextLayer.update({ add: a, filter: o, filterFrom: s, filterTo: r }));
  }
  /**
  Map this range set through a set of changes, return the new set.
  */
  map(t) {
    if (t.empty || this.isEmpty)
      return this;
    let e = [], i = [], s = -1;
    for (let o = 0; o < this.chunk.length; o++) {
      let l = this.chunkPos[o], h = this.chunk[o], a = t.touchesRange(l, l + h.length);
      if (a === !1)
        s = Math.max(s, h.maxPoint), e.push(h), i.push(t.mapPos(l));
      else if (a === !0) {
        let { mapped: c, pos: f } = h.map(l, t);
        c && (s = Math.max(s, c.maxPoint), e.push(c), i.push(f));
      }
    }
    let r = this.nextLayer.map(t);
    return e.length == 0 ? r : new F(i, e, r || F.empty, s);
  }
  /**
  Iterate over the ranges that touch the region `from` to `to`,
  calling `f` for each. There is no guarantee that the ranges will
  be reported in any specific order. When the callback returns
  `false`, iteration stops.
  */
  between(t, e, i) {
    if (!this.isEmpty) {
      for (let s = 0; s < this.chunk.length; s++) {
        let r = this.chunkPos[s], o = this.chunk[s];
        if (e >= r && t <= r + o.length && o.between(r, t - r, e - r, i) === !1)
          return;
      }
      this.nextLayer.between(t, e, i);
    }
  }
  /**
  Iterate over the ranges in this set, in order, including all
  ranges that end at or after `from`.
  */
  iter(t = 0) {
    return wi.from([this]).goto(t);
  }
  /**
  @internal
  */
  get isEmpty() {
    return this.nextLayer == this;
  }
  /**
  Iterate over the ranges in a collection of sets, in order,
  starting from `from`.
  */
  static iter(t, e = 0) {
    return wi.from(t).goto(e);
  }
  /**
  Iterate over two groups of sets, calling methods on `comparator`
  to notify it of possible differences.
  */
  static compare(t, e, i, s, r = -1) {
    let o = t.filter((f) => f.maxPoint > 0 || !f.isEmpty && f.maxPoint >= r), l = e.filter((f) => f.maxPoint > 0 || !f.isEmpty && f.maxPoint >= r), h = Cr(o, l, i), a = new si(o, h, r), c = new si(l, h, r);
    i.iterGaps((f, u, d) => Ar(a, f, c, u, d, s)), i.empty && i.length == 0 && Ar(a, 0, c, 0, 0, s);
  }
  /**
  Compare the contents of two groups of range sets, returning true
  if they are equivalent in the given range.
  */
  static eq(t, e, i = 0, s) {
    s == null && (s = 999999999);
    let r = t.filter((c) => !c.isEmpty && e.indexOf(c) < 0), o = e.filter((c) => !c.isEmpty && t.indexOf(c) < 0);
    if (r.length != o.length)
      return !1;
    if (!r.length)
      return !0;
    let l = Cr(r, o), h = new si(r, l, 0).goto(i), a = new si(o, l, 0).goto(i);
    for (; ; ) {
      if (h.to != a.to || !pn(h.active, a.active) || h.point && (!a.point || !h.point.eq(a.point)))
        return !1;
      if (h.to > s)
        return !0;
      h.next(), a.next();
    }
  }
  /**
  Iterate over a group of range sets at the same time, notifying
  the iterator about the ranges covering every given piece of
  content. Returns the open count (see
  [`SpanIterator.span`](https://codemirror.net/6/docs/ref/#state.SpanIterator.span)) at the end
  of the iteration.
  */
  static spans(t, e, i, s, r = -1) {
    let o = new si(t, null, r).goto(e), l = e, h = o.openStart;
    for (; ; ) {
      let a = Math.min(o.to, i);
      if (o.point) {
        let c = o.activeForPoint(o.to), f = o.pointFrom < e ? c.length + 1 : Math.min(c.length, h);
        s.point(l, a, o.point, c, f, o.pointRank), h = Math.min(o.openEnd(a), c.length);
      } else
        a > l && (s.span(l, a, o.active, h), h = o.openEnd(a));
      if (o.to > i)
        return h + (o.point && o.to > i ? 1 : 0);
      l = o.to, o.next();
    }
  }
  /**
  Create a range set for the given range or array of ranges. By
  default, this expects the ranges to be _sorted_ (by start
  position and, if two start at the same position,
  `value.startSide`). You can pass `true` as second argument to
  cause the method to sort them.
  */
  static of(t, e = !1) {
    let i = new Ee();
    for (let s of t instanceof un ? [t] : e ? Yc(t) : t)
      i.add(s.from, s.to, s.value);
    return i.finish();
  }
}
F.empty = /* @__PURE__ */ new F([], [], null, -1);
function Yc(n) {
  if (n.length > 1)
    for (let t = n[0], e = 1; e < n.length; e++) {
      let i = n[e];
      if (dn(t, i) > 0)
        return n.slice().sort(dn);
      t = i;
    }
  return n;
}
F.empty.nextLayer = F.empty;
class Ee {
  finishChunk(t) {
    this.chunks.push(new Jn(this.from, this.to, this.value, this.maxPoint)), this.chunkPos.push(this.chunkStart), this.chunkStart = -1, this.setMaxPoint = Math.max(this.setMaxPoint, this.maxPoint), this.maxPoint = -1, t && (this.from = [], this.to = [], this.value = []);
  }
  /**
  Create an empty builder.
  */
  constructor() {
    this.chunks = [], this.chunkPos = [], this.chunkStart = -1, this.last = null, this.lastFrom = -1e9, this.lastTo = -1e9, this.from = [], this.to = [], this.value = [], this.maxPoint = -1, this.setMaxPoint = -1, this.nextLayer = null;
  }
  /**
  Add a range. Ranges should be added in sorted (by `from` and
  `value.startSide`) order.
  */
  add(t, e, i) {
    this.addInner(t, e, i) || (this.nextLayer || (this.nextLayer = new Ee())).add(t, e, i);
  }
  /**
  @internal
  */
  addInner(t, e, i) {
    let s = t - this.lastTo || i.startSide - this.last.endSide;
    if (s <= 0 && (t - this.lastFrom || i.startSide - this.last.startSide) < 0)
      throw new Error("Ranges must be added sorted by `from` position and `startSide`");
    return s < 0 ? !1 : (this.from.length == 250 && this.finishChunk(!0), this.chunkStart < 0 && (this.chunkStart = t), this.from.push(t - this.chunkStart), this.to.push(e - this.chunkStart), this.last = i, this.lastFrom = t, this.lastTo = e, this.value.push(i), i.point && (this.maxPoint = Math.max(this.maxPoint, e - t)), !0);
  }
  /**
  @internal
  */
  addChunk(t, e) {
    if ((t - this.lastTo || e.value[0].startSide - this.last.endSide) < 0)
      return !1;
    this.from.length && this.finishChunk(!0), this.setMaxPoint = Math.max(this.setMaxPoint, e.maxPoint), this.chunks.push(e), this.chunkPos.push(t);
    let i = e.value.length - 1;
    return this.last = e.value[i], this.lastFrom = e.from[i] + t, this.lastTo = e.to[i] + t, !0;
  }
  /**
  Finish the range set. Returns the new set. The builder can't be
  used anymore after this has been called.
  */
  finish() {
    return this.finishInner(F.empty);
  }
  /**
  @internal
  */
  finishInner(t) {
    if (this.from.length && this.finishChunk(!1), this.chunks.length == 0)
      return t;
    let e = F.create(this.chunkPos, this.chunks, this.nextLayer ? this.nextLayer.finishInner(t) : t, this.setMaxPoint);
    return this.from = null, e;
  }
}
function Cr(n, t, e) {
  let i = /* @__PURE__ */ new Map();
  for (let r of n)
    for (let o = 0; o < r.chunk.length; o++)
      r.chunk[o].maxPoint <= 0 && i.set(r.chunk[o], r.chunkPos[o]);
  let s = /* @__PURE__ */ new Set();
  for (let r of t)
    for (let o = 0; o < r.chunk.length; o++) {
      let l = i.get(r.chunk[o]);
      l != null && (e ? e.mapPos(l) : l) == r.chunkPos[o] && !(e != null && e.touchesRange(l, l + r.chunk[o].length)) && s.add(r.chunk[o]);
    }
  return s;
}
class bl {
  constructor(t, e, i, s = 0) {
    this.layer = t, this.skip = e, this.minPoint = i, this.rank = s;
  }
  get startSide() {
    return this.value ? this.value.startSide : 0;
  }
  get endSide() {
    return this.value ? this.value.endSide : 0;
  }
  goto(t, e = -1e9) {
    return this.chunkIndex = this.rangeIndex = 0, this.gotoInner(t, e, !1), this;
  }
  gotoInner(t, e, i) {
    for (; this.chunkIndex < this.layer.chunk.length; ) {
      let s = this.layer.chunk[this.chunkIndex];
      if (!(this.skip && this.skip.has(s) || this.layer.chunkEnd(this.chunkIndex) < t || s.maxPoint < this.minPoint))
        break;
      this.chunkIndex++, i = !1;
    }
    if (this.chunkIndex < this.layer.chunk.length) {
      let s = this.layer.chunk[this.chunkIndex].findIndex(t - this.layer.chunkPos[this.chunkIndex], e, !0);
      (!i || this.rangeIndex < s) && this.setRangeIndex(s);
    }
    this.next();
  }
  forward(t, e) {
    (this.to - t || this.endSide - e) < 0 && this.gotoInner(t, e, !0);
  }
  next() {
    for (; ; )
      if (this.chunkIndex == this.layer.chunk.length) {
        this.from = this.to = 1e9, this.value = null;
        break;
      } else {
        let t = this.layer.chunkPos[this.chunkIndex], e = this.layer.chunk[this.chunkIndex], i = t + e.from[this.rangeIndex];
        if (this.from = i, this.to = t + e.to[this.rangeIndex], this.value = e.value[this.rangeIndex], this.setRangeIndex(this.rangeIndex + 1), this.minPoint < 0 || this.value.point && this.to - this.from >= this.minPoint)
          break;
      }
  }
  setRangeIndex(t) {
    if (t == this.layer.chunk[this.chunkIndex].value.length) {
      if (this.chunkIndex++, this.skip)
        for (; this.chunkIndex < this.layer.chunk.length && this.skip.has(this.layer.chunk[this.chunkIndex]); )
          this.chunkIndex++;
      this.rangeIndex = 0;
    } else
      this.rangeIndex = t;
  }
  nextChunk() {
    this.chunkIndex++, this.rangeIndex = 0, this.next();
  }
  compare(t) {
    return this.from - t.from || this.startSide - t.startSide || this.rank - t.rank || this.to - t.to || this.endSide - t.endSide;
  }
}
class wi {
  constructor(t) {
    this.heap = t;
  }
  static from(t, e = null, i = -1) {
    let s = [];
    for (let r = 0; r < t.length; r++)
      for (let o = t[r]; !o.isEmpty; o = o.nextLayer)
        o.maxPoint >= i && s.push(new bl(o, e, i, r));
    return s.length == 1 ? s[0] : new wi(s);
  }
  get startSide() {
    return this.value ? this.value.startSide : 0;
  }
  goto(t, e = -1e9) {
    for (let i of this.heap)
      i.goto(t, e);
    for (let i = this.heap.length >> 1; i >= 0; i--)
      Hs(this.heap, i);
    return this.next(), this;
  }
  forward(t, e) {
    for (let i of this.heap)
      i.forward(t, e);
    for (let i = this.heap.length >> 1; i >= 0; i--)
      Hs(this.heap, i);
    (this.to - t || this.value.endSide - e) < 0 && this.next();
  }
  next() {
    if (this.heap.length == 0)
      this.from = this.to = 1e9, this.value = null, this.rank = -1;
    else {
      let t = this.heap[0];
      this.from = t.from, this.to = t.to, this.value = t.value, this.rank = t.rank, t.value && t.next(), Hs(this.heap, 0);
    }
  }
}
function Hs(n, t) {
  for (let e = n[t]; ; ) {
    let i = (t << 1) + 1;
    if (i >= n.length)
      break;
    let s = n[i];
    if (i + 1 < n.length && s.compare(n[i + 1]) >= 0 && (s = n[i + 1], i++), e.compare(s) < 0)
      break;
    n[i] = e, n[t] = s, t = i;
  }
}
class si {
  constructor(t, e, i) {
    this.minPoint = i, this.active = [], this.activeTo = [], this.activeRank = [], this.minActive = -1, this.point = null, this.pointFrom = 0, this.pointRank = 0, this.to = -1e9, this.endSide = 0, this.openStart = -1, this.cursor = wi.from(t, e, i);
  }
  goto(t, e = -1e9) {
    return this.cursor.goto(t, e), this.active.length = this.activeTo.length = this.activeRank.length = 0, this.minActive = -1, this.to = t, this.endSide = e, this.openStart = -1, this.next(), this;
  }
  forward(t, e) {
    for (; this.minActive > -1 && (this.activeTo[this.minActive] - t || this.active[this.minActive].endSide - e) < 0; )
      this.removeActive(this.minActive);
    this.cursor.forward(t, e);
  }
  removeActive(t) {
    Li(this.active, t), Li(this.activeTo, t), Li(this.activeRank, t), this.minActive = Or(this.active, this.activeTo);
  }
  addActive(t) {
    let e = 0, { value: i, to: s, rank: r } = this.cursor;
    for (; e < this.activeRank.length && this.activeRank[e] <= r; )
      e++;
    Ei(this.active, e, i), Ei(this.activeTo, e, s), Ei(this.activeRank, e, r), t && Ei(t, e, this.cursor.from), this.minActive = Or(this.active, this.activeTo);
  }
  // After calling this, if `this.point` != null, the next range is a
  // point. Otherwise, it's a regular range, covered by `this.active`.
  next() {
    let t = this.to, e = this.point;
    this.point = null;
    let i = this.openStart < 0 ? [] : null;
    for (; ; ) {
      let s = this.minActive;
      if (s > -1 && (this.activeTo[s] - this.cursor.from || this.active[s].endSide - this.cursor.startSide) < 0) {
        if (this.activeTo[s] > t) {
          this.to = this.activeTo[s], this.endSide = this.active[s].endSide;
          break;
        }
        this.removeActive(s), i && Li(i, s);
      } else if (this.cursor.value)
        if (this.cursor.from > t) {
          this.to = this.cursor.from, this.endSide = this.cursor.startSide;
          break;
        } else {
          let r = this.cursor.value;
          if (!r.point)
            this.addActive(i), this.cursor.next();
          else if (e && this.cursor.to == this.to && this.cursor.from < this.cursor.to)
            this.cursor.next();
          else {
            this.point = r, this.pointFrom = this.cursor.from, this.pointRank = this.cursor.rank, this.to = this.cursor.to, this.endSide = r.endSide, this.cursor.next(), this.forward(this.to, this.endSide);
            break;
          }
        }
      else {
        this.to = this.endSide = 1e9;
        break;
      }
    }
    if (i) {
      this.openStart = 0;
      for (let s = i.length - 1; s >= 0 && i[s] < t; s--)
        this.openStart++;
    }
  }
  activeForPoint(t) {
    if (!this.active.length)
      return this.active;
    let e = [];
    for (let i = this.active.length - 1; i >= 0 && !(this.activeRank[i] < this.pointRank); i--)
      (this.activeTo[i] > t || this.activeTo[i] == t && this.active[i].endSide >= this.point.endSide) && e.push(this.active[i]);
    return e.reverse();
  }
  openEnd(t) {
    let e = 0;
    for (let i = this.activeTo.length - 1; i >= 0 && this.activeTo[i] > t; i--)
      e++;
    return e;
  }
}
function Ar(n, t, e, i, s, r) {
  n.goto(t), e.goto(i);
  let o = i + s, l = i, h = i - t;
  for (; ; ) {
    let a = n.to + h - e.to || n.endSide - e.endSide, c = a < 0 ? n.to + h : e.to, f = Math.min(c, o);
    if (n.point || e.point ? n.point && e.point && (n.point == e.point || n.point.eq(e.point)) && pn(n.activeForPoint(n.to), e.activeForPoint(e.to)) || r.comparePoint(l, f, n.point, e.point) : f > l && !pn(n.active, e.active) && r.compareRange(l, f, n.active, e.active), c > o)
      break;
    l = c, a <= 0 && n.next(), a >= 0 && e.next();
  }
}
function pn(n, t) {
  if (n.length != t.length)
    return !1;
  for (let e = 0; e < n.length; e++)
    if (n[e] != t[e] && !n[e].eq(t[e]))
      return !1;
  return !0;
}
function Li(n, t) {
  for (let e = t, i = n.length - 1; e < i; e++)
    n[e] = n[e + 1];
  n.pop();
}
function Ei(n, t, e) {
  for (let i = n.length - 1; i >= t; i--)
    n[i + 1] = n[i];
  n[t] = e;
}
function Or(n, t) {
  let e = -1, i = 1e9;
  for (let s = 0; s < t.length; s++)
    (t[s] - i || n[s].endSide - n[e].endSide) < 0 && (e = s, i = t[s]);
  return e;
}
function Oi(n, t, e = n.length) {
  let i = 0;
  for (let s = 0; s < e; )
    n.charCodeAt(s) == 9 ? (i += t - i % t, s++) : (i++, s = wt(n, s));
  return i;
}
function Qc(n, t, e, i) {
  for (let s = 0, r = 0; ; ) {
    if (r >= t)
      return s;
    if (s == n.length)
      break;
    r += n.charCodeAt(s) == 9 ? e - r % e : 1, s = wt(n, s);
  }
  return i === !0 ? -1 : n.length;
}
const gn = "ͼ", Mr = typeof Symbol > "u" ? "__" + gn : Symbol.for(gn), mn = typeof Symbol > "u" ? "__styleSet" + Math.floor(Math.random() * 1e8) : Symbol("styleSet"), Tr = typeof globalThis < "u" ? globalThis : typeof window < "u" ? window : {};
class we {
  // :: (Object<Style>, ?{finish: ?(string) → string})
  // Create a style module from the given spec.
  //
  // When `finish` is given, it is called on regular (non-`@`)
  // selectors (after `&` expansion) to compute the final selector.
  constructor(t, e) {
    this.rules = [];
    let { finish: i } = e || {};
    function s(o) {
      return /^@/.test(o) ? [o] : o.split(/,\s*/);
    }
    function r(o, l, h, a) {
      let c = [], f = /^@(\w+)\b/.exec(o[0]), u = f && f[1] == "keyframes";
      if (f && l == null)
        return h.push(o[0] + ";");
      for (let d in l) {
        let p = l[d];
        if (/&/.test(d))
          r(
            d.split(/,\s*/).map((m) => o.map((g) => m.replace(/&/, g))).reduce((m, g) => m.concat(g)),
            p,
            h
          );
        else if (p && typeof p == "object") {
          if (!f)
            throw new RangeError("The value of a property (" + d + ") should be a primitive value.");
          r(s(d), p, c, u);
        } else
          p != null && c.push(d.replace(/_.*/, "").replace(/[A-Z]/g, (m) => "-" + m.toLowerCase()) + ": " + p + ";");
      }
      (c.length || u) && h.push((i && !f && !a ? o.map(i) : o).join(", ") + " {" + c.join(" ") + "}");
    }
    for (let o in t)
      r(s(o), t[o], this.rules);
  }
  // :: () → string
  // Returns a string containing the module's CSS rules.
  getRules() {
    return this.rules.join(`
`);
  }
  // :: () → string
  // Generate a new unique CSS class name.
  static newName() {
    let t = Tr[Mr] || 1;
    return Tr[Mr] = t + 1, gn + t.toString(36);
  }
  // :: (union<Document, ShadowRoot>, union<[StyleModule], StyleModule>, ?{nonce: ?string})
  //
  // Mount the given set of modules in the given DOM root, which ensures
  // that the CSS rules defined by the module are available in that
  // context.
  //
  // Rules are only added to the document once per root.
  //
  // Rule order will follow the order of the modules, so that rules from
  // modules later in the array take precedence of those from earlier
  // modules. If you call this function multiple times for the same root
  // in a way that changes the order of already mounted modules, the old
  // order will be changed.
  //
  // If a Content Security Policy nonce is provided, it is added to
  // the `<style>` tag generated by the library.
  static mount(t, e, i) {
    let s = t[mn], r = i && i.nonce;
    s ? r && s.setNonce(r) : s = new Jc(t, r), s.mount(Array.isArray(e) ? e : [e]);
  }
}
let Dr = /* @__PURE__ */ new Map();
class Jc {
  constructor(t, e) {
    let i = t.ownerDocument || t, s = i.defaultView;
    if (!t.head && t.adoptedStyleSheets && s.CSSStyleSheet) {
      let r = Dr.get(i);
      if (r)
        return t.adoptedStyleSheets = [r.sheet, ...t.adoptedStyleSheets], t[mn] = r;
      this.sheet = new s.CSSStyleSheet(), t.adoptedStyleSheets = [this.sheet, ...t.adoptedStyleSheets], Dr.set(i, this);
    } else {
      this.styleTag = i.createElement("style"), e && this.styleTag.setAttribute("nonce", e);
      let r = t.head || t;
      r.insertBefore(this.styleTag, r.firstChild);
    }
    this.modules = [], t[mn] = this;
  }
  mount(t) {
    let e = this.sheet, i = 0, s = 0;
    for (let r = 0; r < t.length; r++) {
      let o = t[r], l = this.modules.indexOf(o);
      if (l < s && l > -1 && (this.modules.splice(l, 1), s--, l = -1), l == -1) {
        if (this.modules.splice(s++, 0, o), e)
          for (let h = 0; h < o.rules.length; h++)
            e.insertRule(o.rules[h], i++);
      } else {
        for (; s < l; )
          i += this.modules[s++].rules.length;
        i += o.rules.length, s++;
      }
    }
    if (!e) {
      let r = "";
      for (let o = 0; o < this.modules.length; o++)
        r += this.modules[o].getRules() + `
`;
      this.styleTag.textContent = r;
    }
  }
  setNonce(t) {
    this.styleTag && this.styleTag.getAttribute("nonce") != t && this.styleTag.setAttribute("nonce", t);
  }
}
var ye = {
  8: "Backspace",
  9: "Tab",
  10: "Enter",
  12: "NumLock",
  13: "Enter",
  16: "Shift",
  17: "Control",
  18: "Alt",
  20: "CapsLock",
  27: "Escape",
  32: " ",
  33: "PageUp",
  34: "PageDown",
  35: "End",
  36: "Home",
  37: "ArrowLeft",
  38: "ArrowUp",
  39: "ArrowRight",
  40: "ArrowDown",
  44: "PrintScreen",
  45: "Insert",
  46: "Delete",
  59: ";",
  61: "=",
  91: "Meta",
  92: "Meta",
  106: "*",
  107: "+",
  108: ",",
  109: "-",
  110: ".",
  111: "/",
  144: "NumLock",
  145: "ScrollLock",
  160: "Shift",
  161: "Shift",
  162: "Control",
  163: "Control",
  164: "Alt",
  165: "Alt",
  173: "-",
  186: ";",
  187: "=",
  188: ",",
  189: "-",
  190: ".",
  191: "/",
  192: "`",
  219: "[",
  220: "\\",
  221: "]",
  222: "'"
}, yi = {
  48: ")",
  49: "!",
  50: "@",
  51: "#",
  52: "$",
  53: "%",
  54: "^",
  55: "&",
  56: "*",
  57: "(",
  59: ":",
  61: "+",
  173: "_",
  186: ":",
  187: "+",
  188: "<",
  189: "_",
  190: ">",
  191: "?",
  192: "~",
  219: "{",
  220: "|",
  221: "}",
  222: '"'
}, Xc = typeof navigator < "u" && /Mac/.test(navigator.platform), Zc = typeof navigator < "u" && /MSIE \d|Trident\/(?:[7-9]|\d{2,})\..*rv:(\d+)/.exec(navigator.userAgent);
for (var ot = 0; ot < 10; ot++)
  ye[48 + ot] = ye[96 + ot] = String(ot);
for (var ot = 1; ot <= 24; ot++)
  ye[ot + 111] = "F" + ot;
for (var ot = 65; ot <= 90; ot++)
  ye[ot] = String.fromCharCode(ot + 32), yi[ot] = String.fromCharCode(ot);
for (var $s in ye)
  yi.hasOwnProperty($s) || (yi[$s] = ye[$s]);
function tf(n) {
  var t = Xc && n.metaKey && n.shiftKey && !n.ctrlKey && !n.altKey || Zc && n.shiftKey && n.key && n.key.length == 1 || n.key == "Unidentified", e = !t && n.key || (n.shiftKey ? yi : ye)[n.keyCode] || n.key || "Unidentified";
  return e == "Esc" && (e = "Escape"), e == "Del" && (e = "Delete"), e == "Left" && (e = "ArrowLeft"), e == "Up" && (e = "ArrowUp"), e == "Right" && (e = "ArrowRight"), e == "Down" && (e = "ArrowDown"), e;
}
function us(n) {
  let t;
  return n.nodeType == 11 ? t = n.getSelection ? n : n.ownerDocument : t = n, t.getSelection();
}
function wn(n, t) {
  return t ? n == t || n.contains(t.nodeType != 1 ? t.parentNode : t) : !1;
}
function ef(n) {
  let t = n.activeElement;
  for (; t && t.shadowRoot; )
    t = t.shadowRoot.activeElement;
  return t;
}
function ts(n, t) {
  if (!t.anchorNode)
    return !1;
  try {
    return wn(n, t.anchorNode);
  } catch {
    return !1;
  }
}
function bi(n) {
  return n.nodeType == 3 ? Ne(n, 0, n.nodeValue.length).getClientRects() : n.nodeType == 1 ? n.getClientRects() : [];
}
function ds(n, t, e, i) {
  return e ? Pr(n, t, e, i, -1) || Pr(n, t, e, i, 1) : !1;
}
function ki(n) {
  for (var t = 0; ; t++)
    if (n = n.previousSibling, !n)
      return t;
}
function Pr(n, t, e, i, s) {
  for (; ; ) {
    if (n == e && t == i)
      return !0;
    if (t == (s < 0 ? 0 : ne(n))) {
      if (n.nodeName == "DIV")
        return !1;
      let r = n.parentNode;
      if (!r || r.nodeType != 1)
        return !1;
      t = ki(n) + (s < 0 ? 0 : 1), n = r;
    } else if (n.nodeType == 1) {
      if (n = n.childNodes[t + (s < 0 ? -1 : 0)], n.nodeType == 1 && n.contentEditable == "false")
        return !1;
      t = s < 0 ? ne(n) : 0;
    } else
      return !1;
  }
}
function ne(n) {
  return n.nodeType == 3 ? n.nodeValue.length : n.childNodes.length;
}
function Xn(n, t) {
  let e = t ? n.left : n.right;
  return { left: e, right: e, top: n.top, bottom: n.bottom };
}
function sf(n) {
  return {
    left: 0,
    right: n.innerWidth,
    top: 0,
    bottom: n.innerHeight
  };
}
function nf(n, t, e, i, s, r, o, l) {
  let h = n.ownerDocument, a = h.defaultView || window;
  for (let c = n, f = !1; c && !f; )
    if (c.nodeType == 1) {
      let u, d = c == h.body, p = 1, m = 1;
      if (d)
        u = sf(a);
      else {
        if (/^(fixed|sticky)$/.test(getComputedStyle(c).position) && (f = !0), c.scrollHeight <= c.clientHeight && c.scrollWidth <= c.clientWidth) {
          c = c.assignedSlot || c.parentNode;
          continue;
        }
        let x = c.getBoundingClientRect();
        p = x.width / c.offsetWidth, m = x.height / c.offsetHeight, u = {
          left: x.left,
          right: x.left + c.clientWidth * p,
          top: x.top,
          bottom: x.top + c.clientHeight * m
        };
      }
      let g = 0, y = 0;
      if (s == "nearest")
        t.top < u.top ? (y = -(u.top - t.top + o), e > 0 && t.bottom > u.bottom + y && (y = t.bottom - u.bottom + y + o)) : t.bottom > u.bottom && (y = t.bottom - u.bottom + o, e < 0 && t.top - y < u.top && (y = -(u.top + y - t.top + o)));
      else {
        let x = t.bottom - t.top, S = u.bottom - u.top;
        y = (s == "center" && x <= S ? t.top + x / 2 - S / 2 : s == "start" || s == "center" && e < 0 ? t.top - o : t.bottom - S + o) - u.top;
      }
      if (i == "nearest" ? t.left < u.left ? (g = -(u.left - t.left + r), e > 0 && t.right > u.right + g && (g = t.right - u.right + g + r)) : t.right > u.right && (g = t.right - u.right + r, e < 0 && t.left < u.left + g && (g = -(u.left + g - t.left + r))) : g = (i == "center" ? t.left + (t.right - t.left) / 2 - (u.right - u.left) / 2 : i == "start" == l ? t.left - r : t.right - (u.right - u.left) + r) - u.left, g || y)
        if (d)
          a.scrollBy(g, y);
        else {
          let x = 0, S = 0;
          if (y) {
            let v = c.scrollTop;
            c.scrollTop += y / m, S = (c.scrollTop - v) * m;
          }
          if (g) {
            let v = c.scrollLeft;
            c.scrollLeft += g / p, x = (c.scrollLeft - v) * p;
          }
          t = {
            left: t.left - x,
            top: t.top - S,
            right: t.right - x,
            bottom: t.bottom - S
          }, x && Math.abs(x - g) < 1 && (i = "nearest"), S && Math.abs(S - y) < 1 && (s = "nearest");
        }
      if (d)
        break;
      c = c.assignedSlot || c.parentNode;
    } else if (c.nodeType == 11)
      c = c.host;
    else
      break;
}
function rf(n) {
  let t = n.ownerDocument;
  for (let e = n.parentNode; e && e != t.body; )
    if (e.nodeType == 1) {
      if (e.scrollHeight > e.clientHeight || e.scrollWidth > e.clientWidth)
        return e;
      e = e.assignedSlot || e.parentNode;
    } else if (e.nodeType == 11)
      e = e.host;
    else
      break;
  return null;
}
class of {
  constructor() {
    this.anchorNode = null, this.anchorOffset = 0, this.focusNode = null, this.focusOffset = 0;
  }
  eq(t) {
    return this.anchorNode == t.anchorNode && this.anchorOffset == t.anchorOffset && this.focusNode == t.focusNode && this.focusOffset == t.focusOffset;
  }
  setRange(t) {
    let { anchorNode: e, focusNode: i } = t;
    this.set(e, Math.min(t.anchorOffset, e ? ne(e) : 0), i, Math.min(t.focusOffset, i ? ne(i) : 0));
  }
  set(t, e, i, s) {
    this.anchorNode = t, this.anchorOffset = e, this.focusNode = i, this.focusOffset = s;
  }
}
let _e = null;
function kl(n) {
  if (n.setActive)
    return n.setActive();
  if (_e)
    return n.focus(_e);
  let t = [];
  for (let e = n; e && (t.push(e, e.scrollTop, e.scrollLeft), e != e.ownerDocument); e = e.parentNode)
    ;
  if (n.focus(_e == null ? {
    get preventScroll() {
      return _e = { preventScroll: !0 }, !0;
    }
  } : void 0), !_e) {
    _e = !1;
    for (let e = 0; e < t.length; ) {
      let i = t[e++], s = t[e++], r = t[e++];
      i.scrollTop != s && (i.scrollTop = s), i.scrollLeft != r && (i.scrollLeft = r);
    }
  }
}
let Br;
function Ne(n, t, e = t) {
  let i = Br || (Br = document.createRange());
  return i.setEnd(n, e), i.setStart(n, t), i;
}
function Ke(n, t, e) {
  let i = { key: t, code: t, keyCode: e, which: e, cancelable: !0 }, s = new KeyboardEvent("keydown", i);
  s.synthetic = !0, n.dispatchEvent(s);
  let r = new KeyboardEvent("keyup", i);
  return r.synthetic = !0, n.dispatchEvent(r), s.defaultPrevented || r.defaultPrevented;
}
function lf(n) {
  for (; n; ) {
    if (n && (n.nodeType == 9 || n.nodeType == 11 && n.host))
      return n;
    n = n.assignedSlot || n.parentNode;
  }
  return null;
}
function xl(n) {
  for (; n.attributes.length; )
    n.removeAttributeNode(n.attributes[0]);
}
function hf(n, t) {
  let e = t.focusNode, i = t.focusOffset;
  if (!e || t.anchorNode != e || t.anchorOffset != i)
    return !1;
  for (i = Math.min(i, ne(e)); ; )
    if (i) {
      if (e.nodeType != 1)
        return !1;
      let s = e.childNodes[i - 1];
      s.contentEditable == "false" ? i-- : (e = s, i = ne(e));
    } else {
      if (e == n)
        return !0;
      i = ki(e), e = e.parentNode;
    }
}
function vl(n) {
  return n.scrollTop > Math.max(1, n.scrollHeight - n.clientHeight - 4);
}
class ct {
  constructor(t, e, i = !0) {
    this.node = t, this.offset = e, this.precise = i;
  }
  static before(t, e) {
    return new ct(t.parentNode, ki(t), e);
  }
  static after(t, e) {
    return new ct(t.parentNode, ki(t) + 1, e);
  }
}
const Zn = [];
class q {
  constructor() {
    this.parent = null, this.dom = null, this.flags = 2;
  }
  get overrideDOMText() {
    return null;
  }
  get posAtStart() {
    return this.parent ? this.parent.posBefore(this) : 0;
  }
  get posAtEnd() {
    return this.posAtStart + this.length;
  }
  posBefore(t) {
    let e = this.posAtStart;
    for (let i of this.children) {
      if (i == t)
        return e;
      e += i.length + i.breakAfter;
    }
    throw new RangeError("Invalid child in posBefore");
  }
  posAfter(t) {
    return this.posBefore(t) + t.length;
  }
  sync(t, e) {
    if (this.flags & 2) {
      let i = this.dom, s = null, r;
      for (let o of this.children) {
        if (o.flags & 7) {
          if (!o.dom && (r = s ? s.nextSibling : i.firstChild)) {
            let l = q.get(r);
            (!l || !l.parent && l.canReuseDOM(o)) && o.reuseDOM(r);
          }
          o.sync(t, e), o.flags &= -8;
        }
        if (r = s ? s.nextSibling : i.firstChild, e && !e.written && e.node == i && r != o.dom && (e.written = !0), o.dom.parentNode == i)
          for (; r && r != o.dom; )
            r = Rr(r);
        else
          i.insertBefore(o.dom, r);
        s = o.dom;
      }
      for (r = s ? s.nextSibling : i.firstChild, r && e && e.node == i && (e.written = !0); r; )
        r = Rr(r);
    } else if (this.flags & 1)
      for (let i of this.children)
        i.flags & 7 && (i.sync(t, e), i.flags &= -8);
  }
  reuseDOM(t) {
  }
  localPosFromDOM(t, e) {
    let i;
    if (t == this.dom)
      i = this.dom.childNodes[e];
    else {
      let s = ne(t) == 0 ? 0 : e == 0 ? -1 : 1;
      for (; ; ) {
        let r = t.parentNode;
        if (r == this.dom)
          break;
        s == 0 && r.firstChild != r.lastChild && (t == r.firstChild ? s = -1 : s = 1), t = r;
      }
      s < 0 ? i = t : i = t.nextSibling;
    }
    if (i == this.dom.firstChild)
      return 0;
    for (; i && !q.get(i); )
      i = i.nextSibling;
    if (!i)
      return this.length;
    for (let s = 0, r = 0; ; s++) {
      let o = this.children[s];
      if (o.dom == i)
        return r;
      r += o.length + o.breakAfter;
    }
  }
  domBoundsAround(t, e, i = 0) {
    let s = -1, r = -1, o = -1, l = -1;
    for (let h = 0, a = i, c = i; h < this.children.length; h++) {
      let f = this.children[h], u = a + f.length;
      if (a < t && u > e)
        return f.domBoundsAround(t, e, a);
      if (u >= t && s == -1 && (s = h, r = a), a > e && f.dom.parentNode == this.dom) {
        o = h, l = c;
        break;
      }
      c = u, a = u + f.breakAfter;
    }
    return {
      from: r,
      to: l < 0 ? i + this.length : l,
      startDOM: (s ? this.children[s - 1].dom.nextSibling : null) || this.dom.firstChild,
      endDOM: o < this.children.length && o >= 0 ? this.children[o].dom : null
    };
  }
  markDirty(t = !1) {
    this.flags |= 2, this.markParentsDirty(t);
  }
  markParentsDirty(t) {
    for (let e = this.parent; e; e = e.parent) {
      if (t && (e.flags |= 2), e.flags & 1)
        return;
      e.flags |= 1, t = !1;
    }
  }
  setParent(t) {
    this.parent != t && (this.parent = t, this.flags & 7 && this.markParentsDirty(!0));
  }
  setDOM(t) {
    this.dom != t && (this.dom && (this.dom.cmView = null), this.dom = t, t.cmView = this);
  }
  get rootView() {
    for (let t = this; ; ) {
      let e = t.parent;
      if (!e)
        return t;
      t = e;
    }
  }
  replaceChildren(t, e, i = Zn) {
    this.markDirty();
    for (let s = t; s < e; s++) {
      let r = this.children[s];
      r.parent == this && r.destroy();
    }
    this.children.splice(t, e - t, ...i);
    for (let s = 0; s < i.length; s++)
      i[s].setParent(this);
  }
  ignoreMutation(t) {
    return !1;
  }
  ignoreEvent(t) {
    return !1;
  }
  childCursor(t = this.length) {
    return new Sl(this.children, t, this.children.length);
  }
  childPos(t, e = 1) {
    return this.childCursor().findPos(t, e);
  }
  toString() {
    let t = this.constructor.name.replace("View", "");
    return t + (this.children.length ? "(" + this.children.join() + ")" : this.length ? "[" + (t == "Text" ? this.text : this.length) + "]" : "") + (this.breakAfter ? "#" : "");
  }
  static get(t) {
    return t.cmView;
  }
  get isEditable() {
    return !0;
  }
  get isWidget() {
    return !1;
  }
  get isHidden() {
    return !1;
  }
  merge(t, e, i, s, r, o) {
    return !1;
  }
  become(t) {
    return !1;
  }
  canReuseDOM(t) {
    return t.constructor == this.constructor && !((this.flags | t.flags) & 8);
  }
  // When this is a zero-length view with a side, this should return a
  // number <= 0 to indicate it is before its position, or a
  // number > 0 when after its position.
  getSide() {
    return 0;
  }
  destroy() {
    this.parent = null;
  }
}
q.prototype.breakAfter = 0;
function Rr(n) {
  let t = n.nextSibling;
  return n.parentNode.removeChild(n), t;
}
class Sl {
  constructor(t, e, i) {
    this.children = t, this.pos = e, this.i = i, this.off = 0;
  }
  findPos(t, e = 1) {
    for (; ; ) {
      if (t > this.pos || t == this.pos && (e > 0 || this.i == 0 || this.children[this.i - 1].breakAfter))
        return this.off = t - this.pos, this;
      let i = this.children[--this.i];
      this.pos -= i.length + i.breakAfter;
    }
  }
}
function Cl(n, t, e, i, s, r, o, l, h) {
  let { children: a } = n, c = a.length ? a[t] : null, f = r.length ? r[r.length - 1] : null, u = f ? f.breakAfter : o;
  if (!(t == i && c && !o && !u && r.length < 2 && c.merge(e, s, r.length ? f : null, e == 0, l, h))) {
    if (i < a.length) {
      let d = a[i];
      d && (s < d.length || d.breakAfter && (f != null && f.breakAfter)) ? (t == i && (d = d.split(s), s = 0), !u && f && d.merge(0, s, f, !0, 0, h) ? r[r.length - 1] = d : ((s || d.children.length && !d.children[0].length) && d.merge(0, s, null, !1, 0, h), r.push(d))) : d != null && d.breakAfter && (f ? f.breakAfter = 1 : o = 1), i++;
    }
    for (c && (c.breakAfter = o, e > 0 && (!o && r.length && c.merge(e, c.length, r[0], !1, l, 0) ? c.breakAfter = r.shift().breakAfter : (e < c.length || c.children.length && c.children[c.children.length - 1].length == 0) && c.merge(e, c.length, null, !1, l, 0), t++)); t < i && r.length; )
      if (a[i - 1].become(r[r.length - 1]))
        i--, r.pop(), h = r.length ? 0 : l;
      else if (a[t].become(r[0]))
        t++, r.shift(), l = r.length ? 0 : h;
      else
        break;
    !r.length && t && i < a.length && !a[t - 1].breakAfter && a[i].merge(0, 0, a[t - 1], !1, l, h) && t--, (t < i || r.length) && n.replaceChildren(t, i, r);
  }
}
function Al(n, t, e, i, s, r) {
  let o = n.childCursor(), { i: l, off: h } = o.findPos(e, 1), { i: a, off: c } = o.findPos(t, -1), f = t - e;
  for (let u of i)
    f += u.length;
  n.length += f, Cl(n, a, c, l, h, i, 0, s, r);
}
let vt = typeof navigator < "u" ? navigator : { userAgent: "", vendor: "", platform: "" }, yn = typeof document < "u" ? document : { documentElement: { style: {} } };
const bn = /* @__PURE__ */ /Edge\/(\d+)/.exec(vt.userAgent), Ol = /* @__PURE__ */ /MSIE \d/.test(vt.userAgent), kn = /* @__PURE__ */ /Trident\/(?:[7-9]|\d{2,})\..*rv:(\d+)/.exec(vt.userAgent), Ps = !!(Ol || kn || bn), Lr = !Ps && /* @__PURE__ */ /gecko\/(\d+)/i.test(vt.userAgent), Fs = !Ps && /* @__PURE__ */ /Chrome\/(\d+)/.exec(vt.userAgent), Er = "webkitFontSmoothing" in yn.documentElement.style, Ml = !Ps && /* @__PURE__ */ /Apple Computer/.test(vt.vendor), Nr = Ml && (/* @__PURE__ */ /Mobile\/\w+/.test(vt.userAgent) || vt.maxTouchPoints > 2);
var C = {
  mac: Nr || /* @__PURE__ */ /Mac/.test(vt.platform),
  windows: /* @__PURE__ */ /Win/.test(vt.platform),
  linux: /* @__PURE__ */ /Linux|X11/.test(vt.platform),
  ie: Ps,
  ie_version: Ol ? yn.documentMode || 6 : kn ? +kn[1] : bn ? +bn[1] : 0,
  gecko: Lr,
  gecko_version: Lr ? +(/* @__PURE__ */ /Firefox\/(\d+)/.exec(vt.userAgent) || [0, 0])[1] : 0,
  chrome: !!Fs,
  chrome_version: Fs ? +Fs[1] : 0,
  ios: Nr,
  android: /* @__PURE__ */ /Android\b/.test(vt.userAgent),
  webkit: Er,
  safari: Ml,
  webkit_version: Er ? +(/* @__PURE__ */ /\bAppleWebKit\/(\d+)/.exec(navigator.userAgent) || [0, 0])[1] : 0,
  tabSize: yn.documentElement.style.tabSize != null ? "tab-size" : "-moz-tab-size"
};
const af = 256;
class re extends q {
  constructor(t) {
    super(), this.text = t;
  }
  get length() {
    return this.text.length;
  }
  createDOM(t) {
    this.setDOM(t || document.createTextNode(this.text));
  }
  sync(t, e) {
    this.dom || this.createDOM(), this.dom.nodeValue != this.text && (e && e.node == this.dom && (e.written = !0), this.dom.nodeValue = this.text);
  }
  reuseDOM(t) {
    t.nodeType == 3 && this.createDOM(t);
  }
  merge(t, e, i) {
    return this.flags & 8 || i && (!(i instanceof re) || this.length - (e - t) + i.length > af || i.flags & 8) ? !1 : (this.text = this.text.slice(0, t) + (i ? i.text : "") + this.text.slice(e), this.markDirty(), !0);
  }
  split(t) {
    let e = new re(this.text.slice(t));
    return this.text = this.text.slice(0, t), this.markDirty(), e.flags |= this.flags & 8, e;
  }
  localPosFromDOM(t, e) {
    return t == this.dom ? e : e ? this.text.length : 0;
  }
  domAtPos(t) {
    return new ct(this.dom, t);
  }
  domBoundsAround(t, e, i) {
    return { from: i, to: i + this.length, startDOM: this.dom, endDOM: this.dom.nextSibling };
  }
  coordsAt(t, e) {
    return cf(this.dom, t, e);
  }
}
class oe extends q {
  constructor(t, e = [], i = 0) {
    super(), this.mark = t, this.children = e, this.length = i;
    for (let s of e)
      s.setParent(this);
  }
  setAttrs(t) {
    if (xl(t), this.mark.class && (t.className = this.mark.class), this.mark.attrs)
      for (let e in this.mark.attrs)
        t.setAttribute(e, this.mark.attrs[e]);
    return t;
  }
  canReuseDOM(t) {
    return super.canReuseDOM(t) && !((this.flags | t.flags) & 8);
  }
  reuseDOM(t) {
    t.nodeName == this.mark.tagName.toUpperCase() && (this.setDOM(t), this.flags |= 6);
  }
  sync(t, e) {
    this.dom ? this.flags & 4 && this.setAttrs(this.dom) : this.setDOM(this.setAttrs(document.createElement(this.mark.tagName))), super.sync(t, e);
  }
  merge(t, e, i, s, r, o) {
    return i && (!(i instanceof oe && i.mark.eq(this.mark)) || t && r <= 0 || e < this.length && o <= 0) ? !1 : (Al(this, t, e, i ? i.children : [], r - 1, o - 1), this.markDirty(), !0);
  }
  split(t) {
    let e = [], i = 0, s = -1, r = 0;
    for (let l of this.children) {
      let h = i + l.length;
      h > t && e.push(i < t ? l.split(t - i) : l), s < 0 && i >= t && (s = r), i = h, r++;
    }
    let o = this.length - t;
    return this.length = t, s > -1 && (this.children.length = s, this.markDirty()), new oe(this.mark, e, o);
  }
  domAtPos(t) {
    return Tl(this, t);
  }
  coordsAt(t, e) {
    return Pl(this, t, e);
  }
}
function cf(n, t, e) {
  let i = n.nodeValue.length;
  t > i && (t = i);
  let s = t, r = t, o = 0;
  t == 0 && e < 0 || t == i && e >= 0 ? C.chrome || C.gecko || (t ? (s--, o = 1) : r < i && (r++, o = -1)) : e < 0 ? s-- : r < i && r++;
  let l = Ne(n, s, r).getClientRects();
  if (!l.length)
    return null;
  let h = l[(o ? o < 0 : e >= 0) ? 0 : l.length - 1];
  return C.safari && !o && h.width == 0 && (h = Array.prototype.find.call(l, (a) => a.width) || h), o ? Xn(h, o < 0) : h || null;
}
class fe extends q {
  static create(t, e, i) {
    return new fe(t, e, i);
  }
  constructor(t, e, i) {
    super(), this.widget = t, this.length = e, this.side = i, this.prevWidget = null;
  }
  split(t) {
    let e = fe.create(this.widget, this.length - t, this.side);
    return this.length -= t, e;
  }
  sync(t) {
    (!this.dom || !this.widget.updateDOM(this.dom, t)) && (this.dom && this.prevWidget && this.prevWidget.destroy(this.dom), this.prevWidget = null, this.setDOM(this.widget.toDOM(t)), this.dom.contentEditable = "false");
  }
  getSide() {
    return this.side;
  }
  merge(t, e, i, s, r, o) {
    return i && (!(i instanceof fe) || !this.widget.compare(i.widget) || t > 0 && r <= 0 || e < this.length && o <= 0) ? !1 : (this.length = t + (i ? i.length : 0) + (this.length - e), !0);
  }
  become(t) {
    return t instanceof fe && t.side == this.side && this.widget.constructor == t.widget.constructor ? (this.widget.compare(t.widget) || this.markDirty(!0), this.dom && !this.prevWidget && (this.prevWidget = this.widget), this.widget = t.widget, this.length = t.length, !0) : !1;
  }
  ignoreMutation() {
    return !0;
  }
  ignoreEvent(t) {
    return this.widget.ignoreEvent(t);
  }
  get overrideDOMText() {
    if (this.length == 0)
      return V.empty;
    let t = this;
    for (; t.parent; )
      t = t.parent;
    let { view: e } = t, i = e && e.state.doc, s = this.posAtStart;
    return i ? i.slice(s, s + this.length) : V.empty;
  }
  domAtPos(t) {
    return (this.length ? t == 0 : this.side > 0) ? ct.before(this.dom) : ct.after(this.dom, t == this.length);
  }
  domBoundsAround() {
    return null;
  }
  coordsAt(t, e) {
    let i = this.widget.coordsAt(this.dom, t, e);
    if (i)
      return i;
    let s = this.dom.getClientRects(), r = null;
    if (!s.length)
      return null;
    let o = this.side ? this.side < 0 : t > 0;
    for (let l = o ? s.length - 1 : 0; r = s[l], !(t > 0 ? l == 0 : l == s.length - 1 || r.top < r.bottom); l += o ? -1 : 1)
      ;
    return Xn(r, !o);
  }
  get isEditable() {
    return !1;
  }
  get isWidget() {
    return !0;
  }
  get isHidden() {
    return this.widget.isHidden;
  }
  destroy() {
    super.destroy(), this.dom && this.widget.destroy(this.dom);
  }
}
class Je extends q {
  constructor(t) {
    super(), this.side = t;
  }
  get length() {
    return 0;
  }
  merge() {
    return !1;
  }
  become(t) {
    return t instanceof Je && t.side == this.side;
  }
  split() {
    return new Je(this.side);
  }
  sync() {
    if (!this.dom) {
      let t = document.createElement("img");
      t.className = "cm-widgetBuffer", t.setAttribute("aria-hidden", "true"), this.setDOM(t);
    }
  }
  getSide() {
    return this.side;
  }
  domAtPos(t) {
    return this.side > 0 ? ct.before(this.dom) : ct.after(this.dom);
  }
  localPosFromDOM() {
    return 0;
  }
  domBoundsAround() {
    return null;
  }
  coordsAt(t) {
    return this.dom.getBoundingClientRect();
  }
  get overrideDOMText() {
    return V.empty;
  }
  get isHidden() {
    return !0;
  }
}
re.prototype.children = fe.prototype.children = Je.prototype.children = Zn;
function Tl(n, t) {
  let e = n.dom, { children: i } = n, s = 0;
  for (let r = 0; s < i.length; s++) {
    let o = i[s], l = r + o.length;
    if (!(l == r && o.getSide() <= 0)) {
      if (t > r && t < l && o.dom.parentNode == e)
        return o.domAtPos(t - r);
      if (t <= r)
        break;
      r = l;
    }
  }
  for (let r = s; r > 0; r--) {
    let o = i[r - 1];
    if (o.dom.parentNode == e)
      return o.domAtPos(o.length);
  }
  for (let r = s; r < i.length; r++) {
    let o = i[r];
    if (o.dom.parentNode == e)
      return o.domAtPos(0);
  }
  return new ct(e, 0);
}
function Dl(n, t, e) {
  let i, { children: s } = n;
  e > 0 && t instanceof oe && s.length && (i = s[s.length - 1]) instanceof oe && i.mark.eq(t.mark) ? Dl(i, t.children[0], e - 1) : (s.push(t), t.setParent(n)), n.length += t.length;
}
function Pl(n, t, e) {
  let i = null, s = -1, r = null, o = -1;
  function l(a, c) {
    for (let f = 0, u = 0; f < a.children.length && u <= c; f++) {
      let d = a.children[f], p = u + d.length;
      p >= c && (d.children.length ? l(d, c - u) : (!r || r.isHidden && e > 0) && (p > c || u == p && d.getSide() > 0) ? (r = d, o = c - u) : (u < c || u == p && d.getSide() < 0 && !d.isHidden) && (i = d, s = c - u)), u = p;
    }
  }
  l(n, t);
  let h = (e < 0 ? i : r) || i || r;
  return h ? h.coordsAt(Math.max(0, h == i ? s : o), e) : ff(n);
}
function ff(n) {
  let t = n.dom.lastChild;
  if (!t)
    return n.dom.getBoundingClientRect();
  let e = bi(t);
  return e[e.length - 1] || null;
}
function xn(n, t) {
  for (let e in n)
    e == "class" && t.class ? t.class += " " + n.class : e == "style" && t.style ? t.style += ";" + n.style : t[e] = n[e];
  return t;
}
const Ir = /* @__PURE__ */ Object.create(null);
function tr(n, t, e) {
  if (n == t)
    return !0;
  n || (n = Ir), t || (t = Ir);
  let i = Object.keys(n), s = Object.keys(t);
  if (i.length - (e && i.indexOf(e) > -1 ? 1 : 0) != s.length - (e && s.indexOf(e) > -1 ? 1 : 0))
    return !1;
  for (let r of i)
    if (r != e && (s.indexOf(r) == -1 || n[r] !== t[r]))
      return !1;
  return !0;
}
function vn(n, t, e) {
  let i = !1;
  if (t)
    for (let s in t)
      e && s in e || (i = !0, s == "style" ? n.style.cssText = "" : n.removeAttribute(s));
  if (e)
    for (let s in e)
      t && t[s] == e[s] || (i = !0, s == "style" ? n.style.cssText = e[s] : n.setAttribute(s, e[s]));
  return i;
}
function uf(n) {
  let t = /* @__PURE__ */ Object.create(null);
  for (let e = 0; e < n.attributes.length; e++) {
    let i = n.attributes[e];
    t[i.name] = i.value;
  }
  return t;
}
class Z extends q {
  constructor() {
    super(...arguments), this.children = [], this.length = 0, this.prevAttrs = void 0, this.attrs = null, this.breakAfter = 0;
  }
  // Consumes source
  merge(t, e, i, s, r, o) {
    if (i) {
      if (!(i instanceof Z))
        return !1;
      this.dom || i.transferDOM(this);
    }
    return s && this.setDeco(i ? i.attrs : null), Al(this, t, e, i ? i.children : [], r, o), !0;
  }
  split(t) {
    let e = new Z();
    if (e.breakAfter = this.breakAfter, this.length == 0)
      return e;
    let { i, off: s } = this.childPos(t);
    s && (e.append(this.children[i].split(s), 0), this.children[i].merge(s, this.children[i].length, null, !1, 0, 0), i++);
    for (let r = i; r < this.children.length; r++)
      e.append(this.children[r], 0);
    for (; i > 0 && this.children[i - 1].length == 0; )
      this.children[--i].destroy();
    return this.children.length = i, this.markDirty(), this.length = t, e;
  }
  transferDOM(t) {
    this.dom && (this.markDirty(), t.setDOM(this.dom), t.prevAttrs = this.prevAttrs === void 0 ? this.attrs : this.prevAttrs, this.prevAttrs = void 0, this.dom = null);
  }
  setDeco(t) {
    tr(this.attrs, t) || (this.dom && (this.prevAttrs = this.attrs, this.markDirty()), this.attrs = t);
  }
  append(t, e) {
    Dl(this, t, e);
  }
  // Only called when building a line view in ContentBuilder
  addLineDeco(t) {
    let e = t.spec.attributes, i = t.spec.class;
    e && (this.attrs = xn(e, this.attrs || {})), i && (this.attrs = xn({ class: i }, this.attrs || {}));
  }
  domAtPos(t) {
    return Tl(this, t);
  }
  reuseDOM(t) {
    t.nodeName == "DIV" && (this.setDOM(t), this.flags |= 6);
  }
  sync(t, e) {
    var i;
    this.dom ? this.flags & 4 && (xl(this.dom), this.dom.className = "cm-line", this.prevAttrs = this.attrs ? null : void 0) : (this.setDOM(document.createElement("div")), this.dom.className = "cm-line", this.prevAttrs = this.attrs ? null : void 0), this.prevAttrs !== void 0 && (vn(this.dom, this.prevAttrs, this.attrs), this.dom.classList.add("cm-line"), this.prevAttrs = void 0), super.sync(t, e);
    let s = this.dom.lastChild;
    for (; s && q.get(s) instanceof oe; )
      s = s.lastChild;
    if (!s || !this.length || s.nodeName != "BR" && ((i = q.get(s)) === null || i === void 0 ? void 0 : i.isEditable) == !1 && (!C.ios || !this.children.some((r) => r instanceof re))) {
      let r = document.createElement("BR");
      r.cmIgnore = !0, this.dom.appendChild(r);
    }
  }
  measureTextSize() {
    if (this.children.length == 0 || this.length > 20)
      return null;
    let t = 0, e;
    for (let i of this.children) {
      if (!(i instanceof re) || /[^ -~]/.test(i.text))
        return null;
      let s = bi(i.dom);
      if (s.length != 1)
        return null;
      t += s[0].width, e = s[0].height;
    }
    return t ? {
      lineHeight: this.dom.getBoundingClientRect().height,
      charWidth: t / this.length,
      textHeight: e
    } : null;
  }
  coordsAt(t, e) {
    let i = Pl(this, t, e);
    if (!this.children.length && i && this.parent) {
      let { heightOracle: s } = this.parent.view.viewState, r = i.bottom - i.top;
      if (Math.abs(r - s.lineHeight) < 2 && s.textHeight < r) {
        let o = (r - s.textHeight) / 2;
        return { top: i.top + o, bottom: i.bottom - o, left: i.left, right: i.left };
      }
    }
    return i;
  }
  become(t) {
    return !1;
  }
  covers() {
    return !0;
  }
  static find(t, e) {
    for (let i = 0, s = 0; i < t.children.length; i++) {
      let r = t.children[i], o = s + r.length;
      if (o >= e) {
        if (r instanceof Z)
          return r;
        if (o > e)
          break;
      }
      s = o + r.breakAfter;
    }
    return null;
  }
}
class pe extends q {
  constructor(t, e, i) {
    super(), this.widget = t, this.length = e, this.deco = i, this.breakAfter = 0, this.prevWidget = null;
  }
  merge(t, e, i, s, r, o) {
    return i && (!(i instanceof pe) || !this.widget.compare(i.widget) || t > 0 && r <= 0 || e < this.length && o <= 0) ? !1 : (this.length = t + (i ? i.length : 0) + (this.length - e), !0);
  }
  domAtPos(t) {
    return t == 0 ? ct.before(this.dom) : ct.after(this.dom, t == this.length);
  }
  split(t) {
    let e = this.length - t;
    this.length = t;
    let i = new pe(this.widget, e, this.deco);
    return i.breakAfter = this.breakAfter, i;
  }
  get children() {
    return Zn;
  }
  sync(t) {
    (!this.dom || !this.widget.updateDOM(this.dom, t)) && (this.dom && this.prevWidget && this.prevWidget.destroy(this.dom), this.prevWidget = null, this.setDOM(this.widget.toDOM(t)), this.dom.contentEditable = "false");
  }
  get overrideDOMText() {
    return this.parent ? this.parent.view.state.doc.slice(this.posAtStart, this.posAtEnd) : V.empty;
  }
  domBoundsAround() {
    return null;
  }
  become(t) {
    return t instanceof pe && t.widget.constructor == this.widget.constructor ? (t.widget.compare(this.widget) || this.markDirty(!0), this.dom && !this.prevWidget && (this.prevWidget = this.widget), this.widget = t.widget, this.length = t.length, this.deco = t.deco, this.breakAfter = t.breakAfter, !0) : !1;
  }
  ignoreMutation() {
    return !0;
  }
  ignoreEvent(t) {
    return this.widget.ignoreEvent(t);
  }
  get isEditable() {
    return !1;
  }
  get isWidget() {
    return !0;
  }
  coordsAt(t, e) {
    return this.widget.coordsAt(this.dom, t, e);
  }
  destroy() {
    super.destroy(), this.dom && this.widget.destroy(this.dom);
  }
  covers(t) {
    let { startSide: e, endSide: i } = this.deco;
    return e == i ? !1 : t < 0 ? e < 0 : i > 0;
  }
}
class Se {
  /**
  Compare this instance to another instance of the same type.
  (TypeScript can't express this, but only instances of the same
  specific class will be passed to this method.) This is used to
  avoid redrawing widgets when they are replaced by a new
  decoration of the same type. The default implementation just
  returns `false`, which will cause new instances of the widget to
  always be redrawn.
  */
  eq(t) {
    return !1;
  }
  /**
  Update a DOM element created by a widget of the same type (but
  different, non-`eq` content) to reflect this widget. May return
  true to indicate that it could update, false to indicate it
  couldn't (in which case the widget will be redrawn). The default
  implementation just returns false.
  */
  updateDOM(t, e) {
    return !1;
  }
  /**
  @internal
  */
  compare(t) {
    return this == t || this.constructor == t.constructor && this.eq(t);
  }
  /**
  The estimated height this widget will have, to be used when
  estimating the height of content that hasn't been drawn. May
  return -1 to indicate you don't know. The default implementation
  returns -1.
  */
  get estimatedHeight() {
    return -1;
  }
  /**
  For inline widgets that are displayed inline (as opposed to
  `inline-block`) and introduce line breaks (through `<br>` tags
  or textual newlines), this must indicate the amount of line
  breaks they introduce. Defaults to 0.
  */
  get lineBreaks() {
    return 0;
  }
  /**
  Can be used to configure which kinds of events inside the widget
  should be ignored by the editor. The default is to ignore all
  events.
  */
  ignoreEvent(t) {
    return !0;
  }
  /**
  Override the way screen coordinates for positions at/in the
  widget are found. `pos` will be the offset into the widget, and
  `side` the side of the position that is being queried—less than
  zero for before, greater than zero for after, and zero for
  directly at that position.
  */
  coordsAt(t, e, i) {
    return null;
  }
  /**
  @internal
  */
  get isHidden() {
    return !1;
  }
  /**
  This is called when the an instance of the widget is removed
  from the editor view.
  */
  destroy(t) {
  }
}
var Lt = /* @__PURE__ */ function(n) {
  return n[n.Text = 0] = "Text", n[n.WidgetBefore = 1] = "WidgetBefore", n[n.WidgetAfter = 2] = "WidgetAfter", n[n.WidgetRange = 3] = "WidgetRange", n;
}(Lt || (Lt = {}));
class N extends Qe {
  constructor(t, e, i, s) {
    super(), this.startSide = t, this.endSide = e, this.widget = i, this.spec = s;
  }
  /**
  @internal
  */
  get heightRelevant() {
    return !1;
  }
  /**
  Create a mark decoration, which influences the styling of the
  content in its range. Nested mark decorations will cause nested
  DOM elements to be created. Nesting order is determined by
  precedence of the [facet](https://codemirror.net/6/docs/ref/#view.EditorView^decorations), with
  the higher-precedence decorations creating the inner DOM nodes.
  Such elements are split on line boundaries and on the boundaries
  of lower-precedence decorations.
  */
  static mark(t) {
    return new Mi(t);
  }
  /**
  Create a widget decoration, which displays a DOM element at the
  given position.
  */
  static widget(t) {
    let e = Math.max(-1e4, Math.min(1e4, t.side || 0)), i = !!t.block;
    return e += i && !t.inlineOrder ? e > 0 ? 3e8 : -4e8 : e > 0 ? 1e8 : -1e8, new be(t, e, e, i, t.widget || null, !1);
  }
  /**
  Create a replace decoration which replaces the given range with
  a widget, or simply hides it.
  */
  static replace(t) {
    let e = !!t.block, i, s;
    if (t.isBlockGap)
      i = -5e8, s = 4e8;
    else {
      let { start: r, end: o } = Bl(t, e);
      i = (r ? e ? -3e8 : -1 : 5e8) - 1, s = (o ? e ? 2e8 : 1 : -6e8) + 1;
    }
    return new be(t, i, s, e, t.widget || null, !0);
  }
  /**
  Create a line decoration, which can add DOM attributes to the
  line starting at the given position.
  */
  static line(t) {
    return new Ti(t);
  }
  /**
  Build a [`DecorationSet`](https://codemirror.net/6/docs/ref/#view.DecorationSet) from the given
  decorated range or ranges. If the ranges aren't already sorted,
  pass `true` for `sort` to make the library sort them for you.
  */
  static set(t, e = !1) {
    return F.of(t, e);
  }
  /**
  @internal
  */
  hasHeight() {
    return this.widget ? this.widget.estimatedHeight > -1 : !1;
  }
}
N.none = F.empty;
class Mi extends N {
  constructor(t) {
    let { start: e, end: i } = Bl(t);
    super(e ? -1 : 5e8, i ? 1 : -6e8, null, t), this.tagName = t.tagName || "span", this.class = t.class || "", this.attrs = t.attributes || null;
  }
  eq(t) {
    var e, i;
    return this == t || t instanceof Mi && this.tagName == t.tagName && (this.class || ((e = this.attrs) === null || e === void 0 ? void 0 : e.class)) == (t.class || ((i = t.attrs) === null || i === void 0 ? void 0 : i.class)) && tr(this.attrs, t.attrs, "class");
  }
  range(t, e = t) {
    if (t >= e)
      throw new RangeError("Mark decorations may not be empty");
    return super.range(t, e);
  }
}
Mi.prototype.point = !1;
class Ti extends N {
  constructor(t) {
    super(-2e8, -2e8, null, t);
  }
  eq(t) {
    return t instanceof Ti && this.spec.class == t.spec.class && tr(this.spec.attributes, t.spec.attributes);
  }
  range(t, e = t) {
    if (e != t)
      throw new RangeError("Line decoration ranges must be zero-length");
    return super.range(t, e);
  }
}
Ti.prototype.mapMode = mt.TrackBefore;
Ti.prototype.point = !0;
class be extends N {
  constructor(t, e, i, s, r, o) {
    super(e, i, r, t), this.block = s, this.isReplace = o, this.mapMode = s ? e <= 0 ? mt.TrackBefore : mt.TrackAfter : mt.TrackDel;
  }
  // Only relevant when this.block == true
  get type() {
    return this.startSide != this.endSide ? Lt.WidgetRange : this.startSide <= 0 ? Lt.WidgetBefore : Lt.WidgetAfter;
  }
  get heightRelevant() {
    return this.block || !!this.widget && (this.widget.estimatedHeight >= 5 || this.widget.lineBreaks > 0);
  }
  eq(t) {
    return t instanceof be && df(this.widget, t.widget) && this.block == t.block && this.startSide == t.startSide && this.endSide == t.endSide;
  }
  range(t, e = t) {
    if (this.isReplace && (t > e || t == e && this.startSide > 0 && this.endSide <= 0))
      throw new RangeError("Invalid range for replacement decoration");
    if (!this.isReplace && e != t)
      throw new RangeError("Widget decorations can only have zero-length ranges");
    return super.range(t, e);
  }
}
be.prototype.point = !0;
function Bl(n, t = !1) {
  let { inclusiveStart: e, inclusiveEnd: i } = n;
  return e == null && (e = n.inclusive), i == null && (i = n.inclusive), { start: e ?? t, end: i ?? t };
}
function df(n, t) {
  return n == t || !!(n && t && n.compare(t));
}
function Sn(n, t, e, i = 0) {
  let s = e.length - 1;
  s >= 0 && e[s] + i >= n ? e[s] = Math.max(e[s], t) : e.push(n, t);
}
class gi {
  constructor(t, e, i, s) {
    this.doc = t, this.pos = e, this.end = i, this.disallowBlockEffectsFor = s, this.content = [], this.curLine = null, this.breakAtStart = 0, this.pendingBuffer = 0, this.bufferMarks = [], this.atCursorPos = !0, this.openStart = -1, this.openEnd = -1, this.text = "", this.textOff = 0, this.cursor = t.iter(), this.skip = e;
  }
  posCovered() {
    if (this.content.length == 0)
      return !this.breakAtStart && this.doc.lineAt(this.pos).from != this.pos;
    let t = this.content[this.content.length - 1];
    return !(t.breakAfter || t instanceof pe && t.deco.endSide < 0);
  }
  getLine() {
    return this.curLine || (this.content.push(this.curLine = new Z()), this.atCursorPos = !0), this.curLine;
  }
  flushBuffer(t = this.bufferMarks) {
    this.pendingBuffer && (this.curLine.append(Ni(new Je(-1), t), t.length), this.pendingBuffer = 0);
  }
  addBlockWidget(t) {
    this.flushBuffer(), this.curLine = null, this.content.push(t);
  }
  finish(t) {
    this.pendingBuffer && t <= this.bufferMarks.length ? this.flushBuffer() : this.pendingBuffer = 0, !this.posCovered() && !(t && this.content.length && this.content[this.content.length - 1] instanceof pe) && this.getLine();
  }
  buildText(t, e, i) {
    for (; t > 0; ) {
      if (this.textOff == this.text.length) {
        let { value: r, lineBreak: o, done: l } = this.cursor.next(this.skip);
        if (this.skip = 0, l)
          throw new Error("Ran out of text content when drawing inline views");
        if (o) {
          this.posCovered() || this.getLine(), this.content.length ? this.content[this.content.length - 1].breakAfter = 1 : this.breakAtStart = 1, this.flushBuffer(), this.curLine = null, this.atCursorPos = !0, t--;
          continue;
        } else
          this.text = r, this.textOff = 0;
      }
      let s = Math.min(
        this.text.length - this.textOff,
        t,
        512
        /* T.Chunk */
      );
      this.flushBuffer(e.slice(e.length - i)), this.getLine().append(Ni(new re(this.text.slice(this.textOff, this.textOff + s)), e), i), this.atCursorPos = !0, this.textOff += s, t -= s, i = 0;
    }
  }
  span(t, e, i, s) {
    this.buildText(e - t, i, s), this.pos = e, this.openStart < 0 && (this.openStart = s);
  }
  point(t, e, i, s, r, o) {
    if (this.disallowBlockEffectsFor[o] && i instanceof be) {
      if (i.block)
        throw new RangeError("Block decorations may not be specified via plugins");
      if (e > this.doc.lineAt(this.pos).to)
        throw new RangeError("Decorations that replace line breaks may not be specified via plugins");
    }
    let l = e - t;
    if (i instanceof be)
      if (i.block)
        i.startSide > 0 && !this.posCovered() && this.getLine(), this.addBlockWidget(new pe(i.widget || new Vr("div"), l, i));
      else {
        let h = fe.create(i.widget || new Vr("span"), l, l ? 0 : i.startSide), a = this.atCursorPos && !h.isEditable && r <= s.length && (t < e || i.startSide > 0), c = !h.isEditable && (t < e || r > s.length || i.startSide <= 0), f = this.getLine();
        this.pendingBuffer == 2 && !a && !h.isEditable && (this.pendingBuffer = 0), this.flushBuffer(s), a && (f.append(Ni(new Je(1), s), r), r = s.length + Math.max(0, r - s.length)), f.append(Ni(h, s), r), this.atCursorPos = c, this.pendingBuffer = c ? t < e || r > s.length ? 1 : 2 : 0, this.pendingBuffer && (this.bufferMarks = s.slice());
      }
    else
      this.doc.lineAt(this.pos).from == this.pos && this.getLine().addLineDeco(i);
    l && (this.textOff + l <= this.text.length ? this.textOff += l : (this.skip += l - (this.text.length - this.textOff), this.text = "", this.textOff = 0), this.pos = e), this.openStart < 0 && (this.openStart = r);
  }
  static build(t, e, i, s, r) {
    let o = new gi(t, e, i, r);
    return o.openEnd = F.spans(s, e, i, o), o.openStart < 0 && (o.openStart = o.openEnd), o.finish(o.openEnd), o;
  }
}
function Ni(n, t) {
  for (let e of t)
    n = new oe(e, [n], n.length);
  return n;
}
class Vr extends Se {
  constructor(t) {
    super(), this.tag = t;
  }
  eq(t) {
    return t.tag == this.tag;
  }
  toDOM() {
    return document.createElement(this.tag);
  }
  updateDOM(t) {
    return t.nodeName.toLowerCase() == this.tag;
  }
  get isHidden() {
    return !0;
  }
}
const Rl = /* @__PURE__ */ O.define(), Ll = /* @__PURE__ */ O.define(), El = /* @__PURE__ */ O.define(), Nl = /* @__PURE__ */ O.define(), Cn = /* @__PURE__ */ O.define(), Il = /* @__PURE__ */ O.define(), Vl = /* @__PURE__ */ O.define(), Hl = /* @__PURE__ */ O.define({
  combine: (n) => n.some((t) => t)
}), pf = /* @__PURE__ */ O.define({
  combine: (n) => n.some((t) => t)
});
class qe {
  constructor(t, e = "nearest", i = "nearest", s = 5, r = 5, o = !1) {
    this.range = t, this.y = e, this.x = i, this.yMargin = s, this.xMargin = r, this.isSnapshot = o;
  }
  map(t) {
    return t.empty ? this : new qe(this.range.map(t), this.y, this.x, this.yMargin, this.xMargin, this.isSnapshot);
  }
  clip(t) {
    return this.range.to <= t.doc.length ? this : new qe(b.cursor(t.doc.length), this.y, this.x, this.yMargin, this.xMargin, this.isSnapshot);
  }
}
const Ii = /* @__PURE__ */ z.define({ map: (n, t) => n.map(t) });
function ie(n, t, e) {
  let i = n.facet(Nl);
  i.length ? i[0](t) : window.onerror ? window.onerror(String(t), e, void 0, void 0, t) : e ? console.error(e + ":", t) : console.error(t);
}
const Bs = /* @__PURE__ */ O.define({ combine: (n) => n.length ? n[0] : !0 });
let gf = 0;
const hi = /* @__PURE__ */ O.define();
class yt {
  constructor(t, e, i, s, r) {
    this.id = t, this.create = e, this.domEventHandlers = i, this.domEventObservers = s, this.extension = r(this);
  }
  /**
  Define a plugin from a constructor function that creates the
  plugin's value, given an editor view.
  */
  static define(t, e) {
    const { eventHandlers: i, eventObservers: s, provide: r, decorations: o } = e || {};
    return new yt(gf++, t, i, s, (l) => {
      let h = [hi.of(l)];
      return o && h.push(xi.of((a) => {
        let c = a.plugin(l);
        return c ? o(c) : N.none;
      })), r && h.push(r(l)), h;
    });
  }
  /**
  Create a plugin for a class whose constructor takes a single
  editor view as argument.
  */
  static fromClass(t, e) {
    return yt.define((i) => new t(i), e);
  }
}
class _s {
  constructor(t) {
    this.spec = t, this.mustUpdate = null, this.value = null;
  }
  update(t) {
    if (this.value) {
      if (this.mustUpdate) {
        let e = this.mustUpdate;
        if (this.mustUpdate = null, this.value.update)
          try {
            this.value.update(e);
          } catch (i) {
            if (ie(e.state, i, "CodeMirror plugin crashed"), this.value.destroy)
              try {
                this.value.destroy();
              } catch {
              }
            this.deactivate();
          }
      }
    } else if (this.spec)
      try {
        this.value = this.spec.create(t);
      } catch (e) {
        ie(t.state, e, "CodeMirror plugin crashed"), this.deactivate();
      }
    return this;
  }
  destroy(t) {
    var e;
    if (!((e = this.value) === null || e === void 0) && e.destroy)
      try {
        this.value.destroy();
      } catch (i) {
        ie(t.state, i, "CodeMirror plugin crashed");
      }
  }
  deactivate() {
    this.spec = this.value = null;
  }
}
const $l = /* @__PURE__ */ O.define(), er = /* @__PURE__ */ O.define(), xi = /* @__PURE__ */ O.define(), ir = /* @__PURE__ */ O.define(), Fl = /* @__PURE__ */ O.define();
function Hr(n, t, e) {
  let i = n.state.facet(Fl);
  if (!i.length)
    return i;
  let s = i.map((o) => o instanceof Function ? o(n) : o), r = [];
  return F.spans(s, t, e, {
    point() {
    },
    span(o, l, h, a) {
      let c = r;
      for (let f = h.length - 1; f >= 0; f--, a--) {
        let u = h[f].spec.bidiIsolate, d;
        if (u != null)
          if (a > 0 && c.length && (d = c[c.length - 1]).to == o && d.direction == u)
            d.to = l, c = d.inner;
          else {
            let p = { from: o, to: l, direction: u, inner: [] };
            c.push(p), c = p.inner;
          }
      }
    }
  }), r;
}
const _l = /* @__PURE__ */ O.define();
function zl(n) {
  let t = 0, e = 0, i = 0, s = 0;
  for (let r of n.state.facet(_l)) {
    let o = r(n);
    o && (o.left != null && (t = Math.max(t, o.left)), o.right != null && (e = Math.max(e, o.right)), o.top != null && (i = Math.max(i, o.top)), o.bottom != null && (s = Math.max(s, o.bottom)));
  }
  return { left: t, right: e, top: i, bottom: s };
}
const ai = /* @__PURE__ */ O.define();
class Mt {
  constructor(t, e, i, s) {
    this.fromA = t, this.toA = e, this.fromB = i, this.toB = s;
  }
  join(t) {
    return new Mt(Math.min(this.fromA, t.fromA), Math.max(this.toA, t.toA), Math.min(this.fromB, t.fromB), Math.max(this.toB, t.toB));
  }
  addToSet(t) {
    let e = t.length, i = this;
    for (; e > 0; e--) {
      let s = t[e - 1];
      if (!(s.fromA > i.toA)) {
        if (s.toA < i.fromA)
          break;
        i = i.join(s), t.splice(e - 1, 1);
      }
    }
    return t.splice(e, 0, i), t;
  }
  static extendWithRanges(t, e) {
    if (e.length == 0)
      return t;
    let i = [];
    for (let s = 0, r = 0, o = 0, l = 0; ; s++) {
      let h = s == t.length ? null : t[s], a = o - l, c = h ? h.fromB : 1e9;
      for (; r < e.length && e[r] < c; ) {
        let f = e[r], u = e[r + 1], d = Math.max(l, f), p = Math.min(c, u);
        if (d <= p && new Mt(d + a, p + a, d, p).addToSet(i), u > c)
          break;
        r += 2;
      }
      if (!h)
        return i;
      new Mt(h.fromA, h.toA, h.fromB, h.toB).addToSet(i), o = h.toA, l = h.toB;
    }
  }
}
class ps {
  constructor(t, e, i) {
    this.view = t, this.state = e, this.transactions = i, this.flags = 0, this.startState = t.state, this.changes = it.empty(this.startState.doc.length);
    for (let r of i)
      this.changes = this.changes.compose(r.changes);
    let s = [];
    this.changes.iterChangedRanges((r, o, l, h) => s.push(new Mt(r, o, l, h))), this.changedRanges = s;
  }
  /**
  @internal
  */
  static create(t, e, i) {
    return new ps(t, e, i);
  }
  /**
  Tells you whether the [viewport](https://codemirror.net/6/docs/ref/#view.EditorView.viewport) or
  [visible ranges](https://codemirror.net/6/docs/ref/#view.EditorView.visibleRanges) changed in this
  update.
  */
  get viewportChanged() {
    return (this.flags & 4) > 0;
  }
  /**
  Indicates whether the height of a block element in the editor
  changed in this update.
  */
  get heightChanged() {
    return (this.flags & 2) > 0;
  }
  /**
  Returns true when the document was modified or the size of the
  editor, or elements within the editor, changed.
  */
  get geometryChanged() {
    return this.docChanged || (this.flags & 10) > 0;
  }
  /**
  True when this update indicates a focus change.
  */
  get focusChanged() {
    return (this.flags & 1) > 0;
  }
  /**
  Whether the document changed in this update.
  */
  get docChanged() {
    return !this.changes.empty;
  }
  /**
  Whether the selection was explicitly set in this update.
  */
  get selectionSet() {
    return this.transactions.some((t) => t.selection);
  }
  /**
  @internal
  */
  get empty() {
    return this.flags == 0 && this.transactions.length == 0;
  }
}
var tt = /* @__PURE__ */ function(n) {
  return n[n.LTR = 0] = "LTR", n[n.RTL = 1] = "RTL", n;
}(tt || (tt = {}));
const vi = tt.LTR, Wl = tt.RTL;
function jl(n) {
  let t = [];
  for (let e = 0; e < n.length; e++)
    t.push(1 << +n[e]);
  return t;
}
const mf = /* @__PURE__ */ jl("88888888888888888888888888888888888666888888787833333333337888888000000000000000000000000008888880000000000000000000000000088888888888888888888888888888888888887866668888088888663380888308888800000000000000000000000800000000000000000000000000000008"), wf = /* @__PURE__ */ jl("4444448826627288999999999992222222222222222222222222222222222222222222222229999999999999999999994444444444644222822222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222999999949999999229989999223333333333"), An = /* @__PURE__ */ Object.create(null), _t = [];
for (let n of ["()", "[]", "{}"]) {
  let t = /* @__PURE__ */ n.charCodeAt(0), e = /* @__PURE__ */ n.charCodeAt(1);
  An[t] = e, An[e] = -t;
}
function yf(n) {
  return n <= 247 ? mf[n] : 1424 <= n && n <= 1524 ? 2 : 1536 <= n && n <= 1785 ? wf[n - 1536] : 1774 <= n && n <= 2220 ? 4 : 8192 <= n && n <= 8203 ? 256 : 64336 <= n && n <= 65023 ? 4 : n == 8204 ? 256 : 1;
}
const bf = /[\u0590-\u05f4\u0600-\u06ff\u0700-\u08ac\ufb50-\ufdff]/;
class ue {
  /**
  The direction of this span.
  */
  get dir() {
    return this.level % 2 ? Wl : vi;
  }
  /**
  @internal
  */
  constructor(t, e, i) {
    this.from = t, this.to = e, this.level = i;
  }
  /**
  @internal
  */
  side(t, e) {
    return this.dir == e == t ? this.to : this.from;
  }
  /**
  @internal
  */
  static find(t, e, i, s) {
    let r = -1;
    for (let o = 0; o < t.length; o++) {
      let l = t[o];
      if (l.from <= e && l.to >= e) {
        if (l.level == i)
          return o;
        (r < 0 || (s != 0 ? s < 0 ? l.from < e : l.to > e : t[r].level > l.level)) && (r = o);
      }
    }
    if (r < 0)
      throw new RangeError("Index out of range");
    return r;
  }
}
function Kl(n, t) {
  if (n.length != t.length)
    return !1;
  for (let e = 0; e < n.length; e++) {
    let i = n[e], s = t[e];
    if (i.from != s.from || i.to != s.to || i.direction != s.direction || !Kl(i.inner, s.inner))
      return !1;
  }
  return !0;
}
const _ = [];
function kf(n, t, e, i, s) {
  for (let r = 0; r <= i.length; r++) {
    let o = r ? i[r - 1].to : t, l = r < i.length ? i[r].from : e, h = r ? 256 : s;
    for (let a = o, c = h, f = h; a < l; a++) {
      let u = yf(n.charCodeAt(a));
      u == 512 ? u = c : u == 8 && f == 4 && (u = 16), _[a] = u == 4 ? 2 : u, u & 7 && (f = u), c = u;
    }
    for (let a = o, c = h, f = h; a < l; a++) {
      let u = _[a];
      if (u == 128)
        a < l - 1 && c == _[a + 1] && c & 24 ? u = _[a] = c : _[a] = 256;
      else if (u == 64) {
        let d = a + 1;
        for (; d < l && _[d] == 64; )
          d++;
        let p = a && c == 8 || d < e && _[d] == 8 ? f == 1 ? 1 : 8 : 256;
        for (let m = a; m < d; m++)
          _[m] = p;
        a = d - 1;
      } else
        u == 8 && f == 1 && (_[a] = 1);
      c = u, u & 7 && (f = u);
    }
  }
}
function xf(n, t, e, i, s) {
  let r = s == 1 ? 2 : 1;
  for (let o = 0, l = 0, h = 0; o <= i.length; o++) {
    let a = o ? i[o - 1].to : t, c = o < i.length ? i[o].from : e;
    for (let f = a, u, d, p; f < c; f++)
      if (d = An[u = n.charCodeAt(f)])
        if (d < 0) {
          for (let m = l - 3; m >= 0; m -= 3)
            if (_t[m + 1] == -d) {
              let g = _t[m + 2], y = g & 2 ? s : g & 4 ? g & 1 ? r : s : 0;
              y && (_[f] = _[_t[m]] = y), l = m;
              break;
            }
        } else {
          if (_t.length == 189)
            break;
          _t[l++] = f, _t[l++] = u, _t[l++] = h;
        }
      else if ((p = _[f]) == 2 || p == 1) {
        let m = p == s;
        h = m ? 0 : 1;
        for (let g = l - 3; g >= 0; g -= 3) {
          let y = _t[g + 2];
          if (y & 2)
            break;
          if (m)
            _t[g + 2] |= 2;
          else {
            if (y & 4)
              break;
            _t[g + 2] |= 4;
          }
        }
      }
  }
}
function vf(n, t, e, i) {
  for (let s = 0, r = i; s <= e.length; s++) {
    let o = s ? e[s - 1].to : n, l = s < e.length ? e[s].from : t;
    for (let h = o; h < l; ) {
      let a = _[h];
      if (a == 256) {
        let c = h + 1;
        for (; ; )
          if (c == l) {
            if (s == e.length)
              break;
            c = e[s++].to, l = s < e.length ? e[s].from : t;
          } else if (_[c] == 256)
            c++;
          else
            break;
        let f = r == 1, u = (c < t ? _[c] : i) == 1, d = f == u ? f ? 1 : 2 : i;
        for (let p = c, m = s, g = m ? e[m - 1].to : n; p > h; )
          p == g && (p = e[--m].from, g = m ? e[m - 1].to : n), _[--p] = d;
        h = c;
      } else
        r = a, h++;
    }
  }
}
function On(n, t, e, i, s, r, o) {
  let l = i % 2 ? 2 : 1;
  if (i % 2 == s % 2)
    for (let h = t, a = 0; h < e; ) {
      let c = !0, f = !1;
      if (a == r.length || h < r[a].from) {
        let m = _[h];
        m != l && (c = !1, f = m == 16);
      }
      let u = !c && l == 1 ? [] : null, d = c ? i : i + 1, p = h;
      t:
        for (; ; )
          if (a < r.length && p == r[a].from) {
            if (f)
              break t;
            let m = r[a];
            if (!c)
              for (let g = m.to, y = a + 1; ; ) {
                if (g == e)
                  break t;
                if (y < r.length && r[y].from == g)
                  g = r[y++].to;
                else {
                  if (_[g] == l)
                    break t;
                  break;
                }
              }
            if (a++, u)
              u.push(m);
            else {
              m.from > h && o.push(new ue(h, m.from, d));
              let g = m.direction == vi != !(d % 2);
              Mn(n, g ? i + 1 : i, s, m.inner, m.from, m.to, o), h = m.to;
            }
            p = m.to;
          } else {
            if (p == e || (c ? _[p] != l : _[p] == l))
              break;
            p++;
          }
      u ? On(n, h, p, i + 1, s, u, o) : h < p && o.push(new ue(h, p, d)), h = p;
    }
  else
    for (let h = e, a = r.length; h > t; ) {
      let c = !0, f = !1;
      if (!a || h > r[a - 1].to) {
        let m = _[h - 1];
        m != l && (c = !1, f = m == 16);
      }
      let u = !c && l == 1 ? [] : null, d = c ? i : i + 1, p = h;
      t:
        for (; ; )
          if (a && p == r[a - 1].to) {
            if (f)
              break t;
            let m = r[--a];
            if (!c)
              for (let g = m.from, y = a; ; ) {
                if (g == t)
                  break t;
                if (y && r[y - 1].to == g)
                  g = r[--y].from;
                else {
                  if (_[g - 1] == l)
                    break t;
                  break;
                }
              }
            if (u)
              u.push(m);
            else {
              m.to < h && o.push(new ue(m.to, h, d));
              let g = m.direction == vi != !(d % 2);
              Mn(n, g ? i + 1 : i, s, m.inner, m.from, m.to, o), h = m.from;
            }
            p = m.from;
          } else {
            if (p == t || (c ? _[p - 1] != l : _[p - 1] == l))
              break;
            p--;
          }
      u ? On(n, p, h, i + 1, s, u, o) : p < h && o.push(new ue(p, h, d)), h = p;
    }
}
function Mn(n, t, e, i, s, r, o) {
  let l = t % 2 ? 2 : 1;
  kf(n, s, r, i, l), xf(n, s, r, i, l), vf(s, r, i, l), On(n, s, r, t, e, i, o);
}
function Sf(n, t, e) {
  if (!n)
    return [new ue(0, 0, t == Wl ? 1 : 0)];
  if (t == vi && !e.length && !bf.test(n))
    return ql(n.length);
  if (e.length)
    for (; n.length > _.length; )
      _[_.length] = 256;
  let i = [], s = t == vi ? 0 : 1;
  return Mn(n, s, s, e, 0, n.length, i), i;
}
function ql(n) {
  return [new ue(0, n, 0)];
}
let Gl = "";
function Cf(n, t, e, i, s) {
  var r;
  let o = i.head - n.from, l = -1;
  if (o == 0) {
    if (!s || !n.length)
      return null;
    t[0].level != e && (o = t[0].side(!1, e), l = 0);
  } else if (o == n.length) {
    if (s)
      return null;
    let u = t[t.length - 1];
    u.level != e && (o = u.side(!0, e), l = t.length - 1);
  }
  l < 0 && (l = ue.find(t, o, (r = i.bidiLevel) !== null && r !== void 0 ? r : -1, i.assoc));
  let h = t[l];
  o == h.side(s, e) && (h = t[l += s ? 1 : -1], o = h.side(!s, e));
  let a = s == (h.dir == e), c = wt(n.text, o, a);
  if (Gl = n.text.slice(Math.min(o, c), Math.max(o, c)), c != h.side(s, e))
    return b.cursor(c + n.from, a ? -1 : 1, h.level);
  let f = l == (s ? t.length - 1 : 0) ? null : t[l + (s ? 1 : -1)];
  return !f && h.level != e ? b.cursor(s ? n.to : n.from, s ? -1 : 1, e) : f && f.level < h.level ? b.cursor(f.side(!s, e) + n.from, s ? 1 : -1, f.level) : b.cursor(c + n.from, s ? -1 : 1, h.level);
}
class $r extends q {
  get length() {
    return this.view.state.doc.length;
  }
  constructor(t) {
    super(), this.view = t, this.decorations = [], this.dynamicDecorationMap = [], this.domChanged = null, this.hasComposition = null, this.markedForComposition = /* @__PURE__ */ new Set(), this.minWidth = 0, this.minWidthFrom = 0, this.minWidthTo = 0, this.impreciseAnchor = null, this.impreciseHead = null, this.forceSelection = !1, this.lastUpdate = Date.now(), this.setDOM(t.contentDOM), this.children = [new Z()], this.children[0].setParent(this), this.updateDeco(), this.updateInner([new Mt(0, 0, 0, t.state.doc.length)], 0, null);
  }
  // Update the document view to a given state.
  update(t) {
    var e;
    let i = t.changedRanges;
    this.minWidth > 0 && i.length && (i.every(({ fromA: a, toA: c }) => c < this.minWidthFrom || a > this.minWidthTo) ? (this.minWidthFrom = t.changes.mapPos(this.minWidthFrom, 1), this.minWidthTo = t.changes.mapPos(this.minWidthTo, 1)) : this.minWidth = this.minWidthFrom = this.minWidthTo = 0);
    let s = -1;
    this.view.inputState.composing >= 0 && (!((e = this.domChanged) === null || e === void 0) && e.newSel ? s = this.domChanged.newSel.head : !Bf(t.changes, this.hasComposition) && !t.selectionSet && (s = t.state.selection.main.head));
    let r = s > -1 ? Of(this.view, t.changes, s) : null;
    if (this.domChanged = null, this.hasComposition) {
      this.markedForComposition.clear();
      let { from: a, to: c } = this.hasComposition;
      i = new Mt(a, c, t.changes.mapPos(a, -1), t.changes.mapPos(c, 1)).addToSet(i.slice());
    }
    this.hasComposition = r ? { from: r.range.fromB, to: r.range.toB } : null, (C.ie || C.chrome) && !r && t && t.state.doc.lines != t.startState.doc.lines && (this.forceSelection = !0);
    let o = this.decorations, l = this.updateDeco(), h = Df(o, l, t.changes);
    return i = Mt.extendWithRanges(i, h), !(this.flags & 7) && i.length == 0 ? !1 : (this.updateInner(i, t.startState.doc.length, r), t.transactions.length && (this.lastUpdate = Date.now()), !0);
  }
  // Used by update and the constructor do perform the actual DOM
  // update
  updateInner(t, e, i) {
    this.view.viewState.mustMeasureContent = !0, this.updateChildren(t, e, i);
    let { observer: s } = this.view;
    s.ignore(() => {
      this.dom.style.height = this.view.viewState.contentHeight / this.view.scaleY + "px", this.dom.style.flexBasis = this.minWidth ? this.minWidth + "px" : "";
      let o = C.chrome || C.ios ? { node: s.selectionRange.focusNode, written: !1 } : void 0;
      this.sync(this.view, o), this.flags &= -8, o && (o.written || s.selectionRange.focusNode != o.node) && (this.forceSelection = !0), this.dom.style.height = "";
    }), this.markedForComposition.forEach(
      (o) => o.flags &= -9
      /* ViewFlag.Composition */
    );
    let r = [];
    if (this.view.viewport.from || this.view.viewport.to < this.view.state.doc.length)
      for (let o of this.children)
        o instanceof pe && o.widget instanceof Fr && r.push(o.dom);
    s.updateGaps(r);
  }
  updateChildren(t, e, i) {
    let s = i ? i.range.addToSet(t.slice()) : t, r = this.childCursor(e);
    for (let o = s.length - 1; ; o--) {
      let l = o >= 0 ? s[o] : null;
      if (!l)
        break;
      let { fromA: h, toA: a, fromB: c, toB: f } = l, u, d, p, m;
      if (i && i.range.fromB < f && i.range.toB > c) {
        let v = gi.build(this.view.state.doc, c, i.range.fromB, this.decorations, this.dynamicDecorationMap), A = gi.build(this.view.state.doc, i.range.toB, f, this.decorations, this.dynamicDecorationMap);
        d = v.breakAtStart, p = v.openStart, m = A.openEnd;
        let P = this.compositionView(i);
        A.breakAtStart ? P.breakAfter = 1 : A.content.length && P.merge(P.length, P.length, A.content[0], !1, A.openStart, 0) && (P.breakAfter = A.content[0].breakAfter, A.content.shift()), v.content.length && P.merge(0, 0, v.content[v.content.length - 1], !0, 0, v.openEnd) && v.content.pop(), u = v.content.concat(P).concat(A.content);
      } else
        ({ content: u, breakAtStart: d, openStart: p, openEnd: m } = gi.build(this.view.state.doc, c, f, this.decorations, this.dynamicDecorationMap));
      let { i: g, off: y } = r.findPos(a, 1), { i: x, off: S } = r.findPos(h, -1);
      Cl(this, x, S, g, y, u, d, p, m);
    }
    i && this.fixCompositionDOM(i);
  }
  compositionView(t) {
    let e = new re(t.text.nodeValue);
    e.flags |= 8;
    for (let { deco: s } of t.marks)
      e = new oe(s, [e], e.length);
    let i = new Z();
    return i.append(e, 0), i;
  }
  fixCompositionDOM(t) {
    let e = (r, o) => {
      o.flags |= 8 | (o.children.some(
        (h) => h.flags & 7
        /* ViewFlag.Dirty */
      ) ? 1 : 0), this.markedForComposition.add(o);
      let l = q.get(r);
      l && l != o && (l.dom = null), o.setDOM(r);
    }, i = this.childPos(t.range.fromB, 1), s = this.children[i.i];
    e(t.line, s);
    for (let r = t.marks.length - 1; r >= -1; r--)
      i = s.childPos(i.off, 1), s = s.children[i.i], e(r >= 0 ? t.marks[r].node : t.text, s);
  }
  // Sync the DOM selection to this.state.selection
  updateSelection(t = !1, e = !1) {
    (t || !this.view.observer.selectionRange.focusNode) && this.view.observer.readSelectionRange();
    let i = this.view.root.activeElement, s = i == this.dom, r = !s && ts(this.dom, this.view.observer.selectionRange) && !(i && this.dom.contains(i));
    if (!(s || e || r))
      return;
    let o = this.forceSelection;
    this.forceSelection = !1;
    let l = this.view.state.selection.main, h = this.moveToLine(this.domAtPos(l.anchor)), a = l.empty ? h : this.moveToLine(this.domAtPos(l.head));
    if (C.gecko && l.empty && !this.hasComposition && Af(h)) {
      let f = document.createTextNode("");
      this.view.observer.ignore(() => h.node.insertBefore(f, h.node.childNodes[h.offset] || null)), h = a = new ct(f, 0), o = !0;
    }
    let c = this.view.observer.selectionRange;
    (o || !c.focusNode || !ds(h.node, h.offset, c.anchorNode, c.anchorOffset) || !ds(a.node, a.offset, c.focusNode, c.focusOffset)) && (this.view.observer.ignore(() => {
      C.android && C.chrome && this.dom.contains(c.focusNode) && Pf(c.focusNode, this.dom) && (this.dom.blur(), this.dom.focus({ preventScroll: !0 }));
      let f = us(this.view.root);
      if (f)
        if (l.empty) {
          if (C.gecko) {
            let u = Mf(h.node, h.offset);
            if (u && u != 3) {
              let d = Yl(h.node, h.offset, u == 1 ? 1 : -1);
              d && (h = new ct(d.node, d.offset));
            }
          }
          f.collapse(h.node, h.offset), l.bidiLevel != null && f.caretBidiLevel !== void 0 && (f.caretBidiLevel = l.bidiLevel);
        } else if (f.extend) {
          f.collapse(h.node, h.offset);
          try {
            f.extend(a.node, a.offset);
          } catch {
          }
        } else {
          let u = document.createRange();
          l.anchor > l.head && ([h, a] = [a, h]), u.setEnd(a.node, a.offset), u.setStart(h.node, h.offset), f.removeAllRanges(), f.addRange(u);
        }
      r && this.view.root.activeElement == this.dom && (this.dom.blur(), i && i.focus());
    }), this.view.observer.setSelectionRange(h, a)), this.impreciseAnchor = h.precise ? null : new ct(c.anchorNode, c.anchorOffset), this.impreciseHead = a.precise ? null : new ct(c.focusNode, c.focusOffset);
  }
  enforceCursorAssoc() {
    if (this.hasComposition)
      return;
    let { view: t } = this, e = t.state.selection.main, i = us(t.root), { anchorNode: s, anchorOffset: r } = t.observer.selectionRange;
    if (!i || !e.empty || !e.assoc || !i.modify)
      return;
    let o = Z.find(this, e.head);
    if (!o)
      return;
    let l = o.posAtStart;
    if (e.head == l || e.head == l + o.length)
      return;
    let h = this.coordsAt(e.head, -1), a = this.coordsAt(e.head, 1);
    if (!h || !a || h.bottom > a.top)
      return;
    let c = this.domAtPos(e.head + e.assoc);
    i.collapse(c.node, c.offset), i.modify("move", e.assoc < 0 ? "forward" : "backward", "lineboundary"), t.observer.readSelectionRange();
    let f = t.observer.selectionRange;
    t.docView.posFromDOM(f.anchorNode, f.anchorOffset) != e.from && i.collapse(s, r);
  }
  // If a position is in/near a block widget, move it to a nearby text
  // line, since we don't want the cursor inside a block widget.
  moveToLine(t) {
    let e = this.dom, i;
    if (t.node != e)
      return t;
    for (let s = t.offset; !i && s < e.childNodes.length; s++) {
      let r = q.get(e.childNodes[s]);
      r instanceof Z && (i = r.domAtPos(0));
    }
    for (let s = t.offset - 1; !i && s >= 0; s--) {
      let r = q.get(e.childNodes[s]);
      r instanceof Z && (i = r.domAtPos(r.length));
    }
    return i ? new ct(i.node, i.offset, !0) : t;
  }
  nearest(t) {
    for (let e = t; e; ) {
      let i = q.get(e);
      if (i && i.rootView == this)
        return i;
      e = e.parentNode;
    }
    return null;
  }
  posFromDOM(t, e) {
    let i = this.nearest(t);
    if (!i)
      throw new RangeError("Trying to find position for a DOM position outside of the document");
    return i.localPosFromDOM(t, e) + i.posAtStart;
  }
  domAtPos(t) {
    let { i: e, off: i } = this.childCursor().findPos(t, -1);
    for (; e < this.children.length - 1; ) {
      let s = this.children[e];
      if (i < s.length || s instanceof Z)
        break;
      e++, i = 0;
    }
    return this.children[e].domAtPos(i);
  }
  coordsAt(t, e) {
    let i = null, s = 0;
    for (let r = this.length, o = this.children.length - 1; o >= 0; o--) {
      let l = this.children[o], h = r - l.breakAfter, a = h - l.length;
      if (h < t)
        break;
      a <= t && (a < t || l.covers(-1)) && (h > t || l.covers(1)) && (!i || l instanceof Z && !(i instanceof Z && e >= 0)) && (i = l, s = a), r = a;
    }
    return i ? i.coordsAt(t - s, e) : null;
  }
  coordsForChar(t) {
    let { i: e, off: i } = this.childPos(t, 1), s = this.children[e];
    if (!(s instanceof Z))
      return null;
    for (; s.children.length; ) {
      let { i: l, off: h } = s.childPos(i, 1);
      for (; ; l++) {
        if (l == s.children.length)
          return null;
        if ((s = s.children[l]).length)
          break;
      }
      i = h;
    }
    if (!(s instanceof re))
      return null;
    let r = wt(s.text, i);
    if (r == i)
      return null;
    let o = Ne(s.dom, i, r).getClientRects();
    for (let l = 0; l < o.length; l++) {
      let h = o[l];
      if (l == o.length - 1 || h.top < h.bottom && h.left < h.right)
        return h;
    }
    return null;
  }
  measureVisibleLineHeights(t) {
    let e = [], { from: i, to: s } = t, r = this.view.contentDOM.clientWidth, o = r > Math.max(this.view.scrollDOM.clientWidth, this.minWidth) + 1, l = -1, h = this.view.textDirection == tt.LTR;
    for (let a = 0, c = 0; c < this.children.length; c++) {
      let f = this.children[c], u = a + f.length;
      if (u > s)
        break;
      if (a >= i) {
        let d = f.dom.getBoundingClientRect();
        if (e.push(d.height), o) {
          let p = f.dom.lastChild, m = p ? bi(p) : [];
          if (m.length) {
            let g = m[m.length - 1], y = h ? g.right - d.left : d.right - g.left;
            y > l && (l = y, this.minWidth = r, this.minWidthFrom = a, this.minWidthTo = u);
          }
        }
      }
      a = u + f.breakAfter;
    }
    return e;
  }
  textDirectionAt(t) {
    let { i: e } = this.childPos(t, 1);
    return getComputedStyle(this.children[e].dom).direction == "rtl" ? tt.RTL : tt.LTR;
  }
  measureTextSize() {
    for (let r of this.children)
      if (r instanceof Z) {
        let o = r.measureTextSize();
        if (o)
          return o;
      }
    let t = document.createElement("div"), e, i, s;
    return t.className = "cm-line", t.style.width = "99999px", t.style.position = "absolute", t.textContent = "abc def ghi jkl mno pqr stu", this.view.observer.ignore(() => {
      this.dom.appendChild(t);
      let r = bi(t.firstChild)[0];
      e = t.getBoundingClientRect().height, i = r ? r.width / 27 : 7, s = r ? r.height : e, t.remove();
    }), { lineHeight: e, charWidth: i, textHeight: s };
  }
  childCursor(t = this.length) {
    let e = this.children.length;
    return e && (t -= this.children[--e].length), new Sl(this.children, t, e);
  }
  computeBlockGapDeco() {
    let t = [], e = this.view.viewState;
    for (let i = 0, s = 0; ; s++) {
      let r = s == e.viewports.length ? null : e.viewports[s], o = r ? r.from - 1 : this.length;
      if (o > i) {
        let l = (e.lineBlockAt(o).bottom - e.lineBlockAt(i).top) / this.view.scaleY;
        t.push(N.replace({
          widget: new Fr(l),
          block: !0,
          inclusive: !0,
          isBlockGap: !0
        }).range(i, o));
      }
      if (!r)
        break;
      i = r.to + 1;
    }
    return N.set(t);
  }
  updateDeco() {
    let t = this.view.state.facet(xi).map((e, i) => (this.dynamicDecorationMap[i] = typeof e == "function") ? e(this.view) : e);
    for (let e = t.length; e < t.length + 3; e++)
      this.dynamicDecorationMap[e] = !1;
    return this.decorations = [
      ...t,
      this.computeBlockGapDeco(),
      this.view.viewState.lineGapDeco
    ];
  }
  scrollIntoView(t) {
    if (t.isSnapshot) {
      let a = this.view.viewState.lineBlockAt(t.range.head);
      this.view.scrollDOM.scrollTop = a.top - t.yMargin, this.view.scrollDOM.scrollLeft = t.xMargin;
      return;
    }
    let { range: e } = t, i = this.coordsAt(e.head, e.empty ? e.assoc : e.head > e.anchor ? -1 : 1), s;
    if (!i)
      return;
    !e.empty && (s = this.coordsAt(e.anchor, e.anchor > e.head ? -1 : 1)) && (i = {
      left: Math.min(i.left, s.left),
      top: Math.min(i.top, s.top),
      right: Math.max(i.right, s.right),
      bottom: Math.max(i.bottom, s.bottom)
    });
    let r = zl(this.view), o = {
      left: i.left - r.left,
      top: i.top - r.top,
      right: i.right + r.right,
      bottom: i.bottom + r.bottom
    }, { offsetWidth: l, offsetHeight: h } = this.view.scrollDOM;
    nf(this.view.scrollDOM, o, e.head < e.anchor ? -1 : 1, t.x, t.y, Math.max(Math.min(t.xMargin, l), -l), Math.max(Math.min(t.yMargin, h), -h), this.view.textDirection == tt.LTR);
  }
}
function Af(n) {
  return n.node.nodeType == 1 && n.node.firstChild && (n.offset == 0 || n.node.childNodes[n.offset - 1].contentEditable == "false") && (n.offset == n.node.childNodes.length || n.node.childNodes[n.offset].contentEditable == "false");
}
class Fr extends Se {
  constructor(t) {
    super(), this.height = t;
  }
  toDOM() {
    let t = document.createElement("div");
    return this.updateDOM(t), t;
  }
  eq(t) {
    return t.height == this.height;
  }
  updateDOM(t) {
    return t.style.height = this.height + "px", !0;
  }
  get estimatedHeight() {
    return this.height;
  }
}
function Ul(n, t) {
  let e = n.observer.selectionRange, i = e.focusNode && Yl(e.focusNode, e.focusOffset, 0);
  if (!i)
    return null;
  let s = t - i.offset;
  return { from: s, to: s + i.node.nodeValue.length, node: i.node };
}
function Of(n, t, e) {
  let i = Ul(n, e);
  if (!i)
    return null;
  let { node: s, from: r, to: o } = i, l = s.nodeValue;
  if (/[\n\r]/.test(l) || n.state.doc.sliceString(i.from, i.to) != l)
    return null;
  let h = t.invertedDesc, a = new Mt(h.mapPos(r), h.mapPos(o), r, o), c = [];
  for (let f = s.parentNode; ; f = f.parentNode) {
    let u = q.get(f);
    if (u instanceof oe)
      c.push({ node: f, deco: u.mark });
    else {
      if (u instanceof Z || f.nodeName == "DIV" && f.parentNode == n.contentDOM)
        return { range: a, text: s, marks: c, line: f };
      if (f != n.contentDOM)
        c.push({ node: f, deco: new Mi({
          inclusive: !0,
          attributes: uf(f),
          tagName: f.tagName.toLowerCase()
        }) });
      else
        return null;
    }
  }
}
function Yl(n, t, e) {
  if (e <= 0)
    for (let i = n, s = t; ; ) {
      if (i.nodeType == 3)
        return { node: i, offset: s };
      if (i.nodeType == 1 && s > 0)
        i = i.childNodes[s - 1], s = ne(i);
      else
        break;
    }
  if (e >= 0)
    for (let i = n, s = t; ; ) {
      if (i.nodeType == 3)
        return { node: i, offset: s };
      if (i.nodeType == 1 && s < i.childNodes.length && e >= 0)
        i = i.childNodes[s], s = 0;
      else
        break;
    }
  return null;
}
function Mf(n, t) {
  return n.nodeType != 1 ? 0 : (t && n.childNodes[t - 1].contentEditable == "false" ? 1 : 0) | (t < n.childNodes.length && n.childNodes[t].contentEditable == "false" ? 2 : 0);
}
let Tf = class {
  constructor() {
    this.changes = [];
  }
  compareRange(t, e) {
    Sn(t, e, this.changes);
  }
  comparePoint(t, e) {
    Sn(t, e, this.changes);
  }
};
function Df(n, t, e) {
  let i = new Tf();
  return F.compare(n, t, e, i), i.changes;
}
function Pf(n, t) {
  for (let e = n; e && e != t; e = e.assignedSlot || e.parentNode)
    if (e.nodeType == 1 && e.contentEditable == "false")
      return !0;
  return !1;
}
function Bf(n, t) {
  let e = !1;
  return t && n.iterChangedRanges((i, s) => {
    i < t.to && s > t.from && (e = !0);
  }), e;
}
function Rf(n, t, e = 1) {
  let i = n.charCategorizer(t), s = n.doc.lineAt(t), r = t - s.from;
  if (s.length == 0)
    return b.cursor(t);
  r == 0 ? e = 1 : r == s.length && (e = -1);
  let o = r, l = r;
  e < 0 ? o = wt(s.text, r, !1) : l = wt(s.text, r);
  let h = i(s.text.slice(o, l));
  for (; o > 0; ) {
    let a = wt(s.text, o, !1);
    if (i(s.text.slice(a, o)) != h)
      break;
    o = a;
  }
  for (; l < s.length; ) {
    let a = wt(s.text, l);
    if (i(s.text.slice(l, a)) != h)
      break;
    l = a;
  }
  return b.range(o + s.from, l + s.from);
}
function Lf(n, t) {
  return t.left > n ? t.left - n : Math.max(0, n - t.right);
}
function Ef(n, t) {
  return t.top > n ? t.top - n : Math.max(0, n - t.bottom);
}
function zs(n, t) {
  return n.top < t.bottom - 1 && n.bottom > t.top + 1;
}
function _r(n, t) {
  return t < n.top ? { top: t, left: n.left, right: n.right, bottom: n.bottom } : n;
}
function zr(n, t) {
  return t > n.bottom ? { top: n.top, left: n.left, right: n.right, bottom: t } : n;
}
function Tn(n, t, e) {
  let i, s, r, o, l = !1, h, a, c, f;
  for (let p = n.firstChild; p; p = p.nextSibling) {
    let m = bi(p);
    for (let g = 0; g < m.length; g++) {
      let y = m[g];
      s && zs(s, y) && (y = _r(zr(y, s.bottom), s.top));
      let x = Lf(t, y), S = Ef(e, y);
      if (x == 0 && S == 0)
        return p.nodeType == 3 ? Wr(p, t, e) : Tn(p, t, e);
      if (!i || o > S || o == S && r > x) {
        i = p, s = y, r = x, o = S;
        let v = S ? e < y.top ? -1 : 1 : x ? t < y.left ? -1 : 1 : 0;
        l = !v || (v > 0 ? g < m.length - 1 : g > 0);
      }
      x == 0 ? e > y.bottom && (!c || c.bottom < y.bottom) ? (h = p, c = y) : e < y.top && (!f || f.top > y.top) && (a = p, f = y) : c && zs(c, y) ? c = zr(c, y.bottom) : f && zs(f, y) && (f = _r(f, y.top));
    }
  }
  if (c && c.bottom >= e ? (i = h, s = c) : f && f.top <= e && (i = a, s = f), !i)
    return { node: n, offset: 0 };
  let u = Math.max(s.left, Math.min(s.right, t));
  if (i.nodeType == 3)
    return Wr(i, u, e);
  if (l && i.contentEditable != "false")
    return Tn(i, u, e);
  let d = Array.prototype.indexOf.call(n.childNodes, i) + (t >= (s.left + s.right) / 2 ? 1 : 0);
  return { node: n, offset: d };
}
function Wr(n, t, e) {
  let i = n.nodeValue.length, s = -1, r = 1e9, o = 0;
  for (let l = 0; l < i; l++) {
    let h = Ne(n, l, l + 1).getClientRects();
    for (let a = 0; a < h.length; a++) {
      let c = h[a];
      if (c.top == c.bottom)
        continue;
      o || (o = t - c.left);
      let f = (c.top > e ? c.top - e : e - c.bottom) - 1;
      if (c.left - 1 <= t && c.right + 1 >= t && f < r) {
        let u = t >= (c.left + c.right) / 2, d = u;
        if ((C.chrome || C.gecko) && Ne(n, l).getBoundingClientRect().left == c.right && (d = !u), f <= 0)
          return { node: n, offset: l + (d ? 1 : 0) };
        s = l + (d ? 1 : 0), r = f;
      }
    }
  }
  return { node: n, offset: s > -1 ? s : o > 0 ? n.nodeValue.length : 0 };
}
function Ql(n, t, e, i = -1) {
  var s, r;
  let o = n.contentDOM.getBoundingClientRect(), l = o.top + n.viewState.paddingTop, h, { docHeight: a } = n.viewState, { x: c, y: f } = t, u = f - l;
  if (u < 0)
    return 0;
  if (u > a)
    return n.state.doc.length;
  for (let v = n.viewState.heightOracle.textHeight / 2, A = !1; h = n.elementAtHeight(u), h.type != Lt.Text; )
    for (; u = i > 0 ? h.bottom + v : h.top - v, !(u >= 0 && u <= a); ) {
      if (A)
        return e ? null : 0;
      A = !0, i = -i;
    }
  f = l + u;
  let d = h.from;
  if (d < n.viewport.from)
    return n.viewport.from == 0 ? 0 : e ? null : jr(n, o, h, c, f);
  if (d > n.viewport.to)
    return n.viewport.to == n.state.doc.length ? n.state.doc.length : e ? null : jr(n, o, h, c, f);
  let p = n.dom.ownerDocument, m = n.root.elementFromPoint ? n.root : p, g = m.elementFromPoint(c, f);
  g && !n.contentDOM.contains(g) && (g = null), g || (c = Math.max(o.left + 1, Math.min(o.right - 1, c)), g = m.elementFromPoint(c, f), g && !n.contentDOM.contains(g) && (g = null));
  let y, x = -1;
  if (g && ((s = n.docView.nearest(g)) === null || s === void 0 ? void 0 : s.isEditable) != !1) {
    if (p.caretPositionFromPoint) {
      let v = p.caretPositionFromPoint(c, f);
      v && ({ offsetNode: y, offset: x } = v);
    } else if (p.caretRangeFromPoint) {
      let v = p.caretRangeFromPoint(c, f);
      v && ({ startContainer: y, startOffset: x } = v, (!n.contentDOM.contains(y) || C.safari && Nf(y, x, c) || C.chrome && If(y, x, c)) && (y = void 0));
    }
  }
  if (!y || !n.docView.dom.contains(y)) {
    let v = Z.find(n.docView, d);
    if (!v)
      return u > h.top + h.height / 2 ? h.to : h.from;
    ({ node: y, offset: x } = Tn(v.dom, c, f));
  }
  let S = n.docView.nearest(y);
  if (!S)
    return null;
  if (S.isWidget && ((r = S.dom) === null || r === void 0 ? void 0 : r.nodeType) == 1) {
    let v = S.dom.getBoundingClientRect();
    return t.y < v.top || t.y <= v.bottom && t.x <= (v.left + v.right) / 2 ? S.posAtStart : S.posAtEnd;
  } else
    return S.localPosFromDOM(y, x) + S.posAtStart;
}
function jr(n, t, e, i, s) {
  let r = Math.round((i - t.left) * n.defaultCharacterWidth);
  if (n.lineWrapping && e.height > n.defaultLineHeight * 1.5) {
    let l = n.viewState.heightOracle.textHeight, h = Math.floor((s - e.top - (n.defaultLineHeight - l) * 0.5) / l);
    r += h * n.viewState.heightOracle.lineLength;
  }
  let o = n.state.sliceDoc(e.from, e.to);
  return e.from + Qc(o, r, n.state.tabSize);
}
function Nf(n, t, e) {
  let i;
  if (n.nodeType != 3 || t != (i = n.nodeValue.length))
    return !1;
  for (let s = n.nextSibling; s; s = s.nextSibling)
    if (s.nodeType != 1 || s.nodeName != "BR")
      return !1;
  return Ne(n, i - 1, i).getBoundingClientRect().left > e;
}
function If(n, t, e) {
  if (t != 0)
    return !1;
  for (let s = n; ; ) {
    let r = s.parentNode;
    if (!r || r.nodeType != 1 || r.firstChild != s)
      return !1;
    if (r.classList.contains("cm-line"))
      break;
    s = r;
  }
  let i = n.nodeType == 1 ? n.getBoundingClientRect() : Ne(n, 0, Math.max(n.nodeValue.length, 1)).getBoundingClientRect();
  return e - i.left > 5;
}
function Vf(n, t) {
  let e = n.lineBlockAt(t);
  if (Array.isArray(e.type)) {
    for (let i of e.type)
      if (i.to > t || i.to == t && (i.to == e.to || i.type == Lt.Text))
        return i;
  }
  return e;
}
function Hf(n, t, e, i) {
  let s = Vf(n, t.head), r = !i || s.type != Lt.Text || !(n.lineWrapping || s.widgetLineBreaks) ? null : n.coordsAtPos(t.assoc < 0 && t.head > s.from ? t.head - 1 : t.head);
  if (r) {
    let o = n.dom.getBoundingClientRect(), l = n.textDirectionAt(s.from), h = n.posAtCoords({
      x: e == (l == tt.LTR) ? o.right - 1 : o.left + 1,
      y: (r.top + r.bottom) / 2
    });
    if (h != null)
      return b.cursor(h, e ? -1 : 1);
  }
  return b.cursor(e ? s.to : s.from, e ? -1 : 1);
}
function Kr(n, t, e, i) {
  let s = n.state.doc.lineAt(t.head), r = n.bidiSpans(s), o = n.textDirectionAt(s.from);
  for (let l = t, h = null; ; ) {
    let a = Cf(s, r, o, l, e), c = Gl;
    if (!a) {
      if (s.number == (e ? n.state.doc.lines : 1))
        return l;
      c = `
`, s = n.state.doc.line(s.number + (e ? 1 : -1)), r = n.bidiSpans(s), a = b.cursor(e ? s.from : s.to);
    }
    if (h) {
      if (!h(c))
        return l;
    } else {
      if (!i)
        return a;
      h = i(c);
    }
    l = a;
  }
}
function $f(n, t, e) {
  let i = n.state.charCategorizer(t), s = i(e);
  return (r) => {
    let o = i(r);
    return s == Zt.Space && (s = o), s == o;
  };
}
function Ff(n, t, e, i) {
  let s = t.head, r = e ? 1 : -1;
  if (s == (e ? n.state.doc.length : 0))
    return b.cursor(s, t.assoc);
  let o = t.goalColumn, l, h = n.contentDOM.getBoundingClientRect(), a = n.coordsAtPos(s, t.assoc || -1), c = n.documentTop;
  if (a)
    o == null && (o = a.left - h.left), l = r < 0 ? a.top : a.bottom;
  else {
    let d = n.viewState.lineBlockAt(s);
    o == null && (o = Math.min(h.right - h.left, n.defaultCharacterWidth * (s - d.from))), l = (r < 0 ? d.top : d.bottom) + c;
  }
  let f = h.left + o, u = i ?? n.viewState.heightOracle.textHeight >> 1;
  for (let d = 0; ; d += 10) {
    let p = l + (u + d) * r, m = Ql(n, { x: f, y: p }, !1, r);
    if (p < h.top || p > h.bottom || (r < 0 ? m < s : m > s)) {
      let g = n.docView.coordsForChar(m), y = !g || p < g.top ? -1 : 1;
      return b.cursor(m, y, void 0, o);
    }
  }
}
function es(n, t, e) {
  for (; ; ) {
    let i = 0;
    for (let s of n)
      s.between(t - 1, t + 1, (r, o, l) => {
        if (t > r && t < o) {
          let h = i || e || (t - r < o - t ? -1 : 1);
          t = h < 0 ? r : o, i = h;
        }
      });
    if (!i)
      return t;
  }
}
function Ws(n, t, e) {
  let i = es(n.state.facet(ir).map((s) => s(n)), e.from, t.head > e.from ? -1 : 1);
  return i == e.from ? e : b.cursor(i, i < e.from ? 1 : -1);
}
class _f {
  setSelectionOrigin(t) {
    this.lastSelectionOrigin = t, this.lastSelectionTime = Date.now();
  }
  constructor(t) {
    this.view = t, this.lastKeyCode = 0, this.lastKeyTime = 0, this.lastTouchTime = 0, this.lastFocusTime = 0, this.lastScrollTop = 0, this.lastScrollLeft = 0, this.pendingIOSKey = void 0, this.lastSelectionOrigin = null, this.lastSelectionTime = 0, this.lastEscPress = 0, this.lastContextMenu = 0, this.scrollHandlers = [], this.handlers = /* @__PURE__ */ Object.create(null), this.composing = -1, this.compositionFirstChange = null, this.compositionEndedAt = 0, this.compositionPendingKey = !1, this.compositionPendingChange = !1, this.mouseSelection = null, this.draggedContent = null, this.handleEvent = this.handleEvent.bind(this), this.notifiedFocused = t.hasFocus, C.safari && t.contentDOM.addEventListener("input", () => null), C.gecko && su(t.contentDOM.ownerDocument);
  }
  handleEvent(t) {
    !Yf(this.view, t) || this.ignoreDuringComposition(t) || t.type == "keydown" && this.keydown(t) || this.runHandlers(t.type, t);
  }
  runHandlers(t, e) {
    let i = this.handlers[t];
    if (i) {
      for (let s of i.observers)
        s(this.view, e);
      for (let s of i.handlers) {
        if (e.defaultPrevented)
          break;
        if (s(this.view, e)) {
          e.preventDefault();
          break;
        }
      }
    }
  }
  ensureHandlers(t) {
    let e = zf(t), i = this.handlers, s = this.view.contentDOM;
    for (let r in e)
      if (r != "scroll") {
        let o = !e[r].handlers.length, l = i[r];
        l && o != !l.handlers.length && (s.removeEventListener(r, this.handleEvent), l = null), l || s.addEventListener(r, this.handleEvent, { passive: o });
      }
    for (let r in i)
      r != "scroll" && !e[r] && s.removeEventListener(r, this.handleEvent);
    this.handlers = e;
  }
  keydown(t) {
    if (this.lastKeyCode = t.keyCode, this.lastKeyTime = Date.now(), t.keyCode == 9 && Date.now() < this.lastEscPress + 2e3)
      return !0;
    if (t.keyCode != 27 && Xl.indexOf(t.keyCode) < 0 && (this.view.inputState.lastEscPress = 0), C.android && C.chrome && !t.synthetic && (t.keyCode == 13 || t.keyCode == 8))
      return this.view.observer.delayAndroidKey(t.key, t.keyCode), !0;
    let e;
    return C.ios && !t.synthetic && !t.altKey && !t.metaKey && ((e = Jl.find((i) => i.keyCode == t.keyCode)) && !t.ctrlKey || Wf.indexOf(t.key) > -1 && t.ctrlKey && !t.shiftKey) ? (this.pendingIOSKey = e || t, setTimeout(() => this.flushIOSKey(), 250), !0) : (t.keyCode != 229 && this.view.observer.forceFlush(), !1);
  }
  flushIOSKey() {
    let t = this.pendingIOSKey;
    return t ? (this.pendingIOSKey = void 0, Ke(this.view.contentDOM, t.key, t.keyCode)) : !1;
  }
  ignoreDuringComposition(t) {
    return /^key/.test(t.type) ? this.composing > 0 ? !0 : C.safari && !C.ios && this.compositionPendingKey && Date.now() - this.compositionEndedAt < 100 ? (this.compositionPendingKey = !1, !0) : !1 : !1;
  }
  startMouseSelection(t) {
    this.mouseSelection && this.mouseSelection.destroy(), this.mouseSelection = t;
  }
  update(t) {
    this.mouseSelection && this.mouseSelection.update(t), this.draggedContent && t.docChanged && (this.draggedContent = this.draggedContent.map(t.changes)), t.transactions.length && (this.lastKeyCode = this.lastSelectionTime = 0);
  }
  destroy() {
    this.mouseSelection && this.mouseSelection.destroy();
  }
}
function qr(n, t) {
  return (e, i) => {
    try {
      return t.call(n, i, e);
    } catch (s) {
      ie(e.state, s);
    }
  };
}
function zf(n) {
  let t = /* @__PURE__ */ Object.create(null);
  function e(i) {
    return t[i] || (t[i] = { observers: [], handlers: [] });
  }
  for (let i of n) {
    let s = i.spec;
    if (s && s.domEventHandlers)
      for (let r in s.domEventHandlers) {
        let o = s.domEventHandlers[r];
        o && e(r).handlers.push(qr(i.value, o));
      }
    if (s && s.domEventObservers)
      for (let r in s.domEventObservers) {
        let o = s.domEventObservers[r];
        o && e(r).observers.push(qr(i.value, o));
      }
  }
  for (let i in Nt)
    e(i).handlers.push(Nt[i]);
  for (let i in It)
    e(i).observers.push(It[i]);
  return t;
}
const Jl = [
  { key: "Backspace", keyCode: 8, inputType: "deleteContentBackward" },
  { key: "Enter", keyCode: 13, inputType: "insertParagraph" },
  { key: "Enter", keyCode: 13, inputType: "insertLineBreak" },
  { key: "Delete", keyCode: 46, inputType: "deleteContentForward" }
], Wf = "dthko", Xl = [16, 17, 18, 20, 91, 92, 224, 225], Vi = 6;
function Hi(n) {
  return Math.max(0, n) * 0.7 + 8;
}
function jf(n, t) {
  return Math.max(Math.abs(n.clientX - t.clientX), Math.abs(n.clientY - t.clientY));
}
class Kf {
  constructor(t, e, i, s) {
    this.view = t, this.startEvent = e, this.style = i, this.mustSelect = s, this.scrollSpeed = { x: 0, y: 0 }, this.scrolling = -1, this.lastEvent = e, this.scrollParent = rf(t.contentDOM), this.atoms = t.state.facet(ir).map((o) => o(t));
    let r = t.contentDOM.ownerDocument;
    r.addEventListener("mousemove", this.move = this.move.bind(this)), r.addEventListener("mouseup", this.up = this.up.bind(this)), this.extend = e.shiftKey, this.multiple = t.state.facet(H.allowMultipleSelections) && qf(t, e), this.dragging = Uf(t, e) && ih(e) == 1 ? null : !1;
  }
  start(t) {
    this.dragging === !1 && this.select(t);
  }
  move(t) {
    var e;
    if (t.buttons == 0)
      return this.destroy();
    if (this.dragging || this.dragging == null && jf(this.startEvent, t) < 10)
      return;
    this.select(this.lastEvent = t);
    let i = 0, s = 0, r = ((e = this.scrollParent) === null || e === void 0 ? void 0 : e.getBoundingClientRect()) || { left: 0, top: 0, right: this.view.win.innerWidth, bottom: this.view.win.innerHeight }, o = zl(this.view);
    t.clientX - o.left <= r.left + Vi ? i = -Hi(r.left - t.clientX) : t.clientX + o.right >= r.right - Vi && (i = Hi(t.clientX - r.right)), t.clientY - o.top <= r.top + Vi ? s = -Hi(r.top - t.clientY) : t.clientY + o.bottom >= r.bottom - Vi && (s = Hi(t.clientY - r.bottom)), this.setScrollSpeed(i, s);
  }
  up(t) {
    this.dragging == null && this.select(this.lastEvent), this.dragging || t.preventDefault(), this.destroy();
  }
  destroy() {
    this.setScrollSpeed(0, 0);
    let t = this.view.contentDOM.ownerDocument;
    t.removeEventListener("mousemove", this.move), t.removeEventListener("mouseup", this.up), this.view.inputState.mouseSelection = this.view.inputState.draggedContent = null;
  }
  setScrollSpeed(t, e) {
    this.scrollSpeed = { x: t, y: e }, t || e ? this.scrolling < 0 && (this.scrolling = setInterval(() => this.scroll(), 50)) : this.scrolling > -1 && (clearInterval(this.scrolling), this.scrolling = -1);
  }
  scroll() {
    this.scrollParent ? (this.scrollParent.scrollLeft += this.scrollSpeed.x, this.scrollParent.scrollTop += this.scrollSpeed.y) : this.view.win.scrollBy(this.scrollSpeed.x, this.scrollSpeed.y), this.dragging === !1 && this.select(this.lastEvent);
  }
  skipAtoms(t) {
    let e = null;
    for (let i = 0; i < t.ranges.length; i++) {
      let s = t.ranges[i], r = null;
      if (s.empty) {
        let o = es(this.atoms, s.from, 0);
        o != s.from && (r = b.cursor(o, -1));
      } else {
        let o = es(this.atoms, s.from, -1), l = es(this.atoms, s.to, 1);
        (o != s.from || l != s.to) && (r = b.range(s.from == s.anchor ? o : l, s.from == s.head ? o : l));
      }
      r && (e || (e = t.ranges.slice()), e[i] = r);
    }
    return e ? b.create(e, t.mainIndex) : t;
  }
  select(t) {
    let { view: e } = this, i = this.skipAtoms(this.style.get(t, this.extend, this.multiple));
    (this.mustSelect || !i.eq(e.state.selection) || i.main.assoc != e.state.selection.main.assoc && this.dragging === !1) && this.view.dispatch({
      selection: i,
      userEvent: "select.pointer"
    }), this.mustSelect = !1;
  }
  update(t) {
    this.style.update(t) && setTimeout(() => this.select(this.lastEvent), 20);
  }
}
function qf(n, t) {
  let e = n.state.facet(Rl);
  return e.length ? e[0](t) : C.mac ? t.metaKey : t.ctrlKey;
}
function Gf(n, t) {
  let e = n.state.facet(Ll);
  return e.length ? e[0](t) : C.mac ? !t.altKey : !t.ctrlKey;
}
function Uf(n, t) {
  let { main: e } = n.state.selection;
  if (e.empty)
    return !1;
  let i = us(n.root);
  if (!i || i.rangeCount == 0)
    return !0;
  let s = i.getRangeAt(0).getClientRects();
  for (let r = 0; r < s.length; r++) {
    let o = s[r];
    if (o.left <= t.clientX && o.right >= t.clientX && o.top <= t.clientY && o.bottom >= t.clientY)
      return !0;
  }
  return !1;
}
function Yf(n, t) {
  if (!t.bubbles)
    return !0;
  if (t.defaultPrevented)
    return !1;
  for (let e = t.target, i; e != n.contentDOM; e = e.parentNode)
    if (!e || e.nodeType == 11 || (i = q.get(e)) && i.ignoreEvent(t))
      return !1;
  return !0;
}
const Nt = /* @__PURE__ */ Object.create(null), It = /* @__PURE__ */ Object.create(null), Zl = C.ie && C.ie_version < 15 || C.ios && C.webkit_version < 604;
function Qf(n) {
  let t = n.dom.parentNode;
  if (!t)
    return;
  let e = t.appendChild(document.createElement("textarea"));
  e.style.cssText = "position: fixed; left: -10000px; top: 10px", e.focus(), setTimeout(() => {
    n.focus(), e.remove(), th(n, e.value);
  }, 50);
}
function th(n, t) {
  let { state: e } = n, i, s = 1, r = e.toText(t), o = r.lines == e.selection.ranges.length;
  if (Dn != null && e.selection.ranges.every((h) => h.empty) && Dn == r.toString()) {
    let h = -1;
    i = e.changeByRange((a) => {
      let c = e.doc.lineAt(a.from);
      if (c.from == h)
        return { range: a };
      h = c.from;
      let f = e.toText((o ? r.line(s++).text : t) + e.lineBreak);
      return {
        changes: { from: c.from, insert: f },
        range: b.cursor(a.from + f.length)
      };
    });
  } else
    o ? i = e.changeByRange((h) => {
      let a = r.line(s++);
      return {
        changes: { from: h.from, to: h.to, insert: a.text },
        range: b.cursor(h.from + a.length)
      };
    }) : i = e.replaceSelection(r);
  n.dispatch(i, {
    userEvent: "input.paste",
    scrollIntoView: !0
  });
}
It.scroll = (n) => {
  n.inputState.lastScrollTop = n.scrollDOM.scrollTop, n.inputState.lastScrollLeft = n.scrollDOM.scrollLeft;
};
Nt.keydown = (n, t) => (n.inputState.setSelectionOrigin("select"), t.keyCode == 27 && (n.inputState.lastEscPress = Date.now()), !1);
It.touchstart = (n, t) => {
  n.inputState.lastTouchTime = Date.now(), n.inputState.setSelectionOrigin("select.pointer");
};
It.touchmove = (n) => {
  n.inputState.setSelectionOrigin("select.pointer");
};
Nt.mousedown = (n, t) => {
  if (n.observer.flush(), n.inputState.lastTouchTime > Date.now() - 2e3)
    return !1;
  let e = null;
  for (let i of n.state.facet(El))
    if (e = i(n, t), e)
      break;
  if (!e && t.button == 0 && (e = Zf(n, t)), e) {
    let i = !n.hasFocus;
    n.inputState.startMouseSelection(new Kf(n, t, e, i)), i && n.observer.ignore(() => kl(n.contentDOM));
    let s = n.inputState.mouseSelection;
    if (s)
      return s.start(t), s.dragging === !1;
  }
  return !1;
};
function Gr(n, t, e, i) {
  if (i == 1)
    return b.cursor(t, e);
  if (i == 2)
    return Rf(n.state, t, e);
  {
    let s = Z.find(n.docView, t), r = n.state.doc.lineAt(s ? s.posAtEnd : t), o = s ? s.posAtStart : r.from, l = s ? s.posAtEnd : r.to;
    return l < n.state.doc.length && l == r.to && l++, b.range(o, l);
  }
}
let eh = (n, t) => n >= t.top && n <= t.bottom, Ur = (n, t, e) => eh(t, e) && n >= e.left && n <= e.right;
function Jf(n, t, e, i) {
  let s = Z.find(n.docView, t);
  if (!s)
    return 1;
  let r = t - s.posAtStart;
  if (r == 0)
    return 1;
  if (r == s.length)
    return -1;
  let o = s.coordsAt(r, -1);
  if (o && Ur(e, i, o))
    return -1;
  let l = s.coordsAt(r, 1);
  return l && Ur(e, i, l) ? 1 : o && eh(i, o) ? -1 : 1;
}
function Yr(n, t) {
  let e = n.posAtCoords({ x: t.clientX, y: t.clientY }, !1);
  return { pos: e, bias: Jf(n, e, t.clientX, t.clientY) };
}
const Xf = C.ie && C.ie_version <= 11;
let Qr = null, Jr = 0, Xr = 0;
function ih(n) {
  if (!Xf)
    return n.detail;
  let t = Qr, e = Xr;
  return Qr = n, Xr = Date.now(), Jr = !t || e > Date.now() - 400 && Math.abs(t.clientX - n.clientX) < 2 && Math.abs(t.clientY - n.clientY) < 2 ? (Jr + 1) % 3 : 1;
}
function Zf(n, t) {
  let e = Yr(n, t), i = ih(t), s = n.state.selection;
  return {
    update(r) {
      r.docChanged && (e.pos = r.changes.mapPos(e.pos), s = s.map(r.changes));
    },
    get(r, o, l) {
      let h = Yr(n, r), a, c = Gr(n, h.pos, h.bias, i);
      if (e.pos != h.pos && !o) {
        let f = Gr(n, e.pos, e.bias, i), u = Math.min(f.from, c.from), d = Math.max(f.to, c.to);
        c = u < c.from ? b.range(u, d) : b.range(d, u);
      }
      return o ? s.replaceRange(s.main.extend(c.from, c.to)) : l && i == 1 && s.ranges.length > 1 && (a = tu(s, h.pos)) ? a : l ? s.addRange(c) : b.create([c]);
    }
  };
}
function tu(n, t) {
  for (let e = 0; e < n.ranges.length; e++) {
    let { from: i, to: s } = n.ranges[e];
    if (i <= t && s >= t)
      return b.create(n.ranges.slice(0, e).concat(n.ranges.slice(e + 1)), n.mainIndex == e ? 0 : n.mainIndex - (n.mainIndex > e ? 1 : 0));
  }
  return null;
}
Nt.dragstart = (n, t) => {
  let { selection: { main: e } } = n.state;
  if (t.target.draggable) {
    let s = n.docView.nearest(t.target);
    if (s && s.isWidget) {
      let r = s.posAtStart, o = r + s.length;
      (r >= e.to || o <= e.from) && (e = b.range(r, o));
    }
  }
  let { inputState: i } = n;
  return i.mouseSelection && (i.mouseSelection.dragging = !0), i.draggedContent = e, t.dataTransfer && (t.dataTransfer.setData("Text", n.state.sliceDoc(e.from, e.to)), t.dataTransfer.effectAllowed = "copyMove"), !1;
};
Nt.dragend = (n) => (n.inputState.draggedContent = null, !1);
function Zr(n, t, e, i) {
  if (!e)
    return;
  let s = n.posAtCoords({ x: t.clientX, y: t.clientY }, !1), { draggedContent: r } = n.inputState, o = i && r && Gf(n, t) ? { from: r.from, to: r.to } : null, l = { from: s, insert: e }, h = n.state.changes(o ? [o, l] : l);
  n.focus(), n.dispatch({
    changes: h,
    selection: { anchor: h.mapPos(s, -1), head: h.mapPos(s, 1) },
    userEvent: o ? "move.drop" : "input.drop"
  }), n.inputState.draggedContent = null;
}
Nt.drop = (n, t) => {
  if (!t.dataTransfer)
    return !1;
  if (n.state.readOnly)
    return !0;
  let e = t.dataTransfer.files;
  if (e && e.length) {
    let i = Array(e.length), s = 0, r = () => {
      ++s == e.length && Zr(n, t, i.filter((o) => o != null).join(n.state.lineBreak), !1);
    };
    for (let o = 0; o < e.length; o++) {
      let l = new FileReader();
      l.onerror = r, l.onload = () => {
        /[\x00-\x08\x0e-\x1f]{2}/.test(l.result) || (i[o] = l.result), r();
      }, l.readAsText(e[o]);
    }
    return !0;
  } else {
    let i = t.dataTransfer.getData("Text");
    if (i)
      return Zr(n, t, i, !0), !0;
  }
  return !1;
};
Nt.paste = (n, t) => {
  if (n.state.readOnly)
    return !0;
  n.observer.flush();
  let e = Zl ? null : t.clipboardData;
  return e ? (th(n, e.getData("text/plain") || e.getData("text/uri-text")), !0) : (Qf(n), !1);
};
function eu(n, t) {
  let e = n.dom.parentNode;
  if (!e)
    return;
  let i = e.appendChild(document.createElement("textarea"));
  i.style.cssText = "position: fixed; left: -10000px; top: 10px", i.value = t, i.focus(), i.selectionEnd = t.length, i.selectionStart = 0, setTimeout(() => {
    i.remove(), n.focus();
  }, 50);
}
function iu(n) {
  let t = [], e = [], i = !1;
  for (let s of n.selection.ranges)
    s.empty || (t.push(n.sliceDoc(s.from, s.to)), e.push(s));
  if (!t.length) {
    let s = -1;
    for (let { from: r } of n.selection.ranges) {
      let o = n.doc.lineAt(r);
      o.number > s && (t.push(o.text), e.push({ from: o.from, to: Math.min(n.doc.length, o.to + 1) })), s = o.number;
    }
    i = !0;
  }
  return { text: t.join(n.lineBreak), ranges: e, linewise: i };
}
let Dn = null;
Nt.copy = Nt.cut = (n, t) => {
  let { text: e, ranges: i, linewise: s } = iu(n.state);
  if (!e && !s)
    return !1;
  Dn = s ? e : null, t.type == "cut" && !n.state.readOnly && n.dispatch({
    changes: i,
    scrollIntoView: !0,
    userEvent: "delete.cut"
  });
  let r = Zl ? null : t.clipboardData;
  return r ? (r.clearData(), r.setData("text/plain", e), !0) : (eu(n, e), !1);
};
const sh = /* @__PURE__ */ ti.define();
function nh(n, t) {
  let e = [];
  for (let i of n.facet(Vl)) {
    let s = i(n, t);
    s && e.push(s);
  }
  return e ? n.update({ effects: e, annotations: sh.of(!0) }) : null;
}
function rh(n) {
  setTimeout(() => {
    let t = n.hasFocus;
    if (t != n.inputState.notifiedFocused) {
      let e = nh(n.state, t);
      e ? n.dispatch(e) : n.update([]);
    }
  }, 10);
}
It.focus = (n) => {
  n.inputState.lastFocusTime = Date.now(), !n.scrollDOM.scrollTop && (n.inputState.lastScrollTop || n.inputState.lastScrollLeft) && (n.scrollDOM.scrollTop = n.inputState.lastScrollTop, n.scrollDOM.scrollLeft = n.inputState.lastScrollLeft), rh(n);
};
It.blur = (n) => {
  n.observer.clearSelectionRange(), rh(n);
};
It.compositionstart = It.compositionupdate = (n) => {
  n.inputState.compositionFirstChange == null && (n.inputState.compositionFirstChange = !0), n.inputState.composing < 0 && (n.inputState.composing = 0);
};
It.compositionend = (n) => {
  n.inputState.composing = -1, n.inputState.compositionEndedAt = Date.now(), n.inputState.compositionPendingKey = !0, n.inputState.compositionPendingChange = n.observer.pendingRecords().length > 0, n.inputState.compositionFirstChange = null, C.chrome && C.android ? n.observer.flushSoon() : n.inputState.compositionPendingChange ? Promise.resolve().then(() => n.observer.flush()) : setTimeout(() => {
    n.inputState.composing < 0 && n.docView.hasComposition && n.update([]);
  }, 50);
};
It.contextmenu = (n) => {
  n.inputState.lastContextMenu = Date.now();
};
Nt.beforeinput = (n, t) => {
  var e;
  let i;
  if (C.chrome && C.android && (i = Jl.find((s) => s.inputType == t.inputType)) && (n.observer.delayAndroidKey(i.key, i.keyCode), i.key == "Backspace" || i.key == "Delete")) {
    let s = ((e = window.visualViewport) === null || e === void 0 ? void 0 : e.height) || 0;
    setTimeout(() => {
      var r;
      (((r = window.visualViewport) === null || r === void 0 ? void 0 : r.height) || 0) > s + 10 && n.hasFocus && (n.contentDOM.blur(), n.focus());
    }, 100);
  }
  return !1;
};
const to = /* @__PURE__ */ new Set();
function su(n) {
  to.has(n) || (to.add(n), n.addEventListener("copy", () => {
  }), n.addEventListener("cut", () => {
  }));
}
const eo = ["pre-wrap", "normal", "pre-line", "break-spaces"];
class nu {
  constructor(t) {
    this.lineWrapping = t, this.doc = V.empty, this.heightSamples = {}, this.lineHeight = 14, this.charWidth = 7, this.textHeight = 14, this.lineLength = 30, this.heightChanged = !1;
  }
  heightForGap(t, e) {
    let i = this.doc.lineAt(e).number - this.doc.lineAt(t).number + 1;
    return this.lineWrapping && (i += Math.max(0, Math.ceil((e - t - i * this.lineLength * 0.5) / this.lineLength))), this.lineHeight * i;
  }
  heightForLine(t) {
    return this.lineWrapping ? (1 + Math.max(0, Math.ceil((t - this.lineLength) / (this.lineLength - 5)))) * this.lineHeight : this.lineHeight;
  }
  setDoc(t) {
    return this.doc = t, this;
  }
  mustRefreshForWrapping(t) {
    return eo.indexOf(t) > -1 != this.lineWrapping;
  }
  mustRefreshForHeights(t) {
    let e = !1;
    for (let i = 0; i < t.length; i++) {
      let s = t[i];
      s < 0 ? i++ : this.heightSamples[Math.floor(s * 10)] || (e = !0, this.heightSamples[Math.floor(s * 10)] = !0);
    }
    return e;
  }
  refresh(t, e, i, s, r, o) {
    let l = eo.indexOf(t) > -1, h = Math.round(e) != Math.round(this.lineHeight) || this.lineWrapping != l;
    if (this.lineWrapping = l, this.lineHeight = e, this.charWidth = i, this.textHeight = s, this.lineLength = r, h) {
      this.heightSamples = {};
      for (let a = 0; a < o.length; a++) {
        let c = o[a];
        c < 0 ? a++ : this.heightSamples[Math.floor(c * 10)] = !0;
      }
    }
    return h;
  }
}
class ru {
  constructor(t, e) {
    this.from = t, this.heights = e, this.index = 0;
  }
  get more() {
    return this.index < this.heights.length;
  }
}
class Gt {
  /**
  @internal
  */
  constructor(t, e, i, s, r) {
    this.from = t, this.length = e, this.top = i, this.height = s, this._content = r;
  }
  /**
  The type of element this is. When querying lines, this may be
  an array of all the blocks that make up the line.
  */
  get type() {
    return typeof this._content == "number" ? Lt.Text : Array.isArray(this._content) ? this._content : this._content.type;
  }
  /**
  The end of the element as a document position.
  */
  get to() {
    return this.from + this.length;
  }
  /**
  The bottom position of the element.
  */
  get bottom() {
    return this.top + this.height;
  }
  /**
  If this is a widget block, this will return the widget
  associated with it.
  */
  get widget() {
    return this._content instanceof be ? this._content.widget : null;
  }
  /**
  If this is a textblock, this holds the number of line breaks
  that appear in widgets inside the block.
  */
  get widgetLineBreaks() {
    return typeof this._content == "number" ? this._content : 0;
  }
  /**
  @internal
  */
  join(t) {
    let e = (Array.isArray(this._content) ? this._content : [this]).concat(Array.isArray(t._content) ? t._content : [t]);
    return new Gt(this.from, this.length + t.length, this.top, this.height + t.height, e);
  }
}
var j = /* @__PURE__ */ function(n) {
  return n[n.ByPos = 0] = "ByPos", n[n.ByHeight = 1] = "ByHeight", n[n.ByPosNoHeight = 2] = "ByPosNoHeight", n;
}(j || (j = {}));
const is = 1e-3;
class pt {
  constructor(t, e, i = 2) {
    this.length = t, this.height = e, this.flags = i;
  }
  get outdated() {
    return (this.flags & 2) > 0;
  }
  set outdated(t) {
    this.flags = (t ? 2 : 0) | this.flags & -3;
  }
  setHeight(t, e) {
    this.height != e && (Math.abs(this.height - e) > is && (t.heightChanged = !0), this.height = e);
  }
  // Base case is to replace a leaf node, which simply builds a tree
  // from the new nodes and returns that (HeightMapBranch and
  // HeightMapGap override this to actually use from/to)
  replace(t, e, i) {
    return pt.of(i);
  }
  // Again, these are base cases, and are overridden for branch and gap nodes.
  decomposeLeft(t, e) {
    e.push(this);
  }
  decomposeRight(t, e) {
    e.push(this);
  }
  applyChanges(t, e, i, s) {
    let r = this, o = i.doc;
    for (let l = s.length - 1; l >= 0; l--) {
      let { fromA: h, toA: a, fromB: c, toB: f } = s[l], u = r.lineAt(h, j.ByPosNoHeight, i.setDoc(e), 0, 0), d = u.to >= a ? u : r.lineAt(a, j.ByPosNoHeight, i, 0, 0);
      for (f += d.to - a, a = d.to; l > 0 && u.from <= s[l - 1].toA; )
        h = s[l - 1].fromA, c = s[l - 1].fromB, l--, h < u.from && (u = r.lineAt(h, j.ByPosNoHeight, i, 0, 0));
      c += u.from - h, h = u.from;
      let p = sr.build(i.setDoc(o), t, c, f);
      r = r.replace(h, a, p);
    }
    return r.updateHeight(i, 0);
  }
  static empty() {
    return new xt(0, 0);
  }
  // nodes uses null values to indicate the position of line breaks.
  // There are never line breaks at the start or end of the array, or
  // two line breaks next to each other, and the array isn't allowed
  // to be empty (same restrictions as return value from the builder).
  static of(t) {
    if (t.length == 1)
      return t[0];
    let e = 0, i = t.length, s = 0, r = 0;
    for (; ; )
      if (e == i)
        if (s > r * 2) {
          let l = t[e - 1];
          l.break ? t.splice(--e, 1, l.left, null, l.right) : t.splice(--e, 1, l.left, l.right), i += 1 + l.break, s -= l.size;
        } else if (r > s * 2) {
          let l = t[i];
          l.break ? t.splice(i, 1, l.left, null, l.right) : t.splice(i, 1, l.left, l.right), i += 2 + l.break, r -= l.size;
        } else
          break;
      else if (s < r) {
        let l = t[e++];
        l && (s += l.size);
      } else {
        let l = t[--i];
        l && (r += l.size);
      }
    let o = 0;
    return t[e - 1] == null ? (o = 1, e--) : t[e] == null && (o = 1, i++), new ou(pt.of(t.slice(0, e)), o, pt.of(t.slice(i)));
  }
}
pt.prototype.size = 1;
class oh extends pt {
  constructor(t, e, i) {
    super(t, e), this.deco = i;
  }
  blockAt(t, e, i, s) {
    return new Gt(s, this.length, i, this.height, this.deco || 0);
  }
  lineAt(t, e, i, s, r) {
    return this.blockAt(0, i, s, r);
  }
  forEachLine(t, e, i, s, r, o) {
    t <= r + this.length && e >= r && o(this.blockAt(0, i, s, r));
  }
  updateHeight(t, e = 0, i = !1, s) {
    return s && s.from <= e && s.more && this.setHeight(t, s.heights[s.index++]), this.outdated = !1, this;
  }
  toString() {
    return `block(${this.length})`;
  }
}
class xt extends oh {
  constructor(t, e) {
    super(t, e, null), this.collapsed = 0, this.widgetHeight = 0, this.breaks = 0;
  }
  blockAt(t, e, i, s) {
    return new Gt(s, this.length, i, this.height, this.breaks);
  }
  replace(t, e, i) {
    let s = i[0];
    return i.length == 1 && (s instanceof xt || s instanceof rt && s.flags & 4) && Math.abs(this.length - s.length) < 10 ? (s instanceof rt ? s = new xt(s.length, this.height) : s.height = this.height, this.outdated || (s.outdated = !1), s) : pt.of(i);
  }
  updateHeight(t, e = 0, i = !1, s) {
    return s && s.from <= e && s.more ? this.setHeight(t, s.heights[s.index++]) : (i || this.outdated) && this.setHeight(t, Math.max(this.widgetHeight, t.heightForLine(this.length - this.collapsed)) + this.breaks * t.lineHeight), this.outdated = !1, this;
  }
  toString() {
    return `line(${this.length}${this.collapsed ? -this.collapsed : ""}${this.widgetHeight ? ":" + this.widgetHeight : ""})`;
  }
}
class rt extends pt {
  constructor(t) {
    super(t, 0);
  }
  heightMetrics(t, e) {
    let i = t.doc.lineAt(e).number, s = t.doc.lineAt(e + this.length).number, r = s - i + 1, o, l = 0;
    if (t.lineWrapping) {
      let h = Math.min(this.height, t.lineHeight * r);
      o = h / r, this.length > r + 1 && (l = (this.height - h) / (this.length - r - 1));
    } else
      o = this.height / r;
    return { firstLine: i, lastLine: s, perLine: o, perChar: l };
  }
  blockAt(t, e, i, s) {
    let { firstLine: r, lastLine: o, perLine: l, perChar: h } = this.heightMetrics(e, s);
    if (e.lineWrapping) {
      let a = s + Math.round(Math.max(0, Math.min(1, (t - i) / this.height)) * this.length), c = e.doc.lineAt(a), f = l + c.length * h, u = Math.max(i, t - f / 2);
      return new Gt(c.from, c.length, u, f, 0);
    } else {
      let a = Math.max(0, Math.min(o - r, Math.floor((t - i) / l))), { from: c, length: f } = e.doc.line(r + a);
      return new Gt(c, f, i + l * a, l, 0);
    }
  }
  lineAt(t, e, i, s, r) {
    if (e == j.ByHeight)
      return this.blockAt(t, i, s, r);
    if (e == j.ByPosNoHeight) {
      let { from: d, to: p } = i.doc.lineAt(t);
      return new Gt(d, p - d, 0, 0, 0);
    }
    let { firstLine: o, perLine: l, perChar: h } = this.heightMetrics(i, r), a = i.doc.lineAt(t), c = l + a.length * h, f = a.number - o, u = s + l * f + h * (a.from - r - f);
    return new Gt(a.from, a.length, Math.max(s, Math.min(u, s + this.height - c)), c, 0);
  }
  forEachLine(t, e, i, s, r, o) {
    t = Math.max(t, r), e = Math.min(e, r + this.length);
    let { firstLine: l, perLine: h, perChar: a } = this.heightMetrics(i, r);
    for (let c = t, f = s; c <= e; ) {
      let u = i.doc.lineAt(c);
      if (c == t) {
        let p = u.number - l;
        f += h * p + a * (t - r - p);
      }
      let d = h + a * u.length;
      o(new Gt(u.from, u.length, f, d, 0)), f += d, c = u.to + 1;
    }
  }
  replace(t, e, i) {
    let s = this.length - e;
    if (s > 0) {
      let r = i[i.length - 1];
      r instanceof rt ? i[i.length - 1] = new rt(r.length + s) : i.push(null, new rt(s - 1));
    }
    if (t > 0) {
      let r = i[0];
      r instanceof rt ? i[0] = new rt(t + r.length) : i.unshift(new rt(t - 1), null);
    }
    return pt.of(i);
  }
  decomposeLeft(t, e) {
    e.push(new rt(t - 1), null);
  }
  decomposeRight(t, e) {
    e.push(null, new rt(this.length - t - 1));
  }
  updateHeight(t, e = 0, i = !1, s) {
    let r = e + this.length;
    if (s && s.from <= e + this.length && s.more) {
      let o = [], l = Math.max(e, s.from), h = -1;
      for (s.from > e && o.push(new rt(s.from - e - 1).updateHeight(t, e)); l <= r && s.more; ) {
        let c = t.doc.lineAt(l).length;
        o.length && o.push(null);
        let f = s.heights[s.index++];
        h == -1 ? h = f : Math.abs(f - h) >= is && (h = -2);
        let u = new xt(c, f);
        u.outdated = !1, o.push(u), l += c + 1;
      }
      l <= r && o.push(null, new rt(r - l).updateHeight(t, l));
      let a = pt.of(o);
      return (h < 0 || Math.abs(a.height - this.height) >= is || Math.abs(h - this.heightMetrics(t, e).perLine) >= is) && (t.heightChanged = !0), a;
    } else
      (i || this.outdated) && (this.setHeight(t, t.heightForGap(e, e + this.length)), this.outdated = !1);
    return this;
  }
  toString() {
    return `gap(${this.length})`;
  }
}
class ou extends pt {
  constructor(t, e, i) {
    super(t.length + e + i.length, t.height + i.height, e | (t.outdated || i.outdated ? 2 : 0)), this.left = t, this.right = i, this.size = t.size + i.size;
  }
  get break() {
    return this.flags & 1;
  }
  blockAt(t, e, i, s) {
    let r = i + this.left.height;
    return t < r ? this.left.blockAt(t, e, i, s) : this.right.blockAt(t, e, r, s + this.left.length + this.break);
  }
  lineAt(t, e, i, s, r) {
    let o = s + this.left.height, l = r + this.left.length + this.break, h = e == j.ByHeight ? t < o : t < l, a = h ? this.left.lineAt(t, e, i, s, r) : this.right.lineAt(t, e, i, o, l);
    if (this.break || (h ? a.to < l : a.from > l))
      return a;
    let c = e == j.ByPosNoHeight ? j.ByPosNoHeight : j.ByPos;
    return h ? a.join(this.right.lineAt(l, c, i, o, l)) : this.left.lineAt(l, c, i, s, r).join(a);
  }
  forEachLine(t, e, i, s, r, o) {
    let l = s + this.left.height, h = r + this.left.length + this.break;
    if (this.break)
      t < h && this.left.forEachLine(t, e, i, s, r, o), e >= h && this.right.forEachLine(t, e, i, l, h, o);
    else {
      let a = this.lineAt(h, j.ByPos, i, s, r);
      t < a.from && this.left.forEachLine(t, a.from - 1, i, s, r, o), a.to >= t && a.from <= e && o(a), e > a.to && this.right.forEachLine(a.to + 1, e, i, l, h, o);
    }
  }
  replace(t, e, i) {
    let s = this.left.length + this.break;
    if (e < s)
      return this.balanced(this.left.replace(t, e, i), this.right);
    if (t > this.left.length)
      return this.balanced(this.left, this.right.replace(t - s, e - s, i));
    let r = [];
    t > 0 && this.decomposeLeft(t, r);
    let o = r.length;
    for (let l of i)
      r.push(l);
    if (t > 0 && io(r, o - 1), e < this.length) {
      let l = r.length;
      this.decomposeRight(e, r), io(r, l);
    }
    return pt.of(r);
  }
  decomposeLeft(t, e) {
    let i = this.left.length;
    if (t <= i)
      return this.left.decomposeLeft(t, e);
    e.push(this.left), this.break && (i++, t >= i && e.push(null)), t > i && this.right.decomposeLeft(t - i, e);
  }
  decomposeRight(t, e) {
    let i = this.left.length, s = i + this.break;
    if (t >= s)
      return this.right.decomposeRight(t - s, e);
    t < i && this.left.decomposeRight(t, e), this.break && t < s && e.push(null), e.push(this.right);
  }
  balanced(t, e) {
    return t.size > 2 * e.size || e.size > 2 * t.size ? pt.of(this.break ? [t, null, e] : [t, e]) : (this.left = t, this.right = e, this.height = t.height + e.height, this.outdated = t.outdated || e.outdated, this.size = t.size + e.size, this.length = t.length + this.break + e.length, this);
  }
  updateHeight(t, e = 0, i = !1, s) {
    let { left: r, right: o } = this, l = e + r.length + this.break, h = null;
    return s && s.from <= e + r.length && s.more ? h = r = r.updateHeight(t, e, i, s) : r.updateHeight(t, e, i), s && s.from <= l + o.length && s.more ? h = o = o.updateHeight(t, l, i, s) : o.updateHeight(t, l, i), h ? this.balanced(r, o) : (this.height = this.left.height + this.right.height, this.outdated = !1, this);
  }
  toString() {
    return this.left + (this.break ? " " : "-") + this.right;
  }
}
function io(n, t) {
  let e, i;
  n[t] == null && (e = n[t - 1]) instanceof rt && (i = n[t + 1]) instanceof rt && n.splice(t - 1, 3, new rt(e.length + 1 + i.length));
}
const lu = 5;
class sr {
  constructor(t, e) {
    this.pos = t, this.oracle = e, this.nodes = [], this.lineStart = -1, this.lineEnd = -1, this.covering = null, this.writtenTo = t;
  }
  get isCovered() {
    return this.covering && this.nodes[this.nodes.length - 1] == this.covering;
  }
  span(t, e) {
    if (this.lineStart > -1) {
      let i = Math.min(e, this.lineEnd), s = this.nodes[this.nodes.length - 1];
      s instanceof xt ? s.length += i - this.pos : (i > this.pos || !this.isCovered) && this.nodes.push(new xt(i - this.pos, -1)), this.writtenTo = i, e > i && (this.nodes.push(null), this.writtenTo++, this.lineStart = -1);
    }
    this.pos = e;
  }
  point(t, e, i) {
    if (t < e || i.heightRelevant) {
      let s = i.widget ? i.widget.estimatedHeight : 0, r = i.widget ? i.widget.lineBreaks : 0;
      s < 0 && (s = this.oracle.lineHeight);
      let o = e - t;
      i.block ? this.addBlock(new oh(o, s, i)) : (o || r || s >= lu) && this.addLineDeco(s, r, o);
    } else
      e > t && this.span(t, e);
    this.lineEnd > -1 && this.lineEnd < this.pos && (this.lineEnd = this.oracle.doc.lineAt(this.pos).to);
  }
  enterLine() {
    if (this.lineStart > -1)
      return;
    let { from: t, to: e } = this.oracle.doc.lineAt(this.pos);
    this.lineStart = t, this.lineEnd = e, this.writtenTo < t && ((this.writtenTo < t - 1 || this.nodes[this.nodes.length - 1] == null) && this.nodes.push(this.blankContent(this.writtenTo, t - 1)), this.nodes.push(null)), this.pos > t && this.nodes.push(new xt(this.pos - t, -1)), this.writtenTo = this.pos;
  }
  blankContent(t, e) {
    let i = new rt(e - t);
    return this.oracle.doc.lineAt(t).to == e && (i.flags |= 4), i;
  }
  ensureLine() {
    this.enterLine();
    let t = this.nodes.length ? this.nodes[this.nodes.length - 1] : null;
    if (t instanceof xt)
      return t;
    let e = new xt(0, -1);
    return this.nodes.push(e), e;
  }
  addBlock(t) {
    this.enterLine();
    let e = t.deco;
    e && e.startSide > 0 && !this.isCovered && this.ensureLine(), this.nodes.push(t), this.writtenTo = this.pos = this.pos + t.length, e && e.endSide > 0 && (this.covering = t);
  }
  addLineDeco(t, e, i) {
    let s = this.ensureLine();
    s.length += i, s.collapsed += i, s.widgetHeight = Math.max(s.widgetHeight, t), s.breaks += e, this.writtenTo = this.pos = this.pos + i;
  }
  finish(t) {
    let e = this.nodes.length == 0 ? null : this.nodes[this.nodes.length - 1];
    this.lineStart > -1 && !(e instanceof xt) && !this.isCovered ? this.nodes.push(new xt(0, -1)) : (this.writtenTo < this.pos || e == null) && this.nodes.push(this.blankContent(this.writtenTo, this.pos));
    let i = t;
    for (let s of this.nodes)
      s instanceof xt && s.updateHeight(this.oracle, i), i += s ? s.length : 1;
    return this.nodes;
  }
  // Always called with a region that on both sides either stretches
  // to a line break or the end of the document.
  // The returned array uses null to indicate line breaks, but never
  // starts or ends in a line break, or has multiple line breaks next
  // to each other.
  static build(t, e, i, s) {
    let r = new sr(i, t);
    return F.spans(e, i, s, r, 0), r.finish(i);
  }
}
function hu(n, t, e) {
  let i = new au();
  return F.compare(n, t, e, i, 0), i.changes;
}
class au {
  constructor() {
    this.changes = [];
  }
  compareRange() {
  }
  comparePoint(t, e, i, s) {
    (t < e || i && i.heightRelevant || s && s.heightRelevant) && Sn(t, e, this.changes, 5);
  }
}
function cu(n, t) {
  let e = n.getBoundingClientRect(), i = n.ownerDocument, s = i.defaultView || window, r = Math.max(0, e.left), o = Math.min(s.innerWidth, e.right), l = Math.max(0, e.top), h = Math.min(s.innerHeight, e.bottom);
  for (let a = n.parentNode; a && a != i.body; )
    if (a.nodeType == 1) {
      let c = a, f = window.getComputedStyle(c);
      if ((c.scrollHeight > c.clientHeight || c.scrollWidth > c.clientWidth) && f.overflow != "visible") {
        let u = c.getBoundingClientRect();
        r = Math.max(r, u.left), o = Math.min(o, u.right), l = Math.max(l, u.top), h = a == n.parentNode ? u.bottom : Math.min(h, u.bottom);
      }
      a = f.position == "absolute" || f.position == "fixed" ? c.offsetParent : c.parentNode;
    } else if (a.nodeType == 11)
      a = a.host;
    else
      break;
  return {
    left: r - e.left,
    right: Math.max(r, o) - e.left,
    top: l - (e.top + t),
    bottom: Math.max(l, h) - (e.top + t)
  };
}
function fu(n, t) {
  let e = n.getBoundingClientRect();
  return {
    left: 0,
    right: e.right - e.left,
    top: t,
    bottom: e.bottom - (e.top + t)
  };
}
class js {
  constructor(t, e, i) {
    this.from = t, this.to = e, this.size = i;
  }
  static same(t, e) {
    if (t.length != e.length)
      return !1;
    for (let i = 0; i < t.length; i++) {
      let s = t[i], r = e[i];
      if (s.from != r.from || s.to != r.to || s.size != r.size)
        return !1;
    }
    return !0;
  }
  draw(t, e) {
    return N.replace({
      widget: new uu(this.size * (e ? t.scaleY : t.scaleX), e)
    }).range(this.from, this.to);
  }
}
class uu extends Se {
  constructor(t, e) {
    super(), this.size = t, this.vertical = e;
  }
  eq(t) {
    return t.size == this.size && t.vertical == this.vertical;
  }
  toDOM() {
    let t = document.createElement("div");
    return this.vertical ? t.style.height = this.size + "px" : (t.style.width = this.size + "px", t.style.height = "2px", t.style.display = "inline-block"), t;
  }
  get estimatedHeight() {
    return this.vertical ? this.size : -1;
  }
}
class so {
  constructor(t) {
    this.state = t, this.pixelViewport = { left: 0, right: window.innerWidth, top: 0, bottom: 0 }, this.inView = !0, this.paddingTop = 0, this.paddingBottom = 0, this.contentDOMWidth = 0, this.contentDOMHeight = 0, this.editorHeight = 0, this.editorWidth = 0, this.scrollTop = 0, this.scrolledToBottom = !0, this.scaleX = 1, this.scaleY = 1, this.scrollAnchorPos = 0, this.scrollAnchorHeight = -1, this.scaler = no, this.scrollTarget = null, this.printing = !1, this.mustMeasureContent = !0, this.defaultTextDirection = tt.LTR, this.visibleRanges = [], this.mustEnforceCursorAssoc = !1;
    let e = t.facet(er).some((i) => typeof i != "function" && i.class == "cm-lineWrapping");
    this.heightOracle = new nu(e), this.stateDeco = t.facet(xi).filter((i) => typeof i != "function"), this.heightMap = pt.empty().applyChanges(this.stateDeco, V.empty, this.heightOracle.setDoc(t.doc), [new Mt(0, 0, 0, t.doc.length)]), this.viewport = this.getViewport(0, null), this.updateViewportLines(), this.updateForViewport(), this.lineGaps = this.ensureLineGaps([]), this.lineGapDeco = N.set(this.lineGaps.map((i) => i.draw(this, !1))), this.computeVisibleRanges();
  }
  updateForViewport() {
    let t = [this.viewport], { main: e } = this.state.selection;
    for (let i = 0; i <= 1; i++) {
      let s = i ? e.head : e.anchor;
      if (!t.some(({ from: r, to: o }) => s >= r && s <= o)) {
        let { from: r, to: o } = this.lineBlockAt(s);
        t.push(new $i(r, o));
      }
    }
    this.viewports = t.sort((i, s) => i.from - s.from), this.scaler = this.heightMap.height <= 7e6 ? no : new gu(this.heightOracle, this.heightMap, this.viewports);
  }
  updateViewportLines() {
    this.viewportLines = [], this.heightMap.forEachLine(this.viewport.from, this.viewport.to, this.heightOracle.setDoc(this.state.doc), 0, 0, (t) => {
      this.viewportLines.push(this.scaler.scale == 1 ? t : ci(t, this.scaler));
    });
  }
  update(t, e = null) {
    this.state = t.state;
    let i = this.stateDeco;
    this.stateDeco = this.state.facet(xi).filter((c) => typeof c != "function");
    let s = t.changedRanges, r = Mt.extendWithRanges(s, hu(i, this.stateDeco, t ? t.changes : it.empty(this.state.doc.length))), o = this.heightMap.height, l = this.scrolledToBottom ? null : this.scrollAnchorAt(this.scrollTop);
    this.heightMap = this.heightMap.applyChanges(this.stateDeco, t.startState.doc, this.heightOracle.setDoc(this.state.doc), r), this.heightMap.height != o && (t.flags |= 2), l ? (this.scrollAnchorPos = t.changes.mapPos(l.from, -1), this.scrollAnchorHeight = l.top) : (this.scrollAnchorPos = -1, this.scrollAnchorHeight = this.heightMap.height);
    let h = r.length ? this.mapViewport(this.viewport, t.changes) : this.viewport;
    (e && (e.range.head < h.from || e.range.head > h.to) || !this.viewportIsAppropriate(h)) && (h = this.getViewport(0, e));
    let a = !t.changes.empty || t.flags & 2 || h.from != this.viewport.from || h.to != this.viewport.to;
    this.viewport = h, this.updateForViewport(), a && this.updateViewportLines(), (this.lineGaps.length || this.viewport.to - this.viewport.from > 4e3) && this.updateLineGaps(this.ensureLineGaps(this.mapLineGaps(this.lineGaps, t.changes))), t.flags |= this.computeVisibleRanges(), e && (this.scrollTarget = e), !this.mustEnforceCursorAssoc && t.selectionSet && t.view.lineWrapping && t.state.selection.main.empty && t.state.selection.main.assoc && !t.state.facet(pf) && (this.mustEnforceCursorAssoc = !0);
  }
  measure(t) {
    let e = t.contentDOM, i = window.getComputedStyle(e), s = this.heightOracle, r = i.whiteSpace;
    this.defaultTextDirection = i.direction == "rtl" ? tt.RTL : tt.LTR;
    let o = this.heightOracle.mustRefreshForWrapping(r), l = e.getBoundingClientRect(), h = o || this.mustMeasureContent || this.contentDOMHeight != l.height;
    this.contentDOMHeight = l.height, this.mustMeasureContent = !1;
    let a = 0, c = 0;
    if (l.width && l.height) {
      let v = l.width / e.offsetWidth, A = l.height / e.offsetHeight;
      (v > 0.995 && v < 1.005 || !isFinite(v) || Math.abs(l.width - e.offsetWidth) < 1) && (v = 1), (A > 0.995 && A < 1.005 || !isFinite(A) || Math.abs(l.height - e.offsetHeight) < 1) && (A = 1), (this.scaleX != v || this.scaleY != A) && (this.scaleX = v, this.scaleY = A, a |= 8, o = h = !0);
    }
    let f = (parseInt(i.paddingTop) || 0) * this.scaleY, u = (parseInt(i.paddingBottom) || 0) * this.scaleY;
    (this.paddingTop != f || this.paddingBottom != u) && (this.paddingTop = f, this.paddingBottom = u, a |= 10), this.editorWidth != t.scrollDOM.clientWidth && (s.lineWrapping && (h = !0), this.editorWidth = t.scrollDOM.clientWidth, a |= 8);
    let d = t.scrollDOM.scrollTop * this.scaleY;
    this.scrollTop != d && (this.scrollAnchorHeight = -1, this.scrollTop = d), this.scrolledToBottom = vl(t.scrollDOM);
    let p = (this.printing ? fu : cu)(e, this.paddingTop), m = p.top - this.pixelViewport.top, g = p.bottom - this.pixelViewport.bottom;
    this.pixelViewport = p;
    let y = this.pixelViewport.bottom > this.pixelViewport.top && this.pixelViewport.right > this.pixelViewport.left;
    if (y != this.inView && (this.inView = y, y && (h = !0)), !this.inView && !this.scrollTarget)
      return 0;
    let x = l.width;
    if ((this.contentDOMWidth != x || this.editorHeight != t.scrollDOM.clientHeight) && (this.contentDOMWidth = l.width, this.editorHeight = t.scrollDOM.clientHeight, a |= 8), h) {
      let v = t.docView.measureVisibleLineHeights(this.viewport);
      if (s.mustRefreshForHeights(v) && (o = !0), o || s.lineWrapping && Math.abs(x - this.contentDOMWidth) > s.charWidth) {
        let { lineHeight: A, charWidth: P, textHeight: M } = t.docView.measureTextSize();
        o = A > 0 && s.refresh(r, A, P, M, x / P, v), o && (t.docView.minWidth = 0, a |= 8);
      }
      m > 0 && g > 0 ? c = Math.max(m, g) : m < 0 && g < 0 && (c = Math.min(m, g)), s.heightChanged = !1;
      for (let A of this.viewports) {
        let P = A.from == this.viewport.from ? v : t.docView.measureVisibleLineHeights(A);
        this.heightMap = (o ? pt.empty().applyChanges(this.stateDeco, V.empty, this.heightOracle, [new Mt(0, 0, 0, t.state.doc.length)]) : this.heightMap).updateHeight(s, 0, o, new ru(A.from, P));
      }
      s.heightChanged && (a |= 2);
    }
    let S = !this.viewportIsAppropriate(this.viewport, c) || this.scrollTarget && (this.scrollTarget.range.head < this.viewport.from || this.scrollTarget.range.head > this.viewport.to);
    return S && (this.viewport = this.getViewport(c, this.scrollTarget)), this.updateForViewport(), (a & 2 || S) && this.updateViewportLines(), (this.lineGaps.length || this.viewport.to - this.viewport.from > 4e3) && this.updateLineGaps(this.ensureLineGaps(o ? [] : this.lineGaps, t)), a |= this.computeVisibleRanges(), this.mustEnforceCursorAssoc && (this.mustEnforceCursorAssoc = !1, t.docView.enforceCursorAssoc()), a;
  }
  get visibleTop() {
    return this.scaler.fromDOM(this.pixelViewport.top);
  }
  get visibleBottom() {
    return this.scaler.fromDOM(this.pixelViewport.bottom);
  }
  getViewport(t, e) {
    let i = 0.5 - Math.max(-0.5, Math.min(0.5, t / 1e3 / 2)), s = this.heightMap, r = this.heightOracle, { visibleTop: o, visibleBottom: l } = this, h = new $i(s.lineAt(o - i * 1e3, j.ByHeight, r, 0, 0).from, s.lineAt(l + (1 - i) * 1e3, j.ByHeight, r, 0, 0).to);
    if (e) {
      let { head: a } = e.range;
      if (a < h.from || a > h.to) {
        let c = Math.min(this.editorHeight, this.pixelViewport.bottom - this.pixelViewport.top), f = s.lineAt(a, j.ByPos, r, 0, 0), u;
        e.y == "center" ? u = (f.top + f.bottom) / 2 - c / 2 : e.y == "start" || e.y == "nearest" && a < h.from ? u = f.top : u = f.bottom - c, h = new $i(s.lineAt(u - 1e3 / 2, j.ByHeight, r, 0, 0).from, s.lineAt(u + c + 1e3 / 2, j.ByHeight, r, 0, 0).to);
      }
    }
    return h;
  }
  mapViewport(t, e) {
    let i = e.mapPos(t.from, -1), s = e.mapPos(t.to, 1);
    return new $i(this.heightMap.lineAt(i, j.ByPos, this.heightOracle, 0, 0).from, this.heightMap.lineAt(s, j.ByPos, this.heightOracle, 0, 0).to);
  }
  // Checks if a given viewport covers the visible part of the
  // document and not too much beyond that.
  viewportIsAppropriate({ from: t, to: e }, i = 0) {
    if (!this.inView)
      return !0;
    let { top: s } = this.heightMap.lineAt(t, j.ByPos, this.heightOracle, 0, 0), { bottom: r } = this.heightMap.lineAt(e, j.ByPos, this.heightOracle, 0, 0), { visibleTop: o, visibleBottom: l } = this;
    return (t == 0 || s <= o - Math.max(10, Math.min(
      -i,
      250
      /* VP.MaxCoverMargin */
    ))) && (e == this.state.doc.length || r >= l + Math.max(10, Math.min(
      i,
      250
      /* VP.MaxCoverMargin */
    ))) && s > o - 2 * 1e3 && r < l + 2 * 1e3;
  }
  mapLineGaps(t, e) {
    if (!t.length || e.empty)
      return t;
    let i = [];
    for (let s of t)
      e.touchesRange(s.from, s.to) || i.push(new js(e.mapPos(s.from), e.mapPos(s.to), s.size));
    return i;
  }
  // Computes positions in the viewport where the start or end of a
  // line should be hidden, trying to reuse existing line gaps when
  // appropriate to avoid unneccesary redraws.
  // Uses crude character-counting for the positioning and sizing,
  // since actual DOM coordinates aren't always available and
  // predictable. Relies on generous margins (see LG.Margin) to hide
  // the artifacts this might produce from the user.
  ensureLineGaps(t, e) {
    let i = this.heightOracle.lineWrapping, s = i ? 1e4 : 2e3, r = s >> 1, o = s << 1;
    if (this.defaultTextDirection != tt.LTR && !i)
      return [];
    let l = [], h = (a, c, f, u) => {
      if (c - a < r)
        return;
      let d = this.state.selection.main, p = [d.from];
      d.empty || p.push(d.to);
      for (let g of p)
        if (g > a && g < c) {
          h(a, g - 10, f, u), h(g + 10, c, f, u);
          return;
        }
      let m = pu(t, (g) => g.from >= f.from && g.to <= f.to && Math.abs(g.from - a) < r && Math.abs(g.to - c) < r && !p.some((y) => g.from < y && g.to > y));
      if (!m) {
        if (c < f.to && e && i && e.visibleRanges.some((g) => g.from <= c && g.to >= c)) {
          let g = e.moveToLineBoundary(b.cursor(c), !1, !0).head;
          g > a && (c = g);
        }
        m = new js(a, c, this.gapSize(f, a, c, u));
      }
      l.push(m);
    };
    for (let a of this.viewportLines) {
      if (a.length < o)
        continue;
      let c = du(a.from, a.to, this.stateDeco);
      if (c.total < o)
        continue;
      let f = this.scrollTarget ? this.scrollTarget.range.head : null, u, d;
      if (i) {
        let p = s / this.heightOracle.lineLength * this.heightOracle.lineHeight, m, g;
        if (f != null) {
          let y = _i(c, f), x = ((this.visibleBottom - this.visibleTop) / 2 + p) / a.height;
          m = y - x, g = y + x;
        } else
          m = (this.visibleTop - a.top - p) / a.height, g = (this.visibleBottom - a.top + p) / a.height;
        u = Fi(c, m), d = Fi(c, g);
      } else {
        let p = c.total * this.heightOracle.charWidth, m = s * this.heightOracle.charWidth, g, y;
        if (f != null) {
          let x = _i(c, f), S = ((this.pixelViewport.right - this.pixelViewport.left) / 2 + m) / p;
          g = x - S, y = x + S;
        } else
          g = (this.pixelViewport.left - m) / p, y = (this.pixelViewport.right + m) / p;
        u = Fi(c, g), d = Fi(c, y);
      }
      u > a.from && h(a.from, u, a, c), d < a.to && h(d, a.to, a, c);
    }
    return l;
  }
  gapSize(t, e, i, s) {
    let r = _i(s, i) - _i(s, e);
    return this.heightOracle.lineWrapping ? t.height * r : s.total * this.heightOracle.charWidth * r;
  }
  updateLineGaps(t) {
    js.same(t, this.lineGaps) || (this.lineGaps = t, this.lineGapDeco = N.set(t.map((e) => e.draw(this, this.heightOracle.lineWrapping))));
  }
  computeVisibleRanges() {
    let t = this.stateDeco;
    this.lineGaps.length && (t = t.concat(this.lineGapDeco));
    let e = [];
    F.spans(t, this.viewport.from, this.viewport.to, {
      span(s, r) {
        e.push({ from: s, to: r });
      },
      point() {
      }
    }, 20);
    let i = e.length != this.visibleRanges.length || this.visibleRanges.some((s, r) => s.from != e[r].from || s.to != e[r].to);
    return this.visibleRanges = e, i ? 4 : 0;
  }
  lineBlockAt(t) {
    return t >= this.viewport.from && t <= this.viewport.to && this.viewportLines.find((e) => e.from <= t && e.to >= t) || ci(this.heightMap.lineAt(t, j.ByPos, this.heightOracle, 0, 0), this.scaler);
  }
  lineBlockAtHeight(t) {
    return ci(this.heightMap.lineAt(this.scaler.fromDOM(t), j.ByHeight, this.heightOracle, 0, 0), this.scaler);
  }
  scrollAnchorAt(t) {
    let e = this.lineBlockAtHeight(t + 8);
    return e.from >= this.viewport.from || this.viewportLines[0].top - t > 200 ? e : this.viewportLines[0];
  }
  elementAtHeight(t) {
    return ci(this.heightMap.blockAt(this.scaler.fromDOM(t), this.heightOracle, 0, 0), this.scaler);
  }
  get docHeight() {
    return this.scaler.toDOM(this.heightMap.height);
  }
  get contentHeight() {
    return this.docHeight + this.paddingTop + this.paddingBottom;
  }
}
class $i {
  constructor(t, e) {
    this.from = t, this.to = e;
  }
}
function du(n, t, e) {
  let i = [], s = n, r = 0;
  return F.spans(e, n, t, {
    span() {
    },
    point(o, l) {
      o > s && (i.push({ from: s, to: o }), r += o - s), s = l;
    }
  }, 20), s < t && (i.push({ from: s, to: t }), r += t - s), { total: r, ranges: i };
}
function Fi({ total: n, ranges: t }, e) {
  if (e <= 0)
    return t[0].from;
  if (e >= 1)
    return t[t.length - 1].to;
  let i = Math.floor(n * e);
  for (let s = 0; ; s++) {
    let { from: r, to: o } = t[s], l = o - r;
    if (i <= l)
      return r + i;
    i -= l;
  }
}
function _i(n, t) {
  let e = 0;
  for (let { from: i, to: s } of n.ranges) {
    if (t <= s) {
      e += t - i;
      break;
    }
    e += s - i;
  }
  return e / n.total;
}
function pu(n, t) {
  for (let e of n)
    if (t(e))
      return e;
}
const no = {
  toDOM(n) {
    return n;
  },
  fromDOM(n) {
    return n;
  },
  scale: 1
};
class gu {
  constructor(t, e, i) {
    let s = 0, r = 0, o = 0;
    this.viewports = i.map(({ from: l, to: h }) => {
      let a = e.lineAt(l, j.ByPos, t, 0, 0).top, c = e.lineAt(h, j.ByPos, t, 0, 0).bottom;
      return s += c - a, { from: l, to: h, top: a, bottom: c, domTop: 0, domBottom: 0 };
    }), this.scale = (7e6 - s) / (e.height - s);
    for (let l of this.viewports)
      l.domTop = o + (l.top - r) * this.scale, o = l.domBottom = l.domTop + (l.bottom - l.top), r = l.bottom;
  }
  toDOM(t) {
    for (let e = 0, i = 0, s = 0; ; e++) {
      let r = e < this.viewports.length ? this.viewports[e] : null;
      if (!r || t < r.top)
        return s + (t - i) * this.scale;
      if (t <= r.bottom)
        return r.domTop + (t - r.top);
      i = r.bottom, s = r.domBottom;
    }
  }
  fromDOM(t) {
    for (let e = 0, i = 0, s = 0; ; e++) {
      let r = e < this.viewports.length ? this.viewports[e] : null;
      if (!r || t < r.domTop)
        return i + (t - s) / this.scale;
      if (t <= r.domBottom)
        return r.top + (t - r.domTop);
      i = r.bottom, s = r.domBottom;
    }
  }
}
function ci(n, t) {
  if (t.scale == 1)
    return n;
  let e = t.toDOM(n.top), i = t.toDOM(n.bottom);
  return new Gt(n.from, n.length, e, i - e, Array.isArray(n._content) ? n._content.map((s) => ci(s, t)) : n._content);
}
const zi = /* @__PURE__ */ O.define({ combine: (n) => n.join(" ") }), Pn = /* @__PURE__ */ O.define({ combine: (n) => n.indexOf(!0) > -1 }), Bn = /* @__PURE__ */ we.newName(), lh = /* @__PURE__ */ we.newName(), hh = /* @__PURE__ */ we.newName(), ah = { "&light": "." + lh, "&dark": "." + hh };
function Rn(n, t, e) {
  return new we(t, {
    finish(i) {
      return /&/.test(i) ? i.replace(/&\w*/, (s) => {
        if (s == "&")
          return n;
        if (!e || !e[s])
          throw new RangeError(`Unsupported selector: ${s}`);
        return e[s];
      }) : n + " " + i;
    }
  });
}
const mu = /* @__PURE__ */ Rn("." + Bn, {
  "&": {
    position: "relative !important",
    boxSizing: "border-box",
    "&.cm-focused": {
      // Provide a simple default outline to make sure a focused
      // editor is visually distinct. Can't leave the default behavior
      // because that will apply to the content element, which is
      // inside the scrollable container and doesn't include the
      // gutters. We also can't use an 'auto' outline, since those
      // are, for some reason, drawn behind the element content, which
      // will cause things like the active line background to cover
      // the outline (#297).
      outline: "1px dotted #212121"
    },
    display: "flex !important",
    flexDirection: "column"
  },
  ".cm-scroller": {
    display: "flex !important",
    alignItems: "flex-start !important",
    fontFamily: "monospace",
    lineHeight: 1.4,
    height: "100%",
    overflowX: "auto",
    position: "relative",
    zIndex: 0
  },
  ".cm-content": {
    margin: 0,
    flexGrow: 2,
    flexShrink: 0,
    display: "block",
    whiteSpace: "pre",
    wordWrap: "normal",
    boxSizing: "border-box",
    minHeight: "100%",
    padding: "4px 0",
    outline: "none",
    "&[contenteditable=true]": {
      WebkitUserModify: "read-write-plaintext-only"
    }
  },
  ".cm-lineWrapping": {
    whiteSpace_fallback: "pre-wrap",
    whiteSpace: "break-spaces",
    wordBreak: "break-word",
    overflowWrap: "anywhere",
    flexShrink: 1
  },
  "&light .cm-content": { caretColor: "black" },
  "&dark .cm-content": { caretColor: "white" },
  ".cm-line": {
    display: "block",
    padding: "0 2px 0 6px"
  },
  ".cm-layer": {
    position: "absolute",
    left: 0,
    top: 0,
    contain: "size style",
    "& > *": {
      position: "absolute"
    }
  },
  "&light .cm-selectionBackground": {
    background: "#d9d9d9"
  },
  "&dark .cm-selectionBackground": {
    background: "#222"
  },
  "&light.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground": {
    background: "#d7d4f0"
  },
  "&dark.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground": {
    background: "#233"
  },
  ".cm-cursorLayer": {
    pointerEvents: "none"
  },
  "&.cm-focused > .cm-scroller > .cm-cursorLayer": {
    animation: "steps(1) cm-blink 1.2s infinite"
  },
  // Two animations defined so that we can switch between them to
  // restart the animation without forcing another style
  // recomputation.
  "@keyframes cm-blink": { "0%": {}, "50%": { opacity: 0 }, "100%": {} },
  "@keyframes cm-blink2": { "0%": {}, "50%": { opacity: 0 }, "100%": {} },
  ".cm-cursor, .cm-dropCursor": {
    borderLeft: "1.2px solid black",
    marginLeft: "-0.6px",
    pointerEvents: "none"
  },
  ".cm-cursor": {
    display: "none"
  },
  "&dark .cm-cursor": {
    borderLeftColor: "#444"
  },
  ".cm-dropCursor": {
    position: "absolute"
  },
  "&.cm-focused > .cm-scroller > .cm-cursorLayer .cm-cursor": {
    display: "block"
  },
  "&light .cm-activeLine": { backgroundColor: "#cceeff44" },
  "&dark .cm-activeLine": { backgroundColor: "#99eeff33" },
  "&light .cm-specialChar": { color: "red" },
  "&dark .cm-specialChar": { color: "#f78" },
  ".cm-gutters": {
    flexShrink: 0,
    display: "flex",
    height: "100%",
    boxSizing: "border-box",
    insetInlineStart: 0,
    zIndex: 200
  },
  "&light .cm-gutters": {
    backgroundColor: "#f5f5f5",
    color: "#6c6c6c",
    borderRight: "1px solid #ddd"
  },
  "&dark .cm-gutters": {
    backgroundColor: "#333338",
    color: "#ccc"
  },
  ".cm-gutter": {
    display: "flex !important",
    flexDirection: "column",
    flexShrink: 0,
    boxSizing: "border-box",
    minHeight: "100%",
    overflow: "hidden"
  },
  ".cm-gutterElement": {
    boxSizing: "border-box"
  },
  ".cm-lineNumbers .cm-gutterElement": {
    padding: "0 3px 0 5px",
    minWidth: "20px",
    textAlign: "right",
    whiteSpace: "nowrap"
  },
  "&light .cm-activeLineGutter": {
    backgroundColor: "#e2f2ff"
  },
  "&dark .cm-activeLineGutter": {
    backgroundColor: "#222227"
  },
  ".cm-panels": {
    boxSizing: "border-box",
    position: "sticky",
    left: 0,
    right: 0
  },
  "&light .cm-panels": {
    backgroundColor: "#f5f5f5",
    color: "black"
  },
  "&light .cm-panels-top": {
    borderBottom: "1px solid #ddd"
  },
  "&light .cm-panels-bottom": {
    borderTop: "1px solid #ddd"
  },
  "&dark .cm-panels": {
    backgroundColor: "#333338",
    color: "white"
  },
  ".cm-tab": {
    display: "inline-block",
    overflow: "hidden",
    verticalAlign: "bottom"
  },
  ".cm-widgetBuffer": {
    verticalAlign: "text-top",
    height: "1em",
    width: 0,
    display: "inline"
  },
  ".cm-placeholder": {
    color: "#888",
    display: "inline-block",
    verticalAlign: "top"
  },
  ".cm-highlightSpace:before": {
    content: "attr(data-display)",
    position: "absolute",
    pointerEvents: "none",
    color: "#888"
  },
  ".cm-highlightTab": {
    backgroundImage: `url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="20"><path stroke="%23888" stroke-width="1" fill="none" d="M1 10H196L190 5M190 15L196 10M197 4L197 16"/></svg>')`,
    backgroundSize: "auto 100%",
    backgroundPosition: "right 90%",
    backgroundRepeat: "no-repeat"
  },
  ".cm-trailingSpace": {
    backgroundColor: "#ff332255"
  },
  ".cm-button": {
    verticalAlign: "middle",
    color: "inherit",
    fontSize: "70%",
    padding: ".2em 1em",
    borderRadius: "1px"
  },
  "&light .cm-button": {
    backgroundImage: "linear-gradient(#eff1f5, #d9d9df)",
    border: "1px solid #888",
    "&:active": {
      backgroundImage: "linear-gradient(#b4b4b4, #d0d3d6)"
    }
  },
  "&dark .cm-button": {
    backgroundImage: "linear-gradient(#393939, #111)",
    border: "1px solid #888",
    "&:active": {
      backgroundImage: "linear-gradient(#111, #333)"
    }
  },
  ".cm-textfield": {
    verticalAlign: "middle",
    color: "inherit",
    fontSize: "70%",
    border: "1px solid silver",
    padding: ".2em .5em"
  },
  "&light .cm-textfield": {
    backgroundColor: "white"
  },
  "&dark .cm-textfield": {
    border: "1px solid #555",
    backgroundColor: "inherit"
  }
}, ah), fi = "￿";
class wu {
  constructor(t, e) {
    this.points = t, this.text = "", this.lineSeparator = e.facet(H.lineSeparator);
  }
  append(t) {
    this.text += t;
  }
  lineBreak() {
    this.text += fi;
  }
  readRange(t, e) {
    if (!t)
      return this;
    let i = t.parentNode;
    for (let s = t; ; ) {
      this.findPointBefore(i, s);
      let r = this.text.length;
      this.readNode(s);
      let o = s.nextSibling;
      if (o == e)
        break;
      let l = q.get(s), h = q.get(o);
      (l && h ? l.breakAfter : (l ? l.breakAfter : ro(s)) || ro(o) && (s.nodeName != "BR" || s.cmIgnore) && this.text.length > r) && this.lineBreak(), s = o;
    }
    return this.findPointBefore(i, e), this;
  }
  readTextNode(t) {
    let e = t.nodeValue;
    for (let i of this.points)
      i.node == t && (i.pos = this.text.length + Math.min(i.offset, e.length));
    for (let i = 0, s = this.lineSeparator ? null : /\r\n?|\n/g; ; ) {
      let r = -1, o = 1, l;
      if (this.lineSeparator ? (r = e.indexOf(this.lineSeparator, i), o = this.lineSeparator.length) : (l = s.exec(e)) && (r = l.index, o = l[0].length), this.append(e.slice(i, r < 0 ? e.length : r)), r < 0)
        break;
      if (this.lineBreak(), o > 1)
        for (let h of this.points)
          h.node == t && h.pos > this.text.length && (h.pos -= o - 1);
      i = r + o;
    }
  }
  readNode(t) {
    if (t.cmIgnore)
      return;
    let e = q.get(t), i = e && e.overrideDOMText;
    if (i != null) {
      this.findPointInside(t, i.length);
      for (let s = i.iter(); !s.next().done; )
        s.lineBreak ? this.lineBreak() : this.append(s.value);
    } else
      t.nodeType == 3 ? this.readTextNode(t) : t.nodeName == "BR" ? t.nextSibling && this.lineBreak() : t.nodeType == 1 && this.readRange(t.firstChild, null);
  }
  findPointBefore(t, e) {
    for (let i of this.points)
      i.node == t && t.childNodes[i.offset] == e && (i.pos = this.text.length);
  }
  findPointInside(t, e) {
    for (let i of this.points)
      (t.nodeType == 3 ? i.node == t : t.contains(i.node)) && (i.pos = this.text.length + (yu(t, i.node, i.offset) ? e : 0));
  }
}
function yu(n, t, e) {
  for (; ; ) {
    if (!t || e < ne(t))
      return !1;
    if (t == n)
      return !0;
    e = ki(t) + 1, t = t.parentNode;
  }
}
function ro(n) {
  return n.nodeType == 1 && /^(DIV|P|LI|UL|OL|BLOCKQUOTE|DD|DT|H\d|SECTION|PRE)$/.test(n.nodeName);
}
class oo {
  constructor(t, e) {
    this.node = t, this.offset = e, this.pos = -1;
  }
}
class bu {
  constructor(t, e, i, s) {
    this.typeOver = s, this.bounds = null, this.text = "";
    let { impreciseHead: r, impreciseAnchor: o } = t.docView;
    if (t.state.readOnly && e > -1)
      this.newSel = null;
    else if (e > -1 && (this.bounds = t.docView.domBoundsAround(e, i, 0))) {
      let l = r || o ? [] : vu(t), h = new wu(l, t.state);
      h.readRange(this.bounds.startDOM, this.bounds.endDOM), this.text = h.text, this.newSel = Su(l, this.bounds.from);
    } else {
      let l = t.observer.selectionRange, h = r && r.node == l.focusNode && r.offset == l.focusOffset || !wn(t.contentDOM, l.focusNode) ? t.state.selection.main.head : t.docView.posFromDOM(l.focusNode, l.focusOffset), a = o && o.node == l.anchorNode && o.offset == l.anchorOffset || !wn(t.contentDOM, l.anchorNode) ? t.state.selection.main.anchor : t.docView.posFromDOM(l.anchorNode, l.anchorOffset);
      this.newSel = b.single(a, h);
    }
  }
}
function ch(n, t) {
  let e, { newSel: i } = t, s = n.state.selection.main, r = n.inputState.lastKeyTime > Date.now() - 100 ? n.inputState.lastKeyCode : -1;
  if (t.bounds) {
    let { from: o, to: l } = t.bounds, h = s.from, a = null;
    (r === 8 || C.android && t.text.length < l - o) && (h = s.to, a = "end");
    let c = xu(n.state.doc.sliceString(o, l, fi), t.text, h - o, a);
    c && (C.chrome && r == 13 && c.toB == c.from + 2 && t.text.slice(c.from, c.toB) == fi + fi && c.toB--, e = {
      from: o + c.from,
      to: o + c.toA,
      insert: V.of(t.text.slice(c.from, c.toB).split(fi))
    });
  } else
    i && (!n.hasFocus && n.state.facet(Bs) || i.main.eq(s)) && (i = null);
  if (!e && !i)
    return !1;
  if (!e && t.typeOver && !s.empty && i && i.main.empty ? e = { from: s.from, to: s.to, insert: n.state.doc.slice(s.from, s.to) } : e && e.from >= s.from && e.to <= s.to && (e.from != s.from || e.to != s.to) && s.to - s.from - (e.to - e.from) <= 4 ? e = {
    from: s.from,
    to: s.to,
    insert: n.state.doc.slice(s.from, e.from).append(e.insert).append(n.state.doc.slice(e.to, s.to))
  } : (C.mac || C.android) && e && e.from == e.to && e.from == s.head - 1 && /^\. ?$/.test(e.insert.toString()) && n.contentDOM.getAttribute("autocorrect") == "off" ? (i && e.insert.length == 2 && (i = b.single(i.main.anchor - 1, i.main.head - 1)), e = { from: s.from, to: s.to, insert: V.of([" "]) }) : C.chrome && e && e.from == e.to && e.from == s.head && e.insert.toString() == `
 ` && n.lineWrapping && (i && (i = b.single(i.main.anchor - 1, i.main.head - 1)), e = { from: s.from, to: s.to, insert: V.of([" "]) }), e) {
    if (C.ios && n.inputState.flushIOSKey() || C.android && (e.from == s.from && e.to == s.to && e.insert.length == 1 && e.insert.lines == 2 && Ke(n.contentDOM, "Enter", 13) || (e.from == s.from - 1 && e.to == s.to && e.insert.length == 0 || r == 8 && e.insert.length < e.to - e.from && e.to > s.head) && Ke(n.contentDOM, "Backspace", 8) || e.from == s.from && e.to == s.to + 1 && e.insert.length == 0 && Ke(n.contentDOM, "Delete", 46)))
      return !0;
    let o = e.insert.toString();
    n.inputState.composing >= 0 && n.inputState.composing++;
    let l, h = () => l || (l = ku(n, e, i));
    return n.state.facet(Il).some((a) => a(n, e.from, e.to, o, h)) || n.dispatch(h()), !0;
  } else if (i && !i.main.eq(s)) {
    let o = !1, l = "select";
    return n.inputState.lastSelectionTime > Date.now() - 50 && (n.inputState.lastSelectionOrigin == "select" && (o = !0), l = n.inputState.lastSelectionOrigin), n.dispatch({ selection: i, scrollIntoView: o, userEvent: l }), !0;
  } else
    return !1;
}
function ku(n, t, e) {
  let i, s = n.state, r = s.selection.main;
  if (t.from >= r.from && t.to <= r.to && t.to - t.from >= (r.to - r.from) / 3 && (!e || e.main.empty && e.main.from == t.from + t.insert.length) && n.inputState.composing < 0) {
    let l = r.from < t.from ? s.sliceDoc(r.from, t.from) : "", h = r.to > t.to ? s.sliceDoc(t.to, r.to) : "";
    i = s.replaceSelection(n.state.toText(l + t.insert.sliceString(0, void 0, n.state.lineBreak) + h));
  } else {
    let l = s.changes(t), h = e && e.main.to <= l.newLength ? e.main : void 0;
    if (s.selection.ranges.length > 1 && n.inputState.composing >= 0 && t.to <= r.to && t.to >= r.to - 10) {
      let a = n.state.sliceDoc(t.from, t.to), c, f = e && Ul(n, e.main.head);
      if (f) {
        let p = t.insert.length - (t.to - t.from);
        c = { from: f.from, to: f.to - p };
      } else
        c = n.state.doc.lineAt(r.head);
      let u = r.to - t.to, d = r.to - r.from;
      i = s.changeByRange((p) => {
        if (p.from == r.from && p.to == r.to)
          return { changes: l, range: h || p.map(l) };
        let m = p.to - u, g = m - a.length;
        if (p.to - p.from != d || n.state.sliceDoc(g, m) != a || // Unfortunately, there's no way to make multiple
        // changes in the same node work without aborting
        // composition, so cursors in the composition range are
        // ignored.
        p.to >= c.from && p.from <= c.to)
          return { range: p };
        let y = s.changes({ from: g, to: m, insert: t.insert }), x = p.to - r.to;
        return {
          changes: y,
          range: h ? b.range(Math.max(0, h.anchor + x), Math.max(0, h.head + x)) : p.map(y)
        };
      });
    } else
      i = {
        changes: l,
        selection: h && s.selection.replaceRange(h)
      };
  }
  let o = "input.type";
  return (n.composing || n.inputState.compositionPendingChange && n.inputState.compositionEndedAt > Date.now() - 50) && (n.inputState.compositionPendingChange = !1, o += ".compose", n.inputState.compositionFirstChange && (o += ".start", n.inputState.compositionFirstChange = !1)), s.update(i, { userEvent: o, scrollIntoView: !0 });
}
function xu(n, t, e, i) {
  let s = Math.min(n.length, t.length), r = 0;
  for (; r < s && n.charCodeAt(r) == t.charCodeAt(r); )
    r++;
  if (r == s && n.length == t.length)
    return null;
  let o = n.length, l = t.length;
  for (; o > 0 && l > 0 && n.charCodeAt(o - 1) == t.charCodeAt(l - 1); )
    o--, l--;
  if (i == "end") {
    let h = Math.max(0, r - Math.min(o, l));
    e -= o + h - r;
  }
  if (o < r && n.length < t.length) {
    let h = e <= r && e >= o ? r - e : 0;
    r -= h, l = r + (l - o), o = r;
  } else if (l < r) {
    let h = e <= r && e >= l ? r - e : 0;
    r -= h, o = r + (o - l), l = r;
  }
  return { from: r, toA: o, toB: l };
}
function vu(n) {
  let t = [];
  if (n.root.activeElement != n.contentDOM)
    return t;
  let { anchorNode: e, anchorOffset: i, focusNode: s, focusOffset: r } = n.observer.selectionRange;
  return e && (t.push(new oo(e, i)), (s != e || r != i) && t.push(new oo(s, r))), t;
}
function Su(n, t) {
  if (n.length == 0)
    return null;
  let e = n[0].pos, i = n.length == 2 ? n[1].pos : e;
  return e > -1 && i > -1 ? b.single(e + t, i + t) : null;
}
const Cu = {
  childList: !0,
  characterData: !0,
  subtree: !0,
  attributes: !0,
  characterDataOldValue: !0
}, Ks = C.ie && C.ie_version <= 11;
class Au {
  constructor(t) {
    this.view = t, this.active = !1, this.selectionRange = new of(), this.selectionChanged = !1, this.delayedFlush = -1, this.resizeTimeout = -1, this.queue = [], this.delayedAndroidKey = null, this.flushingAndroidKey = -1, this.lastChange = 0, this.scrollTargets = [], this.intersection = null, this.resizeScroll = null, this.intersecting = !1, this.gapIntersection = null, this.gaps = [], this.parentCheck = -1, this.dom = t.contentDOM, this.observer = new MutationObserver((e) => {
      for (let i of e)
        this.queue.push(i);
      (C.ie && C.ie_version <= 11 || C.ios && t.composing) && e.some((i) => i.type == "childList" && i.removedNodes.length || i.type == "characterData" && i.oldValue.length > i.target.nodeValue.length) ? this.flushSoon() : this.flush();
    }), Ks && (this.onCharData = (e) => {
      this.queue.push({
        target: e.target,
        type: "characterData",
        oldValue: e.prevValue
      }), this.flushSoon();
    }), this.onSelectionChange = this.onSelectionChange.bind(this), this.onResize = this.onResize.bind(this), this.onPrint = this.onPrint.bind(this), this.onScroll = this.onScroll.bind(this), typeof ResizeObserver == "function" && (this.resizeScroll = new ResizeObserver(() => {
      var e;
      ((e = this.view.docView) === null || e === void 0 ? void 0 : e.lastUpdate) < Date.now() - 75 && this.onResize();
    }), this.resizeScroll.observe(t.scrollDOM)), this.addWindowListeners(this.win = t.win), this.start(), typeof IntersectionObserver == "function" && (this.intersection = new IntersectionObserver((e) => {
      this.parentCheck < 0 && (this.parentCheck = setTimeout(this.listenForScroll.bind(this), 1e3)), e.length > 0 && e[e.length - 1].intersectionRatio > 0 != this.intersecting && (this.intersecting = !this.intersecting, this.intersecting != this.view.inView && this.onScrollChanged(document.createEvent("Event")));
    }, { threshold: [0, 1e-3] }), this.intersection.observe(this.dom), this.gapIntersection = new IntersectionObserver((e) => {
      e.length > 0 && e[e.length - 1].intersectionRatio > 0 && this.onScrollChanged(document.createEvent("Event"));
    }, {})), this.listenForScroll(), this.readSelectionRange();
  }
  onScrollChanged(t) {
    this.view.inputState.runHandlers("scroll", t), this.intersecting && this.view.measure();
  }
  onScroll(t) {
    this.intersecting && this.flush(!1), this.onScrollChanged(t);
  }
  onResize() {
    this.resizeTimeout < 0 && (this.resizeTimeout = setTimeout(() => {
      this.resizeTimeout = -1, this.view.requestMeasure();
    }, 50));
  }
  onPrint() {
    this.view.viewState.printing = !0, this.view.measure(), setTimeout(() => {
      this.view.viewState.printing = !1, this.view.requestMeasure();
    }, 500);
  }
  updateGaps(t) {
    if (this.gapIntersection && (t.length != this.gaps.length || this.gaps.some((e, i) => e != t[i]))) {
      this.gapIntersection.disconnect();
      for (let e of t)
        this.gapIntersection.observe(e);
      this.gaps = t;
    }
  }
  onSelectionChange(t) {
    let e = this.selectionChanged;
    if (!this.readSelectionRange() || this.delayedAndroidKey)
      return;
    let { view: i } = this, s = this.selectionRange;
    if (i.state.facet(Bs) ? i.root.activeElement != this.dom : !ts(i.dom, s))
      return;
    let r = s.anchorNode && i.docView.nearest(s.anchorNode);
    if (r && r.ignoreEvent(t)) {
      e || (this.selectionChanged = !1);
      return;
    }
    (C.ie && C.ie_version <= 11 || C.android && C.chrome) && !i.state.selection.main.empty && // (Selection.isCollapsed isn't reliable on IE)
    s.focusNode && ds(s.focusNode, s.focusOffset, s.anchorNode, s.anchorOffset) ? this.flushSoon() : this.flush(!1);
  }
  readSelectionRange() {
    let { view: t } = this, e = C.safari && t.root.nodeType == 11 && ef(this.dom.ownerDocument) == this.dom && Ou(this.view) || us(t.root);
    if (!e || this.selectionRange.eq(e))
      return !1;
    let i = ts(this.dom, e);
    return i && !this.selectionChanged && t.inputState.lastFocusTime > Date.now() - 200 && t.inputState.lastTouchTime < Date.now() - 300 && hf(this.dom, e) ? (this.view.inputState.lastFocusTime = 0, t.docView.updateSelection(), !1) : (this.selectionRange.setRange(e), i && (this.selectionChanged = !0), !0);
  }
  setSelectionRange(t, e) {
    this.selectionRange.set(t.node, t.offset, e.node, e.offset), this.selectionChanged = !1;
  }
  clearSelectionRange() {
    this.selectionRange.set(null, 0, null, 0);
  }
  listenForScroll() {
    this.parentCheck = -1;
    let t = 0, e = null;
    for (let i = this.dom; i; )
      if (i.nodeType == 1)
        !e && t < this.scrollTargets.length && this.scrollTargets[t] == i ? t++ : e || (e = this.scrollTargets.slice(0, t)), e && e.push(i), i = i.assignedSlot || i.parentNode;
      else if (i.nodeType == 11)
        i = i.host;
      else
        break;
    if (t < this.scrollTargets.length && !e && (e = this.scrollTargets.slice(0, t)), e) {
      for (let i of this.scrollTargets)
        i.removeEventListener("scroll", this.onScroll);
      for (let i of this.scrollTargets = e)
        i.addEventListener("scroll", this.onScroll);
    }
  }
  ignore(t) {
    if (!this.active)
      return t();
    try {
      return this.stop(), t();
    } finally {
      this.start(), this.clear();
    }
  }
  start() {
    this.active || (this.observer.observe(this.dom, Cu), Ks && this.dom.addEventListener("DOMCharacterDataModified", this.onCharData), this.active = !0);
  }
  stop() {
    this.active && (this.active = !1, this.observer.disconnect(), Ks && this.dom.removeEventListener("DOMCharacterDataModified", this.onCharData));
  }
  // Throw away any pending changes
  clear() {
    this.processRecords(), this.queue.length = 0, this.selectionChanged = !1;
  }
  // Chrome Android, especially in combination with GBoard, not only
  // doesn't reliably fire regular key events, but also often
  // surrounds the effect of enter or backspace with a bunch of
  // composition events that, when interrupted, cause text duplication
  // or other kinds of corruption. This hack makes the editor back off
  // from handling DOM changes for a moment when such a key is
  // detected (via beforeinput or keydown), and then tries to flush
  // them or, if that has no effect, dispatches the given key.
  delayAndroidKey(t, e) {
    var i;
    if (!this.delayedAndroidKey) {
      let s = () => {
        let r = this.delayedAndroidKey;
        r && (this.clearDelayedAndroidKey(), this.view.inputState.lastKeyCode = r.keyCode, this.view.inputState.lastKeyTime = Date.now(), !this.flush() && r.force && Ke(this.dom, r.key, r.keyCode));
      };
      this.flushingAndroidKey = this.view.win.requestAnimationFrame(s);
    }
    (!this.delayedAndroidKey || t == "Enter") && (this.delayedAndroidKey = {
      key: t,
      keyCode: e,
      // Only run the key handler when no changes are detected if
      // this isn't coming right after another change, in which case
      // it is probably part of a weird chain of updates, and should
      // be ignored if it returns the DOM to its previous state.
      force: this.lastChange < Date.now() - 50 || !!(!((i = this.delayedAndroidKey) === null || i === void 0) && i.force)
    });
  }
  clearDelayedAndroidKey() {
    this.win.cancelAnimationFrame(this.flushingAndroidKey), this.delayedAndroidKey = null, this.flushingAndroidKey = -1;
  }
  flushSoon() {
    this.delayedFlush < 0 && (this.delayedFlush = this.view.win.requestAnimationFrame(() => {
      this.delayedFlush = -1, this.flush();
    }));
  }
  forceFlush() {
    this.delayedFlush >= 0 && (this.view.win.cancelAnimationFrame(this.delayedFlush), this.delayedFlush = -1), this.flush();
  }
  pendingRecords() {
    for (let t of this.observer.takeRecords())
      this.queue.push(t);
    return this.queue;
  }
  processRecords() {
    let t = this.pendingRecords();
    t.length && (this.queue = []);
    let e = -1, i = -1, s = !1;
    for (let r of t) {
      let o = this.readMutation(r);
      o && (o.typeOver && (s = !0), e == -1 ? { from: e, to: i } = o : (e = Math.min(o.from, e), i = Math.max(o.to, i)));
    }
    return { from: e, to: i, typeOver: s };
  }
  readChange() {
    let { from: t, to: e, typeOver: i } = this.processRecords(), s = this.selectionChanged && ts(this.dom, this.selectionRange);
    if (t < 0 && !s)
      return null;
    t > -1 && (this.lastChange = Date.now()), this.view.inputState.lastFocusTime = 0, this.selectionChanged = !1;
    let r = new bu(this.view, t, e, i);
    return this.view.docView.domChanged = { newSel: r.newSel ? r.newSel.main : null }, r;
  }
  // Apply pending changes, if any
  flush(t = !0) {
    if (this.delayedFlush >= 0 || this.delayedAndroidKey)
      return !1;
    t && this.readSelectionRange();
    let e = this.readChange();
    if (!e)
      return this.view.requestMeasure(), !1;
    let i = this.view.state, s = ch(this.view, e);
    return this.view.state == i && this.view.update([]), s;
  }
  readMutation(t) {
    let e = this.view.docView.nearest(t.target);
    if (!e || e.ignoreMutation(t))
      return null;
    if (e.markDirty(t.type == "attributes"), t.type == "attributes" && (e.flags |= 4), t.type == "childList") {
      let i = lo(e, t.previousSibling || t.target.previousSibling, -1), s = lo(e, t.nextSibling || t.target.nextSibling, 1);
      return {
        from: i ? e.posAfter(i) : e.posAtStart,
        to: s ? e.posBefore(s) : e.posAtEnd,
        typeOver: !1
      };
    } else
      return t.type == "characterData" ? { from: e.posAtStart, to: e.posAtEnd, typeOver: t.target.nodeValue == t.oldValue } : null;
  }
  setWindow(t) {
    t != this.win && (this.removeWindowListeners(this.win), this.win = t, this.addWindowListeners(this.win));
  }
  addWindowListeners(t) {
    t.addEventListener("resize", this.onResize), t.addEventListener("beforeprint", this.onPrint), t.addEventListener("scroll", this.onScroll), t.document.addEventListener("selectionchange", this.onSelectionChange);
  }
  removeWindowListeners(t) {
    t.removeEventListener("scroll", this.onScroll), t.removeEventListener("resize", this.onResize), t.removeEventListener("beforeprint", this.onPrint), t.document.removeEventListener("selectionchange", this.onSelectionChange);
  }
  destroy() {
    var t, e, i;
    this.stop(), (t = this.intersection) === null || t === void 0 || t.disconnect(), (e = this.gapIntersection) === null || e === void 0 || e.disconnect(), (i = this.resizeScroll) === null || i === void 0 || i.disconnect();
    for (let s of this.scrollTargets)
      s.removeEventListener("scroll", this.onScroll);
    this.removeWindowListeners(this.win), clearTimeout(this.parentCheck), clearTimeout(this.resizeTimeout), this.win.cancelAnimationFrame(this.delayedFlush), this.win.cancelAnimationFrame(this.flushingAndroidKey);
  }
}
function lo(n, t, e) {
  for (; t; ) {
    let i = q.get(t);
    if (i && i.parent == n)
      return i;
    let s = t.parentNode;
    t = s != n.dom ? s : e > 0 ? t.nextSibling : t.previousSibling;
  }
  return null;
}
function Ou(n) {
  let t = null;
  function e(h) {
    h.preventDefault(), h.stopImmediatePropagation(), t = h.getTargetRanges()[0];
  }
  if (n.contentDOM.addEventListener("beforeinput", e, !0), n.dom.ownerDocument.execCommand("indent"), n.contentDOM.removeEventListener("beforeinput", e, !0), !t)
    return null;
  let i = t.startContainer, s = t.startOffset, r = t.endContainer, o = t.endOffset, l = n.docView.domAtPos(n.state.selection.main.anchor);
  return ds(l.node, l.offset, r, o) && ([i, s, r, o] = [r, o, i, s]), { anchorNode: i, anchorOffset: s, focusNode: r, focusOffset: o };
}
class T {
  /**
  The current editor state.
  */
  get state() {
    return this.viewState.state;
  }
  /**
  To be able to display large documents without consuming too much
  memory or overloading the browser, CodeMirror only draws the
  code that is visible (plus a margin around it) to the DOM. This
  property tells you the extent of the current drawn viewport, in
  document positions.
  */
  get viewport() {
    return this.viewState.viewport;
  }
  /**
  When there are, for example, large collapsed ranges in the
  viewport, its size can be a lot bigger than the actual visible
  content. Thus, if you are doing something like styling the
  content in the viewport, it is preferable to only do so for
  these ranges, which are the subset of the viewport that is
  actually drawn.
  */
  get visibleRanges() {
    return this.viewState.visibleRanges;
  }
  /**
  Returns false when the editor is entirely scrolled out of view
  or otherwise hidden.
  */
  get inView() {
    return this.viewState.inView;
  }
  /**
  Indicates whether the user is currently composing text via
  [IME](https://en.wikipedia.org/wiki/Input_method), and at least
  one change has been made in the current composition.
  */
  get composing() {
    return this.inputState.composing > 0;
  }
  /**
  Indicates whether the user is currently in composing state. Note
  that on some platforms, like Android, this will be the case a
  lot, since just putting the cursor on a word starts a
  composition there.
  */
  get compositionStarted() {
    return this.inputState.composing >= 0;
  }
  /**
  The document or shadow root that the view lives in.
  */
  get root() {
    return this._root;
  }
  /**
  @internal
  */
  get win() {
    return this.dom.ownerDocument.defaultView || window;
  }
  /**
  Construct a new view. You'll want to either provide a `parent`
  option, or put `view.dom` into your document after creating a
  view, so that the user can see the editor.
  */
  constructor(t = {}) {
    this.plugins = [], this.pluginMap = /* @__PURE__ */ new Map(), this.editorAttrs = {}, this.contentAttrs = {}, this.bidiCache = [], this.destroyed = !1, this.updateState = 2, this.measureScheduled = -1, this.measureRequests = [], this.contentDOM = document.createElement("div"), this.scrollDOM = document.createElement("div"), this.scrollDOM.tabIndex = -1, this.scrollDOM.className = "cm-scroller", this.scrollDOM.appendChild(this.contentDOM), this.announceDOM = document.createElement("div"), this.announceDOM.style.cssText = "position: fixed; top: -10000px", this.announceDOM.setAttribute("aria-live", "polite"), this.dom = document.createElement("div"), this.dom.appendChild(this.announceDOM), this.dom.appendChild(this.scrollDOM);
    let { dispatch: e } = t;
    this.dispatchTransactions = t.dispatchTransactions || e && ((i) => i.forEach((s) => e(s, this))) || ((i) => this.update(i)), this.dispatch = this.dispatch.bind(this), this._root = t.root || lf(t.parent) || document, this.viewState = new so(t.state || H.create(t)), t.scrollTo && t.scrollTo.is(Ii) && (this.viewState.scrollTarget = t.scrollTo.value.clip(this.viewState.state)), this.plugins = this.state.facet(hi).map((i) => new _s(i));
    for (let i of this.plugins)
      i.update(this);
    this.observer = new Au(this), this.inputState = new _f(this), this.inputState.ensureHandlers(this.plugins), this.docView = new $r(this), this.mountStyles(), this.updateAttrs(), this.updateState = 0, this.requestMeasure(), t.parent && t.parent.appendChild(this.dom);
  }
  dispatch(...t) {
    let e = t.length == 1 && t[0] instanceof ft ? t : t.length == 1 && Array.isArray(t[0]) ? t[0] : [this.state.update(...t)];
    this.dispatchTransactions(e, this);
  }
  /**
  Update the view for the given array of transactions. This will
  update the visible document and selection to match the state
  produced by the transactions, and notify view plugins of the
  change. You should usually call
  [`dispatch`](https://codemirror.net/6/docs/ref/#view.EditorView.dispatch) instead, which uses this
  as a primitive.
  */
  update(t) {
    if (this.updateState != 0)
      throw new Error("Calls to EditorView.update are not allowed while an update is in progress");
    let e = !1, i = !1, s, r = this.state;
    for (let u of t) {
      if (u.startState != r)
        throw new RangeError("Trying to update state with a transaction that doesn't start from the previous state.");
      r = u.state;
    }
    if (this.destroyed) {
      this.viewState.state = r;
      return;
    }
    let o = this.hasFocus, l = 0, h = null;
    t.some((u) => u.annotation(sh)) ? (this.inputState.notifiedFocused = o, l = 1) : o != this.inputState.notifiedFocused && (this.inputState.notifiedFocused = o, h = nh(r, o), h || (l = 1));
    let a = this.observer.delayedAndroidKey, c = null;
    if (a ? (this.observer.clearDelayedAndroidKey(), c = this.observer.readChange(), (c && !this.state.doc.eq(r.doc) || !this.state.selection.eq(r.selection)) && (c = null)) : this.observer.clear(), r.facet(H.phrases) != this.state.facet(H.phrases))
      return this.setState(r);
    s = ps.create(this, r, t), s.flags |= l;
    let f = this.viewState.scrollTarget;
    try {
      this.updateState = 2;
      for (let u of t) {
        if (f && (f = f.map(u.changes)), u.scrollIntoView) {
          let { main: d } = u.state.selection;
          f = new qe(d.empty ? d : b.cursor(d.head, d.head > d.anchor ? -1 : 1));
        }
        for (let d of u.effects)
          d.is(Ii) && (f = d.value.clip(this.state));
      }
      this.viewState.update(s, f), this.bidiCache = gs.update(this.bidiCache, s.changes), s.empty || (this.updatePlugins(s), this.inputState.update(s)), e = this.docView.update(s), this.state.facet(ai) != this.styleModules && this.mountStyles(), i = this.updateAttrs(), this.showAnnouncements(t), this.docView.updateSelection(e, t.some((u) => u.isUserEvent("select.pointer")));
    } finally {
      this.updateState = 0;
    }
    if (s.startState.facet(zi) != s.state.facet(zi) && (this.viewState.mustMeasureContent = !0), (e || i || f || this.viewState.mustEnforceCursorAssoc || this.viewState.mustMeasureContent) && this.requestMeasure(), !s.empty)
      for (let u of this.state.facet(Cn))
        try {
          u(s);
        } catch (d) {
          ie(this.state, d, "update listener");
        }
    (h || c) && Promise.resolve().then(() => {
      h && this.state == h.startState && this.dispatch(h), c && !ch(this, c) && a.force && Ke(this.contentDOM, a.key, a.keyCode);
    });
  }
  /**
  Reset the view to the given state. (This will cause the entire
  document to be redrawn and all view plugins to be reinitialized,
  so you should probably only use it when the new state isn't
  derived from the old state. Otherwise, use
  [`dispatch`](https://codemirror.net/6/docs/ref/#view.EditorView.dispatch) instead.)
  */
  setState(t) {
    if (this.updateState != 0)
      throw new Error("Calls to EditorView.setState are not allowed while an update is in progress");
    if (this.destroyed) {
      this.viewState.state = t;
      return;
    }
    this.updateState = 2;
    let e = this.hasFocus;
    try {
      for (let i of this.plugins)
        i.destroy(this);
      this.viewState = new so(t), this.plugins = t.facet(hi).map((i) => new _s(i)), this.pluginMap.clear();
      for (let i of this.plugins)
        i.update(this);
      this.docView = new $r(this), this.inputState.ensureHandlers(this.plugins), this.mountStyles(), this.updateAttrs(), this.bidiCache = [];
    } finally {
      this.updateState = 0;
    }
    e && this.focus(), this.requestMeasure();
  }
  updatePlugins(t) {
    let e = t.startState.facet(hi), i = t.state.facet(hi);
    if (e != i) {
      let s = [];
      for (let r of i) {
        let o = e.indexOf(r);
        if (o < 0)
          s.push(new _s(r));
        else {
          let l = this.plugins[o];
          l.mustUpdate = t, s.push(l);
        }
      }
      for (let r of this.plugins)
        r.mustUpdate != t && r.destroy(this);
      this.plugins = s, this.pluginMap.clear();
    } else
      for (let s of this.plugins)
        s.mustUpdate = t;
    for (let s = 0; s < this.plugins.length; s++)
      this.plugins[s].update(this);
    e != i && this.inputState.ensureHandlers(this.plugins);
  }
  /**
  @internal
  */
  measure(t = !0) {
    if (this.destroyed)
      return;
    if (this.measureScheduled > -1 && this.win.cancelAnimationFrame(this.measureScheduled), this.observer.delayedAndroidKey) {
      this.measureScheduled = -1, this.requestMeasure();
      return;
    }
    this.measureScheduled = 0, t && this.observer.forceFlush();
    let e = null, i = this.scrollDOM, s = i.scrollTop * this.scaleY, { scrollAnchorPos: r, scrollAnchorHeight: o } = this.viewState;
    Math.abs(s - this.viewState.scrollTop) > 1 && (o = -1), this.viewState.scrollAnchorHeight = -1;
    try {
      for (let l = 0; ; l++) {
        if (o < 0)
          if (vl(i))
            r = -1, o = this.viewState.heightMap.height;
          else {
            let d = this.viewState.scrollAnchorAt(s);
            r = d.from, o = d.top;
          }
        this.updateState = 1;
        let h = this.viewState.measure(this);
        if (!h && !this.measureRequests.length && this.viewState.scrollTarget == null)
          break;
        if (l > 5) {
          console.warn(this.measureRequests.length ? "Measure loop restarted more than 5 times" : "Viewport failed to stabilize");
          break;
        }
        let a = [];
        h & 4 || ([this.measureRequests, a] = [a, this.measureRequests]);
        let c = a.map((d) => {
          try {
            return d.read(this);
          } catch (p) {
            return ie(this.state, p), ho;
          }
        }), f = ps.create(this, this.state, []), u = !1;
        f.flags |= h, e ? e.flags |= h : e = f, this.updateState = 2, f.empty || (this.updatePlugins(f), this.inputState.update(f), this.updateAttrs(), u = this.docView.update(f));
        for (let d = 0; d < a.length; d++)
          if (c[d] != ho)
            try {
              let p = a[d];
              p.write && p.write(c[d], this);
            } catch (p) {
              ie(this.state, p);
            }
        if (u && this.docView.updateSelection(!0), !f.viewportChanged && this.measureRequests.length == 0) {
          if (this.viewState.editorHeight)
            if (this.viewState.scrollTarget) {
              this.docView.scrollIntoView(this.viewState.scrollTarget), this.viewState.scrollTarget = null;
              continue;
            } else {
              let p = (r < 0 ? this.viewState.heightMap.height : this.viewState.lineBlockAt(r).top) - o;
              if (p > 1 || p < -1) {
                s = s + p, i.scrollTop = s / this.scaleY, o = -1;
                continue;
              }
            }
          break;
        }
      }
    } finally {
      this.updateState = 0, this.measureScheduled = -1;
    }
    if (e && !e.empty)
      for (let l of this.state.facet(Cn))
        l(e);
  }
  /**
  Get the CSS classes for the currently active editor themes.
  */
  get themeClasses() {
    return Bn + " " + (this.state.facet(Pn) ? hh : lh) + " " + this.state.facet(zi);
  }
  updateAttrs() {
    let t = ao(this, $l, {
      class: "cm-editor" + (this.hasFocus ? " cm-focused " : " ") + this.themeClasses
    }), e = {
      spellcheck: "false",
      autocorrect: "off",
      autocapitalize: "off",
      translate: "no",
      contenteditable: this.state.facet(Bs) ? "true" : "false",
      class: "cm-content",
      style: `${C.tabSize}: ${this.state.tabSize}`,
      role: "textbox",
      "aria-multiline": "true"
    };
    this.state.readOnly && (e["aria-readonly"] = "true"), ao(this, er, e);
    let i = this.observer.ignore(() => {
      let s = vn(this.contentDOM, this.contentAttrs, e), r = vn(this.dom, this.editorAttrs, t);
      return s || r;
    });
    return this.editorAttrs = t, this.contentAttrs = e, i;
  }
  showAnnouncements(t) {
    let e = !0;
    for (let i of t)
      for (let s of i.effects)
        if (s.is(T.announce)) {
          e && (this.announceDOM.textContent = ""), e = !1;
          let r = this.announceDOM.appendChild(document.createElement("div"));
          r.textContent = s.value;
        }
  }
  mountStyles() {
    this.styleModules = this.state.facet(ai);
    let t = this.state.facet(T.cspNonce);
    we.mount(this.root, this.styleModules.concat(mu).reverse(), t ? { nonce: t } : void 0);
  }
  readMeasured() {
    if (this.updateState == 2)
      throw new Error("Reading the editor layout isn't allowed during an update");
    this.updateState == 0 && this.measureScheduled > -1 && this.measure(!1);
  }
  /**
  Schedule a layout measurement, optionally providing callbacks to
  do custom DOM measuring followed by a DOM write phase. Using
  this is preferable reading DOM layout directly from, for
  example, an event handler, because it'll make sure measuring and
  drawing done by other components is synchronized, avoiding
  unnecessary DOM layout computations.
  */
  requestMeasure(t) {
    if (this.measureScheduled < 0 && (this.measureScheduled = this.win.requestAnimationFrame(() => this.measure())), t) {
      if (this.measureRequests.indexOf(t) > -1)
        return;
      if (t.key != null) {
        for (let e = 0; e < this.measureRequests.length; e++)
          if (this.measureRequests[e].key === t.key) {
            this.measureRequests[e] = t;
            return;
          }
      }
      this.measureRequests.push(t);
    }
  }
  /**
  Get the value of a specific plugin, if present. Note that
  plugins that crash can be dropped from a view, so even when you
  know you registered a given plugin, it is recommended to check
  the return value of this method.
  */
  plugin(t) {
    let e = this.pluginMap.get(t);
    return (e === void 0 || e && e.spec != t) && this.pluginMap.set(t, e = this.plugins.find((i) => i.spec == t) || null), e && e.update(this).value;
  }
  /**
  The top position of the document, in screen coordinates. This
  may be negative when the editor is scrolled down. Points
  directly to the top of the first line, not above the padding.
  */
  get documentTop() {
    return this.contentDOM.getBoundingClientRect().top + this.viewState.paddingTop;
  }
  /**
  Reports the padding above and below the document.
  */
  get documentPadding() {
    return { top: this.viewState.paddingTop, bottom: this.viewState.paddingBottom };
  }
  /**
  If the editor is transformed with CSS, this provides the scale
  along the X axis. Otherwise, it will just be 1. Note that
  transforms other than translation and scaling are not supported.
  */
  get scaleX() {
    return this.viewState.scaleX;
  }
  /**
  Provide the CSS transformed scale along the Y axis.
  */
  get scaleY() {
    return this.viewState.scaleY;
  }
  /**
  Find the text line or block widget at the given vertical
  position (which is interpreted as relative to the [top of the
  document](https://codemirror.net/6/docs/ref/#view.EditorView.documentTop)).
  */
  elementAtHeight(t) {
    return this.readMeasured(), this.viewState.elementAtHeight(t);
  }
  /**
  Find the line block (see
  [`lineBlockAt`](https://codemirror.net/6/docs/ref/#view.EditorView.lineBlockAt) at the given
  height, again interpreted relative to the [top of the
  document](https://codemirror.net/6/docs/ref/#view.EditorView.documentTop).
  */
  lineBlockAtHeight(t) {
    return this.readMeasured(), this.viewState.lineBlockAtHeight(t);
  }
  /**
  Get the extent and vertical position of all [line
  blocks](https://codemirror.net/6/docs/ref/#view.EditorView.lineBlockAt) in the viewport. Positions
  are relative to the [top of the
  document](https://codemirror.net/6/docs/ref/#view.EditorView.documentTop);
  */
  get viewportLineBlocks() {
    return this.viewState.viewportLines;
  }
  /**
  Find the line block around the given document position. A line
  block is a range delimited on both sides by either a
  non-[hidden](https://codemirror.net/6/docs/ref/#view.Decoration^replace) line breaks, or the
  start/end of the document. It will usually just hold a line of
  text, but may be broken into multiple textblocks by block
  widgets.
  */
  lineBlockAt(t) {
    return this.viewState.lineBlockAt(t);
  }
  /**
  The editor's total content height.
  */
  get contentHeight() {
    return this.viewState.contentHeight;
  }
  /**
  Move a cursor position by [grapheme
  cluster](https://codemirror.net/6/docs/ref/#state.findClusterBreak). `forward` determines whether
  the motion is away from the line start, or towards it. In
  bidirectional text, the line is traversed in visual order, using
  the editor's [text direction](https://codemirror.net/6/docs/ref/#view.EditorView.textDirection).
  When the start position was the last one on the line, the
  returned position will be across the line break. If there is no
  further line, the original position is returned.
  
  By default, this method moves over a single cluster. The
  optional `by` argument can be used to move across more. It will
  be called with the first cluster as argument, and should return
  a predicate that determines, for each subsequent cluster,
  whether it should also be moved over.
  */
  moveByChar(t, e, i) {
    return Ws(this, t, Kr(this, t, e, i));
  }
  /**
  Move a cursor position across the next group of either
  [letters](https://codemirror.net/6/docs/ref/#state.EditorState.charCategorizer) or non-letter
  non-whitespace characters.
  */
  moveByGroup(t, e) {
    return Ws(this, t, Kr(this, t, e, (i) => $f(this, t.head, i)));
  }
  /**
  Move to the next line boundary in the given direction. If
  `includeWrap` is true, line wrapping is on, and there is a
  further wrap point on the current line, the wrap point will be
  returned. Otherwise this function will return the start or end
  of the line.
  */
  moveToLineBoundary(t, e, i = !0) {
    return Hf(this, t, e, i);
  }
  /**
  Move a cursor position vertically. When `distance` isn't given,
  it defaults to moving to the next line (including wrapped
  lines). Otherwise, `distance` should provide a positive distance
  in pixels.
  
  When `start` has a
  [`goalColumn`](https://codemirror.net/6/docs/ref/#state.SelectionRange.goalColumn), the vertical
  motion will use that as a target horizontal position. Otherwise,
  the cursor's own horizontal position is used. The returned
  cursor will have its goal column set to whichever column was
  used.
  */
  moveVertically(t, e, i) {
    return Ws(this, t, Ff(this, t, e, i));
  }
  /**
  Find the DOM parent node and offset (child offset if `node` is
  an element, character offset when it is a text node) at the
  given document position.
  
  Note that for positions that aren't currently in
  `visibleRanges`, the resulting DOM position isn't necessarily
  meaningful (it may just point before or after a placeholder
  element).
  */
  domAtPos(t) {
    return this.docView.domAtPos(t);
  }
  /**
  Find the document position at the given DOM node. Can be useful
  for associating positions with DOM events. Will raise an error
  when `node` isn't part of the editor content.
  */
  posAtDOM(t, e = 0) {
    return this.docView.posFromDOM(t, e);
  }
  posAtCoords(t, e = !0) {
    return this.readMeasured(), Ql(this, t, e);
  }
  /**
  Get the screen coordinates at the given document position.
  `side` determines whether the coordinates are based on the
  element before (-1) or after (1) the position (if no element is
  available on the given side, the method will transparently use
  another strategy to get reasonable coordinates).
  */
  coordsAtPos(t, e = 1) {
    this.readMeasured();
    let i = this.docView.coordsAt(t, e);
    if (!i || i.left == i.right)
      return i;
    let s = this.state.doc.lineAt(t), r = this.bidiSpans(s), o = r[ue.find(r, t - s.from, -1, e)];
    return Xn(i, o.dir == tt.LTR == e > 0);
  }
  /**
  Return the rectangle around a given character. If `pos` does not
  point in front of a character that is in the viewport and
  rendered (i.e. not replaced, not a line break), this will return
  null. For space characters that are a line wrap point, this will
  return the position before the line break.
  */
  coordsForChar(t) {
    return this.readMeasured(), this.docView.coordsForChar(t);
  }
  /**
  The default width of a character in the editor. May not
  accurately reflect the width of all characters (given variable
  width fonts or styling of invididual ranges).
  */
  get defaultCharacterWidth() {
    return this.viewState.heightOracle.charWidth;
  }
  /**
  The default height of a line in the editor. May not be accurate
  for all lines.
  */
  get defaultLineHeight() {
    return this.viewState.heightOracle.lineHeight;
  }
  /**
  The text direction
  ([`direction`](https://developer.mozilla.org/en-US/docs/Web/CSS/direction)
  CSS property) of the editor's content element.
  */
  get textDirection() {
    return this.viewState.defaultTextDirection;
  }
  /**
  Find the text direction of the block at the given position, as
  assigned by CSS. If
  [`perLineTextDirection`](https://codemirror.net/6/docs/ref/#view.EditorView^perLineTextDirection)
  isn't enabled, or the given position is outside of the viewport,
  this will always return the same as
  [`textDirection`](https://codemirror.net/6/docs/ref/#view.EditorView.textDirection). Note that
  this may trigger a DOM layout.
  */
  textDirectionAt(t) {
    return !this.state.facet(Hl) || t < this.viewport.from || t > this.viewport.to ? this.textDirection : (this.readMeasured(), this.docView.textDirectionAt(t));
  }
  /**
  Whether this editor [wraps lines](https://codemirror.net/6/docs/ref/#view.EditorView.lineWrapping)
  (as determined by the
  [`white-space`](https://developer.mozilla.org/en-US/docs/Web/CSS/white-space)
  CSS property of its content element).
  */
  get lineWrapping() {
    return this.viewState.heightOracle.lineWrapping;
  }
  /**
  Returns the bidirectional text structure of the given line
  (which should be in the current document) as an array of span
  objects. The order of these spans matches the [text
  direction](https://codemirror.net/6/docs/ref/#view.EditorView.textDirection)—if that is
  left-to-right, the leftmost spans come first, otherwise the
  rightmost spans come first.
  */
  bidiSpans(t) {
    if (t.length > Mu)
      return ql(t.length);
    let e = this.textDirectionAt(t.from), i;
    for (let r of this.bidiCache)
      if (r.from == t.from && r.dir == e && (r.fresh || Kl(r.isolates, i = Hr(this, t.from, t.to))))
        return r.order;
    i || (i = Hr(this, t.from, t.to));
    let s = Sf(t.text, e, i);
    return this.bidiCache.push(new gs(t.from, t.to, e, i, !0, s)), s;
  }
  /**
  Check whether the editor has focus.
  */
  get hasFocus() {
    var t;
    return (this.dom.ownerDocument.hasFocus() || C.safari && ((t = this.inputState) === null || t === void 0 ? void 0 : t.lastContextMenu) > Date.now() - 3e4) && this.root.activeElement == this.contentDOM;
  }
  /**
  Put focus on the editor.
  */
  focus() {
    this.observer.ignore(() => {
      kl(this.contentDOM), this.docView.updateSelection();
    });
  }
  /**
  Update the [root](https://codemirror.net/6/docs/ref/##view.EditorViewConfig.root) in which the editor lives. This is only
  necessary when moving the editor's existing DOM to a new window or shadow root.
  */
  setRoot(t) {
    this._root != t && (this._root = t, this.observer.setWindow((t.nodeType == 9 ? t : t.ownerDocument).defaultView || window), this.mountStyles());
  }
  /**
  Clean up this editor view, removing its element from the
  document, unregistering event handlers, and notifying
  plugins. The view instance can no longer be used after
  calling this.
  */
  destroy() {
    for (let t of this.plugins)
      t.destroy(this);
    this.plugins = [], this.inputState.destroy(), this.dom.remove(), this.observer.destroy(), this.measureScheduled > -1 && this.win.cancelAnimationFrame(this.measureScheduled), this.destroyed = !0;
  }
  /**
  Returns an effect that can be
  [added](https://codemirror.net/6/docs/ref/#state.TransactionSpec.effects) to a transaction to
  cause it to scroll the given position or range into view.
  */
  static scrollIntoView(t, e = {}) {
    return Ii.of(new qe(typeof t == "number" ? b.cursor(t) : t, e.y, e.x, e.yMargin, e.xMargin));
  }
  /**
  Return an effect that resets the editor to its current (at the
  time this method was called) scroll position. Note that this
  only affects the editor's own scrollable element, not parents.
  See also
  [`EditorViewConfig.scrollTo`](https://codemirror.net/6/docs/ref/#view.EditorViewConfig.scrollTo).
  
  The effect should be used with a document identical to the one
  it was created for. Failing to do so is not an error, but may
  not scroll to the expected position. You can
  [map](https://codemirror.net/6/docs/ref/#state.StateEffect.map) the effect to account for changes.
  */
  scrollSnapshot() {
    let { scrollTop: t, scrollLeft: e } = this.scrollDOM, i = this.viewState.scrollAnchorAt(t);
    return Ii.of(new qe(b.cursor(i.from), "start", "start", i.top - t, e, !0));
  }
  /**
  Returns an extension that can be used to add DOM event handlers.
  The value should be an object mapping event names to handler
  functions. For any given event, such functions are ordered by
  extension precedence, and the first handler to return true will
  be assumed to have handled that event, and no other handlers or
  built-in behavior will be activated for it. These are registered
  on the [content element](https://codemirror.net/6/docs/ref/#view.EditorView.contentDOM), except
  for `scroll` handlers, which will be called any time the
  editor's [scroll element](https://codemirror.net/6/docs/ref/#view.EditorView.scrollDOM) or one of
  its parent nodes is scrolled.
  */
  static domEventHandlers(t) {
    return yt.define(() => ({}), { eventHandlers: t });
  }
  /**
  Create an extension that registers DOM event observers. Contrary
  to event [handlers](https://codemirror.net/6/docs/ref/#view.EditorView^domEventHandlers),
  observers can't be prevented from running by a higher-precedence
  handler returning true. They also don't prevent other handlers
  and observers from running when they return true, and should not
  call `preventDefault`.
  */
  static domEventObservers(t) {
    return yt.define(() => ({}), { eventObservers: t });
  }
  /**
  Create a theme extension. The first argument can be a
  [`style-mod`](https://github.com/marijnh/style-mod#documentation)
  style spec providing the styles for the theme. These will be
  prefixed with a generated class for the style.
  
  Because the selectors will be prefixed with a scope class, rule
  that directly match the editor's [wrapper
  element](https://codemirror.net/6/docs/ref/#view.EditorView.dom)—to which the scope class will be
  added—need to be explicitly differentiated by adding an `&` to
  the selector for that element—for example
  `&.cm-focused`.
  
  When `dark` is set to true, the theme will be marked as dark,
  which will cause the `&dark` rules from [base
  themes](https://codemirror.net/6/docs/ref/#view.EditorView^baseTheme) to be used (as opposed to
  `&light` when a light theme is active).
  */
  static theme(t, e) {
    let i = we.newName(), s = [zi.of(i), ai.of(Rn(`.${i}`, t))];
    return e && e.dark && s.push(Pn.of(!0)), s;
  }
  /**
  Create an extension that adds styles to the base theme. Like
  with [`theme`](https://codemirror.net/6/docs/ref/#view.EditorView^theme), use `&` to indicate the
  place of the editor wrapper element when directly targeting
  that. You can also use `&dark` or `&light` instead to only
  target editors with a dark or light theme.
  */
  static baseTheme(t) {
    return Qn.lowest(ai.of(Rn("." + Bn, t, ah)));
  }
  /**
  Retrieve an editor view instance from the view's DOM
  representation.
  */
  static findFromDOM(t) {
    var e;
    let i = t.querySelector(".cm-content"), s = i && q.get(i) || q.get(t);
    return ((e = s == null ? void 0 : s.rootView) === null || e === void 0 ? void 0 : e.view) || null;
  }
}
T.styleModule = ai;
T.inputHandler = Il;
T.focusChangeEffect = Vl;
T.perLineTextDirection = Hl;
T.exceptionSink = Nl;
T.updateListener = Cn;
T.editable = Bs;
T.mouseSelectionStyle = El;
T.dragMovesSelection = Ll;
T.clickAddsSelectionRange = Rl;
T.decorations = xi;
T.atomicRanges = ir;
T.bidiIsolatedRanges = Fl;
T.scrollMargins = _l;
T.darkTheme = Pn;
T.cspNonce = /* @__PURE__ */ O.define({ combine: (n) => n.length ? n[0] : "" });
T.contentAttributes = er;
T.editorAttributes = $l;
T.lineWrapping = /* @__PURE__ */ T.contentAttributes.of({ class: "cm-lineWrapping" });
T.announce = /* @__PURE__ */ z.define();
const Mu = 4096, ho = {};
class gs {
  constructor(t, e, i, s, r, o) {
    this.from = t, this.to = e, this.dir = i, this.isolates = s, this.fresh = r, this.order = o;
  }
  static update(t, e) {
    if (e.empty && !t.some((r) => r.fresh))
      return t;
    let i = [], s = t.length ? t[t.length - 1].dir : tt.LTR;
    for (let r = Math.max(0, t.length - 10); r < t.length; r++) {
      let o = t[r];
      o.dir == s && !e.touchesRange(o.from, o.to) && i.push(new gs(e.mapPos(o.from, 1), e.mapPos(o.to, -1), o.dir, o.isolates, !1, o.order));
    }
    return i;
  }
}
function ao(n, t, e) {
  for (let i = n.state.facet(t), s = i.length - 1; s >= 0; s--) {
    let r = i[s], o = typeof r == "function" ? r(n) : r;
    o && xn(o, e);
  }
  return e;
}
const Tu = C.mac ? "mac" : C.windows ? "win" : C.linux ? "linux" : "key";
function Du(n, t) {
  const e = n.split(/-(?!$)/);
  let i = e[e.length - 1];
  i == "Space" && (i = " ");
  let s, r, o, l;
  for (let h = 0; h < e.length - 1; ++h) {
    const a = e[h];
    if (/^(cmd|meta|m)$/i.test(a))
      l = !0;
    else if (/^a(lt)?$/i.test(a))
      s = !0;
    else if (/^(c|ctrl|control)$/i.test(a))
      r = !0;
    else if (/^s(hift)?$/i.test(a))
      o = !0;
    else if (/^mod$/i.test(a))
      t == "mac" ? l = !0 : r = !0;
    else
      throw new Error("Unrecognized modifier name: " + a);
  }
  return s && (i = "Alt-" + i), r && (i = "Ctrl-" + i), l && (i = "Meta-" + i), o && (i = "Shift-" + i), i;
}
function Wi(n, t, e) {
  return t.altKey && (n = "Alt-" + n), t.ctrlKey && (n = "Ctrl-" + n), t.metaKey && (n = "Meta-" + n), e !== !1 && t.shiftKey && (n = "Shift-" + n), n;
}
const Pu = /* @__PURE__ */ Qn.default(/* @__PURE__ */ T.domEventHandlers({
  keydown(n, t) {
    return Eu(Bu(t.state), n, t, "editor");
  }
})), fh = /* @__PURE__ */ O.define({ enables: Pu }), co = /* @__PURE__ */ new WeakMap();
function Bu(n) {
  let t = n.facet(fh), e = co.get(t);
  return e || co.set(t, e = Lu(t.reduce((i, s) => i.concat(s), []))), e;
}
let ae = null;
const Ru = 4e3;
function Lu(n, t = Tu) {
  let e = /* @__PURE__ */ Object.create(null), i = /* @__PURE__ */ Object.create(null), s = (o, l) => {
    let h = i[o];
    if (h == null)
      i[o] = l;
    else if (h != l)
      throw new Error("Key binding " + o + " is used both as a regular binding and as a multi-stroke prefix");
  }, r = (o, l, h, a, c) => {
    var f, u;
    let d = e[o] || (e[o] = /* @__PURE__ */ Object.create(null)), p = l.split(/ (?!$)/).map((y) => Du(y, t));
    for (let y = 1; y < p.length; y++) {
      let x = p.slice(0, y).join(" ");
      s(x, !0), d[x] || (d[x] = {
        preventDefault: !0,
        stopPropagation: !1,
        run: [(S) => {
          let v = ae = { view: S, prefix: x, scope: o };
          return setTimeout(() => {
            ae == v && (ae = null);
          }, Ru), !0;
        }]
      });
    }
    let m = p.join(" ");
    s(m, !1);
    let g = d[m] || (d[m] = {
      preventDefault: !1,
      stopPropagation: !1,
      run: ((u = (f = d._any) === null || f === void 0 ? void 0 : f.run) === null || u === void 0 ? void 0 : u.slice()) || []
    });
    h && g.run.push(h), a && (g.preventDefault = !0), c && (g.stopPropagation = !0);
  };
  for (let o of n) {
    let l = o.scope ? o.scope.split(" ") : ["editor"];
    if (o.any)
      for (let a of l) {
        let c = e[a] || (e[a] = /* @__PURE__ */ Object.create(null));
        c._any || (c._any = { preventDefault: !1, stopPropagation: !1, run: [] });
        for (let f in c)
          c[f].run.push(o.any);
      }
    let h = o[t] || o.key;
    if (h)
      for (let a of l)
        r(a, h, o.run, o.preventDefault, o.stopPropagation), o.shift && r(a, "Shift-" + h, o.shift, o.preventDefault, o.stopPropagation);
  }
  return e;
}
function Eu(n, t, e, i) {
  let s = tf(t), r = di(s, 0), o = nn(r) == s.length && s != " ", l = "", h = !1, a = !1, c = !1;
  ae && ae.view == e && ae.scope == i && (l = ae.prefix + " ", Xl.indexOf(t.keyCode) < 0 && (a = !0, ae = null));
  let f = /* @__PURE__ */ new Set(), u = (g) => {
    if (g) {
      for (let y of g.run)
        if (!f.has(y) && (f.add(y), y(e, t)))
          return g.stopPropagation && (c = !0), !0;
      g.preventDefault && (g.stopPropagation && (c = !0), a = !0);
    }
    return !1;
  }, d = n[i], p, m;
  return d && (u(d[l + Wi(s, t, !o)]) ? h = !0 : o && (t.altKey || t.metaKey || t.ctrlKey) && // Ctrl-Alt may be used for AltGr on Windows
  !(C.windows && t.ctrlKey && t.altKey) && (p = ye[t.keyCode]) && p != s ? (u(d[l + Wi(p, t, !0)]) || t.shiftKey && (m = yi[t.keyCode]) != s && m != p && u(d[l + Wi(m, t, !1)])) && (h = !0) : o && t.shiftKey && u(d[l + Wi(s, t, !0)]) && (h = !0), !h && u(d._any) && (h = !0)), a && (h = !0), h && c && t.stopPropagation(), h;
}
const Nu = !C.ios, Iu = {
  ".cm-line": {
    "& ::selection": { backgroundColor: "transparent !important" },
    "&::selection": { backgroundColor: "transparent !important" }
  }
};
Nu && (Iu[".cm-line"].caretColor = "transparent !important");
function fo(n, t, e, i, s) {
  t.lastIndex = 0;
  for (let r = n.iterRange(e, i), o = e, l; !r.next().done; o += r.value.length)
    if (!r.lineBreak)
      for (; l = t.exec(r.value); )
        s(o + l.index, l);
}
function Vu(n, t) {
  let e = n.visibleRanges;
  if (e.length == 1 && e[0].from == n.viewport.from && e[0].to == n.viewport.to)
    return e;
  let i = [];
  for (let { from: s, to: r } of e)
    s = Math.max(n.state.doc.lineAt(s).from, s - t), r = Math.min(n.state.doc.lineAt(r).to, r + t), i.length && i[i.length - 1].to >= s ? i[i.length - 1].to = r : i.push({ from: s, to: r });
  return i;
}
class Hu {
  /**
  Create a decorator.
  */
  constructor(t) {
    const { regexp: e, decoration: i, decorate: s, boundary: r, maxLength: o = 1e3 } = t;
    if (!e.global)
      throw new RangeError("The regular expression given to MatchDecorator should have its 'g' flag set");
    if (this.regexp = e, s)
      this.addMatch = (l, h, a, c) => s(c, a, a + l[0].length, l, h);
    else if (typeof i == "function")
      this.addMatch = (l, h, a, c) => {
        let f = i(l, h, a);
        f && c(a, a + l[0].length, f);
      };
    else if (i)
      this.addMatch = (l, h, a, c) => c(a, a + l[0].length, i);
    else
      throw new RangeError("Either 'decorate' or 'decoration' should be provided to MatchDecorator");
    this.boundary = r, this.maxLength = o;
  }
  /**
  Compute the full set of decorations for matches in the given
  view's viewport. You'll want to call this when initializing your
  plugin.
  */
  createDeco(t) {
    let e = new Ee(), i = e.add.bind(e);
    for (let { from: s, to: r } of Vu(t, this.maxLength))
      fo(t.state.doc, this.regexp, s, r, (o, l) => this.addMatch(l, t, o, i));
    return e.finish();
  }
  /**
  Update a set of decorations for a view update. `deco` _must_ be
  the set of decorations produced by _this_ `MatchDecorator` for
  the view state before the update.
  */
  updateDeco(t, e) {
    let i = 1e9, s = -1;
    return t.docChanged && t.changes.iterChanges((r, o, l, h) => {
      h > t.view.viewport.from && l < t.view.viewport.to && (i = Math.min(l, i), s = Math.max(h, s));
    }), t.viewportChanged || s - i > 1e3 ? this.createDeco(t.view) : s > -1 ? this.updateRange(t.view, e.map(t.changes), i, s) : e;
  }
  updateRange(t, e, i, s) {
    for (let r of t.visibleRanges) {
      let o = Math.max(r.from, i), l = Math.min(r.to, s);
      if (l > o) {
        let h = t.state.doc.lineAt(o), a = h.to < l ? t.state.doc.lineAt(l) : h, c = Math.max(r.from, h.from), f = Math.min(r.to, a.to);
        if (this.boundary) {
          for (; o > h.from; o--)
            if (this.boundary.test(h.text[o - 1 - h.from])) {
              c = o;
              break;
            }
          for (; l < a.to; l++)
            if (this.boundary.test(a.text[l - a.from])) {
              f = l;
              break;
            }
        }
        let u = [], d, p = (m, g, y) => u.push(y.range(m, g));
        if (h == a)
          for (this.regexp.lastIndex = c - h.from; (d = this.regexp.exec(h.text)) && d.index < f - h.from; )
            this.addMatch(d, t, d.index + h.from, p);
        else
          fo(t.state.doc, this.regexp, c, f, (m, g) => this.addMatch(g, t, m, p));
        e = e.update({ filterFrom: c, filterTo: f, filter: (m, g) => m < c || g > f, add: u });
      }
    }
    return e;
  }
}
const Ln = /x/.unicode != null ? "gu" : "g", $u = /* @__PURE__ */ new RegExp(`[\0-\b
--­؜​‎‏\u2028\u2029‭‮⁦⁧⁩\uFEFF￹-￼]`, Ln), Fu = {
  0: "null",
  7: "bell",
  8: "backspace",
  10: "newline",
  11: "vertical tab",
  13: "carriage return",
  27: "escape",
  8203: "zero width space",
  8204: "zero width non-joiner",
  8205: "zero width joiner",
  8206: "left-to-right mark",
  8207: "right-to-left mark",
  8232: "line separator",
  8237: "left-to-right override",
  8238: "right-to-left override",
  8294: "left-to-right isolate",
  8295: "right-to-left isolate",
  8297: "pop directional isolate",
  8233: "paragraph separator",
  65279: "zero width no-break space",
  65532: "object replacement"
};
let qs = null;
function _u() {
  var n;
  if (qs == null && typeof document < "u" && document.body) {
    let t = document.body.style;
    qs = ((n = t.tabSize) !== null && n !== void 0 ? n : t.MozTabSize) != null;
  }
  return qs || !1;
}
const ss = /* @__PURE__ */ O.define({
  combine(n) {
    let t = Ds(n, {
      render: null,
      specialChars: $u,
      addSpecialChars: null
    });
    return (t.replaceTabs = !_u()) && (t.specialChars = new RegExp("	|" + t.specialChars.source, Ln)), t.addSpecialChars && (t.specialChars = new RegExp(t.specialChars.source + "|" + t.addSpecialChars.source, Ln)), t;
  }
});
function zu(n = {}) {
  return [ss.of(n), Wu()];
}
let uo = null;
function Wu() {
  return uo || (uo = yt.fromClass(class {
    constructor(n) {
      this.view = n, this.decorations = N.none, this.decorationCache = /* @__PURE__ */ Object.create(null), this.decorator = this.makeDecorator(n.state.facet(ss)), this.decorations = this.decorator.createDeco(n);
    }
    makeDecorator(n) {
      return new Hu({
        regexp: n.specialChars,
        decoration: (t, e, i) => {
          let { doc: s } = e.state, r = di(t[0], 0);
          if (r == 9) {
            let o = s.lineAt(i), l = e.state.tabSize, h = Oi(o.text, l, i - o.from);
            return N.replace({
              widget: new Gu((l - h % l) * this.view.defaultCharacterWidth / this.view.scaleX)
            });
          }
          return this.decorationCache[r] || (this.decorationCache[r] = N.replace({ widget: new qu(n, r) }));
        },
        boundary: n.replaceTabs ? void 0 : /[^]/
      });
    }
    update(n) {
      let t = n.state.facet(ss);
      n.startState.facet(ss) != t ? (this.decorator = this.makeDecorator(t), this.decorations = this.decorator.createDeco(n.view)) : this.decorations = this.decorator.updateDeco(n, this.decorations);
    }
  }, {
    decorations: (n) => n.decorations
  }));
}
const ju = "•";
function Ku(n) {
  return n >= 32 ? ju : n == 10 ? "␤" : String.fromCharCode(9216 + n);
}
class qu extends Se {
  constructor(t, e) {
    super(), this.options = t, this.code = e;
  }
  eq(t) {
    return t.code == this.code;
  }
  toDOM(t) {
    let e = Ku(this.code), i = t.state.phrase("Control character") + " " + (Fu[this.code] || "0x" + this.code.toString(16)), s = this.options.render && this.options.render(this.code, i, e);
    if (s)
      return s;
    let r = document.createElement("span");
    return r.textContent = e, r.title = i, r.setAttribute("aria-label", i), r.className = "cm-specialChar", r;
  }
  ignoreEvent() {
    return !1;
  }
}
class Gu extends Se {
  constructor(t) {
    super(), this.width = t;
  }
  eq(t) {
    return t.width == this.width;
  }
  toDOM() {
    let t = document.createElement("span");
    return t.textContent = "	", t.className = "cm-tab", t.style.width = this.width + "px", t;
  }
  ignoreEvent() {
    return !1;
  }
}
function Uu() {
  return Qu;
}
const Yu = /* @__PURE__ */ N.line({ class: "cm-activeLine" }), Qu = /* @__PURE__ */ yt.fromClass(class {
  constructor(n) {
    this.decorations = this.getDeco(n);
  }
  update(n) {
    (n.docChanged || n.selectionSet) && (this.decorations = this.getDeco(n.view));
  }
  getDeco(n) {
    let t = -1, e = [];
    for (let i of n.state.selection.ranges) {
      let s = n.lineBlockAt(i.head);
      s.from > t && (e.push(Yu.range(s.from)), t = s.from);
    }
    return N.set(e);
  }
}, {
  decorations: (n) => n.decorations
}), ni = "-10000px";
class uh {
  constructor(t, e, i) {
    this.facet = e, this.createTooltipView = i, this.input = t.state.facet(e), this.tooltips = this.input.filter((s) => s), this.tooltipViews = this.tooltips.map(i);
  }
  update(t, e) {
    var i;
    let s = t.state.facet(this.facet), r = s.filter((h) => h);
    if (s === this.input) {
      for (let h of this.tooltipViews)
        h.update && h.update(t);
      return !1;
    }
    let o = [], l = e ? [] : null;
    for (let h = 0; h < r.length; h++) {
      let a = r[h], c = -1;
      if (a) {
        for (let f = 0; f < this.tooltips.length; f++) {
          let u = this.tooltips[f];
          u && u.create == a.create && (c = f);
        }
        if (c < 0)
          o[h] = this.createTooltipView(a), l && (l[h] = !!a.above);
        else {
          let f = o[h] = this.tooltipViews[c];
          l && (l[h] = e[c]), f.update && f.update(t);
        }
      }
    }
    for (let h of this.tooltipViews)
      o.indexOf(h) < 0 && (h.dom.remove(), (i = h.destroy) === null || i === void 0 || i.call(h));
    return e && (l.forEach((h, a) => e[a] = h), e.length = l.length), this.input = s, this.tooltips = r, this.tooltipViews = o, !0;
  }
}
function Ju(n) {
  let { win: t } = n;
  return { top: 0, left: 0, bottom: t.innerHeight, right: t.innerWidth };
}
const Gs = /* @__PURE__ */ O.define({
  combine: (n) => {
    var t, e, i;
    return {
      position: C.ios ? "absolute" : ((t = n.find((s) => s.position)) === null || t === void 0 ? void 0 : t.position) || "fixed",
      parent: ((e = n.find((s) => s.parent)) === null || e === void 0 ? void 0 : e.parent) || null,
      tooltipSpace: ((i = n.find((s) => s.tooltipSpace)) === null || i === void 0 ? void 0 : i.tooltipSpace) || Ju
    };
  }
}), po = /* @__PURE__ */ new WeakMap(), Xu = /* @__PURE__ */ yt.fromClass(class {
  constructor(n) {
    this.view = n, this.above = [], this.inView = !0, this.madeAbsolute = !1, this.lastTransaction = 0, this.measureTimeout = -1;
    let t = n.state.facet(Gs);
    this.position = t.position, this.parent = t.parent, this.classes = n.themeClasses, this.createContainer(), this.measureReq = { read: this.readMeasure.bind(this), write: this.writeMeasure.bind(this), key: this }, this.manager = new uh(n, dh, (e) => this.createTooltip(e)), this.intersectionObserver = typeof IntersectionObserver == "function" ? new IntersectionObserver((e) => {
      Date.now() > this.lastTransaction - 50 && e.length > 0 && e[e.length - 1].intersectionRatio < 1 && this.measureSoon();
    }, { threshold: [1] }) : null, this.observeIntersection(), n.win.addEventListener("resize", this.measureSoon = this.measureSoon.bind(this)), this.maybeMeasure();
  }
  createContainer() {
    this.parent ? (this.container = document.createElement("div"), this.container.style.position = "relative", this.container.className = this.view.themeClasses, this.parent.appendChild(this.container)) : this.container = this.view.dom;
  }
  observeIntersection() {
    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect();
      for (let n of this.manager.tooltipViews)
        this.intersectionObserver.observe(n.dom);
    }
  }
  measureSoon() {
    this.measureTimeout < 0 && (this.measureTimeout = setTimeout(() => {
      this.measureTimeout = -1, this.maybeMeasure();
    }, 50));
  }
  update(n) {
    n.transactions.length && (this.lastTransaction = Date.now());
    let t = this.manager.update(n, this.above);
    t && this.observeIntersection();
    let e = t || n.geometryChanged, i = n.state.facet(Gs);
    if (i.position != this.position && !this.madeAbsolute) {
      this.position = i.position;
      for (let s of this.manager.tooltipViews)
        s.dom.style.position = this.position;
      e = !0;
    }
    if (i.parent != this.parent) {
      this.parent && this.container.remove(), this.parent = i.parent, this.createContainer();
      for (let s of this.manager.tooltipViews)
        this.container.appendChild(s.dom);
      e = !0;
    } else
      this.parent && this.view.themeClasses != this.classes && (this.classes = this.container.className = this.view.themeClasses);
    e && this.maybeMeasure();
  }
  createTooltip(n) {
    let t = n.create(this.view);
    if (t.dom.classList.add("cm-tooltip"), n.arrow && !t.dom.querySelector(".cm-tooltip > .cm-tooltip-arrow")) {
      let e = document.createElement("div");
      e.className = "cm-tooltip-arrow", t.dom.appendChild(e);
    }
    return t.dom.style.position = this.position, t.dom.style.top = ni, t.dom.style.left = "0px", this.container.appendChild(t.dom), t.mount && t.mount(this.view), t;
  }
  destroy() {
    var n, t;
    this.view.win.removeEventListener("resize", this.measureSoon);
    for (let e of this.manager.tooltipViews)
      e.dom.remove(), (n = e.destroy) === null || n === void 0 || n.call(e);
    this.parent && this.container.remove(), (t = this.intersectionObserver) === null || t === void 0 || t.disconnect(), clearTimeout(this.measureTimeout);
  }
  readMeasure() {
    let n = this.view.dom.getBoundingClientRect(), t = 1, e = 1, i = !1;
    if (this.position == "fixed" && this.manager.tooltipViews.length) {
      let { dom: s } = this.manager.tooltipViews[0];
      if (C.gecko)
        i = s.offsetParent != this.container.ownerDocument.body;
      else if (this.view.scaleX != 1 || this.view.scaleY != 1)
        i = !0;
      else if (s.style.top == ni && s.style.left == "0px") {
        let r = s.getBoundingClientRect();
        i = Math.abs(r.top + 1e4) > 1 || Math.abs(r.left) > 1;
      }
    }
    if (i || this.position == "absolute")
      if (this.parent) {
        let s = this.parent.getBoundingClientRect();
        s.width && s.height && (t = s.width / this.parent.offsetWidth, e = s.height / this.parent.offsetHeight);
      } else
        ({ scaleX: t, scaleY: e } = this.view.viewState);
    return {
      editor: n,
      parent: this.parent ? this.container.getBoundingClientRect() : n,
      pos: this.manager.tooltips.map((s, r) => {
        let o = this.manager.tooltipViews[r];
        return o.getCoords ? o.getCoords(s.pos) : this.view.coordsAtPos(s.pos);
      }),
      size: this.manager.tooltipViews.map(({ dom: s }) => s.getBoundingClientRect()),
      space: this.view.state.facet(Gs).tooltipSpace(this.view),
      scaleX: t,
      scaleY: e,
      makeAbsolute: i
    };
  }
  writeMeasure(n) {
    var t;
    if (n.makeAbsolute) {
      this.madeAbsolute = !0, this.position = "absolute";
      for (let l of this.manager.tooltipViews)
        l.dom.style.position = "absolute";
    }
    let { editor: e, space: i, scaleX: s, scaleY: r } = n, o = [];
    for (let l = 0; l < this.manager.tooltips.length; l++) {
      let h = this.manager.tooltips[l], a = this.manager.tooltipViews[l], { dom: c } = a, f = n.pos[l], u = n.size[l];
      if (!f || f.bottom <= Math.max(e.top, i.top) || f.top >= Math.min(e.bottom, i.bottom) || f.right < Math.max(e.left, i.left) - 0.1 || f.left > Math.min(e.right, i.right) + 0.1) {
        c.style.top = ni;
        continue;
      }
      let d = h.arrow ? a.dom.querySelector(".cm-tooltip-arrow") : null, p = d ? 7 : 0, m = u.right - u.left, g = (t = po.get(a)) !== null && t !== void 0 ? t : u.bottom - u.top, y = a.offset || td, x = this.view.textDirection == tt.LTR, S = u.width > i.right - i.left ? x ? i.left : i.right - u.width : x ? Math.min(f.left - (d ? 14 : 0) + y.x, i.right - m) : Math.max(i.left, f.left - m + (d ? 14 : 0) - y.x), v = this.above[l];
      !h.strictSide && (v ? f.top - (u.bottom - u.top) - y.y < i.top : f.bottom + (u.bottom - u.top) + y.y > i.bottom) && v == i.bottom - f.bottom > f.top - i.top && (v = this.above[l] = !v);
      let A = (v ? f.top - i.top : i.bottom - f.bottom) - p;
      if (A < g && a.resize !== !1) {
        if (A < this.view.defaultLineHeight) {
          c.style.top = ni;
          continue;
        }
        po.set(a, g), c.style.height = (g = A) / r + "px";
      } else
        c.style.height && (c.style.height = "");
      let P = v ? f.top - g - p - y.y : f.bottom + p + y.y, M = S + m;
      if (a.overlap !== !0)
        for (let I of o)
          I.left < M && I.right > S && I.top < P + g && I.bottom > P && (P = v ? I.top - g - 2 - p : I.bottom + p + 2);
      if (this.position == "absolute" ? (c.style.top = (P - n.parent.top) / r + "px", c.style.left = (S - n.parent.left) / s + "px") : (c.style.top = P / r + "px", c.style.left = S / s + "px"), d) {
        let I = f.left + (x ? y.x : -y.x) - (S + 14 - 7);
        d.style.left = I / s + "px";
      }
      a.overlap !== !0 && o.push({ left: S, top: P, right: M, bottom: P + g }), c.classList.toggle("cm-tooltip-above", v), c.classList.toggle("cm-tooltip-below", !v), a.positioned && a.positioned(n.space);
    }
  }
  maybeMeasure() {
    if (this.manager.tooltips.length && (this.view.inView && this.view.requestMeasure(this.measureReq), this.inView != this.view.inView && (this.inView = this.view.inView, !this.inView)))
      for (let n of this.manager.tooltipViews)
        n.dom.style.top = ni;
  }
}, {
  eventObservers: {
    scroll() {
      this.maybeMeasure();
    }
  }
}), Zu = /* @__PURE__ */ T.baseTheme({
  ".cm-tooltip": {
    zIndex: 100,
    boxSizing: "border-box"
  },
  "&light .cm-tooltip": {
    border: "1px solid #bbb",
    backgroundColor: "#f5f5f5"
  },
  "&light .cm-tooltip-section:not(:first-child)": {
    borderTop: "1px solid #bbb"
  },
  "&dark .cm-tooltip": {
    backgroundColor: "#333338",
    color: "white"
  },
  ".cm-tooltip-arrow": {
    height: "7px",
    width: `${7 * 2}px`,
    position: "absolute",
    zIndex: -1,
    overflow: "hidden",
    "&:before, &:after": {
      content: "''",
      position: "absolute",
      width: 0,
      height: 0,
      borderLeft: "7px solid transparent",
      borderRight: "7px solid transparent"
    },
    ".cm-tooltip-above &": {
      bottom: "-7px",
      "&:before": {
        borderTop: "7px solid #bbb"
      },
      "&:after": {
        borderTop: "7px solid #f5f5f5",
        bottom: "1px"
      }
    },
    ".cm-tooltip-below &": {
      top: "-7px",
      "&:before": {
        borderBottom: "7px solid #bbb"
      },
      "&:after": {
        borderBottom: "7px solid #f5f5f5",
        top: "1px"
      }
    }
  },
  "&dark .cm-tooltip .cm-tooltip-arrow": {
    "&:before": {
      borderTopColor: "#333338",
      borderBottomColor: "#333338"
    },
    "&:after": {
      borderTopColor: "transparent",
      borderBottomColor: "transparent"
    }
  }
}), td = { x: 0, y: 0 }, dh = /* @__PURE__ */ O.define({
  enables: [Xu, Zu]
}), ms = /* @__PURE__ */ O.define();
class nr {
  // Needs to be static so that host tooltip instances always match
  static create(t) {
    return new nr(t);
  }
  constructor(t) {
    this.view = t, this.mounted = !1, this.dom = document.createElement("div"), this.dom.classList.add("cm-tooltip-hover"), this.manager = new uh(t, ms, (e) => this.createHostedView(e));
  }
  createHostedView(t) {
    let e = t.create(this.view);
    return e.dom.classList.add("cm-tooltip-section"), this.dom.appendChild(e.dom), this.mounted && e.mount && e.mount(this.view), e;
  }
  mount(t) {
    for (let e of this.manager.tooltipViews)
      e.mount && e.mount(t);
    this.mounted = !0;
  }
  positioned(t) {
    for (let e of this.manager.tooltipViews)
      e.positioned && e.positioned(t);
  }
  update(t) {
    this.manager.update(t);
  }
  destroy() {
    var t;
    for (let e of this.manager.tooltipViews)
      (t = e.destroy) === null || t === void 0 || t.call(e);
  }
  passProp(t) {
    let e;
    for (let i of this.manager.tooltipViews) {
      let s = i[t];
      if (s !== void 0) {
        if (e === void 0)
          e = s;
        else if (e !== s)
          return;
      }
    }
    return e;
  }
  get offset() {
    return this.passProp("offset");
  }
  get getCoords() {
    return this.passProp("getCoords");
  }
  get overlap() {
    return this.passProp("overlap");
  }
  get resize() {
    return this.passProp("resize");
  }
}
const ed = /* @__PURE__ */ dh.compute([ms], (n) => {
  let t = n.facet(ms).filter((e) => e);
  return t.length === 0 ? null : {
    pos: Math.min(...t.map((e) => e.pos)),
    end: Math.max(...t.filter((e) => e.end != null).map((e) => e.end)),
    create: nr.create,
    above: t[0].above,
    arrow: t.some((e) => e.arrow)
  };
});
class id {
  constructor(t, e, i, s, r) {
    this.view = t, this.source = e, this.field = i, this.setHover = s, this.hoverTime = r, this.hoverTimeout = -1, this.restartTimeout = -1, this.pending = null, this.lastMove = { x: 0, y: 0, target: t.dom, time: 0 }, this.checkHover = this.checkHover.bind(this), t.dom.addEventListener("mouseleave", this.mouseleave = this.mouseleave.bind(this)), t.dom.addEventListener("mousemove", this.mousemove = this.mousemove.bind(this));
  }
  update() {
    this.pending && (this.pending = null, clearTimeout(this.restartTimeout), this.restartTimeout = setTimeout(() => this.startHover(), 20));
  }
  get active() {
    return this.view.state.field(this.field);
  }
  checkHover() {
    if (this.hoverTimeout = -1, this.active)
      return;
    let t = Date.now() - this.lastMove.time;
    t < this.hoverTime ? this.hoverTimeout = setTimeout(this.checkHover, this.hoverTime - t) : this.startHover();
  }
  startHover() {
    clearTimeout(this.restartTimeout);
    let { view: t, lastMove: e } = this, i = t.docView.nearest(e.target);
    if (!i)
      return;
    let s, r = 1;
    if (i instanceof fe)
      s = i.posAtStart;
    else {
      if (s = t.posAtCoords(e), s == null)
        return;
      let l = t.coordsAtPos(s);
      if (!l || e.y < l.top || e.y > l.bottom || e.x < l.left - t.defaultCharacterWidth || e.x > l.right + t.defaultCharacterWidth)
        return;
      let h = t.bidiSpans(t.state.doc.lineAt(s)).find((c) => c.from <= s && c.to >= s), a = h && h.dir == tt.RTL ? -1 : 1;
      r = e.x < l.left ? -a : a;
    }
    let o = this.source(t, s, r);
    if (o != null && o.then) {
      let l = this.pending = { pos: s };
      o.then((h) => {
        this.pending == l && (this.pending = null, h && t.dispatch({ effects: this.setHover.of(h) }));
      }, (h) => ie(t.state, h, "hover tooltip"));
    } else
      o && t.dispatch({ effects: this.setHover.of(o) });
  }
  mousemove(t) {
    var e;
    this.lastMove = { x: t.clientX, y: t.clientY, target: t.target, time: Date.now() }, this.hoverTimeout < 0 && (this.hoverTimeout = setTimeout(this.checkHover, this.hoverTime));
    let i = this.active;
    if (i && !go(this.lastMove.target) || this.pending) {
      let { pos: s } = i || this.pending, r = (e = i == null ? void 0 : i.end) !== null && e !== void 0 ? e : s;
      (s == r ? this.view.posAtCoords(this.lastMove) != s : !sd(this.view, s, r, t.clientX, t.clientY)) && (this.view.dispatch({ effects: this.setHover.of(null) }), this.pending = null);
    }
  }
  mouseleave(t) {
    clearTimeout(this.hoverTimeout), this.hoverTimeout = -1, this.active && !go(t.relatedTarget) && this.view.dispatch({ effects: this.setHover.of(null) });
  }
  destroy() {
    clearTimeout(this.hoverTimeout), this.view.dom.removeEventListener("mouseleave", this.mouseleave), this.view.dom.removeEventListener("mousemove", this.mousemove);
  }
}
function go(n) {
  for (let t = n; t; t = t.parentNode)
    if (t.nodeType == 1 && t.classList.contains("cm-tooltip"))
      return !0;
  return !1;
}
function sd(n, t, e, i, s, r) {
  let o = n.scrollDOM.getBoundingClientRect(), l = n.documentTop + n.documentPadding.top + n.contentHeight;
  if (o.left > i || o.right < i || o.top > s || Math.min(o.bottom, l) < s)
    return !1;
  let h = n.posAtCoords({ x: i, y: s }, !1);
  return h >= t && h <= e;
}
function nd(n, t = {}) {
  let e = z.define(), i = Ht.define({
    create() {
      return null;
    },
    update(s, r) {
      if (s && (t.hideOnChange && (r.docChanged || r.selection) || t.hideOn && t.hideOn(r, s)))
        return null;
      if (s && r.docChanged) {
        let o = r.changes.mapPos(s.pos, -1, mt.TrackDel);
        if (o == null)
          return null;
        let l = Object.assign(/* @__PURE__ */ Object.create(null), s);
        l.pos = o, s.end != null && (l.end = r.changes.mapPos(s.end)), s = l;
      }
      for (let o of r.effects)
        o.is(e) && (s = o.value), o.is(rd) && (s = null);
      return s;
    },
    provide: (s) => ms.from(s)
  });
  return [
    i,
    yt.define((s) => new id(
      s,
      n,
      i,
      e,
      t.hoverTime || 300
      /* Hover.Time */
    )),
    ed
  ];
}
const rd = /* @__PURE__ */ z.define(), mo = /* @__PURE__ */ O.define({
  combine(n) {
    let t, e;
    for (let i of n)
      t = t || i.topContainer, e = e || i.bottomContainer;
    return { topContainer: t, bottomContainer: e };
  }
});
function od(n, t) {
  let e = n.plugin(ph), i = e ? e.specs.indexOf(t) : -1;
  return i > -1 ? e.panels[i] : null;
}
const ph = /* @__PURE__ */ yt.fromClass(class {
  constructor(n) {
    this.input = n.state.facet(En), this.specs = this.input.filter((e) => e), this.panels = this.specs.map((e) => e(n));
    let t = n.state.facet(mo);
    this.top = new ji(n, !0, t.topContainer), this.bottom = new ji(n, !1, t.bottomContainer), this.top.sync(this.panels.filter((e) => e.top)), this.bottom.sync(this.panels.filter((e) => !e.top));
    for (let e of this.panels)
      e.dom.classList.add("cm-panel"), e.mount && e.mount();
  }
  update(n) {
    let t = n.state.facet(mo);
    this.top.container != t.topContainer && (this.top.sync([]), this.top = new ji(n.view, !0, t.topContainer)), this.bottom.container != t.bottomContainer && (this.bottom.sync([]), this.bottom = new ji(n.view, !1, t.bottomContainer)), this.top.syncClasses(), this.bottom.syncClasses();
    let e = n.state.facet(En);
    if (e != this.input) {
      let i = e.filter((h) => h), s = [], r = [], o = [], l = [];
      for (let h of i) {
        let a = this.specs.indexOf(h), c;
        a < 0 ? (c = h(n.view), l.push(c)) : (c = this.panels[a], c.update && c.update(n)), s.push(c), (c.top ? r : o).push(c);
      }
      this.specs = i, this.panels = s, this.top.sync(r), this.bottom.sync(o);
      for (let h of l)
        h.dom.classList.add("cm-panel"), h.mount && h.mount();
    } else
      for (let i of this.panels)
        i.update && i.update(n);
  }
  destroy() {
    this.top.sync([]), this.bottom.sync([]);
  }
}, {
  provide: (n) => T.scrollMargins.of((t) => {
    let e = t.plugin(n);
    return e && { top: e.top.scrollMargin(), bottom: e.bottom.scrollMargin() };
  })
});
class ji {
  constructor(t, e, i) {
    this.view = t, this.top = e, this.container = i, this.dom = void 0, this.classes = "", this.panels = [], this.syncClasses();
  }
  sync(t) {
    for (let e of this.panels)
      e.destroy && t.indexOf(e) < 0 && e.destroy();
    this.panels = t, this.syncDOM();
  }
  syncDOM() {
    if (this.panels.length == 0) {
      this.dom && (this.dom.remove(), this.dom = void 0);
      return;
    }
    if (!this.dom) {
      this.dom = document.createElement("div"), this.dom.className = this.top ? "cm-panels cm-panels-top" : "cm-panels cm-panels-bottom", this.dom.style[this.top ? "top" : "bottom"] = "0";
      let e = this.container || this.view.dom;
      e.insertBefore(this.dom, this.top ? e.firstChild : null);
    }
    let t = this.dom.firstChild;
    for (let e of this.panels)
      if (e.dom.parentNode == this.dom) {
        for (; t != e.dom; )
          t = wo(t);
        t = t.nextSibling;
      } else
        this.dom.insertBefore(e.dom, t);
    for (; t; )
      t = wo(t);
  }
  scrollMargin() {
    return !this.dom || this.container ? 0 : Math.max(0, this.top ? this.dom.getBoundingClientRect().bottom - Math.max(0, this.view.scrollDOM.getBoundingClientRect().top) : Math.min(innerHeight, this.view.scrollDOM.getBoundingClientRect().bottom) - this.dom.getBoundingClientRect().top);
  }
  syncClasses() {
    if (!(!this.container || this.classes == this.view.themeClasses)) {
      for (let t of this.classes.split(" "))
        t && this.container.classList.remove(t);
      for (let t of (this.classes = this.view.themeClasses).split(" "))
        t && this.container.classList.add(t);
    }
  }
}
function wo(n) {
  let t = n.nextSibling;
  return n.remove(), t;
}
const En = /* @__PURE__ */ O.define({
  enables: ph
});
class ke extends Qe {
  /**
  @internal
  */
  compare(t) {
    return this == t || this.constructor == t.constructor && this.eq(t);
  }
  /**
  Compare this marker to another marker of the same type.
  */
  eq(t) {
    return !1;
  }
  /**
  Called if the marker has a `toDOM` method and its representation
  was removed from a gutter.
  */
  destroy(t) {
  }
}
ke.prototype.elementClass = "";
ke.prototype.toDOM = void 0;
ke.prototype.mapMode = mt.TrackBefore;
ke.prototype.startSide = ke.prototype.endSide = -1;
ke.prototype.point = !0;
const ns = /* @__PURE__ */ O.define(), ld = {
  class: "",
  renderEmptyElements: !1,
  elementStyle: "",
  markers: () => F.empty,
  lineMarker: () => null,
  widgetMarker: () => null,
  lineMarkerChange: null,
  initialSpacer: null,
  updateSpacer: null,
  domEventHandlers: {}
}, rs = /* @__PURE__ */ O.define();
function hd(n) {
  return [ad(), rs.of(Object.assign(Object.assign({}, ld), n))];
}
const Nn = /* @__PURE__ */ O.define({
  combine: (n) => n.some((t) => t)
});
function ad(n) {
  let t = [
    cd
  ];
  return n && n.fixed === !1 && t.push(Nn.of(!0)), t;
}
const cd = /* @__PURE__ */ yt.fromClass(class {
  constructor(n) {
    this.view = n, this.prevViewport = n.viewport, this.dom = document.createElement("div"), this.dom.className = "cm-gutters", this.dom.setAttribute("aria-hidden", "true"), this.dom.style.minHeight = this.view.contentHeight / this.view.scaleY + "px", this.gutters = n.state.facet(rs).map((t) => new bo(n, t));
    for (let t of this.gutters)
      this.dom.appendChild(t.dom);
    this.fixed = !n.state.facet(Nn), this.fixed && (this.dom.style.position = "sticky"), this.syncGutters(!1), n.scrollDOM.insertBefore(this.dom, n.contentDOM);
  }
  update(n) {
    if (this.updateGutters(n)) {
      let t = this.prevViewport, e = n.view.viewport, i = Math.min(t.to, e.to) - Math.max(t.from, e.from);
      this.syncGutters(i < (e.to - e.from) * 0.8);
    }
    n.geometryChanged && (this.dom.style.minHeight = this.view.contentHeight + "px"), this.view.state.facet(Nn) != !this.fixed && (this.fixed = !this.fixed, this.dom.style.position = this.fixed ? "sticky" : ""), this.prevViewport = n.view.viewport;
  }
  syncGutters(n) {
    let t = this.dom.nextSibling;
    n && this.dom.remove();
    let e = F.iter(this.view.state.facet(ns), this.view.viewport.from), i = [], s = this.gutters.map((r) => new fd(r, this.view.viewport, -this.view.documentPadding.top));
    for (let r of this.view.viewportLineBlocks)
      if (i.length && (i = []), Array.isArray(r.type)) {
        let o = !0;
        for (let l of r.type)
          if (l.type == Lt.Text && o) {
            In(e, i, l.from);
            for (let h of s)
              h.line(this.view, l, i);
            o = !1;
          } else if (l.widget)
            for (let h of s)
              h.widget(this.view, l);
      } else if (r.type == Lt.Text) {
        In(e, i, r.from);
        for (let o of s)
          o.line(this.view, r, i);
      } else if (r.widget)
        for (let o of s)
          o.widget(this.view, r);
    for (let r of s)
      r.finish();
    n && this.view.scrollDOM.insertBefore(this.dom, t);
  }
  updateGutters(n) {
    let t = n.startState.facet(rs), e = n.state.facet(rs), i = n.docChanged || n.heightChanged || n.viewportChanged || !F.eq(n.startState.facet(ns), n.state.facet(ns), n.view.viewport.from, n.view.viewport.to);
    if (t == e)
      for (let s of this.gutters)
        s.update(n) && (i = !0);
    else {
      i = !0;
      let s = [];
      for (let r of e) {
        let o = t.indexOf(r);
        o < 0 ? s.push(new bo(this.view, r)) : (this.gutters[o].update(n), s.push(this.gutters[o]));
      }
      for (let r of this.gutters)
        r.dom.remove(), s.indexOf(r) < 0 && r.destroy();
      for (let r of s)
        this.dom.appendChild(r.dom);
      this.gutters = s;
    }
    return i;
  }
  destroy() {
    for (let n of this.gutters)
      n.destroy();
    this.dom.remove();
  }
}, {
  provide: (n) => T.scrollMargins.of((t) => {
    let e = t.plugin(n);
    return !e || e.gutters.length == 0 || !e.fixed ? null : t.textDirection == tt.LTR ? { left: e.dom.offsetWidth * t.scaleX } : { right: e.dom.offsetWidth * t.scaleX };
  })
});
function yo(n) {
  return Array.isArray(n) ? n : [n];
}
function In(n, t, e) {
  for (; n.value && n.from <= e; )
    n.from == e && t.push(n.value), n.next();
}
class fd {
  constructor(t, e, i) {
    this.gutter = t, this.height = i, this.i = 0, this.cursor = F.iter(t.markers, e.from);
  }
  addElement(t, e, i) {
    let { gutter: s } = this, r = (e.top - this.height) / t.scaleY, o = e.height / t.scaleY;
    if (this.i == s.elements.length) {
      let l = new gh(t, o, r, i);
      s.elements.push(l), s.dom.appendChild(l.dom);
    } else
      s.elements[this.i].update(t, o, r, i);
    this.height = e.bottom, this.i++;
  }
  line(t, e, i) {
    let s = [];
    In(this.cursor, s, e.from), i.length && (s = s.concat(i));
    let r = this.gutter.config.lineMarker(t, e, s);
    r && s.unshift(r);
    let o = this.gutter;
    s.length == 0 && !o.config.renderEmptyElements || this.addElement(t, e, s);
  }
  widget(t, e) {
    let i = this.gutter.config.widgetMarker(t, e.widget, e);
    i && this.addElement(t, e, [i]);
  }
  finish() {
    let t = this.gutter;
    for (; t.elements.length > this.i; ) {
      let e = t.elements.pop();
      t.dom.removeChild(e.dom), e.destroy();
    }
  }
}
class bo {
  constructor(t, e) {
    this.view = t, this.config = e, this.elements = [], this.spacer = null, this.dom = document.createElement("div"), this.dom.className = "cm-gutter" + (this.config.class ? " " + this.config.class : "");
    for (let i in e.domEventHandlers)
      this.dom.addEventListener(i, (s) => {
        let r = s.target, o;
        if (r != this.dom && this.dom.contains(r)) {
          for (; r.parentNode != this.dom; )
            r = r.parentNode;
          let h = r.getBoundingClientRect();
          o = (h.top + h.bottom) / 2;
        } else
          o = s.clientY;
        let l = t.lineBlockAtHeight(o - t.documentTop);
        e.domEventHandlers[i](t, l, s) && s.preventDefault();
      });
    this.markers = yo(e.markers(t)), e.initialSpacer && (this.spacer = new gh(t, 0, 0, [e.initialSpacer(t)]), this.dom.appendChild(this.spacer.dom), this.spacer.dom.style.cssText += "visibility: hidden; pointer-events: none");
  }
  update(t) {
    let e = this.markers;
    if (this.markers = yo(this.config.markers(t.view)), this.spacer && this.config.updateSpacer) {
      let s = this.config.updateSpacer(this.spacer.markers[0], t);
      s != this.spacer.markers[0] && this.spacer.update(t.view, 0, 0, [s]);
    }
    let i = t.view.viewport;
    return !F.eq(this.markers, e, i.from, i.to) || (this.config.lineMarkerChange ? this.config.lineMarkerChange(t) : !1);
  }
  destroy() {
    for (let t of this.elements)
      t.destroy();
  }
}
class gh {
  constructor(t, e, i, s) {
    this.height = -1, this.above = 0, this.markers = [], this.dom = document.createElement("div"), this.dom.className = "cm-gutterElement", this.update(t, e, i, s);
  }
  update(t, e, i, s) {
    this.height != e && (this.height = e, this.dom.style.height = e + "px"), this.above != i && (this.dom.style.marginTop = (this.above = i) ? i + "px" : ""), ud(this.markers, s) || this.setMarkers(t, s);
  }
  setMarkers(t, e) {
    let i = "cm-gutterElement", s = this.dom.firstChild;
    for (let r = 0, o = 0; ; ) {
      let l = o, h = r < e.length ? e[r++] : null, a = !1;
      if (h) {
        let c = h.elementClass;
        c && (i += " " + c);
        for (let f = o; f < this.markers.length; f++)
          if (this.markers[f].compare(h)) {
            l = f, a = !0;
            break;
          }
      } else
        l = this.markers.length;
      for (; o < l; ) {
        let c = this.markers[o++];
        if (c.toDOM) {
          c.destroy(s);
          let f = s.nextSibling;
          s.remove(), s = f;
        }
      }
      if (!h)
        break;
      h.toDOM && (a ? s = s.nextSibling : this.dom.insertBefore(h.toDOM(t), s)), a && o++;
    }
    this.dom.className = i, this.markers = e;
  }
  destroy() {
    this.setMarkers(null, []);
  }
}
function ud(n, t) {
  if (n.length != t.length)
    return !1;
  for (let e = 0; e < n.length; e++)
    if (!n[e].compare(t[e]))
      return !1;
  return !0;
}
const dd = /* @__PURE__ */ new class extends ke {
  constructor() {
    super(...arguments), this.elementClass = "cm-activeLineGutter";
  }
}(), pd = /* @__PURE__ */ ns.compute(["selection"], (n) => {
  let t = [], e = -1;
  for (let i of n.selection.ranges) {
    let s = n.doc.lineAt(i.head).from;
    s > e && (e = s, t.push(dd.range(s)));
  }
  return F.of(t);
});
function gd() {
  return pd;
}
const mh = 1024;
let md = 0;
class Us {
  constructor(t, e) {
    this.from = t, this.to = e;
  }
}
class R {
  /**
  Create a new node prop type.
  */
  constructor(t = {}) {
    this.id = md++, this.perNode = !!t.perNode, this.deserialize = t.deserialize || (() => {
      throw new Error("This node type doesn't define a deserialize function");
    });
  }
  /**
  This is meant to be used with
  [`NodeSet.extend`](#common.NodeSet.extend) or
  [`LRParser.configure`](#lr.ParserConfig.props) to compute
  prop values for each node type in the set. Takes a [match
  object](#common.NodeType^match) or function that returns undefined
  if the node type doesn't get this prop, and the prop's value if
  it does.
  */
  add(t) {
    if (this.perNode)
      throw new RangeError("Can't add per-node props to node types");
    return typeof t != "function" && (t = bt.match(t)), (e) => {
      let i = t(e);
      return i === void 0 ? null : [this, i];
    };
  }
}
R.closedBy = new R({ deserialize: (n) => n.split(" ") });
R.openedBy = new R({ deserialize: (n) => n.split(" ") });
R.group = new R({ deserialize: (n) => n.split(" ") });
R.contextHash = new R({ perNode: !0 });
R.lookAhead = new R({ perNode: !0 });
R.mounted = new R({ perNode: !0 });
class ws {
  constructor(t, e, i) {
    this.tree = t, this.overlay = e, this.parser = i;
  }
  /**
  @internal
  */
  static get(t) {
    return t && t.props && t.props[R.mounted.id];
  }
}
const wd = /* @__PURE__ */ Object.create(null);
class bt {
  /**
  @internal
  */
  constructor(t, e, i, s = 0) {
    this.name = t, this.props = e, this.id = i, this.flags = s;
  }
  /**
  Define a node type.
  */
  static define(t) {
    let e = t.props && t.props.length ? /* @__PURE__ */ Object.create(null) : wd, i = (t.top ? 1 : 0) | (t.skipped ? 2 : 0) | (t.error ? 4 : 0) | (t.name == null ? 8 : 0), s = new bt(t.name || "", e, t.id, i);
    if (t.props) {
      for (let r of t.props)
        if (Array.isArray(r) || (r = r(s)), r) {
          if (r[0].perNode)
            throw new RangeError("Can't store a per-node prop on a node type");
          e[r[0].id] = r[1];
        }
    }
    return s;
  }
  /**
  Retrieves a node prop for this type. Will return `undefined` if
  the prop isn't present on this node.
  */
  prop(t) {
    return this.props[t.id];
  }
  /**
  True when this is the top node of a grammar.
  */
  get isTop() {
    return (this.flags & 1) > 0;
  }
  /**
  True when this node is produced by a skip rule.
  */
  get isSkipped() {
    return (this.flags & 2) > 0;
  }
  /**
  Indicates whether this is an error node.
  */
  get isError() {
    return (this.flags & 4) > 0;
  }
  /**
  When true, this node type doesn't correspond to a user-declared
  named node, for example because it is used to cache repetition.
  */
  get isAnonymous() {
    return (this.flags & 8) > 0;
  }
  /**
  Returns true when this node's name or one of its
  [groups](#common.NodeProp^group) matches the given string.
  */
  is(t) {
    if (typeof t == "string") {
      if (this.name == t)
        return !0;
      let e = this.prop(R.group);
      return e ? e.indexOf(t) > -1 : !1;
    }
    return this.id == t;
  }
  /**
  Create a function from node types to arbitrary values by
  specifying an object whose property names are node or
  [group](#common.NodeProp^group) names. Often useful with
  [`NodeProp.add`](#common.NodeProp.add). You can put multiple
  names, separated by spaces, in a single property name to map
  multiple node names to a single value.
  */
  static match(t) {
    let e = /* @__PURE__ */ Object.create(null);
    for (let i in t)
      for (let s of i.split(" "))
        e[s] = t[i];
    return (i) => {
      for (let s = i.prop(R.group), r = -1; r < (s ? s.length : 0); r++) {
        let o = e[r < 0 ? i.name : s[r]];
        if (o)
          return o;
      }
    };
  }
}
bt.none = new bt(
  "",
  /* @__PURE__ */ Object.create(null),
  0,
  8
  /* NodeFlag.Anonymous */
);
class rr {
  /**
  Create a set with the given types. The `id` property of each
  type should correspond to its position within the array.
  */
  constructor(t) {
    this.types = t;
    for (let e = 0; e < t.length; e++)
      if (t[e].id != e)
        throw new RangeError("Node type ids should correspond to array positions when creating a node set");
  }
  /**
  Create a copy of this set with some node properties added. The
  arguments to this method can be created with
  [`NodeProp.add`](#common.NodeProp.add).
  */
  extend(...t) {
    let e = [];
    for (let i of this.types) {
      let s = null;
      for (let r of t) {
        let o = r(i);
        o && (s || (s = Object.assign({}, i.props)), s[o[0].id] = o[1]);
      }
      e.push(s ? new bt(i.name, s, i.id, i.flags) : i);
    }
    return new rr(e);
  }
}
const Ki = /* @__PURE__ */ new WeakMap(), ko = /* @__PURE__ */ new WeakMap();
var st;
(function(n) {
  n[n.ExcludeBuffers = 1] = "ExcludeBuffers", n[n.IncludeAnonymous = 2] = "IncludeAnonymous", n[n.IgnoreMounts = 4] = "IgnoreMounts", n[n.IgnoreOverlays = 8] = "IgnoreOverlays";
})(st || (st = {}));
class X {
  /**
  Construct a new tree. See also [`Tree.build`](#common.Tree^build).
  */
  constructor(t, e, i, s, r) {
    if (this.type = t, this.children = e, this.positions = i, this.length = s, this.props = null, r && r.length) {
      this.props = /* @__PURE__ */ Object.create(null);
      for (let [o, l] of r)
        this.props[typeof o == "number" ? o : o.id] = l;
    }
  }
  /**
  @internal
  */
  toString() {
    let t = ws.get(this);
    if (t && !t.overlay)
      return t.tree.toString();
    let e = "";
    for (let i of this.children) {
      let s = i.toString();
      s && (e && (e += ","), e += s);
    }
    return this.type.name ? (/\W/.test(this.type.name) && !this.type.isError ? JSON.stringify(this.type.name) : this.type.name) + (e.length ? "(" + e + ")" : "") : e;
  }
  /**
  Get a [tree cursor](#common.TreeCursor) positioned at the top of
  the tree. Mode can be used to [control](#common.IterMode) which
  nodes the cursor visits.
  */
  cursor(t = 0) {
    return new Hn(this.topNode, t);
  }
  /**
  Get a [tree cursor](#common.TreeCursor) pointing into this tree
  at the given position and side (see
  [`moveTo`](#common.TreeCursor.moveTo).
  */
  cursorAt(t, e = 0, i = 0) {
    let s = Ki.get(this) || this.topNode, r = new Hn(s);
    return r.moveTo(t, e), Ki.set(this, r._tree), r;
  }
  /**
  Get a [syntax node](#common.SyntaxNode) object for the top of the
  tree.
  */
  get topNode() {
    return new Tt(this, 0, 0, null);
  }
  /**
  Get the [syntax node](#common.SyntaxNode) at the given position.
  If `side` is -1, this will move into nodes that end at the
  position. If 1, it'll move into nodes that start at the
  position. With 0, it'll only enter nodes that cover the position
  from both sides.
  
  Note that this will not enter
  [overlays](#common.MountedTree.overlay), and you often want
  [`resolveInner`](#common.Tree.resolveInner) instead.
  */
  resolve(t, e = 0) {
    let i = Si(Ki.get(this) || this.topNode, t, e, !1);
    return Ki.set(this, i), i;
  }
  /**
  Like [`resolve`](#common.Tree.resolve), but will enter
  [overlaid](#common.MountedTree.overlay) nodes, producing a syntax node
  pointing into the innermost overlaid tree at the given position
  (with parent links going through all parent structure, including
  the host trees).
  */
  resolveInner(t, e = 0) {
    let i = Si(ko.get(this) || this.topNode, t, e, !0);
    return ko.set(this, i), i;
  }
  /**
  In some situations, it can be useful to iterate through all
  nodes around a position, including those in overlays that don't
  directly cover the position. This method gives you an iterator
  that will produce all nodes, from small to big, around the given
  position.
  */
  resolveStack(t, e = 0) {
    return kd(this, t, e);
  }
  /**
  Iterate over the tree and its children, calling `enter` for any
  node that touches the `from`/`to` region (if given) before
  running over such a node's children, and `leave` (if given) when
  leaving the node. When `enter` returns `false`, that node will
  not have its children iterated over (or `leave` called).
  */
  iterate(t) {
    let { enter: e, leave: i, from: s = 0, to: r = this.length } = t, o = t.mode || 0, l = (o & st.IncludeAnonymous) > 0;
    for (let h = this.cursor(o | st.IncludeAnonymous); ; ) {
      let a = !1;
      if (h.from <= r && h.to >= s && (!l && h.type.isAnonymous || e(h) !== !1)) {
        if (h.firstChild())
          continue;
        a = !0;
      }
      for (; a && i && (l || !h.type.isAnonymous) && i(h), !h.nextSibling(); ) {
        if (!h.parent())
          return;
        a = !0;
      }
    }
  }
  /**
  Get the value of the given [node prop](#common.NodeProp) for this
  node. Works with both per-node and per-type props.
  */
  prop(t) {
    return t.perNode ? this.props ? this.props[t.id] : void 0 : this.type.prop(t);
  }
  /**
  Returns the node's [per-node props](#common.NodeProp.perNode) in a
  format that can be passed to the [`Tree`](#common.Tree)
  constructor.
  */
  get propValues() {
    let t = [];
    if (this.props)
      for (let e in this.props)
        t.push([+e, this.props[e]]);
    return t;
  }
  /**
  Balance the direct children of this tree, producing a copy of
  which may have children grouped into subtrees with type
  [`NodeType.none`](#common.NodeType^none).
  */
  balance(t = {}) {
    return this.children.length <= 8 ? this : hr(bt.none, this.children, this.positions, 0, this.children.length, 0, this.length, (e, i, s) => new X(this.type, e, i, s, this.propValues), t.makeTree || ((e, i, s) => new X(bt.none, e, i, s)));
  }
  /**
  Build a tree from a postfix-ordered buffer of node information,
  or a cursor over such a buffer.
  */
  static build(t) {
    return xd(t);
  }
}
X.empty = new X(bt.none, [], [], 0);
class or {
  constructor(t, e) {
    this.buffer = t, this.index = e;
  }
  get id() {
    return this.buffer[this.index - 4];
  }
  get start() {
    return this.buffer[this.index - 3];
  }
  get end() {
    return this.buffer[this.index - 2];
  }
  get size() {
    return this.buffer[this.index - 1];
  }
  get pos() {
    return this.index;
  }
  next() {
    this.index -= 4;
  }
  fork() {
    return new or(this.buffer, this.index);
  }
}
class xe {
  /**
  Create a tree buffer.
  */
  constructor(t, e, i) {
    this.buffer = t, this.length = e, this.set = i;
  }
  /**
  @internal
  */
  get type() {
    return bt.none;
  }
  /**
  @internal
  */
  toString() {
    let t = [];
    for (let e = 0; e < this.buffer.length; )
      t.push(this.childString(e)), e = this.buffer[e + 3];
    return t.join(",");
  }
  /**
  @internal
  */
  childString(t) {
    let e = this.buffer[t], i = this.buffer[t + 3], s = this.set.types[e], r = s.name;
    if (/\W/.test(r) && !s.isError && (r = JSON.stringify(r)), t += 4, i == t)
      return r;
    let o = [];
    for (; t < i; )
      o.push(this.childString(t)), t = this.buffer[t + 3];
    return r + "(" + o.join(",") + ")";
  }
  /**
  @internal
  */
  findChild(t, e, i, s, r) {
    let { buffer: o } = this, l = -1;
    for (let h = t; h != e && !(wh(r, s, o[h + 1], o[h + 2]) && (l = h, i > 0)); h = o[h + 3])
      ;
    return l;
  }
  /**
  @internal
  */
  slice(t, e, i) {
    let s = this.buffer, r = new Uint16Array(e - t), o = 0;
    for (let l = t, h = 0; l < e; ) {
      r[h++] = s[l++], r[h++] = s[l++] - i;
      let a = r[h++] = s[l++] - i;
      r[h++] = s[l++] - t, o = Math.max(o, a);
    }
    return new xe(r, o, this.set);
  }
}
function wh(n, t, e, i) {
  switch (n) {
    case -2:
      return e < t;
    case -1:
      return i >= t && e < t;
    case 0:
      return e < t && i > t;
    case 1:
      return e <= t && i > t;
    case 2:
      return i > t;
    case 4:
      return !0;
  }
}
function Si(n, t, e, i) {
  for (var s; n.from == n.to || (e < 1 ? n.from >= t : n.from > t) || (e > -1 ? n.to <= t : n.to < t); ) {
    let o = !i && n instanceof Tt && n.index < 0 ? null : n.parent;
    if (!o)
      return n;
    n = o;
  }
  let r = i ? 0 : st.IgnoreOverlays;
  if (i)
    for (let o = n, l = o.parent; l; o = l, l = o.parent)
      o instanceof Tt && o.index < 0 && ((s = l.enter(t, e, r)) === null || s === void 0 ? void 0 : s.from) != o.from && (n = l);
  for (; ; ) {
    let o = n.enter(t, e, r);
    if (!o)
      return n;
    n = o;
  }
}
class yh {
  cursor(t = 0) {
    return new Hn(this, t);
  }
  getChild(t, e = null, i = null) {
    let s = xo(this, t, e, i);
    return s.length ? s[0] : null;
  }
  getChildren(t, e = null, i = null) {
    return xo(this, t, e, i);
  }
  resolve(t, e = 0) {
    return Si(this, t, e, !1);
  }
  resolveInner(t, e = 0) {
    return Si(this, t, e, !0);
  }
  matchContext(t) {
    return Vn(this, t);
  }
  enterUnfinishedNodesBefore(t) {
    let e = this.childBefore(t), i = this;
    for (; e; ) {
      let s = e.lastChild;
      if (!s || s.to != e.to)
        break;
      s.type.isError && s.from == s.to ? (i = e, e = s.prevSibling) : e = s;
    }
    return i;
  }
  get node() {
    return this;
  }
  get next() {
    return this.parent;
  }
}
class Tt extends yh {
  constructor(t, e, i, s) {
    super(), this._tree = t, this.from = e, this.index = i, this._parent = s;
  }
  get type() {
    return this._tree.type;
  }
  get name() {
    return this._tree.type.name;
  }
  get to() {
    return this.from + this._tree.length;
  }
  nextChild(t, e, i, s, r = 0) {
    for (let o = this; ; ) {
      for (let { children: l, positions: h } = o._tree, a = e > 0 ? l.length : -1; t != a; t += e) {
        let c = l[t], f = h[t] + o.from;
        if (wh(s, i, f, f + c.length)) {
          if (c instanceof xe) {
            if (r & st.ExcludeBuffers)
              continue;
            let u = c.findChild(0, c.buffer.length, e, i - f, s);
            if (u > -1)
              return new de(new yd(o, c, t, f), null, u);
          } else if (r & st.IncludeAnonymous || !c.type.isAnonymous || lr(c)) {
            let u;
            if (!(r & st.IgnoreMounts) && (u = ws.get(c)) && !u.overlay)
              return new Tt(u.tree, f, t, o);
            let d = new Tt(c, f, t, o);
            return r & st.IncludeAnonymous || !d.type.isAnonymous ? d : d.nextChild(e < 0 ? c.children.length - 1 : 0, e, i, s);
          }
        }
      }
      if (r & st.IncludeAnonymous || !o.type.isAnonymous || (o.index >= 0 ? t = o.index + e : t = e < 0 ? -1 : o._parent._tree.children.length, o = o._parent, !o))
        return null;
    }
  }
  get firstChild() {
    return this.nextChild(
      0,
      1,
      0,
      4
      /* Side.DontCare */
    );
  }
  get lastChild() {
    return this.nextChild(
      this._tree.children.length - 1,
      -1,
      0,
      4
      /* Side.DontCare */
    );
  }
  childAfter(t) {
    return this.nextChild(
      0,
      1,
      t,
      2
      /* Side.After */
    );
  }
  childBefore(t) {
    return this.nextChild(
      this._tree.children.length - 1,
      -1,
      t,
      -2
      /* Side.Before */
    );
  }
  enter(t, e, i = 0) {
    let s;
    if (!(i & st.IgnoreOverlays) && (s = ws.get(this._tree)) && s.overlay) {
      let r = t - this.from;
      for (let { from: o, to: l } of s.overlay)
        if ((e > 0 ? o <= r : o < r) && (e < 0 ? l >= r : l > r))
          return new Tt(s.tree, s.overlay[0].from + this.from, -1, this);
    }
    return this.nextChild(0, 1, t, e, i);
  }
  nextSignificantParent() {
    let t = this;
    for (; t.type.isAnonymous && t._parent; )
      t = t._parent;
    return t;
  }
  get parent() {
    return this._parent ? this._parent.nextSignificantParent() : null;
  }
  get nextSibling() {
    return this._parent && this.index >= 0 ? this._parent.nextChild(
      this.index + 1,
      1,
      0,
      4
      /* Side.DontCare */
    ) : null;
  }
  get prevSibling() {
    return this._parent && this.index >= 0 ? this._parent.nextChild(
      this.index - 1,
      -1,
      0,
      4
      /* Side.DontCare */
    ) : null;
  }
  get tree() {
    return this._tree;
  }
  toTree() {
    return this._tree;
  }
  /**
  @internal
  */
  toString() {
    return this._tree.toString();
  }
}
function xo(n, t, e, i) {
  let s = n.cursor(), r = [];
  if (!s.firstChild())
    return r;
  if (e != null) {
    for (; !s.type.is(e); )
      if (!s.nextSibling())
        return r;
  }
  for (; ; ) {
    if (i != null && s.type.is(i))
      return r;
    if (s.type.is(t) && r.push(s.node), !s.nextSibling())
      return i == null ? r : [];
  }
}
function Vn(n, t, e = t.length - 1) {
  for (let i = n.parent; e >= 0; i = i.parent) {
    if (!i)
      return !1;
    if (!i.type.isAnonymous) {
      if (t[e] && t[e] != i.name)
        return !1;
      e--;
    }
  }
  return !0;
}
class yd {
  constructor(t, e, i, s) {
    this.parent = t, this.buffer = e, this.index = i, this.start = s;
  }
}
class de extends yh {
  get name() {
    return this.type.name;
  }
  get from() {
    return this.context.start + this.context.buffer.buffer[this.index + 1];
  }
  get to() {
    return this.context.start + this.context.buffer.buffer[this.index + 2];
  }
  constructor(t, e, i) {
    super(), this.context = t, this._parent = e, this.index = i, this.type = t.buffer.set.types[t.buffer.buffer[i]];
  }
  child(t, e, i) {
    let { buffer: s } = this.context, r = s.findChild(this.index + 4, s.buffer[this.index + 3], t, e - this.context.start, i);
    return r < 0 ? null : new de(this.context, this, r);
  }
  get firstChild() {
    return this.child(
      1,
      0,
      4
      /* Side.DontCare */
    );
  }
  get lastChild() {
    return this.child(
      -1,
      0,
      4
      /* Side.DontCare */
    );
  }
  childAfter(t) {
    return this.child(
      1,
      t,
      2
      /* Side.After */
    );
  }
  childBefore(t) {
    return this.child(
      -1,
      t,
      -2
      /* Side.Before */
    );
  }
  enter(t, e, i = 0) {
    if (i & st.ExcludeBuffers)
      return null;
    let { buffer: s } = this.context, r = s.findChild(this.index + 4, s.buffer[this.index + 3], e > 0 ? 1 : -1, t - this.context.start, e);
    return r < 0 ? null : new de(this.context, this, r);
  }
  get parent() {
    return this._parent || this.context.parent.nextSignificantParent();
  }
  externalSibling(t) {
    return this._parent ? null : this.context.parent.nextChild(
      this.context.index + t,
      t,
      0,
      4
      /* Side.DontCare */
    );
  }
  get nextSibling() {
    let { buffer: t } = this.context, e = t.buffer[this.index + 3];
    return e < (this._parent ? t.buffer[this._parent.index + 3] : t.buffer.length) ? new de(this.context, this._parent, e) : this.externalSibling(1);
  }
  get prevSibling() {
    let { buffer: t } = this.context, e = this._parent ? this._parent.index + 4 : 0;
    return this.index == e ? this.externalSibling(-1) : new de(this.context, this._parent, t.findChild(
      e,
      this.index,
      -1,
      0,
      4
      /* Side.DontCare */
    ));
  }
  get tree() {
    return null;
  }
  toTree() {
    let t = [], e = [], { buffer: i } = this.context, s = this.index + 4, r = i.buffer[this.index + 3];
    if (r > s) {
      let o = i.buffer[this.index + 1];
      t.push(i.slice(s, r, o)), e.push(0);
    }
    return new X(this.type, t, e, this.to - this.from);
  }
  /**
  @internal
  */
  toString() {
    return this.context.buffer.childString(this.index);
  }
}
function bh(n) {
  if (!n.length)
    return null;
  let t = 0, e = n[0];
  for (let r = 1; r < n.length; r++) {
    let o = n[r];
    (o.from > e.from || o.to < e.to) && (e = o, t = r);
  }
  let i = e instanceof Tt && e.index < 0 ? null : e.parent, s = n.slice();
  return i ? s[t] = i : s.splice(t, 1), new bd(s, e);
}
class bd {
  constructor(t, e) {
    this.heads = t, this.node = e;
  }
  get next() {
    return bh(this.heads);
  }
}
function kd(n, t, e) {
  let i = n.resolveInner(t, e), s = null;
  for (let r = i instanceof Tt ? i : i.context.parent; r; r = r.parent)
    if (r.index < 0) {
      let o = r.parent;
      (s || (s = [i])).push(o.resolve(t, e)), r = o;
    } else {
      let o = ws.get(r.tree);
      if (o && o.overlay && o.overlay[0].from <= t && o.overlay[o.overlay.length - 1].to >= t) {
        let l = new Tt(o.tree, o.overlay[0].from + r.from, -1, r);
        (s || (s = [i])).push(Si(l, t, e, !1));
      }
    }
  return s ? bh(s) : i;
}
class Hn {
  /**
  Shorthand for `.type.name`.
  */
  get name() {
    return this.type.name;
  }
  /**
  @internal
  */
  constructor(t, e = 0) {
    if (this.mode = e, this.buffer = null, this.stack = [], this.index = 0, this.bufferNode = null, t instanceof Tt)
      this.yieldNode(t);
    else {
      this._tree = t.context.parent, this.buffer = t.context;
      for (let i = t._parent; i; i = i._parent)
        this.stack.unshift(i.index);
      this.bufferNode = t, this.yieldBuf(t.index);
    }
  }
  yieldNode(t) {
    return t ? (this._tree = t, this.type = t.type, this.from = t.from, this.to = t.to, !0) : !1;
  }
  yieldBuf(t, e) {
    this.index = t;
    let { start: i, buffer: s } = this.buffer;
    return this.type = e || s.set.types[s.buffer[t]], this.from = i + s.buffer[t + 1], this.to = i + s.buffer[t + 2], !0;
  }
  /**
  @internal
  */
  yield(t) {
    return t ? t instanceof Tt ? (this.buffer = null, this.yieldNode(t)) : (this.buffer = t.context, this.yieldBuf(t.index, t.type)) : !1;
  }
  /**
  @internal
  */
  toString() {
    return this.buffer ? this.buffer.buffer.childString(this.index) : this._tree.toString();
  }
  /**
  @internal
  */
  enterChild(t, e, i) {
    if (!this.buffer)
      return this.yield(this._tree.nextChild(t < 0 ? this._tree._tree.children.length - 1 : 0, t, e, i, this.mode));
    let { buffer: s } = this.buffer, r = s.findChild(this.index + 4, s.buffer[this.index + 3], t, e - this.buffer.start, i);
    return r < 0 ? !1 : (this.stack.push(this.index), this.yieldBuf(r));
  }
  /**
  Move the cursor to this node's first child. When this returns
  false, the node has no child, and the cursor has not been moved.
  */
  firstChild() {
    return this.enterChild(
      1,
      0,
      4
      /* Side.DontCare */
    );
  }
  /**
  Move the cursor to this node's last child.
  */
  lastChild() {
    return this.enterChild(
      -1,
      0,
      4
      /* Side.DontCare */
    );
  }
  /**
  Move the cursor to the first child that ends after `pos`.
  */
  childAfter(t) {
    return this.enterChild(
      1,
      t,
      2
      /* Side.After */
    );
  }
  /**
  Move to the last child that starts before `pos`.
  */
  childBefore(t) {
    return this.enterChild(
      -1,
      t,
      -2
      /* Side.Before */
    );
  }
  /**
  Move the cursor to the child around `pos`. If side is -1 the
  child may end at that position, when 1 it may start there. This
  will also enter [overlaid](#common.MountedTree.overlay)
  [mounted](#common.NodeProp^mounted) trees unless `overlays` is
  set to false.
  */
  enter(t, e, i = this.mode) {
    return this.buffer ? i & st.ExcludeBuffers ? !1 : this.enterChild(1, t, e) : this.yield(this._tree.enter(t, e, i));
  }
  /**
  Move to the node's parent node, if this isn't the top node.
  */
  parent() {
    if (!this.buffer)
      return this.yieldNode(this.mode & st.IncludeAnonymous ? this._tree._parent : this._tree.parent);
    if (this.stack.length)
      return this.yieldBuf(this.stack.pop());
    let t = this.mode & st.IncludeAnonymous ? this.buffer.parent : this.buffer.parent.nextSignificantParent();
    return this.buffer = null, this.yieldNode(t);
  }
  /**
  @internal
  */
  sibling(t) {
    if (!this.buffer)
      return this._tree._parent ? this.yield(this._tree.index < 0 ? null : this._tree._parent.nextChild(this._tree.index + t, t, 0, 4, this.mode)) : !1;
    let { buffer: e } = this.buffer, i = this.stack.length - 1;
    if (t < 0) {
      let s = i < 0 ? 0 : this.stack[i] + 4;
      if (this.index != s)
        return this.yieldBuf(e.findChild(
          s,
          this.index,
          -1,
          0,
          4
          /* Side.DontCare */
        ));
    } else {
      let s = e.buffer[this.index + 3];
      if (s < (i < 0 ? e.buffer.length : e.buffer[this.stack[i] + 3]))
        return this.yieldBuf(s);
    }
    return i < 0 ? this.yield(this.buffer.parent.nextChild(this.buffer.index + t, t, 0, 4, this.mode)) : !1;
  }
  /**
  Move to this node's next sibling, if any.
  */
  nextSibling() {
    return this.sibling(1);
  }
  /**
  Move to this node's previous sibling, if any.
  */
  prevSibling() {
    return this.sibling(-1);
  }
  atLastNode(t) {
    let e, i, { buffer: s } = this;
    if (s) {
      if (t > 0) {
        if (this.index < s.buffer.buffer.length)
          return !1;
      } else
        for (let r = 0; r < this.index; r++)
          if (s.buffer.buffer[r + 3] < this.index)
            return !1;
      ({ index: e, parent: i } = s);
    } else
      ({ index: e, _parent: i } = this._tree);
    for (; i; { index: e, _parent: i } = i)
      if (e > -1)
        for (let r = e + t, o = t < 0 ? -1 : i._tree.children.length; r != o; r += t) {
          let l = i._tree.children[r];
          if (this.mode & st.IncludeAnonymous || l instanceof xe || !l.type.isAnonymous || lr(l))
            return !1;
        }
    return !0;
  }
  move(t, e) {
    if (e && this.enterChild(
      t,
      0,
      4
      /* Side.DontCare */
    ))
      return !0;
    for (; ; ) {
      if (this.sibling(t))
        return !0;
      if (this.atLastNode(t) || !this.parent())
        return !1;
    }
  }
  /**
  Move to the next node in a
  [pre-order](https://en.wikipedia.org/wiki/Tree_traversal#Pre-order,_NLR)
  traversal, going from a node to its first child or, if the
  current node is empty or `enter` is false, its next sibling or
  the next sibling of the first parent node that has one.
  */
  next(t = !0) {
    return this.move(1, t);
  }
  /**
  Move to the next node in a last-to-first pre-order traveral. A
  node is followed by its last child or, if it has none, its
  previous sibling or the previous sibling of the first parent
  node that has one.
  */
  prev(t = !0) {
    return this.move(-1, t);
  }
  /**
  Move the cursor to the innermost node that covers `pos`. If
  `side` is -1, it will enter nodes that end at `pos`. If it is 1,
  it will enter nodes that start at `pos`.
  */
  moveTo(t, e = 0) {
    for (; (this.from == this.to || (e < 1 ? this.from >= t : this.from > t) || (e > -1 ? this.to <= t : this.to < t)) && this.parent(); )
      ;
    for (; this.enterChild(1, t, e); )
      ;
    return this;
  }
  /**
  Get a [syntax node](#common.SyntaxNode) at the cursor's current
  position.
  */
  get node() {
    if (!this.buffer)
      return this._tree;
    let t = this.bufferNode, e = null, i = 0;
    if (t && t.context == this.buffer)
      t:
        for (let s = this.index, r = this.stack.length; r >= 0; ) {
          for (let o = t; o; o = o._parent)
            if (o.index == s) {
              if (s == this.index)
                return o;
              e = o, i = r + 1;
              break t;
            }
          s = this.stack[--r];
        }
    for (let s = i; s < this.stack.length; s++)
      e = new de(this.buffer, e, this.stack[s]);
    return this.bufferNode = new de(this.buffer, e, this.index);
  }
  /**
  Get the [tree](#common.Tree) that represents the current node, if
  any. Will return null when the node is in a [tree
  buffer](#common.TreeBuffer).
  */
  get tree() {
    return this.buffer ? null : this._tree._tree;
  }
  /**
  Iterate over the current node and all its descendants, calling
  `enter` when entering a node and `leave`, if given, when leaving
  one. When `enter` returns `false`, any children of that node are
  skipped, and `leave` isn't called for it.
  */
  iterate(t, e) {
    for (let i = 0; ; ) {
      let s = !1;
      if (this.type.isAnonymous || t(this) !== !1) {
        if (this.firstChild()) {
          i++;
          continue;
        }
        this.type.isAnonymous || (s = !0);
      }
      for (; s && e && e(this), s = this.type.isAnonymous, !this.nextSibling(); ) {
        if (!i)
          return;
        this.parent(), i--, s = !0;
      }
    }
  }
  /**
  Test whether the current node matches a given context—a sequence
  of direct parent node names. Empty strings in the context array
  are treated as wildcards.
  */
  matchContext(t) {
    if (!this.buffer)
      return Vn(this.node, t);
    let { buffer: e } = this.buffer, { types: i } = e.set;
    for (let s = t.length - 1, r = this.stack.length - 1; s >= 0; r--) {
      if (r < 0)
        return Vn(this.node, t, s);
      let o = i[e.buffer[this.stack[r]]];
      if (!o.isAnonymous) {
        if (t[s] && t[s] != o.name)
          return !1;
        s--;
      }
    }
    return !0;
  }
}
function lr(n) {
  return n.children.some((t) => t instanceof xe || !t.type.isAnonymous || lr(t));
}
function xd(n) {
  var t;
  let { buffer: e, nodeSet: i, maxBufferLength: s = mh, reused: r = [], minRepeatType: o = i.types.length } = n, l = Array.isArray(e) ? new or(e, e.length) : e, h = i.types, a = 0, c = 0;
  function f(A, P, M, I, W, $) {
    let { id: L, start: E, end: Y, size: U } = l, gt = c;
    for (; U < 0; )
      if (l.next(), U == -1) {
        let Jt = r[L];
        M.push(Jt), I.push(E - A);
        return;
      } else if (U == -3) {
        a = L;
        return;
      } else if (U == -4) {
        c = L;
        return;
      } else
        throw new RangeError(`Unrecognized record size: ${U}`);
    let Ae = h[L], $e, Oe, wr = E - A;
    if (Y - E <= s && (Oe = g(l.pos - P, W))) {
      let Jt = new Uint16Array(Oe.size - Oe.skip), Ot = l.pos - Oe.size, Ft = Jt.length;
      for (; l.pos > Ot; )
        Ft = y(Oe.start, Jt, Ft);
      $e = new xe(Jt, Y - Oe.start, i), wr = Oe.start - A;
    } else {
      let Jt = l.pos - U;
      l.next();
      let Ot = [], Ft = [], Me = L >= o ? L : -1, Fe = 0, Ri = Y;
      for (; l.pos > Jt; )
        Me >= 0 && l.id == Me && l.size >= 0 ? (l.end <= Ri - s && (p(Ot, Ft, E, Fe, l.end, Ri, Me, gt), Fe = Ot.length, Ri = l.end), l.next()) : $ > 2500 ? u(E, Jt, Ot, Ft) : f(E, Jt, Ot, Ft, Me, $ + 1);
      if (Me >= 0 && Fe > 0 && Fe < Ot.length && p(Ot, Ft, E, Fe, E, Ri, Me, gt), Ot.reverse(), Ft.reverse(), Me > -1 && Fe > 0) {
        let yr = d(Ae);
        $e = hr(Ae, Ot, Ft, 0, Ot.length, 0, Y - E, yr, yr);
      } else
        $e = m(Ae, Ot, Ft, Y - E, gt - Y);
    }
    M.push($e), I.push(wr);
  }
  function u(A, P, M, I) {
    let W = [], $ = 0, L = -1;
    for (; l.pos > P; ) {
      let { id: E, start: Y, end: U, size: gt } = l;
      if (gt > 4)
        l.next();
      else {
        if (L > -1 && Y < L)
          break;
        L < 0 && (L = U - s), W.push(E, Y, U), $++, l.next();
      }
    }
    if ($) {
      let E = new Uint16Array($ * 4), Y = W[W.length - 2];
      for (let U = W.length - 3, gt = 0; U >= 0; U -= 3)
        E[gt++] = W[U], E[gt++] = W[U + 1] - Y, E[gt++] = W[U + 2] - Y, E[gt++] = gt;
      M.push(new xe(E, W[2] - Y, i)), I.push(Y - A);
    }
  }
  function d(A) {
    return (P, M, I) => {
      let W = 0, $ = P.length - 1, L, E;
      if ($ >= 0 && (L = P[$]) instanceof X) {
        if (!$ && L.type == A && L.length == I)
          return L;
        (E = L.prop(R.lookAhead)) && (W = M[$] + L.length + E);
      }
      return m(A, P, M, I, W);
    };
  }
  function p(A, P, M, I, W, $, L, E) {
    let Y = [], U = [];
    for (; A.length > I; )
      Y.push(A.pop()), U.push(P.pop() + M - W);
    A.push(m(i.types[L], Y, U, $ - W, E - $)), P.push(W - M);
  }
  function m(A, P, M, I, W = 0, $) {
    if (a) {
      let L = [R.contextHash, a];
      $ = $ ? [L].concat($) : [L];
    }
    if (W > 25) {
      let L = [R.lookAhead, W];
      $ = $ ? [L].concat($) : [L];
    }
    return new X(A, P, M, I, $);
  }
  function g(A, P) {
    let M = l.fork(), I = 0, W = 0, $ = 0, L = M.end - s, E = { size: 0, start: 0, skip: 0 };
    t:
      for (let Y = M.pos - A; M.pos > Y; ) {
        let U = M.size;
        if (M.id == P && U >= 0) {
          E.size = I, E.start = W, E.skip = $, $ += 4, I += 4, M.next();
          continue;
        }
        let gt = M.pos - U;
        if (U < 0 || gt < Y || M.start < L)
          break;
        let Ae = M.id >= o ? 4 : 0, $e = M.start;
        for (M.next(); M.pos > gt; ) {
          if (M.size < 0)
            if (M.size == -3)
              Ae += 4;
            else
              break t;
          else
            M.id >= o && (Ae += 4);
          M.next();
        }
        W = $e, I += U, $ += Ae;
      }
    return (P < 0 || I == A) && (E.size = I, E.start = W, E.skip = $), E.size > 4 ? E : void 0;
  }
  function y(A, P, M) {
    let { id: I, start: W, end: $, size: L } = l;
    if (l.next(), L >= 0 && I < o) {
      let E = M;
      if (L > 4) {
        let Y = l.pos - (L - 4);
        for (; l.pos > Y; )
          M = y(A, P, M);
      }
      P[--M] = E, P[--M] = $ - A, P[--M] = W - A, P[--M] = I;
    } else
      L == -3 ? a = I : L == -4 && (c = I);
    return M;
  }
  let x = [], S = [];
  for (; l.pos > 0; )
    f(n.start || 0, n.bufferStart || 0, x, S, -1, 0);
  let v = (t = n.length) !== null && t !== void 0 ? t : x.length ? S[0] + x[0].length : 0;
  return new X(h[n.topID], x.reverse(), S.reverse(), v);
}
const vo = /* @__PURE__ */ new WeakMap();
function os(n, t) {
  if (!n.isAnonymous || t instanceof xe || t.type != n)
    return 1;
  let e = vo.get(t);
  if (e == null) {
    e = 1;
    for (let i of t.children) {
      if (i.type != n || !(i instanceof X)) {
        e = 1;
        break;
      }
      e += os(n, i);
    }
    vo.set(t, e);
  }
  return e;
}
function hr(n, t, e, i, s, r, o, l, h) {
  let a = 0;
  for (let p = i; p < s; p++)
    a += os(n, t[p]);
  let c = Math.ceil(
    a * 1.5 / 8
    /* Balance.BranchFactor */
  ), f = [], u = [];
  function d(p, m, g, y, x) {
    for (let S = g; S < y; ) {
      let v = S, A = m[S], P = os(n, p[S]);
      for (S++; S < y; S++) {
        let M = os(n, p[S]);
        if (P + M >= c)
          break;
        P += M;
      }
      if (S == v + 1) {
        if (P > c) {
          let M = p[v];
          d(M.children, M.positions, 0, M.children.length, m[v] + x);
          continue;
        }
        f.push(p[v]);
      } else {
        let M = m[S - 1] + p[S - 1].length - A;
        f.push(hr(n, p, m, v, S, A, M, null, h));
      }
      u.push(A + x - r);
    }
  }
  return d(t, e, i, s, 0), (l || h)(f, u, o);
}
class Re {
  /**
  Construct a tree fragment. You'll usually want to use
  [`addTree`](#common.TreeFragment^addTree) and
  [`applyChanges`](#common.TreeFragment^applyChanges) instead of
  calling this directly.
  */
  constructor(t, e, i, s, r = !1, o = !1) {
    this.from = t, this.to = e, this.tree = i, this.offset = s, this.open = (r ? 1 : 0) | (o ? 2 : 0);
  }
  /**
  Whether the start of the fragment represents the start of a
  parse, or the end of a change. (In the second case, it may not
  be safe to reuse some nodes at the start, depending on the
  parsing algorithm.)
  */
  get openStart() {
    return (this.open & 1) > 0;
  }
  /**
  Whether the end of the fragment represents the end of a
  full-document parse, or the start of a change.
  */
  get openEnd() {
    return (this.open & 2) > 0;
  }
  /**
  Create a set of fragments from a freshly parsed tree, or update
  an existing set of fragments by replacing the ones that overlap
  with a tree with content from the new tree. When `partial` is
  true, the parse is treated as incomplete, and the resulting
  fragment has [`openEnd`](#common.TreeFragment.openEnd) set to
  true.
  */
  static addTree(t, e = [], i = !1) {
    let s = [new Re(0, t.length, t, 0, !1, i)];
    for (let r of e)
      r.to > t.length && s.push(r);
    return s;
  }
  /**
  Apply a set of edits to an array of fragments, removing or
  splitting fragments as necessary to remove edited ranges, and
  adjusting offsets for fragments that moved.
  */
  static applyChanges(t, e, i = 128) {
    if (!e.length)
      return t;
    let s = [], r = 1, o = t.length ? t[0] : null;
    for (let l = 0, h = 0, a = 0; ; l++) {
      let c = l < e.length ? e[l] : null, f = c ? c.fromA : 1e9;
      if (f - h >= i)
        for (; o && o.from < f; ) {
          let u = o;
          if (h >= u.from || f <= u.to || a) {
            let d = Math.max(u.from, h) - a, p = Math.min(u.to, f) - a;
            u = d >= p ? null : new Re(d, p, u.tree, u.offset + a, l > 0, !!c);
          }
          if (u && s.push(u), o.to > f)
            break;
          o = r < t.length ? t[r++] : null;
        }
      if (!c)
        break;
      h = c.toA, a = c.toA - c.toB;
    }
    return s;
  }
}
class kh {
  /**
  Start a parse, returning a [partial parse](#common.PartialParse)
  object. [`fragments`](#common.TreeFragment) can be passed in to
  make the parse incremental.
  
  By default, the entire input is parsed. You can pass `ranges`,
  which should be a sorted array of non-empty, non-overlapping
  ranges, to parse only those ranges. The tree returned in that
  case will start at `ranges[0].from`.
  */
  startParse(t, e, i) {
    return typeof t == "string" && (t = new vd(t)), i = i ? i.length ? i.map((s) => new Us(s.from, s.to)) : [new Us(0, 0)] : [new Us(0, t.length)], this.createParse(t, e || [], i);
  }
  /**
  Run a full parse, returning the resulting tree.
  */
  parse(t, e, i) {
    let s = this.startParse(t, e, i);
    for (; ; ) {
      let r = s.advance();
      if (r)
        return r;
    }
  }
}
class vd {
  constructor(t) {
    this.string = t;
  }
  get length() {
    return this.string.length;
  }
  chunk(t) {
    return this.string.slice(t);
  }
  get lineChunks() {
    return !1;
  }
  read(t, e) {
    return this.string.slice(t, e);
  }
}
new R({ perNode: !0 });
let Sd = 0;
class Kt {
  /**
  @internal
  */
  constructor(t, e, i) {
    this.set = t, this.base = e, this.modified = i, this.id = Sd++;
  }
  /**
  Define a new tag. If `parent` is given, the tag is treated as a
  sub-tag of that parent, and
  [highlighters](#highlight.tagHighlighter) that don't mention
  this tag will try to fall back to the parent tag (or grandparent
  tag, etc).
  */
  static define(t) {
    if (t != null && t.base)
      throw new Error("Can not derive from a modified tag");
    let e = new Kt([], null, []);
    if (e.set.push(e), t)
      for (let i of t.set)
        e.set.push(i);
    return e;
  }
  /**
  Define a tag _modifier_, which is a function that, given a tag,
  will return a tag that is a subtag of the original. Applying the
  same modifier to a twice tag will return the same value (`m1(t1)
  == m1(t1)`) and applying multiple modifiers will, regardless or
  order, produce the same tag (`m1(m2(t1)) == m2(m1(t1))`).
  
  When multiple modifiers are applied to a given base tag, each
  smaller set of modifiers is registered as a parent, so that for
  example `m1(m2(m3(t1)))` is a subtype of `m1(m2(t1))`,
  `m1(m3(t1)`, and so on.
  */
  static defineModifier() {
    let t = new ys();
    return (e) => e.modified.indexOf(t) > -1 ? e : ys.get(e.base || e, e.modified.concat(t).sort((i, s) => i.id - s.id));
  }
}
let Cd = 0;
class ys {
  constructor() {
    this.instances = [], this.id = Cd++;
  }
  static get(t, e) {
    if (!e.length)
      return t;
    let i = e[0].instances.find((l) => l.base == t && Ad(e, l.modified));
    if (i)
      return i;
    let s = [], r = new Kt(s, t, e);
    for (let l of e)
      l.instances.push(r);
    let o = Od(e);
    for (let l of t.set)
      if (!l.modified.length)
        for (let h of o)
          s.push(ys.get(l, h));
    return r;
  }
}
function Ad(n, t) {
  return n.length == t.length && n.every((e, i) => e == t[i]);
}
function Od(n) {
  let t = [[]];
  for (let e = 0; e < n.length; e++)
    for (let i = 0, s = t.length; i < s; i++)
      t.push(t[i].concat(n[e]));
  return t.sort((e, i) => i.length - e.length);
}
function xh(n) {
  let t = /* @__PURE__ */ Object.create(null);
  for (let e in n) {
    let i = n[e];
    Array.isArray(i) || (i = [i]);
    for (let s of e.split(" "))
      if (s) {
        let r = [], o = 2, l = s;
        for (let f = 0; ; ) {
          if (l == "..." && f > 0 && f + 3 == s.length) {
            o = 1;
            break;
          }
          let u = /^"(?:[^"\\]|\\.)*?"|[^\/!]+/.exec(l);
          if (!u)
            throw new RangeError("Invalid path: " + s);
          if (r.push(u[0] == "*" ? "" : u[0][0] == '"' ? JSON.parse(u[0]) : u[0]), f += u[0].length, f == s.length)
            break;
          let d = s[f++];
          if (f == s.length && d == "!") {
            o = 0;
            break;
          }
          if (d != "/")
            throw new RangeError("Invalid path: " + s);
          l = s.slice(f);
        }
        let h = r.length - 1, a = r[h];
        if (!a)
          throw new RangeError("Invalid path: " + s);
        let c = new bs(i, o, h > 0 ? r.slice(0, h) : null);
        t[a] = c.sort(t[a]);
      }
  }
  return vh.add(t);
}
const vh = new R();
class bs {
  constructor(t, e, i, s) {
    this.tags = t, this.mode = e, this.context = i, this.next = s;
  }
  get opaque() {
    return this.mode == 0;
  }
  get inherit() {
    return this.mode == 1;
  }
  sort(t) {
    return !t || t.depth < this.depth ? (this.next = t, this) : (t.next = this.sort(t.next), t);
  }
  get depth() {
    return this.context ? this.context.length : 0;
  }
}
bs.empty = new bs([], 2, null);
function Sh(n, t) {
  let e = /* @__PURE__ */ Object.create(null);
  for (let r of n)
    if (!Array.isArray(r.tag))
      e[r.tag.id] = r.class;
    else
      for (let o of r.tag)
        e[o.id] = r.class;
  let { scope: i, all: s = null } = t || {};
  return {
    style: (r) => {
      let o = s;
      for (let l of r)
        for (let h of l.set) {
          let a = e[h.id];
          if (a) {
            o = o ? o + " " + a : a;
            break;
          }
        }
      return o;
    },
    scope: i
  };
}
function Md(n, t) {
  let e = null;
  for (let i of n) {
    let s = i.style(t);
    s && (e = e ? e + " " + s : s);
  }
  return e;
}
function Td(n, t, e, i = 0, s = n.length) {
  let r = new Dd(i, Array.isArray(t) ? t : [t], e);
  r.highlightRange(n.cursor(), i, s, "", r.highlighters), r.flush(s);
}
class Dd {
  constructor(t, e, i) {
    this.at = t, this.highlighters = e, this.span = i, this.class = "";
  }
  startSpan(t, e) {
    e != this.class && (this.flush(t), t > this.at && (this.at = t), this.class = e);
  }
  flush(t) {
    t > this.at && this.class && this.span(this.at, t, this.class);
  }
  highlightRange(t, e, i, s, r) {
    let { type: o, from: l, to: h } = t;
    if (l >= i || h <= e)
      return;
    o.isTop && (r = this.highlighters.filter((d) => !d.scope || d.scope(o)));
    let a = s, c = Pd(t) || bs.empty, f = Md(r, c.tags);
    if (f && (a && (a += " "), a += f, c.mode == 1 && (s += (s ? " " : "") + f)), this.startSpan(Math.max(e, l), a), c.opaque)
      return;
    let u = t.tree && t.tree.prop(R.mounted);
    if (u && u.overlay) {
      let d = t.node.enter(u.overlay[0].from + l, 1), p = this.highlighters.filter((g) => !g.scope || g.scope(u.tree.type)), m = t.firstChild();
      for (let g = 0, y = l; ; g++) {
        let x = g < u.overlay.length ? u.overlay[g] : null, S = x ? x.from + l : h, v = Math.max(e, y), A = Math.min(i, S);
        if (v < A && m)
          for (; t.from < A && (this.highlightRange(t, v, A, s, r), this.startSpan(Math.min(A, t.to), a), !(t.to >= S || !t.nextSibling())); )
            ;
        if (!x || S > i)
          break;
        y = x.to + l, y > e && (this.highlightRange(d.cursor(), Math.max(e, x.from + l), Math.min(i, y), "", p), this.startSpan(Math.min(i, y), a));
      }
      m && t.parent();
    } else if (t.firstChild()) {
      u && (s = "");
      do
        if (!(t.to <= e)) {
          if (t.from >= i)
            break;
          this.highlightRange(t, e, i, s, r), this.startSpan(Math.min(i, t.to), a);
        }
      while (t.nextSibling());
      t.parent();
    }
  }
}
function Pd(n) {
  let t = n.type.prop(vh);
  for (; t && t.context && !n.matchContext(t.context); )
    t = t.next;
  return t || null;
}
const k = Kt.define, qi = k(), le = k(), So = k(le), Co = k(le), he = k(), Gi = k(he), Ys = k(he), jt = k(), Te = k(jt), zt = k(), Wt = k(), $n = k(), ri = k($n), Ui = k(), w = {
  /**
  A comment.
  */
  comment: qi,
  /**
  A line [comment](#highlight.tags.comment).
  */
  lineComment: k(qi),
  /**
  A block [comment](#highlight.tags.comment).
  */
  blockComment: k(qi),
  /**
  A documentation [comment](#highlight.tags.comment).
  */
  docComment: k(qi),
  /**
  Any kind of identifier.
  */
  name: le,
  /**
  The [name](#highlight.tags.name) of a variable.
  */
  variableName: k(le),
  /**
  A type [name](#highlight.tags.name).
  */
  typeName: So,
  /**
  A tag name (subtag of [`typeName`](#highlight.tags.typeName)).
  */
  tagName: k(So),
  /**
  A property or field [name](#highlight.tags.name).
  */
  propertyName: Co,
  /**
  An attribute name (subtag of [`propertyName`](#highlight.tags.propertyName)).
  */
  attributeName: k(Co),
  /**
  The [name](#highlight.tags.name) of a class.
  */
  className: k(le),
  /**
  A label [name](#highlight.tags.name).
  */
  labelName: k(le),
  /**
  A namespace [name](#highlight.tags.name).
  */
  namespace: k(le),
  /**
  The [name](#highlight.tags.name) of a macro.
  */
  macroName: k(le),
  /**
  A literal value.
  */
  literal: he,
  /**
  A string [literal](#highlight.tags.literal).
  */
  string: Gi,
  /**
  A documentation [string](#highlight.tags.string).
  */
  docString: k(Gi),
  /**
  A character literal (subtag of [string](#highlight.tags.string)).
  */
  character: k(Gi),
  /**
  An attribute value (subtag of [string](#highlight.tags.string)).
  */
  attributeValue: k(Gi),
  /**
  A number [literal](#highlight.tags.literal).
  */
  number: Ys,
  /**
  An integer [number](#highlight.tags.number) literal.
  */
  integer: k(Ys),
  /**
  A floating-point [number](#highlight.tags.number) literal.
  */
  float: k(Ys),
  /**
  A boolean [literal](#highlight.tags.literal).
  */
  bool: k(he),
  /**
  Regular expression [literal](#highlight.tags.literal).
  */
  regexp: k(he),
  /**
  An escape [literal](#highlight.tags.literal), for example a
  backslash escape in a string.
  */
  escape: k(he),
  /**
  A color [literal](#highlight.tags.literal).
  */
  color: k(he),
  /**
  A URL [literal](#highlight.tags.literal).
  */
  url: k(he),
  /**
  A language keyword.
  */
  keyword: zt,
  /**
  The [keyword](#highlight.tags.keyword) for the self or this
  object.
  */
  self: k(zt),
  /**
  The [keyword](#highlight.tags.keyword) for null.
  */
  null: k(zt),
  /**
  A [keyword](#highlight.tags.keyword) denoting some atomic value.
  */
  atom: k(zt),
  /**
  A [keyword](#highlight.tags.keyword) that represents a unit.
  */
  unit: k(zt),
  /**
  A modifier [keyword](#highlight.tags.keyword).
  */
  modifier: k(zt),
  /**
  A [keyword](#highlight.tags.keyword) that acts as an operator.
  */
  operatorKeyword: k(zt),
  /**
  A control-flow related [keyword](#highlight.tags.keyword).
  */
  controlKeyword: k(zt),
  /**
  A [keyword](#highlight.tags.keyword) that defines something.
  */
  definitionKeyword: k(zt),
  /**
  A [keyword](#highlight.tags.keyword) related to defining or
  interfacing with modules.
  */
  moduleKeyword: k(zt),
  /**
  An operator.
  */
  operator: Wt,
  /**
  An [operator](#highlight.tags.operator) that dereferences something.
  */
  derefOperator: k(Wt),
  /**
  Arithmetic-related [operator](#highlight.tags.operator).
  */
  arithmeticOperator: k(Wt),
  /**
  Logical [operator](#highlight.tags.operator).
  */
  logicOperator: k(Wt),
  /**
  Bit [operator](#highlight.tags.operator).
  */
  bitwiseOperator: k(Wt),
  /**
  Comparison [operator](#highlight.tags.operator).
  */
  compareOperator: k(Wt),
  /**
  [Operator](#highlight.tags.operator) that updates its operand.
  */
  updateOperator: k(Wt),
  /**
  [Operator](#highlight.tags.operator) that defines something.
  */
  definitionOperator: k(Wt),
  /**
  Type-related [operator](#highlight.tags.operator).
  */
  typeOperator: k(Wt),
  /**
  Control-flow [operator](#highlight.tags.operator).
  */
  controlOperator: k(Wt),
  /**
  Program or markup punctuation.
  */
  punctuation: $n,
  /**
  [Punctuation](#highlight.tags.punctuation) that separates
  things.
  */
  separator: k($n),
  /**
  Bracket-style [punctuation](#highlight.tags.punctuation).
  */
  bracket: ri,
  /**
  Angle [brackets](#highlight.tags.bracket) (usually `<` and `>`
  tokens).
  */
  angleBracket: k(ri),
  /**
  Square [brackets](#highlight.tags.bracket) (usually `[` and `]`
  tokens).
  */
  squareBracket: k(ri),
  /**
  Parentheses (usually `(` and `)` tokens). Subtag of
  [bracket](#highlight.tags.bracket).
  */
  paren: k(ri),
  /**
  Braces (usually `{` and `}` tokens). Subtag of
  [bracket](#highlight.tags.bracket).
  */
  brace: k(ri),
  /**
  Content, for example plain text in XML or markup documents.
  */
  content: jt,
  /**
  [Content](#highlight.tags.content) that represents a heading.
  */
  heading: Te,
  /**
  A level 1 [heading](#highlight.tags.heading).
  */
  heading1: k(Te),
  /**
  A level 2 [heading](#highlight.tags.heading).
  */
  heading2: k(Te),
  /**
  A level 3 [heading](#highlight.tags.heading).
  */
  heading3: k(Te),
  /**
  A level 4 [heading](#highlight.tags.heading).
  */
  heading4: k(Te),
  /**
  A level 5 [heading](#highlight.tags.heading).
  */
  heading5: k(Te),
  /**
  A level 6 [heading](#highlight.tags.heading).
  */
  heading6: k(Te),
  /**
  A prose separator (such as a horizontal rule).
  */
  contentSeparator: k(jt),
  /**
  [Content](#highlight.tags.content) that represents a list.
  */
  list: k(jt),
  /**
  [Content](#highlight.tags.content) that represents a quote.
  */
  quote: k(jt),
  /**
  [Content](#highlight.tags.content) that is emphasized.
  */
  emphasis: k(jt),
  /**
  [Content](#highlight.tags.content) that is styled strong.
  */
  strong: k(jt),
  /**
  [Content](#highlight.tags.content) that is part of a link.
  */
  link: k(jt),
  /**
  [Content](#highlight.tags.content) that is styled as code or
  monospace.
  */
  monospace: k(jt),
  /**
  [Content](#highlight.tags.content) that has a strike-through
  style.
  */
  strikethrough: k(jt),
  /**
  Inserted text in a change-tracking format.
  */
  inserted: k(),
  /**
  Deleted text.
  */
  deleted: k(),
  /**
  Changed text.
  */
  changed: k(),
  /**
  An invalid or unsyntactic element.
  */
  invalid: k(),
  /**
  Metadata or meta-instruction.
  */
  meta: Ui,
  /**
  [Metadata](#highlight.tags.meta) that applies to the entire
  document.
  */
  documentMeta: k(Ui),
  /**
  [Metadata](#highlight.tags.meta) that annotates or adds
  attributes to a given syntactic element.
  */
  annotation: k(Ui),
  /**
  Processing instruction or preprocessor directive. Subtag of
  [meta](#highlight.tags.meta).
  */
  processingInstruction: k(Ui),
  /**
  [Modifier](#highlight.Tag^defineModifier) that indicates that a
  given element is being defined. Expected to be used with the
  various [name](#highlight.tags.name) tags.
  */
  definition: Kt.defineModifier(),
  /**
  [Modifier](#highlight.Tag^defineModifier) that indicates that
  something is constant. Mostly expected to be used with
  [variable names](#highlight.tags.variableName).
  */
  constant: Kt.defineModifier(),
  /**
  [Modifier](#highlight.Tag^defineModifier) used to indicate that
  a [variable](#highlight.tags.variableName) or [property
  name](#highlight.tags.propertyName) is being called or defined
  as a function.
  */
  function: Kt.defineModifier(),
  /**
  [Modifier](#highlight.Tag^defineModifier) that can be applied to
  [names](#highlight.tags.name) to indicate that they belong to
  the language's standard environment.
  */
  standard: Kt.defineModifier(),
  /**
  [Modifier](#highlight.Tag^defineModifier) that indicates a given
  [names](#highlight.tags.name) is local to some scope.
  */
  local: Kt.defineModifier(),
  /**
  A generic variant [modifier](#highlight.Tag^defineModifier) that
  can be used to tag language-specific alternative variants of
  some common tag. It is recommended for themes to define special
  forms of at least the [string](#highlight.tags.string) and
  [variable name](#highlight.tags.variableName) tags, since those
  come up a lot.
  */
  special: Kt.defineModifier()
};
Sh([
  { tag: w.link, class: "tok-link" },
  { tag: w.heading, class: "tok-heading" },
  { tag: w.emphasis, class: "tok-emphasis" },
  { tag: w.strong, class: "tok-strong" },
  { tag: w.keyword, class: "tok-keyword" },
  { tag: w.atom, class: "tok-atom" },
  { tag: w.bool, class: "tok-bool" },
  { tag: w.url, class: "tok-url" },
  { tag: w.labelName, class: "tok-labelName" },
  { tag: w.inserted, class: "tok-inserted" },
  { tag: w.deleted, class: "tok-deleted" },
  { tag: w.literal, class: "tok-literal" },
  { tag: w.string, class: "tok-string" },
  { tag: w.number, class: "tok-number" },
  { tag: [w.regexp, w.escape, w.special(w.string)], class: "tok-string2" },
  { tag: w.variableName, class: "tok-variableName" },
  { tag: w.local(w.variableName), class: "tok-variableName tok-local" },
  { tag: w.definition(w.variableName), class: "tok-variableName tok-definition" },
  { tag: w.special(w.variableName), class: "tok-variableName2" },
  { tag: w.definition(w.propertyName), class: "tok-propertyName tok-definition" },
  { tag: w.typeName, class: "tok-typeName" },
  { tag: w.namespace, class: "tok-namespace" },
  { tag: w.className, class: "tok-className" },
  { tag: w.macroName, class: "tok-macroName" },
  { tag: w.propertyName, class: "tok-propertyName" },
  { tag: w.operator, class: "tok-operator" },
  { tag: w.comment, class: "tok-comment" },
  { tag: w.meta, class: "tok-meta" },
  { tag: w.invalid, class: "tok-invalid" },
  { tag: w.punctuation, class: "tok-punctuation" }
]);
var Qs;
const ze = /* @__PURE__ */ new R();
function Bd(n) {
  return O.define({
    combine: n ? (t) => t.concat(n) : void 0
  });
}
const Rd = /* @__PURE__ */ new R();
class Rt {
  /**
  Construct a language object. If you need to invoke this
  directly, first define a data facet with
  [`defineLanguageFacet`](https://codemirror.net/6/docs/ref/#language.defineLanguageFacet), and then
  configure your parser to [attach](https://codemirror.net/6/docs/ref/#language.languageDataProp) it
  to the language's outer syntax node.
  */
  constructor(t, e, i = [], s = "") {
    this.data = t, this.name = s, H.prototype.hasOwnProperty("tree") || Object.defineProperty(H.prototype, "tree", { get() {
      return At(this);
    } }), this.parser = e, this.extension = [
      ve.of(this),
      H.languageData.of((r, o, l) => {
        let h = Ao(r, o, l), a = h.type.prop(ze);
        if (!a)
          return [];
        let c = r.facet(a), f = h.type.prop(Rd);
        if (f) {
          let u = h.resolve(o - h.from, l);
          for (let d of f)
            if (d.test(u, r)) {
              let p = r.facet(d.facet);
              return d.type == "replace" ? p : p.concat(c);
            }
        }
        return c;
      })
    ].concat(i);
  }
  /**
  Query whether this language is active at the given position.
  */
  isActiveAt(t, e, i = -1) {
    return Ao(t, e, i).type.prop(ze) == this.data;
  }
  /**
  Find the document regions that were parsed using this language.
  The returned regions will _include_ any nested languages rooted
  in this language, when those exist.
  */
  findRegions(t) {
    let e = t.facet(ve);
    if ((e == null ? void 0 : e.data) == this.data)
      return [{ from: 0, to: t.doc.length }];
    if (!e || !e.allowsNesting)
      return [];
    let i = [], s = (r, o) => {
      if (r.prop(ze) == this.data) {
        i.push({ from: o, to: o + r.length });
        return;
      }
      let l = r.prop(R.mounted);
      if (l) {
        if (l.tree.prop(ze) == this.data) {
          if (l.overlay)
            for (let h of l.overlay)
              i.push({ from: h.from + o, to: h.to + o });
          else
            i.push({ from: o, to: o + r.length });
          return;
        } else if (l.overlay) {
          let h = i.length;
          if (s(l.tree, l.overlay[0].from + o), i.length > h)
            return;
        }
      }
      for (let h = 0; h < r.children.length; h++) {
        let a = r.children[h];
        a instanceof X && s(a, r.positions[h] + o);
      }
    };
    return s(At(t), 0), i;
  }
  /**
  Indicates whether this language allows nested languages. The
  default implementation returns true.
  */
  get allowsNesting() {
    return !0;
  }
}
Rt.setState = /* @__PURE__ */ z.define();
function Ao(n, t, e) {
  let i = n.facet(ve), s = At(n).topNode;
  if (!i || i.allowsNesting)
    for (let r = s; r; r = r.enter(t, e, st.ExcludeBuffers))
      r.type.isTop && (s = r);
  return s;
}
class ks extends Rt {
  constructor(t, e, i) {
    super(t, e, [], i), this.parser = e;
  }
  /**
  Define a language from a parser.
  */
  static define(t) {
    let e = Bd(t.languageData);
    return new ks(e, t.parser.configure({
      props: [ze.add((i) => i.isTop ? e : void 0)]
    }), t.name);
  }
  /**
  Create a new instance of this language with a reconfigured
  version of its parser and optionally a new name.
  */
  configure(t, e) {
    return new ks(this.data, this.parser.configure(t), e || this.name);
  }
  get allowsNesting() {
    return this.parser.hasWrappers();
  }
}
function At(n) {
  let t = n.field(Rt.state, !1);
  return t ? t.tree : X.empty;
}
class Ld {
  /**
  Create an input object for the given document.
  */
  constructor(t) {
    this.doc = t, this.cursorPos = 0, this.string = "", this.cursor = t.iter();
  }
  get length() {
    return this.doc.length;
  }
  syncTo(t) {
    return this.string = this.cursor.next(t - this.cursorPos).value, this.cursorPos = t + this.string.length, this.cursorPos - this.string.length;
  }
  chunk(t) {
    return this.syncTo(t), this.string;
  }
  get lineChunks() {
    return !0;
  }
  read(t, e) {
    let i = this.cursorPos - this.string.length;
    return t < i || e >= this.cursorPos ? this.doc.sliceString(t, e) : this.string.slice(t - i, e - i);
  }
}
let oi = null;
class xs {
  constructor(t, e, i = [], s, r, o, l, h) {
    this.parser = t, this.state = e, this.fragments = i, this.tree = s, this.treeLen = r, this.viewport = o, this.skipped = l, this.scheduleOn = h, this.parse = null, this.tempSkipped = [];
  }
  /**
  @internal
  */
  static create(t, e, i) {
    return new xs(t, e, [], X.empty, 0, i, [], null);
  }
  startParse() {
    return this.parser.startParse(new Ld(this.state.doc), this.fragments);
  }
  /**
  @internal
  */
  work(t, e) {
    return e != null && e >= this.state.doc.length && (e = void 0), this.tree != X.empty && this.isDone(e ?? this.state.doc.length) ? (this.takeTree(), !0) : this.withContext(() => {
      var i;
      if (typeof t == "number") {
        let s = Date.now() + t;
        t = () => Date.now() > s;
      }
      for (this.parse || (this.parse = this.startParse()), e != null && (this.parse.stoppedAt == null || this.parse.stoppedAt > e) && e < this.state.doc.length && this.parse.stopAt(e); ; ) {
        let s = this.parse.advance();
        if (s)
          if (this.fragments = this.withoutTempSkipped(Re.addTree(s, this.fragments, this.parse.stoppedAt != null)), this.treeLen = (i = this.parse.stoppedAt) !== null && i !== void 0 ? i : this.state.doc.length, this.tree = s, this.parse = null, this.treeLen < (e ?? this.state.doc.length))
            this.parse = this.startParse();
          else
            return !0;
        if (t())
          return !1;
      }
    });
  }
  /**
  @internal
  */
  takeTree() {
    let t, e;
    this.parse && (t = this.parse.parsedPos) >= this.treeLen && ((this.parse.stoppedAt == null || this.parse.stoppedAt > t) && this.parse.stopAt(t), this.withContext(() => {
      for (; !(e = this.parse.advance()); )
        ;
    }), this.treeLen = t, this.tree = e, this.fragments = this.withoutTempSkipped(Re.addTree(this.tree, this.fragments, !0)), this.parse = null);
  }
  withContext(t) {
    let e = oi;
    oi = this;
    try {
      return t();
    } finally {
      oi = e;
    }
  }
  withoutTempSkipped(t) {
    for (let e; e = this.tempSkipped.pop(); )
      t = Oo(t, e.from, e.to);
    return t;
  }
  /**
  @internal
  */
  changes(t, e) {
    let { fragments: i, tree: s, treeLen: r, viewport: o, skipped: l } = this;
    if (this.takeTree(), !t.empty) {
      let h = [];
      if (t.iterChangedRanges((a, c, f, u) => h.push({ fromA: a, toA: c, fromB: f, toB: u })), i = Re.applyChanges(i, h), s = X.empty, r = 0, o = { from: t.mapPos(o.from, -1), to: t.mapPos(o.to, 1) }, this.skipped.length) {
        l = [];
        for (let a of this.skipped) {
          let c = t.mapPos(a.from, 1), f = t.mapPos(a.to, -1);
          c < f && l.push({ from: c, to: f });
        }
      }
    }
    return new xs(this.parser, e, i, s, r, o, l, this.scheduleOn);
  }
  /**
  @internal
  */
  updateViewport(t) {
    if (this.viewport.from == t.from && this.viewport.to == t.to)
      return !1;
    this.viewport = t;
    let e = this.skipped.length;
    for (let i = 0; i < this.skipped.length; i++) {
      let { from: s, to: r } = this.skipped[i];
      s < t.to && r > t.from && (this.fragments = Oo(this.fragments, s, r), this.skipped.splice(i--, 1));
    }
    return this.skipped.length >= e ? !1 : (this.reset(), !0);
  }
  /**
  @internal
  */
  reset() {
    this.parse && (this.takeTree(), this.parse = null);
  }
  /**
  Notify the parse scheduler that the given region was skipped
  because it wasn't in view, and the parse should be restarted
  when it comes into view.
  */
  skipUntilInView(t, e) {
    this.skipped.push({ from: t, to: e });
  }
  /**
  Returns a parser intended to be used as placeholder when
  asynchronously loading a nested parser. It'll skip its input and
  mark it as not-really-parsed, so that the next update will parse
  it again.
  
  When `until` is given, a reparse will be scheduled when that
  promise resolves.
  */
  static getSkippingParser(t) {
    return new class extends kh {
      createParse(e, i, s) {
        let r = s[0].from, o = s[s.length - 1].to;
        return {
          parsedPos: r,
          advance() {
            let h = oi;
            if (h) {
              for (let a of s)
                h.tempSkipped.push(a);
              t && (h.scheduleOn = h.scheduleOn ? Promise.all([h.scheduleOn, t]) : t);
            }
            return this.parsedPos = o, new X(bt.none, [], [], o - r);
          },
          stoppedAt: null,
          stopAt() {
          }
        };
      }
    }();
  }
  /**
  @internal
  */
  isDone(t) {
    t = Math.min(t, this.state.doc.length);
    let e = this.fragments;
    return this.treeLen >= t && e.length && e[0].from == 0 && e[0].to >= t;
  }
  /**
  Get the context for the current parse, or `null` if no editor
  parse is in progress.
  */
  static get() {
    return oi;
  }
}
function Oo(n, t, e) {
  return Re.applyChanges(n, [{ fromA: t, toA: e, fromB: t, toB: e }]);
}
class Xe {
  constructor(t) {
    this.context = t, this.tree = t.tree;
  }
  apply(t) {
    if (!t.docChanged && this.tree == this.context.tree)
      return this;
    let e = this.context.changes(t.changes, t.state), i = this.context.treeLen == t.startState.doc.length ? void 0 : Math.max(t.changes.mapPos(this.context.treeLen), e.viewport.to);
    return e.work(20, i) || e.takeTree(), new Xe(e);
  }
  static init(t) {
    let e = Math.min(3e3, t.doc.length), i = xs.create(t.facet(ve).parser, t, { from: 0, to: e });
    return i.work(20, e) || i.takeTree(), new Xe(i);
  }
}
Rt.state = /* @__PURE__ */ Ht.define({
  create: Xe.init,
  update(n, t) {
    for (let e of t.effects)
      if (e.is(Rt.setState))
        return e.value;
    return t.startState.facet(ve) != t.state.facet(ve) ? Xe.init(t.state) : n.apply(t);
  }
});
let Ch = (n) => {
  let t = setTimeout(
    () => n(),
    500
    /* Work.MaxPause */
  );
  return () => clearTimeout(t);
};
typeof requestIdleCallback < "u" && (Ch = (n) => {
  let t = -1, e = setTimeout(
    () => {
      t = requestIdleCallback(n, {
        timeout: 400
        /* Work.MinPause */
      });
    },
    100
    /* Work.MinPause */
  );
  return () => t < 0 ? clearTimeout(e) : cancelIdleCallback(t);
});
const Js = typeof navigator < "u" && (!((Qs = navigator.scheduling) === null || Qs === void 0) && Qs.isInputPending) ? () => navigator.scheduling.isInputPending() : null, Ed = /* @__PURE__ */ yt.fromClass(class {
  constructor(t) {
    this.view = t, this.working = null, this.workScheduled = 0, this.chunkEnd = -1, this.chunkBudget = -1, this.work = this.work.bind(this), this.scheduleWork();
  }
  update(t) {
    let e = this.view.state.field(Rt.state).context;
    (e.updateViewport(t.view.viewport) || this.view.viewport.to > e.treeLen) && this.scheduleWork(), (t.docChanged || t.selectionSet) && (this.view.hasFocus && (this.chunkBudget += 50), this.scheduleWork()), this.checkAsyncSchedule(e);
  }
  scheduleWork() {
    if (this.working)
      return;
    let { state: t } = this.view, e = t.field(Rt.state);
    (e.tree != e.context.tree || !e.context.isDone(t.doc.length)) && (this.working = Ch(this.work));
  }
  work(t) {
    this.working = null;
    let e = Date.now();
    if (this.chunkEnd < e && (this.chunkEnd < 0 || this.view.hasFocus) && (this.chunkEnd = e + 3e4, this.chunkBudget = 3e3), this.chunkBudget <= 0)
      return;
    let { state: i, viewport: { to: s } } = this.view, r = i.field(Rt.state);
    if (r.tree == r.context.tree && r.context.isDone(
      s + 1e5
      /* Work.MaxParseAhead */
    ))
      return;
    let o = Date.now() + Math.min(this.chunkBudget, 100, t && !Js ? Math.max(25, t.timeRemaining() - 5) : 1e9), l = r.context.treeLen < s && i.doc.length > s + 1e3, h = r.context.work(() => Js && Js() || Date.now() > o, s + (l ? 0 : 1e5));
    this.chunkBudget -= Date.now() - e, (h || this.chunkBudget <= 0) && (r.context.takeTree(), this.view.dispatch({ effects: Rt.setState.of(new Xe(r.context)) })), this.chunkBudget > 0 && !(h && !l) && this.scheduleWork(), this.checkAsyncSchedule(r.context);
  }
  checkAsyncSchedule(t) {
    t.scheduleOn && (this.workScheduled++, t.scheduleOn.then(() => this.scheduleWork()).catch((e) => ie(this.view.state, e)).then(() => this.workScheduled--), t.scheduleOn = null);
  }
  destroy() {
    this.working && this.working();
  }
  isWorking() {
    return !!(this.working || this.workScheduled > 0);
  }
}, {
  eventHandlers: { focus() {
    this.scheduleWork();
  } }
}), ve = /* @__PURE__ */ O.define({
  combine(n) {
    return n.length ? n[0] : null;
  },
  enables: (n) => [
    Rt.state,
    Ed,
    T.contentAttributes.compute([n], (t) => {
      let e = t.facet(n);
      return e && e.name ? { "data-language": e.name } : {};
    })
  ]
});
class Nd {
  /**
  Create a language support object.
  */
  constructor(t, e = []) {
    this.language = t, this.support = e, this.extension = [t, e];
  }
}
const Id = /* @__PURE__ */ O.define(), ar = /* @__PURE__ */ O.define({
  combine: (n) => {
    if (!n.length)
      return "  ";
    let t = n[0];
    if (!t || /\S/.test(t) || Array.from(t).some((e) => e != t[0]))
      throw new Error("Invalid indent unit: " + JSON.stringify(n[0]));
    return t;
  }
});
function vs(n) {
  let t = n.facet(ar);
  return t.charCodeAt(0) == 9 ? n.tabSize * t.length : t.length;
}
function Ci(n, t) {
  let e = "", i = n.tabSize, s = n.facet(ar)[0];
  if (s == "	") {
    for (; t >= i; )
      e += "	", t -= i;
    s = " ";
  }
  for (let r = 0; r < t; r++)
    e += s;
  return e;
}
function cr(n, t) {
  n instanceof H && (n = new Rs(n));
  for (let i of n.state.facet(Id)) {
    let s = i(n, t);
    if (s !== void 0)
      return s;
  }
  let e = At(n.state);
  return e.length >= t ? Vd(n, e, t) : null;
}
class Rs {
  /**
  Create an indent context.
  */
  constructor(t, e = {}) {
    this.state = t, this.options = e, this.unit = vs(t);
  }
  /**
  Get a description of the line at the given position, taking
  [simulated line
  breaks](https://codemirror.net/6/docs/ref/#language.IndentContext.constructor^options.simulateBreak)
  into account. If there is such a break at `pos`, the `bias`
  argument determines whether the part of the line line before or
  after the break is used.
  */
  lineAt(t, e = 1) {
    let i = this.state.doc.lineAt(t), { simulateBreak: s, simulateDoubleBreak: r } = this.options;
    return s != null && s >= i.from && s <= i.to ? r && s == t ? { text: "", from: t } : (e < 0 ? s < t : s <= t) ? { text: i.text.slice(s - i.from), from: s } : { text: i.text.slice(0, s - i.from), from: i.from } : i;
  }
  /**
  Get the text directly after `pos`, either the entire line
  or the next 100 characters, whichever is shorter.
  */
  textAfterPos(t, e = 1) {
    if (this.options.simulateDoubleBreak && t == this.options.simulateBreak)
      return "";
    let { text: i, from: s } = this.lineAt(t, e);
    return i.slice(t - s, Math.min(i.length, t + 100 - s));
  }
  /**
  Find the column for the given position.
  */
  column(t, e = 1) {
    let { text: i, from: s } = this.lineAt(t, e), r = this.countColumn(i, t - s), o = this.options.overrideIndentation ? this.options.overrideIndentation(s) : -1;
    return o > -1 && (r += o - this.countColumn(i, i.search(/\S|$/))), r;
  }
  /**
  Find the column position (taking tabs into account) of the given
  position in the given string.
  */
  countColumn(t, e = t.length) {
    return Oi(t, this.state.tabSize, e);
  }
  /**
  Find the indentation column of the line at the given point.
  */
  lineIndent(t, e = 1) {
    let { text: i, from: s } = this.lineAt(t, e), r = this.options.overrideIndentation;
    if (r) {
      let o = r(s);
      if (o > -1)
        return o;
    }
    return this.countColumn(i, i.search(/\S|$/));
  }
  /**
  Returns the [simulated line
  break](https://codemirror.net/6/docs/ref/#language.IndentContext.constructor^options.simulateBreak)
  for this context, if any.
  */
  get simulatedBreak() {
    return this.options.simulateBreak || null;
  }
}
const Ah = /* @__PURE__ */ new R();
function Vd(n, t, e) {
  let i = t.resolveStack(e), s = i.node.enterUnfinishedNodesBefore(e);
  if (s != i.node) {
    let r = [];
    for (let o = s; o != i.node; o = o.parent)
      r.push(o);
    for (let o = r.length - 1; o >= 0; o--)
      i = { node: r[o], next: i };
  }
  return Oh(i, n, e);
}
function Oh(n, t, e) {
  for (let i = n; i; i = i.next) {
    let s = $d(i.node);
    if (s)
      return s(fr.create(t, e, i));
  }
  return 0;
}
function Hd(n) {
  return n.pos == n.options.simulateBreak && n.options.simulateDoubleBreak;
}
function $d(n) {
  let t = n.type.prop(Ah);
  if (t)
    return t;
  let e = n.firstChild, i;
  if (e && (i = e.type.prop(R.closedBy))) {
    let s = n.lastChild, r = s && i.indexOf(s.name) > -1;
    return (o) => Wd(o, !0, 1, void 0, r && !Hd(o) ? s.from : void 0);
  }
  return n.parent == null ? Fd : null;
}
function Fd() {
  return 0;
}
class fr extends Rs {
  constructor(t, e, i) {
    super(t.state, t.options), this.base = t, this.pos = e, this.context = i;
  }
  /**
  The syntax tree node to which the indentation strategy
  applies.
  */
  get node() {
    return this.context.node;
  }
  /**
  @internal
  */
  static create(t, e, i) {
    return new fr(t, e, i);
  }
  /**
  Get the text directly after `this.pos`, either the entire line
  or the next 100 characters, whichever is shorter.
  */
  get textAfter() {
    return this.textAfterPos(this.pos);
  }
  /**
  Get the indentation at the reference line for `this.node`, which
  is the line on which it starts, unless there is a node that is
  _not_ a parent of this node covering the start of that line. If
  so, the line at the start of that node is tried, again skipping
  on if it is covered by another such node.
  */
  get baseIndent() {
    return this.baseIndentFor(this.node);
  }
  /**
  Get the indentation for the reference line of the given node
  (see [`baseIndent`](https://codemirror.net/6/docs/ref/#language.TreeIndentContext.baseIndent)).
  */
  baseIndentFor(t) {
    let e = this.state.doc.lineAt(t.from);
    for (; ; ) {
      let i = t.resolve(e.from);
      for (; i.parent && i.parent.from == i.from; )
        i = i.parent;
      if (_d(i, t))
        break;
      e = this.state.doc.lineAt(i.from);
    }
    return this.lineIndent(e.from);
  }
  /**
  Continue looking for indentations in the node's parent nodes,
  and return the result of that.
  */
  continue() {
    return Oh(this.context.next, this.base, this.pos);
  }
}
function _d(n, t) {
  for (let e = t; e; e = e.parent)
    if (n == e)
      return !0;
  return !1;
}
function zd(n) {
  let t = n.node, e = t.childAfter(t.from), i = t.lastChild;
  if (!e)
    return null;
  let s = n.options.simulateBreak, r = n.state.doc.lineAt(e.from), o = s == null || s <= r.from ? r.to : Math.min(r.to, s);
  for (let l = e.to; ; ) {
    let h = t.childAfter(l);
    if (!h || h == i)
      return null;
    if (!h.type.isSkipped)
      return h.from < o ? e : null;
    l = h.to;
  }
}
function Wd(n, t, e, i, s) {
  let r = n.textAfter, o = r.match(/^\s*/)[0].length, l = i && r.slice(o, o + i.length) == i || s == n.pos + o, h = t ? zd(n) : null;
  return h ? l ? n.column(h.from) : n.column(h.to) : n.baseIndent + (l ? 0 : n.unit * e);
}
function Mo({ except: n, units: t = 1 } = {}) {
  return (e) => {
    let i = n && n.test(e.textAfter);
    return e.baseIndent + (i ? 0 : t * e.unit);
  };
}
const jd = 200;
function Kd() {
  return H.transactionFilter.of((n) => {
    if (!n.docChanged || !n.isUserEvent("input.type") && !n.isUserEvent("input.complete"))
      return n;
    let t = n.startState.languageDataAt("indentOnInput", n.startState.selection.main.head);
    if (!t.length)
      return n;
    let e = n.newDoc, { head: i } = n.newSelection.main, s = e.lineAt(i);
    if (i > s.from + jd)
      return n;
    let r = e.sliceString(s.from, i);
    if (!t.some((a) => a.test(r)))
      return n;
    let { state: o } = n, l = -1, h = [];
    for (let { head: a } of o.selection.ranges) {
      let c = o.doc.lineAt(a);
      if (c.from == l)
        continue;
      l = c.from;
      let f = cr(o, c.from);
      if (f == null)
        continue;
      let u = /^\s*/.exec(c.text)[0], d = Ci(o, f);
      u != d && h.push({ from: c.from, to: c.from + u.length, insert: d });
    }
    return h.length ? [n, { changes: h, sequential: !0 }] : n;
  });
}
const qd = /* @__PURE__ */ O.define(), Mh = /* @__PURE__ */ new R();
function Gd(n) {
  let t = n.firstChild, e = n.lastChild;
  return t && t.to < e.from ? { from: t.to, to: e.type.isError ? n.to : e.from } : null;
}
function Ud(n, t, e) {
  let i = At(n);
  if (i.length < e)
    return null;
  let s = i.resolveStack(e, 1), r = null;
  for (let o = s; o; o = o.next) {
    let l = o.node;
    if (l.to <= e || l.from > e)
      continue;
    if (r && l.from < t)
      break;
    let h = l.type.prop(Mh);
    if (h && (l.to < i.length - 50 || i.length == n.doc.length || !Yd(l))) {
      let a = h(l, n);
      a && a.from <= e && a.from >= t && a.to > e && (r = a);
    }
  }
  return r;
}
function Yd(n) {
  let t = n.lastChild;
  return t && t.to == n.to && t.type.isError;
}
function Ss(n, t, e) {
  for (let i of n.facet(qd)) {
    let s = i(n, t, e);
    if (s)
      return s;
  }
  return Ud(n, t, e);
}
function Th(n, t) {
  let e = t.mapPos(n.from, 1), i = t.mapPos(n.to, -1);
  return e >= i ? void 0 : { from: e, to: i };
}
const Ls = /* @__PURE__ */ z.define({ map: Th }), Di = /* @__PURE__ */ z.define({ map: Th });
function Dh(n) {
  let t = [];
  for (let { head: e } of n.state.selection.ranges)
    t.some((i) => i.from <= e && i.to >= e) || t.push(n.lineBlockAt(e));
  return t;
}
const Ie = /* @__PURE__ */ Ht.define({
  create() {
    return N.none;
  },
  update(n, t) {
    n = n.map(t.changes);
    for (let e of t.effects)
      if (e.is(Ls) && !Qd(n, e.value.from, e.value.to)) {
        let { preparePlaceholder: i } = t.state.facet(ur), s = i ? N.replace({ widget: new sp(i(t.state, e.value)) }) : To;
        n = n.update({ add: [s.range(e.value.from, e.value.to)] });
      } else
        e.is(Di) && (n = n.update({
          filter: (i, s) => e.value.from != i || e.value.to != s,
          filterFrom: e.value.from,
          filterTo: e.value.to
        }));
    if (t.selection) {
      let e = !1, { head: i } = t.selection.main;
      n.between(i, i, (s, r) => {
        s < i && r > i && (e = !0);
      }), e && (n = n.update({
        filterFrom: i,
        filterTo: i,
        filter: (s, r) => r <= i || s >= i
      }));
    }
    return n;
  },
  provide: (n) => T.decorations.from(n),
  toJSON(n, t) {
    let e = [];
    return n.between(0, t.doc.length, (i, s) => {
      e.push(i, s);
    }), e;
  },
  fromJSON(n) {
    if (!Array.isArray(n) || n.length % 2)
      throw new RangeError("Invalid JSON for fold state");
    let t = [];
    for (let e = 0; e < n.length; ) {
      let i = n[e++], s = n[e++];
      if (typeof i != "number" || typeof s != "number")
        throw new RangeError("Invalid JSON for fold state");
      t.push(To.range(i, s));
    }
    return N.set(t, !0);
  }
});
function Cs(n, t, e) {
  var i;
  let s = null;
  return (i = n.field(Ie, !1)) === null || i === void 0 || i.between(t, e, (r, o) => {
    (!s || s.from > r) && (s = { from: r, to: o });
  }), s;
}
function Qd(n, t, e) {
  let i = !1;
  return n.between(t, t, (s, r) => {
    s == t && r == e && (i = !0);
  }), i;
}
function Ph(n, t) {
  return n.field(Ie, !1) ? t : t.concat(z.appendConfig.of(Rh()));
}
const Jd = (n) => {
  for (let t of Dh(n)) {
    let e = Ss(n.state, t.from, t.to);
    if (e)
      return n.dispatch({ effects: Ph(n.state, [Ls.of(e), Bh(n, e)]) }), !0;
  }
  return !1;
}, Xd = (n) => {
  if (!n.state.field(Ie, !1))
    return !1;
  let t = [];
  for (let e of Dh(n)) {
    let i = Cs(n.state, e.from, e.to);
    i && t.push(Di.of(i), Bh(n, i, !1));
  }
  return t.length && n.dispatch({ effects: t }), t.length > 0;
};
function Bh(n, t, e = !0) {
  let i = n.state.doc.lineAt(t.from).number, s = n.state.doc.lineAt(t.to).number;
  return T.announce.of(`${n.state.phrase(e ? "Folded lines" : "Unfolded lines")} ${i} ${n.state.phrase("to")} ${s}.`);
}
const Zd = (n) => {
  let { state: t } = n, e = [];
  for (let i = 0; i < t.doc.length; ) {
    let s = n.lineBlockAt(i), r = Ss(t, s.from, s.to);
    r && e.push(Ls.of(r)), i = (r ? n.lineBlockAt(r.to) : s).to + 1;
  }
  return e.length && n.dispatch({ effects: Ph(n.state, e) }), !!e.length;
}, tp = (n) => {
  let t = n.state.field(Ie, !1);
  if (!t || !t.size)
    return !1;
  let e = [];
  return t.between(0, n.state.doc.length, (i, s) => {
    e.push(Di.of({ from: i, to: s }));
  }), n.dispatch({ effects: e }), !0;
}, ep = [
  { key: "Ctrl-Shift-[", mac: "Cmd-Alt-[", run: Jd },
  { key: "Ctrl-Shift-]", mac: "Cmd-Alt-]", run: Xd },
  { key: "Ctrl-Alt-[", run: Zd },
  { key: "Ctrl-Alt-]", run: tp }
], ip = {
  placeholderDOM: null,
  preparePlaceholder: null,
  placeholderText: "…"
}, ur = /* @__PURE__ */ O.define({
  combine(n) {
    return Ds(n, ip);
  }
});
function Rh(n) {
  let t = [Ie, op];
  return n && t.push(ur.of(n)), t;
}
function Lh(n, t) {
  let { state: e } = n, i = e.facet(ur), s = (o) => {
    let l = n.lineBlockAt(n.posAtDOM(o.target)), h = Cs(n.state, l.from, l.to);
    h && n.dispatch({ effects: Di.of(h) }), o.preventDefault();
  };
  if (i.placeholderDOM)
    return i.placeholderDOM(n, s, t);
  let r = document.createElement("span");
  return r.textContent = i.placeholderText, r.setAttribute("aria-label", e.phrase("folded code")), r.title = e.phrase("unfold"), r.className = "cm-foldPlaceholder", r.onclick = s, r;
}
const To = /* @__PURE__ */ N.replace({ widget: /* @__PURE__ */ new class extends Se {
  toDOM(n) {
    return Lh(n, null);
  }
}() });
class sp extends Se {
  constructor(t) {
    super(), this.value = t;
  }
  eq(t) {
    return this.value == t.value;
  }
  toDOM(t) {
    return Lh(t, this.value);
  }
}
const np = {
  openText: "⌄",
  closedText: "›",
  markerDOM: null,
  domEventHandlers: {},
  foldingChanged: () => !1
};
class Xs extends ke {
  constructor(t, e) {
    super(), this.config = t, this.open = e;
  }
  eq(t) {
    return this.config == t.config && this.open == t.open;
  }
  toDOM(t) {
    if (this.config.markerDOM)
      return this.config.markerDOM(this.open);
    let e = document.createElement("span");
    return e.textContent = this.open ? this.config.openText : this.config.closedText, e.title = t.state.phrase(this.open ? "Fold line" : "Unfold line"), e;
  }
}
function rp(n = {}) {
  let t = Object.assign(Object.assign({}, np), n), e = new Xs(t, !0), i = new Xs(t, !1), s = yt.fromClass(class {
    constructor(o) {
      this.from = o.viewport.from, this.markers = this.buildMarkers(o);
    }
    update(o) {
      (o.docChanged || o.viewportChanged || o.startState.facet(ve) != o.state.facet(ve) || o.startState.field(Ie, !1) != o.state.field(Ie, !1) || At(o.startState) != At(o.state) || t.foldingChanged(o)) && (this.markers = this.buildMarkers(o.view));
    }
    buildMarkers(o) {
      let l = new Ee();
      for (let h of o.viewportLineBlocks) {
        let a = Cs(o.state, h.from, h.to) ? i : Ss(o.state, h.from, h.to) ? e : null;
        a && l.add(h.from, h.from, a);
      }
      return l.finish();
    }
  }), { domEventHandlers: r } = t;
  return [
    s,
    hd({
      class: "cm-foldGutter",
      markers(o) {
        var l;
        return ((l = o.plugin(s)) === null || l === void 0 ? void 0 : l.markers) || F.empty;
      },
      initialSpacer() {
        return new Xs(t, !1);
      },
      domEventHandlers: Object.assign(Object.assign({}, r), { click: (o, l, h) => {
        if (r.click && r.click(o, l, h))
          return !0;
        let a = Cs(o.state, l.from, l.to);
        if (a)
          return o.dispatch({ effects: Di.of(a) }), !0;
        let c = Ss(o.state, l.from, l.to);
        return c ? (o.dispatch({ effects: Ls.of(c) }), !0) : !1;
      } })
    }),
    Rh()
  ];
}
const op = /* @__PURE__ */ T.baseTheme({
  ".cm-foldPlaceholder": {
    backgroundColor: "#eee",
    border: "1px solid #ddd",
    color: "#888",
    borderRadius: ".2em",
    margin: "0 1px",
    padding: "0 1px",
    cursor: "pointer"
  },
  ".cm-foldGutter span": {
    padding: "0 1px",
    cursor: "pointer"
  }
});
class Pi {
  constructor(t, e) {
    this.specs = t;
    let i;
    function s(l) {
      let h = we.newName();
      return (i || (i = /* @__PURE__ */ Object.create(null)))["." + h] = l, h;
    }
    const r = typeof e.all == "string" ? e.all : e.all ? s(e.all) : void 0, o = e.scope;
    this.scope = o instanceof Rt ? (l) => l.prop(ze) == o.data : o ? (l) => l == o : void 0, this.style = Sh(t.map((l) => ({
      tag: l.tag,
      class: l.class || s(Object.assign({}, l, { tag: null }))
    })), {
      all: r
    }).style, this.module = i ? new we(i) : null, this.themeType = e.themeType;
  }
  /**
  Create a highlighter style that associates the given styles to
  the given tags. The specs must be objects that hold a style tag
  or array of tags in their `tag` property, and either a single
  `class` property providing a static CSS class (for highlighter
  that rely on external styling), or a
  [`style-mod`](https://github.com/marijnh/style-mod#documentation)-style
  set of CSS properties (which define the styling for those tags).
  
  The CSS rules created for a highlighter will be emitted in the
  order of the spec's properties. That means that for elements that
  have multiple tags associated with them, styles defined further
  down in the list will have a higher CSS precedence than styles
  defined earlier.
  */
  static define(t, e) {
    return new Pi(t, e || {});
  }
}
const Fn = /* @__PURE__ */ O.define(), Eh = /* @__PURE__ */ O.define({
  combine(n) {
    return n.length ? [n[0]] : null;
  }
});
function Zs(n) {
  let t = n.facet(Fn);
  return t.length ? t : n.facet(Eh);
}
function Do(n, t) {
  let e = [hp], i;
  return n instanceof Pi && (n.module && e.push(T.styleModule.of(n.module)), i = n.themeType), t != null && t.fallback ? e.push(Eh.of(n)) : i ? e.push(Fn.computeN([T.darkTheme], (s) => s.facet(T.darkTheme) == (i == "dark") ? [n] : [])) : e.push(Fn.of(n)), e;
}
class lp {
  constructor(t) {
    this.markCache = /* @__PURE__ */ Object.create(null), this.tree = At(t.state), this.decorations = this.buildDeco(t, Zs(t.state));
  }
  update(t) {
    let e = At(t.state), i = Zs(t.state), s = i != Zs(t.startState);
    e.length < t.view.viewport.to && !s && e.type == this.tree.type ? this.decorations = this.decorations.map(t.changes) : (e != this.tree || t.viewportChanged || s) && (this.tree = e, this.decorations = this.buildDeco(t.view, i));
  }
  buildDeco(t, e) {
    if (!e || !this.tree.length)
      return N.none;
    let i = new Ee();
    for (let { from: s, to: r } of t.visibleRanges)
      Td(this.tree, e, (o, l, h) => {
        i.add(o, l, this.markCache[h] || (this.markCache[h] = N.mark({ class: h })));
      }, s, r);
    return i.finish();
  }
}
const hp = /* @__PURE__ */ Qn.high(/* @__PURE__ */ yt.fromClass(lp, {
  decorations: (n) => n.decorations
})), ap = /* @__PURE__ */ Pi.define([
  {
    tag: w.meta,
    color: "#404740"
  },
  {
    tag: w.link,
    textDecoration: "underline"
  },
  {
    tag: w.heading,
    textDecoration: "underline",
    fontWeight: "bold"
  },
  {
    tag: w.emphasis,
    fontStyle: "italic"
  },
  {
    tag: w.strong,
    fontWeight: "bold"
  },
  {
    tag: w.strikethrough,
    textDecoration: "line-through"
  },
  {
    tag: w.keyword,
    color: "#708"
  },
  {
    tag: [w.atom, w.bool, w.url, w.contentSeparator, w.labelName],
    color: "#219"
  },
  {
    tag: [w.literal, w.inserted],
    color: "#164"
  },
  {
    tag: [w.string, w.deleted],
    color: "#a11"
  },
  {
    tag: [w.regexp, w.escape, /* @__PURE__ */ w.special(w.string)],
    color: "#e40"
  },
  {
    tag: /* @__PURE__ */ w.definition(w.variableName),
    color: "#00f"
  },
  {
    tag: /* @__PURE__ */ w.local(w.variableName),
    color: "#30a"
  },
  {
    tag: [w.typeName, w.namespace],
    color: "#085"
  },
  {
    tag: w.className,
    color: "#167"
  },
  {
    tag: [/* @__PURE__ */ w.special(w.variableName), w.macroName],
    color: "#256"
  },
  {
    tag: /* @__PURE__ */ w.definition(w.propertyName),
    color: "#00c"
  },
  {
    tag: w.comment,
    color: "#940"
  },
  {
    tag: w.invalid,
    color: "#f00"
  }
]), cp = /* @__PURE__ */ T.baseTheme({
  "&.cm-focused .cm-matchingBracket": { backgroundColor: "#328c8252" },
  "&.cm-focused .cm-nonmatchingBracket": { backgroundColor: "#bb555544" }
}), Nh = 1e4, Ih = "()[]{}", Vh = /* @__PURE__ */ O.define({
  combine(n) {
    return Ds(n, {
      afterCursor: !0,
      brackets: Ih,
      maxScanDistance: Nh,
      renderMatch: dp
    });
  }
}), fp = /* @__PURE__ */ N.mark({ class: "cm-matchingBracket" }), up = /* @__PURE__ */ N.mark({ class: "cm-nonmatchingBracket" });
function dp(n) {
  let t = [], e = n.matched ? fp : up;
  return t.push(e.range(n.start.from, n.start.to)), n.end && t.push(e.range(n.end.from, n.end.to)), t;
}
const pp = /* @__PURE__ */ Ht.define({
  create() {
    return N.none;
  },
  update(n, t) {
    if (!t.docChanged && !t.selection)
      return n;
    let e = [], i = t.state.facet(Vh);
    for (let s of t.state.selection.ranges) {
      if (!s.empty)
        continue;
      let r = Yt(t.state, s.head, -1, i) || s.head > 0 && Yt(t.state, s.head - 1, 1, i) || i.afterCursor && (Yt(t.state, s.head, 1, i) || s.head < t.state.doc.length && Yt(t.state, s.head + 1, -1, i));
      r && (e = e.concat(i.renderMatch(r, t.state)));
    }
    return N.set(e, !0);
  },
  provide: (n) => T.decorations.from(n)
}), gp = [
  pp,
  cp
];
function mp(n = {}) {
  return [Vh.of(n), gp];
}
const wp = /* @__PURE__ */ new R();
function _n(n, t, e) {
  let i = n.prop(t < 0 ? R.openedBy : R.closedBy);
  if (i)
    return i;
  if (n.name.length == 1) {
    let s = e.indexOf(n.name);
    if (s > -1 && s % 2 == (t < 0 ? 1 : 0))
      return [e[s + t]];
  }
  return null;
}
function zn(n) {
  let t = n.type.prop(wp);
  return t ? t(n.node) : n;
}
function Yt(n, t, e, i = {}) {
  let s = i.maxScanDistance || Nh, r = i.brackets || Ih, o = At(n), l = o.resolveInner(t, e);
  for (let h = l; h; h = h.parent) {
    let a = _n(h.type, e, r);
    if (a && h.from < h.to) {
      let c = zn(h);
      if (c && (e > 0 ? t >= c.from && t < c.to : t > c.from && t <= c.to))
        return yp(n, t, e, h, c, a, r);
    }
  }
  return bp(n, t, e, o, l.type, s, r);
}
function yp(n, t, e, i, s, r, o) {
  let l = i.parent, h = { from: s.from, to: s.to }, a = 0, c = l == null ? void 0 : l.cursor();
  if (c && (e < 0 ? c.childBefore(i.from) : c.childAfter(i.to)))
    do
      if (e < 0 ? c.to <= i.from : c.from >= i.to) {
        if (a == 0 && r.indexOf(c.type.name) > -1 && c.from < c.to) {
          let f = zn(c);
          return { start: h, end: f ? { from: f.from, to: f.to } : void 0, matched: !0 };
        } else if (_n(c.type, e, o))
          a++;
        else if (_n(c.type, -e, o)) {
          if (a == 0) {
            let f = zn(c);
            return {
              start: h,
              end: f && f.from < f.to ? { from: f.from, to: f.to } : void 0,
              matched: !1
            };
          }
          a--;
        }
      }
    while (e < 0 ? c.prevSibling() : c.nextSibling());
  return { start: h, matched: !1 };
}
function bp(n, t, e, i, s, r, o) {
  let l = e < 0 ? n.sliceDoc(t - 1, t) : n.sliceDoc(t, t + 1), h = o.indexOf(l);
  if (h < 0 || h % 2 == 0 != e > 0)
    return null;
  let a = { from: e < 0 ? t - 1 : t, to: e > 0 ? t + 1 : t }, c = n.doc.iterRange(t, e > 0 ? n.doc.length : 0), f = 0;
  for (let u = 0; !c.next().done && u <= r; ) {
    let d = c.value;
    e < 0 && (u += d.length);
    let p = t + u * e;
    for (let m = e > 0 ? 0 : d.length - 1, g = e > 0 ? d.length : -1; m != g; m += e) {
      let y = o.indexOf(d[m]);
      if (!(y < 0 || i.resolveInner(p + m, 1).type != s))
        if (y % 2 == 0 == e > 0)
          f++;
        else {
          if (f == 1)
            return { start: a, end: { from: p + m, to: p + m + 1 }, matched: y >> 1 == h >> 1 };
          f--;
        }
    }
    e > 0 && (u += d.length);
  }
  return c.done ? { start: a, matched: !1 } : null;
}
const kp = /* @__PURE__ */ Object.create(null), Po = [bt.none], Bo = [], xp = /* @__PURE__ */ Object.create(null);
for (let [n, t] of [
  ["variable", "variableName"],
  ["variable-2", "variableName.special"],
  ["string-2", "string.special"],
  ["def", "variableName.definition"],
  ["tag", "tagName"],
  ["attribute", "attributeName"],
  ["type", "typeName"],
  ["builtin", "variableName.standard"],
  ["qualifier", "modifier"],
  ["error", "invalid"],
  ["header", "heading"],
  ["property", "propertyName"]
])
  xp[n] = /* @__PURE__ */ vp(kp, t);
function tn(n, t) {
  Bo.indexOf(n) > -1 || (Bo.push(n), console.warn(t));
}
function vp(n, t) {
  let e = [];
  for (let r of t.split(" ")) {
    let o = [];
    for (let l of r.split(".")) {
      let h = n[l] || w[l];
      h ? typeof h == "function" ? o.length ? o = o.map(h) : tn(l, `Modifier ${l} used at start of tag`) : o.length ? tn(l, `Tag ${l} used as modifier`) : o = Array.isArray(h) ? h : [h] : tn(l, `Unknown highlighting tag ${l}`);
    }
    for (let l of o)
      e.push(l);
  }
  if (!e.length)
    return 0;
  let i = t.replace(/ /g, "_"), s = bt.define({
    id: Po.length,
    name: i,
    props: [xh({ [i]: e })]
  });
  return Po.push(s), s.id;
}
const Sp = (n) => {
  let { state: t } = n, e = t.doc.lineAt(t.selection.main.from), i = pr(n.state, e.from);
  return i.line ? Cp(n) : i.block ? Op(n) : !1;
};
function dr(n, t) {
  return ({ state: e, dispatch: i }) => {
    if (e.readOnly)
      return !1;
    let s = n(t, e);
    return s ? (i(e.update(s)), !0) : !1;
  };
}
const Cp = /* @__PURE__ */ dr(
  Dp,
  0
  /* CommentOption.Toggle */
), Ap = /* @__PURE__ */ dr(
  Hh,
  0
  /* CommentOption.Toggle */
), Op = /* @__PURE__ */ dr(
  (n, t) => Hh(n, t, Tp(t)),
  0
  /* CommentOption.Toggle */
);
function pr(n, t) {
  let e = n.languageDataAt("commentTokens", t);
  return e.length ? e[0] : {};
}
const li = 50;
function Mp(n, { open: t, close: e }, i, s) {
  let r = n.sliceDoc(i - li, i), o = n.sliceDoc(s, s + li), l = /\s*$/.exec(r)[0].length, h = /^\s*/.exec(o)[0].length, a = r.length - l;
  if (r.slice(a - t.length, a) == t && o.slice(h, h + e.length) == e)
    return {
      open: { pos: i - l, margin: l && 1 },
      close: { pos: s + h, margin: h && 1 }
    };
  let c, f;
  s - i <= 2 * li ? c = f = n.sliceDoc(i, s) : (c = n.sliceDoc(i, i + li), f = n.sliceDoc(s - li, s));
  let u = /^\s*/.exec(c)[0].length, d = /\s*$/.exec(f)[0].length, p = f.length - d - e.length;
  return c.slice(u, u + t.length) == t && f.slice(p, p + e.length) == e ? {
    open: {
      pos: i + u + t.length,
      margin: /\s/.test(c.charAt(u + t.length)) ? 1 : 0
    },
    close: {
      pos: s - d - e.length,
      margin: /\s/.test(f.charAt(p - 1)) ? 1 : 0
    }
  } : null;
}
function Tp(n) {
  let t = [];
  for (let e of n.selection.ranges) {
    let i = n.doc.lineAt(e.from), s = e.to <= i.to ? i : n.doc.lineAt(e.to), r = t.length - 1;
    r >= 0 && t[r].to > i.from ? t[r].to = s.to : t.push({ from: i.from + /^\s*/.exec(i.text)[0].length, to: s.to });
  }
  return t;
}
function Hh(n, t, e = t.selection.ranges) {
  let i = e.map((r) => pr(t, r.from).block);
  if (!i.every((r) => r))
    return null;
  let s = e.map((r, o) => Mp(t, i[o], r.from, r.to));
  if (n != 2 && !s.every((r) => r))
    return { changes: t.changes(e.map((r, o) => s[o] ? [] : [{ from: r.from, insert: i[o].open + " " }, { from: r.to, insert: " " + i[o].close }])) };
  if (n != 1 && s.some((r) => r)) {
    let r = [];
    for (let o = 0, l; o < s.length; o++)
      if (l = s[o]) {
        let h = i[o], { open: a, close: c } = l;
        r.push({ from: a.pos - h.open.length, to: a.pos + a.margin }, { from: c.pos - c.margin, to: c.pos + h.close.length });
      }
    return { changes: r };
  }
  return null;
}
function Dp(n, t, e = t.selection.ranges) {
  let i = [], s = -1;
  for (let { from: r, to: o } of e) {
    let l = i.length, h = 1e9, a = pr(t, r).line;
    if (a) {
      for (let c = r; c <= o; ) {
        let f = t.doc.lineAt(c);
        if (f.from > s && (r == o || o > f.from)) {
          s = f.from;
          let u = /^\s*/.exec(f.text)[0].length, d = u == f.length, p = f.text.slice(u, u + a.length) == a ? u : -1;
          u < f.text.length && u < h && (h = u), i.push({ line: f, comment: p, token: a, indent: u, empty: d, single: !1 });
        }
        c = f.to + 1;
      }
      if (h < 1e9)
        for (let c = l; c < i.length; c++)
          i[c].indent < i[c].line.text.length && (i[c].indent = h);
      i.length == l + 1 && (i[l].single = !0);
    }
  }
  if (n != 2 && i.some((r) => r.comment < 0 && (!r.empty || r.single))) {
    let r = [];
    for (let { line: l, token: h, indent: a, empty: c, single: f } of i)
      (f || !c) && r.push({ from: l.from + a, insert: h + " " });
    let o = t.changes(r);
    return { changes: o, selection: t.selection.map(o, 1) };
  } else if (n != 1 && i.some((r) => r.comment >= 0)) {
    let r = [];
    for (let { line: o, comment: l, token: h } of i)
      if (l >= 0) {
        let a = o.from + l, c = a + h.length;
        o.text[c - o.from] == " " && c++, r.push({ from: a, to: c });
      }
    return { changes: r };
  }
  return null;
}
function ei(n, t) {
  return b.create(n.ranges.map(t), n.mainIndex);
}
function Qt(n, t) {
  return n.update({ selection: t, scrollIntoView: !0, userEvent: "select" });
}
function $t({ state: n, dispatch: t }, e) {
  let i = ei(n.selection, e);
  return i.eq(n.selection) ? !1 : (t(Qt(n, i)), !0);
}
function Es(n, t) {
  return b.cursor(t ? n.to : n.from);
}
function $h(n, t) {
  return $t(n, (e) => e.empty ? n.moveByChar(e, t) : Es(e, t));
}
function ut(n) {
  return n.textDirectionAt(n.state.selection.main.head) == tt.LTR;
}
const Fh = (n) => $h(n, !ut(n)), _h = (n) => $h(n, ut(n));
function zh(n, t) {
  return $t(n, (e) => e.empty ? n.moveByGroup(e, t) : Es(e, t));
}
const Pp = (n) => zh(n, !ut(n)), Bp = (n) => zh(n, ut(n));
function Rp(n, t, e) {
  if (t.type.prop(e))
    return !0;
  let i = t.to - t.from;
  return i && (i > 2 || /[^\s,.;:]/.test(n.sliceDoc(t.from, t.to))) || t.firstChild;
}
function Ns(n, t, e) {
  let i = At(n).resolveInner(t.head), s = e ? R.closedBy : R.openedBy;
  for (let h = t.head; ; ) {
    let a = e ? i.childAfter(h) : i.childBefore(h);
    if (!a)
      break;
    Rp(n, a, s) ? i = a : h = e ? a.to : a.from;
  }
  let r = i.type.prop(s), o, l;
  return r && (o = e ? Yt(n, i.from, 1) : Yt(n, i.to, -1)) && o.matched ? l = e ? o.end.to : o.end.from : l = e ? i.to : i.from, b.cursor(l, e ? -1 : 1);
}
const Lp = (n) => $t(n, (t) => Ns(n.state, t, !ut(n))), Ep = (n) => $t(n, (t) => Ns(n.state, t, ut(n)));
function Wh(n, t) {
  return $t(n, (e) => {
    if (!e.empty)
      return Es(e, t);
    let i = n.moveVertically(e, t);
    return i.head != e.head ? i : n.moveToLineBoundary(e, t);
  });
}
const jh = (n) => Wh(n, !1), Kh = (n) => Wh(n, !0);
function qh(n) {
  let t = n.scrollDOM.clientHeight < n.scrollDOM.scrollHeight - 2, e = 0, i = 0, s;
  if (t) {
    for (let r of n.state.facet(T.scrollMargins)) {
      let o = r(n);
      o != null && o.top && (e = Math.max(o == null ? void 0 : o.top, e)), o != null && o.bottom && (i = Math.max(o == null ? void 0 : o.bottom, i));
    }
    s = n.scrollDOM.clientHeight - e - i;
  } else
    s = (n.dom.ownerDocument.defaultView || window).innerHeight;
  return {
    marginTop: e,
    marginBottom: i,
    selfScroll: t,
    height: Math.max(n.defaultLineHeight, s - 5)
  };
}
function Gh(n, t) {
  let e = qh(n), { state: i } = n, s = ei(i.selection, (o) => o.empty ? n.moveVertically(o, t, e.height) : Es(o, t));
  if (s.eq(i.selection))
    return !1;
  let r;
  if (e.selfScroll) {
    let o = n.coordsAtPos(i.selection.main.head), l = n.scrollDOM.getBoundingClientRect(), h = l.top + e.marginTop, a = l.bottom - e.marginBottom;
    o && o.top > h && o.bottom < a && (r = T.scrollIntoView(s.main.head, { y: "start", yMargin: o.top - h }));
  }
  return n.dispatch(Qt(i, s), { effects: r }), !0;
}
const Ro = (n) => Gh(n, !1), Wn = (n) => Gh(n, !0);
function Ce(n, t, e) {
  let i = n.lineBlockAt(t.head), s = n.moveToLineBoundary(t, e);
  if (s.head == t.head && s.head != (e ? i.to : i.from) && (s = n.moveToLineBoundary(t, e, !1)), !e && s.head == i.from && i.length) {
    let r = /^\s*/.exec(n.state.sliceDoc(i.from, Math.min(i.from + 100, i.to)))[0].length;
    r && t.head != i.from + r && (s = b.cursor(i.from + r));
  }
  return s;
}
const Np = (n) => $t(n, (t) => Ce(n, t, !0)), Ip = (n) => $t(n, (t) => Ce(n, t, !1)), Vp = (n) => $t(n, (t) => Ce(n, t, !ut(n))), Hp = (n) => $t(n, (t) => Ce(n, t, ut(n))), $p = (n) => $t(n, (t) => b.cursor(n.lineBlockAt(t.head).from, 1)), Fp = (n) => $t(n, (t) => b.cursor(n.lineBlockAt(t.head).to, -1));
function _p(n, t, e) {
  let i = !1, s = ei(n.selection, (r) => {
    let o = Yt(n, r.head, -1) || Yt(n, r.head, 1) || r.head > 0 && Yt(n, r.head - 1, 1) || r.head < n.doc.length && Yt(n, r.head + 1, -1);
    if (!o || !o.end)
      return r;
    i = !0;
    let l = o.start.from == r.head ? o.end.to : o.end.from;
    return e ? b.range(r.anchor, l) : b.cursor(l);
  });
  return i ? (t(Qt(n, s)), !0) : !1;
}
const zp = ({ state: n, dispatch: t }) => _p(n, t, !1);
function Bt(n, t) {
  let e = ei(n.state.selection, (i) => {
    let s = t(i);
    return b.range(i.anchor, s.head, s.goalColumn, s.bidiLevel || void 0);
  });
  return e.eq(n.state.selection) ? !1 : (n.dispatch(Qt(n.state, e)), !0);
}
function Uh(n, t) {
  return Bt(n, (e) => n.moveByChar(e, t));
}
const Yh = (n) => Uh(n, !ut(n)), Qh = (n) => Uh(n, ut(n));
function Jh(n, t) {
  return Bt(n, (e) => n.moveByGroup(e, t));
}
const Wp = (n) => Jh(n, !ut(n)), jp = (n) => Jh(n, ut(n)), Kp = (n) => Bt(n, (t) => Ns(n.state, t, !ut(n))), qp = (n) => Bt(n, (t) => Ns(n.state, t, ut(n)));
function Xh(n, t) {
  return Bt(n, (e) => n.moveVertically(e, t));
}
const Zh = (n) => Xh(n, !1), ta = (n) => Xh(n, !0);
function ea(n, t) {
  return Bt(n, (e) => n.moveVertically(e, t, qh(n).height));
}
const Lo = (n) => ea(n, !1), Eo = (n) => ea(n, !0), Gp = (n) => Bt(n, (t) => Ce(n, t, !0)), Up = (n) => Bt(n, (t) => Ce(n, t, !1)), Yp = (n) => Bt(n, (t) => Ce(n, t, !ut(n))), Qp = (n) => Bt(n, (t) => Ce(n, t, ut(n))), Jp = (n) => Bt(n, (t) => b.cursor(n.lineBlockAt(t.head).from)), Xp = (n) => Bt(n, (t) => b.cursor(n.lineBlockAt(t.head).to)), No = ({ state: n, dispatch: t }) => (t(Qt(n, { anchor: 0 })), !0), Io = ({ state: n, dispatch: t }) => (t(Qt(n, { anchor: n.doc.length })), !0), Vo = ({ state: n, dispatch: t }) => (t(Qt(n, { anchor: n.selection.main.anchor, head: 0 })), !0), Ho = ({ state: n, dispatch: t }) => (t(Qt(n, { anchor: n.selection.main.anchor, head: n.doc.length })), !0), Zp = ({ state: n, dispatch: t }) => (t(n.update({ selection: { anchor: 0, head: n.doc.length }, userEvent: "select" })), !0), tg = ({ state: n, dispatch: t }) => {
  let e = Is(n).map(({ from: i, to: s }) => b.range(i, Math.min(s + 1, n.doc.length)));
  return t(n.update({ selection: b.create(e), userEvent: "select" })), !0;
}, eg = ({ state: n, dispatch: t }) => {
  let e = ei(n.selection, (i) => {
    var s;
    let r = At(n).resolveStack(i.from, 1);
    for (let o = r; o; o = o.next) {
      let { node: l } = o;
      if ((l.from < i.from && l.to >= i.to || l.to > i.to && l.from <= i.from) && (!((s = l.parent) === null || s === void 0) && s.parent))
        return b.range(l.to, l.from);
    }
    return i;
  });
  return t(Qt(n, e)), !0;
}, ig = ({ state: n, dispatch: t }) => {
  let e = n.selection, i = null;
  return e.ranges.length > 1 ? i = b.create([e.main]) : e.main.empty || (i = b.create([b.cursor(e.main.head)])), i ? (t(Qt(n, i)), !0) : !1;
};
function Bi(n, t) {
  if (n.state.readOnly)
    return !1;
  let e = "delete.selection", { state: i } = n, s = i.changeByRange((r) => {
    let { from: o, to: l } = r;
    if (o == l) {
      let h = t(r);
      h < o ? (e = "delete.backward", h = Yi(n, h, !1)) : h > o && (e = "delete.forward", h = Yi(n, h, !0)), o = Math.min(o, h), l = Math.max(l, h);
    } else
      o = Yi(n, o, !1), l = Yi(n, l, !0);
    return o == l ? { range: r } : { changes: { from: o, to: l }, range: b.cursor(o, o < r.head ? -1 : 1) };
  });
  return s.changes.empty ? !1 : (n.dispatch(i.update(s, {
    scrollIntoView: !0,
    userEvent: e,
    effects: e == "delete.selection" ? T.announce.of(i.phrase("Selection deleted")) : void 0
  })), !0);
}
function Yi(n, t, e) {
  if (n instanceof T)
    for (let i of n.state.facet(T.atomicRanges).map((s) => s(n)))
      i.between(t, t, (s, r) => {
        s < t && r > t && (t = e ? r : s);
      });
  return t;
}
const ia = (n, t) => Bi(n, (e) => {
  let i = e.from, { state: s } = n, r = s.doc.lineAt(i), o, l;
  if (!t && i > r.from && i < r.from + 200 && !/[^ \t]/.test(o = r.text.slice(0, i - r.from))) {
    if (o[o.length - 1] == "	")
      return i - 1;
    let h = Oi(o, s.tabSize), a = h % vs(s) || vs(s);
    for (let c = 0; c < a && o[o.length - 1 - c] == " "; c++)
      i--;
    l = i;
  } else
    l = wt(r.text, i - r.from, t, t) + r.from, l == i && r.number != (t ? s.doc.lines : 1) && (l += t ? 1 : -1);
  return l;
}), jn = (n) => ia(n, !1), sa = (n) => ia(n, !0), na = (n, t) => Bi(n, (e) => {
  let i = e.head, { state: s } = n, r = s.doc.lineAt(i), o = s.charCategorizer(i);
  for (let l = null; ; ) {
    if (i == (t ? r.to : r.from)) {
      i == e.head && r.number != (t ? s.doc.lines : 1) && (i += t ? 1 : -1);
      break;
    }
    let h = wt(r.text, i - r.from, t) + r.from, a = r.text.slice(Math.min(i, h) - r.from, Math.max(i, h) - r.from), c = o(a);
    if (l != null && c != l)
      break;
    (a != " " || i != e.head) && (l = c), i = h;
  }
  return i;
}), ra = (n) => na(n, !1), sg = (n) => na(n, !0), ng = (n) => Bi(n, (t) => {
  let e = n.lineBlockAt(t.head).to;
  return t.head < e ? e : Math.min(n.state.doc.length, t.head + 1);
}), rg = (n) => Bi(n, (t) => {
  let e = n.moveToLineBoundary(t, !1).head;
  return t.head > e ? e : Math.max(0, t.head - 1);
}), og = (n) => Bi(n, (t) => {
  let e = n.moveToLineBoundary(t, !0).head;
  return t.head < e ? e : Math.min(n.state.doc.length, t.head + 1);
}), lg = ({ state: n, dispatch: t }) => {
  if (n.readOnly)
    return !1;
  let e = n.changeByRange((i) => ({
    changes: { from: i.from, to: i.to, insert: V.of(["", ""]) },
    range: b.cursor(i.from)
  }));
  return t(n.update(e, { scrollIntoView: !0, userEvent: "input" })), !0;
}, hg = ({ state: n, dispatch: t }) => {
  if (n.readOnly)
    return !1;
  let e = n.changeByRange((i) => {
    if (!i.empty || i.from == 0 || i.from == n.doc.length)
      return { range: i };
    let s = i.from, r = n.doc.lineAt(s), o = s == r.from ? s - 1 : wt(r.text, s - r.from, !1) + r.from, l = s == r.to ? s + 1 : wt(r.text, s - r.from, !0) + r.from;
    return {
      changes: { from: o, to: l, insert: n.doc.slice(s, l).append(n.doc.slice(o, s)) },
      range: b.cursor(l)
    };
  });
  return e.changes.empty ? !1 : (t(n.update(e, { scrollIntoView: !0, userEvent: "move.character" })), !0);
};
function Is(n) {
  let t = [], e = -1;
  for (let i of n.selection.ranges) {
    let s = n.doc.lineAt(i.from), r = n.doc.lineAt(i.to);
    if (!i.empty && i.to == r.from && (r = n.doc.lineAt(i.to - 1)), e >= s.number) {
      let o = t[t.length - 1];
      o.to = r.to, o.ranges.push(i);
    } else
      t.push({ from: s.from, to: r.to, ranges: [i] });
    e = r.number + 1;
  }
  return t;
}
function oa(n, t, e) {
  if (n.readOnly)
    return !1;
  let i = [], s = [];
  for (let r of Is(n)) {
    if (e ? r.to == n.doc.length : r.from == 0)
      continue;
    let o = n.doc.lineAt(e ? r.to + 1 : r.from - 1), l = o.length + 1;
    if (e) {
      i.push({ from: r.to, to: o.to }, { from: r.from, insert: o.text + n.lineBreak });
      for (let h of r.ranges)
        s.push(b.range(Math.min(n.doc.length, h.anchor + l), Math.min(n.doc.length, h.head + l)));
    } else {
      i.push({ from: o.from, to: r.from }, { from: r.to, insert: n.lineBreak + o.text });
      for (let h of r.ranges)
        s.push(b.range(h.anchor - l, h.head - l));
    }
  }
  return i.length ? (t(n.update({
    changes: i,
    scrollIntoView: !0,
    selection: b.create(s, n.selection.mainIndex),
    userEvent: "move.line"
  })), !0) : !1;
}
const ag = ({ state: n, dispatch: t }) => oa(n, t, !1), cg = ({ state: n, dispatch: t }) => oa(n, t, !0);
function la(n, t, e) {
  if (n.readOnly)
    return !1;
  let i = [];
  for (let s of Is(n))
    e ? i.push({ from: s.from, insert: n.doc.slice(s.from, s.to) + n.lineBreak }) : i.push({ from: s.to, insert: n.lineBreak + n.doc.slice(s.from, s.to) });
  return t(n.update({ changes: i, scrollIntoView: !0, userEvent: "input.copyline" })), !0;
}
const fg = ({ state: n, dispatch: t }) => la(n, t, !1), ug = ({ state: n, dispatch: t }) => la(n, t, !0), dg = (n) => {
  if (n.state.readOnly)
    return !1;
  let { state: t } = n, e = t.changes(Is(t).map(({ from: s, to: r }) => (s > 0 ? s-- : r < t.doc.length && r++, { from: s, to: r }))), i = ei(t.selection, (s) => n.moveVertically(s, !0)).map(e);
  return n.dispatch({ changes: e, selection: i, scrollIntoView: !0, userEvent: "delete.line" }), !0;
};
function pg(n, t) {
  if (/\(\)|\[\]|\{\}/.test(n.sliceDoc(t - 1, t + 1)))
    return { from: t, to: t };
  let e = At(n).resolveInner(t), i = e.childBefore(t), s = e.childAfter(t), r;
  return i && s && i.to <= t && s.from >= t && (r = i.type.prop(R.closedBy)) && r.indexOf(s.name) > -1 && n.doc.lineAt(i.to).from == n.doc.lineAt(s.from).from && !/\S/.test(n.sliceDoc(i.to, s.from)) ? { from: i.to, to: s.from } : null;
}
const gg = /* @__PURE__ */ ha(!1), mg = /* @__PURE__ */ ha(!0);
function ha(n) {
  return ({ state: t, dispatch: e }) => {
    if (t.readOnly)
      return !1;
    let i = t.changeByRange((s) => {
      let { from: r, to: o } = s, l = t.doc.lineAt(r), h = !n && r == o && pg(t, r);
      n && (r = o = (o <= l.to ? l : t.doc.lineAt(o)).to);
      let a = new Rs(t, { simulateBreak: r, simulateDoubleBreak: !!h }), c = cr(a, r);
      for (c == null && (c = Oi(/^\s*/.exec(t.doc.lineAt(r).text)[0], t.tabSize)); o < l.to && /\s/.test(l.text[o - l.from]); )
        o++;
      h ? { from: r, to: o } = h : r > l.from && r < l.from + 100 && !/\S/.test(l.text.slice(0, r)) && (r = l.from);
      let f = ["", Ci(t, c)];
      return h && f.push(Ci(t, a.lineIndent(l.from, -1))), {
        changes: { from: r, to: o, insert: V.of(f) },
        range: b.cursor(r + 1 + f[1].length)
      };
    });
    return e(t.update(i, { scrollIntoView: !0, userEvent: "input" })), !0;
  };
}
function gr(n, t) {
  let e = -1;
  return n.changeByRange((i) => {
    let s = [];
    for (let o = i.from; o <= i.to; ) {
      let l = n.doc.lineAt(o);
      l.number > e && (i.empty || i.to > l.from) && (t(l, s, i), e = l.number), o = l.to + 1;
    }
    let r = n.changes(s);
    return {
      changes: s,
      range: b.range(r.mapPos(i.anchor, 1), r.mapPos(i.head, 1))
    };
  });
}
const wg = ({ state: n, dispatch: t }) => {
  if (n.readOnly)
    return !1;
  let e = /* @__PURE__ */ Object.create(null), i = new Rs(n, { overrideIndentation: (r) => {
    let o = e[r];
    return o ?? -1;
  } }), s = gr(n, (r, o, l) => {
    let h = cr(i, r.from);
    if (h == null)
      return;
    /\S/.test(r.text) || (h = 0);
    let a = /^\s*/.exec(r.text)[0], c = Ci(n, h);
    (a != c || l.from < r.from + a.length) && (e[r.from] = h, o.push({ from: r.from, to: r.from + a.length, insert: c }));
  });
  return s.changes.empty || t(n.update(s, { userEvent: "indent" })), !0;
}, yg = ({ state: n, dispatch: t }) => n.readOnly ? !1 : (t(n.update(gr(n, (e, i) => {
  i.push({ from: e.from, insert: n.facet(ar) });
}), { userEvent: "input.indent" })), !0), bg = ({ state: n, dispatch: t }) => n.readOnly ? !1 : (t(n.update(gr(n, (e, i) => {
  let s = /^\s*/.exec(e.text)[0];
  if (!s)
    return;
  let r = Oi(s, n.tabSize), o = 0, l = Ci(n, Math.max(0, r - vs(n)));
  for (; o < s.length && o < l.length && s.charCodeAt(o) == l.charCodeAt(o); )
    o++;
  i.push({ from: e.from + o, to: e.from + s.length, insert: l.slice(o) });
}), { userEvent: "delete.dedent" })), !0), kg = [
  { key: "Ctrl-b", run: Fh, shift: Yh, preventDefault: !0 },
  { key: "Ctrl-f", run: _h, shift: Qh },
  { key: "Ctrl-p", run: jh, shift: Zh },
  { key: "Ctrl-n", run: Kh, shift: ta },
  { key: "Ctrl-a", run: $p, shift: Jp },
  { key: "Ctrl-e", run: Fp, shift: Xp },
  { key: "Ctrl-d", run: sa },
  { key: "Ctrl-h", run: jn },
  { key: "Ctrl-k", run: ng },
  { key: "Ctrl-Alt-h", run: ra },
  { key: "Ctrl-o", run: lg },
  { key: "Ctrl-t", run: hg },
  { key: "Ctrl-v", run: Wn }
], xg = /* @__PURE__ */ [
  { key: "ArrowLeft", run: Fh, shift: Yh, preventDefault: !0 },
  { key: "Mod-ArrowLeft", mac: "Alt-ArrowLeft", run: Pp, shift: Wp, preventDefault: !0 },
  { mac: "Cmd-ArrowLeft", run: Vp, shift: Yp, preventDefault: !0 },
  { key: "ArrowRight", run: _h, shift: Qh, preventDefault: !0 },
  { key: "Mod-ArrowRight", mac: "Alt-ArrowRight", run: Bp, shift: jp, preventDefault: !0 },
  { mac: "Cmd-ArrowRight", run: Hp, shift: Qp, preventDefault: !0 },
  { key: "ArrowUp", run: jh, shift: Zh, preventDefault: !0 },
  { mac: "Cmd-ArrowUp", run: No, shift: Vo },
  { mac: "Ctrl-ArrowUp", run: Ro, shift: Lo },
  { key: "ArrowDown", run: Kh, shift: ta, preventDefault: !0 },
  { mac: "Cmd-ArrowDown", run: Io, shift: Ho },
  { mac: "Ctrl-ArrowDown", run: Wn, shift: Eo },
  { key: "PageUp", run: Ro, shift: Lo },
  { key: "PageDown", run: Wn, shift: Eo },
  { key: "Home", run: Ip, shift: Up, preventDefault: !0 },
  { key: "Mod-Home", run: No, shift: Vo },
  { key: "End", run: Np, shift: Gp, preventDefault: !0 },
  { key: "Mod-End", run: Io, shift: Ho },
  { key: "Enter", run: gg },
  { key: "Mod-a", run: Zp },
  { key: "Backspace", run: jn, shift: jn },
  { key: "Delete", run: sa },
  { key: "Mod-Backspace", mac: "Alt-Backspace", run: ra },
  { key: "Mod-Delete", mac: "Alt-Delete", run: sg },
  { mac: "Mod-Backspace", run: rg },
  { mac: "Mod-Delete", run: og }
].concat(/* @__PURE__ */ kg.map((n) => ({ mac: n.key, run: n.run, shift: n.shift }))), vg = /* @__PURE__ */ [
  { key: "Alt-ArrowLeft", mac: "Ctrl-ArrowLeft", run: Lp, shift: Kp },
  { key: "Alt-ArrowRight", mac: "Ctrl-ArrowRight", run: Ep, shift: qp },
  { key: "Alt-ArrowUp", run: ag },
  { key: "Shift-Alt-ArrowUp", run: fg },
  { key: "Alt-ArrowDown", run: cg },
  { key: "Shift-Alt-ArrowDown", run: ug },
  { key: "Escape", run: ig },
  { key: "Mod-Enter", run: mg },
  { key: "Alt-l", mac: "Ctrl-l", run: tg },
  { key: "Mod-i", run: eg, preventDefault: !0 },
  { key: "Mod-[", run: bg },
  { key: "Mod-]", run: yg },
  { key: "Mod-Alt-\\", run: wg },
  { key: "Shift-Mod-k", run: dg },
  { key: "Shift-Mod-\\", run: zp },
  { key: "Mod-/", run: Sp },
  { key: "Alt-A", run: Ap }
].concat(xg);
class As {
  /**
  @internal
  */
  constructor(t, e, i, s, r, o, l, h, a, c = 0, f) {
    this.p = t, this.stack = e, this.state = i, this.reducePos = s, this.pos = r, this.score = o, this.buffer = l, this.bufferBase = h, this.curContext = a, this.lookAhead = c, this.parent = f;
  }
  /**
  @internal
  */
  toString() {
    return `[${this.stack.filter((t, e) => e % 3 == 0).concat(this.state)}]@${this.pos}${this.score ? "!" + this.score : ""}`;
  }
  // Start an empty stack
  /**
  @internal
  */
  static start(t, e, i = 0) {
    let s = t.parser.context;
    return new As(t, [], e, i, i, 0, [], 0, s ? new $o(s, s.start) : null, 0, null);
  }
  /**
  The stack's current [context](#lr.ContextTracker) value, if
  any. Its type will depend on the context tracker's type
  parameter, or it will be `null` if there is no context
  tracker.
  */
  get context() {
    return this.curContext ? this.curContext.context : null;
  }
  // Push a state onto the stack, tracking its start position as well
  // as the buffer base at that point.
  /**
  @internal
  */
  pushState(t, e) {
    this.stack.push(this.state, e, this.bufferBase + this.buffer.length), this.state = t;
  }
  // Apply a reduce action
  /**
  @internal
  */
  reduce(t) {
    var e;
    let i = t >> 19, s = t & 65535, { parser: r } = this.p, o = r.dynamicPrecedence(s);
    if (o && (this.score += o), i == 0) {
      this.pushState(r.getGoto(this.state, s, !0), this.reducePos), s < r.minRepeatTerm && this.storeNode(s, this.reducePos, this.reducePos, 4, !0), this.reduceContext(s, this.reducePos);
      return;
    }
    let l = this.stack.length - (i - 1) * 3 - (t & 262144 ? 6 : 0), h = l ? this.stack[l - 2] : this.p.ranges[0].from, a = this.reducePos - h;
    a >= 2e3 && !(!((e = this.p.parser.nodeSet.types[s]) === null || e === void 0) && e.isAnonymous) && (h == this.p.lastBigReductionStart ? (this.p.bigReductionCount++, this.p.lastBigReductionSize = a) : this.p.lastBigReductionSize < a && (this.p.bigReductionCount = 1, this.p.lastBigReductionStart = h, this.p.lastBigReductionSize = a));
    let c = l ? this.stack[l - 1] : 0, f = this.bufferBase + this.buffer.length - c;
    if (s < r.minRepeatTerm || t & 131072) {
      let u = r.stateFlag(
        this.state,
        1
        /* StateFlag.Skipped */
      ) ? this.pos : this.reducePos;
      this.storeNode(s, h, u, f + 4, !0);
    }
    if (t & 262144)
      this.state = this.stack[l];
    else {
      let u = this.stack[l - 3];
      this.state = r.getGoto(u, s, !0);
    }
    for (; this.stack.length > l; )
      this.stack.pop();
    this.reduceContext(s, h);
  }
  // Shift a value into the buffer
  /**
  @internal
  */
  storeNode(t, e, i, s = 4, r = !1) {
    if (t == 0 && (!this.stack.length || this.stack[this.stack.length - 1] < this.buffer.length + this.bufferBase)) {
      let o = this, l = this.buffer.length;
      if (l == 0 && o.parent && (l = o.bufferBase - o.parent.bufferBase, o = o.parent), l > 0 && o.buffer[l - 4] == 0 && o.buffer[l - 1] > -1) {
        if (e == i)
          return;
        if (o.buffer[l - 2] >= e) {
          o.buffer[l - 2] = i;
          return;
        }
      }
    }
    if (!r || this.pos == i)
      this.buffer.push(t, e, i, s);
    else {
      let o = this.buffer.length;
      if (o > 0 && this.buffer[o - 4] != 0)
        for (; o > 0 && this.buffer[o - 2] > i; )
          this.buffer[o] = this.buffer[o - 4], this.buffer[o + 1] = this.buffer[o - 3], this.buffer[o + 2] = this.buffer[o - 2], this.buffer[o + 3] = this.buffer[o - 1], o -= 4, s > 4 && (s -= 4);
      this.buffer[o] = t, this.buffer[o + 1] = e, this.buffer[o + 2] = i, this.buffer[o + 3] = s;
    }
  }
  // Apply a shift action
  /**
  @internal
  */
  shift(t, e, i, s) {
    if (t & 131072)
      this.pushState(t & 65535, this.pos);
    else if (t & 262144)
      this.pos = s, this.shiftContext(e, i), e <= this.p.parser.maxNode && this.buffer.push(e, i, s, 4);
    else {
      let r = t, { parser: o } = this.p;
      (s > this.pos || e <= o.maxNode) && (this.pos = s, o.stateFlag(
        r,
        1
        /* StateFlag.Skipped */
      ) || (this.reducePos = s)), this.pushState(r, i), this.shiftContext(e, i), e <= o.maxNode && this.buffer.push(e, i, s, 4);
    }
  }
  // Apply an action
  /**
  @internal
  */
  apply(t, e, i, s) {
    t & 65536 ? this.reduce(t) : this.shift(t, e, i, s);
  }
  // Add a prebuilt (reused) node into the buffer.
  /**
  @internal
  */
  useNode(t, e) {
    let i = this.p.reused.length - 1;
    (i < 0 || this.p.reused[i] != t) && (this.p.reused.push(t), i++);
    let s = this.pos;
    this.reducePos = this.pos = s + t.length, this.pushState(e, s), this.buffer.push(
      i,
      s,
      this.reducePos,
      -1
      /* size == -1 means this is a reused value */
    ), this.curContext && this.updateContext(this.curContext.tracker.reuse(this.curContext.context, t, this, this.p.stream.reset(this.pos - t.length)));
  }
  // Split the stack. Due to the buffer sharing and the fact
  // that `this.stack` tends to stay quite shallow, this isn't very
  // expensive.
  /**
  @internal
  */
  split() {
    let t = this, e = t.buffer.length;
    for (; e > 0 && t.buffer[e - 2] > t.reducePos; )
      e -= 4;
    let i = t.buffer.slice(e), s = t.bufferBase + e;
    for (; t && s == t.bufferBase; )
      t = t.parent;
    return new As(this.p, this.stack.slice(), this.state, this.reducePos, this.pos, this.score, i, s, this.curContext, this.lookAhead, t);
  }
  // Try to recover from an error by 'deleting' (ignoring) one token.
  /**
  @internal
  */
  recoverByDelete(t, e) {
    let i = t <= this.p.parser.maxNode;
    i && this.storeNode(t, this.pos, e, 4), this.storeNode(0, this.pos, e, i ? 8 : 4), this.pos = this.reducePos = e, this.score -= 190;
  }
  /**
  Check if the given term would be able to be shifted (optionally
  after some reductions) on this stack. This can be useful for
  external tokenizers that want to make sure they only provide a
  given token when it applies.
  */
  canShift(t) {
    for (let e = new Sg(this); ; ) {
      let i = this.p.parser.stateSlot(
        e.state,
        4
        /* ParseState.DefaultReduce */
      ) || this.p.parser.hasAction(e.state, t);
      if (i == 0)
        return !1;
      if (!(i & 65536))
        return !0;
      e.reduce(i);
    }
  }
  // Apply up to Recover.MaxNext recovery actions that conceptually
  // inserts some missing token or rule.
  /**
  @internal
  */
  recoverByInsert(t) {
    if (this.stack.length >= 300)
      return [];
    let e = this.p.parser.nextStates(this.state);
    if (e.length > 8 || this.stack.length >= 120) {
      let s = [];
      for (let r = 0, o; r < e.length; r += 2)
        (o = e[r + 1]) != this.state && this.p.parser.hasAction(o, t) && s.push(e[r], o);
      if (this.stack.length < 120)
        for (let r = 0; s.length < 8 && r < e.length; r += 2) {
          let o = e[r + 1];
          s.some((l, h) => h & 1 && l == o) || s.push(e[r], o);
        }
      e = s;
    }
    let i = [];
    for (let s = 0; s < e.length && i.length < 4; s += 2) {
      let r = e[s + 1];
      if (r == this.state)
        continue;
      let o = this.split();
      o.pushState(r, this.pos), o.storeNode(0, o.pos, o.pos, 4, !0), o.shiftContext(e[s], this.pos), o.reducePos = this.pos, o.score -= 200, i.push(o);
    }
    return i;
  }
  // Force a reduce, if possible. Return false if that can't
  // be done.
  /**
  @internal
  */
  forceReduce() {
    let { parser: t } = this.p, e = t.stateSlot(
      this.state,
      5
      /* ParseState.ForcedReduce */
    );
    if (!(e & 65536))
      return !1;
    if (!t.validAction(this.state, e)) {
      let i = e >> 19, s = e & 65535, r = this.stack.length - i * 3;
      if (r < 0 || t.getGoto(this.stack[r], s, !1) < 0) {
        let o = this.findForcedReduction();
        if (o == null)
          return !1;
        e = o;
      }
      this.storeNode(0, this.pos, this.pos, 4, !0), this.score -= 100;
    }
    return this.reducePos = this.pos, this.reduce(e), !0;
  }
  /**
  Try to scan through the automaton to find some kind of reduction
  that can be applied. Used when the regular ForcedReduce field
  isn't a valid action. @internal
  */
  findForcedReduction() {
    let { parser: t } = this.p, e = [], i = (s, r) => {
      if (!e.includes(s))
        return e.push(s), t.allActions(s, (o) => {
          if (!(o & 393216))
            if (o & 65536) {
              let l = (o >> 19) - r;
              if (l > 1) {
                let h = o & 65535, a = this.stack.length - l * 3;
                if (a >= 0 && t.getGoto(this.stack[a], h, !1) >= 0)
                  return l << 19 | 65536 | h;
              }
            } else {
              let l = i(o, r + 1);
              if (l != null)
                return l;
            }
        });
    };
    return i(this.state, 0);
  }
  /**
  @internal
  */
  forceAll() {
    for (; !this.p.parser.stateFlag(
      this.state,
      2
      /* StateFlag.Accepting */
    ); )
      if (!this.forceReduce()) {
        this.storeNode(0, this.pos, this.pos, 4, !0);
        break;
      }
    return this;
  }
  /**
  Check whether this state has no further actions (assumed to be a direct descendant of the
  top state, since any other states must be able to continue
  somehow). @internal
  */
  get deadEnd() {
    if (this.stack.length != 3)
      return !1;
    let { parser: t } = this.p;
    return t.data[t.stateSlot(
      this.state,
      1
      /* ParseState.Actions */
    )] == 65535 && !t.stateSlot(
      this.state,
      4
      /* ParseState.DefaultReduce */
    );
  }
  /**
  Restart the stack (put it back in its start state). Only safe
  when this.stack.length == 3 (state is directly below the top
  state). @internal
  */
  restart() {
    this.storeNode(0, this.pos, this.pos, 4, !0), this.state = this.stack[0], this.stack.length = 0;
  }
  /**
  @internal
  */
  sameState(t) {
    if (this.state != t.state || this.stack.length != t.stack.length)
      return !1;
    for (let e = 0; e < this.stack.length; e += 3)
      if (this.stack[e] != t.stack[e])
        return !1;
    return !0;
  }
  /**
  Get the parser used by this stack.
  */
  get parser() {
    return this.p.parser;
  }
  /**
  Test whether a given dialect (by numeric ID, as exported from
  the terms file) is enabled.
  */
  dialectEnabled(t) {
    return this.p.parser.dialect.flags[t];
  }
  shiftContext(t, e) {
    this.curContext && this.updateContext(this.curContext.tracker.shift(this.curContext.context, t, this, this.p.stream.reset(e)));
  }
  reduceContext(t, e) {
    this.curContext && this.updateContext(this.curContext.tracker.reduce(this.curContext.context, t, this, this.p.stream.reset(e)));
  }
  /**
  @internal
  */
  emitContext() {
    let t = this.buffer.length - 1;
    (t < 0 || this.buffer[t] != -3) && this.buffer.push(this.curContext.hash, this.pos, this.pos, -3);
  }
  /**
  @internal
  */
  emitLookAhead() {
    let t = this.buffer.length - 1;
    (t < 0 || this.buffer[t] != -4) && this.buffer.push(this.lookAhead, this.pos, this.pos, -4);
  }
  updateContext(t) {
    if (t != this.curContext.context) {
      let e = new $o(this.curContext.tracker, t);
      e.hash != this.curContext.hash && this.emitContext(), this.curContext = e;
    }
  }
  /**
  @internal
  */
  setLookAhead(t) {
    t > this.lookAhead && (this.emitLookAhead(), this.lookAhead = t);
  }
  /**
  @internal
  */
  close() {
    this.curContext && this.curContext.tracker.strict && this.emitContext(), this.lookAhead > 0 && this.emitLookAhead();
  }
}
class $o {
  constructor(t, e) {
    this.tracker = t, this.context = e, this.hash = t.strict ? t.hash(e) : 0;
  }
}
class Sg {
  constructor(t) {
    this.start = t, this.state = t.state, this.stack = t.stack, this.base = this.stack.length;
  }
  reduce(t) {
    let e = t & 65535, i = t >> 19;
    i == 0 ? (this.stack == this.start.stack && (this.stack = this.stack.slice()), this.stack.push(this.state, 0, 0), this.base += 3) : this.base -= (i - 1) * 3;
    let s = this.start.p.parser.getGoto(this.stack[this.base - 3], e, !0);
    this.state = s;
  }
}
class Os {
  constructor(t, e, i) {
    this.stack = t, this.pos = e, this.index = i, this.buffer = t.buffer, this.index == 0 && this.maybeNext();
  }
  static create(t, e = t.bufferBase + t.buffer.length) {
    return new Os(t, e, e - t.bufferBase);
  }
  maybeNext() {
    let t = this.stack.parent;
    t != null && (this.index = this.stack.bufferBase - t.bufferBase, this.stack = t, this.buffer = t.buffer);
  }
  get id() {
    return this.buffer[this.index - 4];
  }
  get start() {
    return this.buffer[this.index - 3];
  }
  get end() {
    return this.buffer[this.index - 2];
  }
  get size() {
    return this.buffer[this.index - 1];
  }
  next() {
    this.index -= 4, this.pos -= 4, this.index == 0 && this.maybeNext();
  }
  fork() {
    return new Os(this.stack, this.pos, this.index);
  }
}
function Qi(n, t = Uint16Array) {
  if (typeof n != "string")
    return n;
  let e = null;
  for (let i = 0, s = 0; i < n.length; ) {
    let r = 0;
    for (; ; ) {
      let o = n.charCodeAt(i++), l = !1;
      if (o == 126) {
        r = 65535;
        break;
      }
      o >= 92 && o--, o >= 34 && o--;
      let h = o - 32;
      if (h >= 46 && (h -= 46, l = !0), r += h, l)
        break;
      r *= 46;
    }
    e ? e[s++] = r : e = new t(r);
  }
  return e;
}
class ls {
  constructor() {
    this.start = -1, this.value = -1, this.end = -1, this.extended = -1, this.lookAhead = 0, this.mask = 0, this.context = 0;
  }
}
const Fo = new ls();
class Cg {
  /**
  @internal
  */
  constructor(t, e) {
    this.input = t, this.ranges = e, this.chunk = "", this.chunkOff = 0, this.chunk2 = "", this.chunk2Pos = 0, this.next = -1, this.token = Fo, this.rangeIndex = 0, this.pos = this.chunkPos = e[0].from, this.range = e[0], this.end = e[e.length - 1].to, this.readNext();
  }
  /**
  @internal
  */
  resolveOffset(t, e) {
    let i = this.range, s = this.rangeIndex, r = this.pos + t;
    for (; r < i.from; ) {
      if (!s)
        return null;
      let o = this.ranges[--s];
      r -= i.from - o.to, i = o;
    }
    for (; e < 0 ? r > i.to : r >= i.to; ) {
      if (s == this.ranges.length - 1)
        return null;
      let o = this.ranges[++s];
      r += o.from - i.to, i = o;
    }
    return r;
  }
  /**
  @internal
  */
  clipPos(t) {
    if (t >= this.range.from && t < this.range.to)
      return t;
    for (let e of this.ranges)
      if (e.to > t)
        return Math.max(t, e.from);
    return this.end;
  }
  /**
  Look at a code unit near the stream position. `.peek(0)` equals
  `.next`, `.peek(-1)` gives you the previous character, and so
  on.
  
  Note that looking around during tokenizing creates dependencies
  on potentially far-away content, which may reduce the
  effectiveness incremental parsing—when looking forward—or even
  cause invalid reparses when looking backward more than 25 code
  units, since the library does not track lookbehind.
  */
  peek(t) {
    let e = this.chunkOff + t, i, s;
    if (e >= 0 && e < this.chunk.length)
      i = this.pos + t, s = this.chunk.charCodeAt(e);
    else {
      let r = this.resolveOffset(t, 1);
      if (r == null)
        return -1;
      if (i = r, i >= this.chunk2Pos && i < this.chunk2Pos + this.chunk2.length)
        s = this.chunk2.charCodeAt(i - this.chunk2Pos);
      else {
        let o = this.rangeIndex, l = this.range;
        for (; l.to <= i; )
          l = this.ranges[++o];
        this.chunk2 = this.input.chunk(this.chunk2Pos = i), i + this.chunk2.length > l.to && (this.chunk2 = this.chunk2.slice(0, l.to - i)), s = this.chunk2.charCodeAt(0);
      }
    }
    return i >= this.token.lookAhead && (this.token.lookAhead = i + 1), s;
  }
  /**
  Accept a token. By default, the end of the token is set to the
  current stream position, but you can pass an offset (relative to
  the stream position) to change that.
  */
  acceptToken(t, e = 0) {
    let i = e ? this.resolveOffset(e, -1) : this.pos;
    if (i == null || i < this.token.start)
      throw new RangeError("Token end out of bounds");
    this.token.value = t, this.token.end = i;
  }
  getChunk() {
    if (this.pos >= this.chunk2Pos && this.pos < this.chunk2Pos + this.chunk2.length) {
      let { chunk: t, chunkPos: e } = this;
      this.chunk = this.chunk2, this.chunkPos = this.chunk2Pos, this.chunk2 = t, this.chunk2Pos = e, this.chunkOff = this.pos - this.chunkPos;
    } else {
      this.chunk2 = this.chunk, this.chunk2Pos = this.chunkPos;
      let t = this.input.chunk(this.pos), e = this.pos + t.length;
      this.chunk = e > this.range.to ? t.slice(0, this.range.to - this.pos) : t, this.chunkPos = this.pos, this.chunkOff = 0;
    }
  }
  readNext() {
    return this.chunkOff >= this.chunk.length && (this.getChunk(), this.chunkOff == this.chunk.length) ? this.next = -1 : this.next = this.chunk.charCodeAt(this.chunkOff);
  }
  /**
  Move the stream forward N (defaults to 1) code units. Returns
  the new value of [`next`](#lr.InputStream.next).
  */
  advance(t = 1) {
    for (this.chunkOff += t; this.pos + t >= this.range.to; ) {
      if (this.rangeIndex == this.ranges.length - 1)
        return this.setDone();
      t -= this.range.to - this.pos, this.range = this.ranges[++this.rangeIndex], this.pos = this.range.from;
    }
    return this.pos += t, this.pos >= this.token.lookAhead && (this.token.lookAhead = this.pos + 1), this.readNext();
  }
  setDone() {
    return this.pos = this.chunkPos = this.end, this.range = this.ranges[this.rangeIndex = this.ranges.length - 1], this.chunk = "", this.next = -1;
  }
  /**
  @internal
  */
  reset(t, e) {
    if (e ? (this.token = e, e.start = t, e.lookAhead = t + 1, e.value = e.extended = -1) : this.token = Fo, this.pos != t) {
      if (this.pos = t, t == this.end)
        return this.setDone(), this;
      for (; t < this.range.from; )
        this.range = this.ranges[--this.rangeIndex];
      for (; t >= this.range.to; )
        this.range = this.ranges[++this.rangeIndex];
      t >= this.chunkPos && t < this.chunkPos + this.chunk.length ? this.chunkOff = t - this.chunkPos : (this.chunk = "", this.chunkOff = 0), this.readNext();
    }
    return this;
  }
  /**
  @internal
  */
  read(t, e) {
    if (t >= this.chunkPos && e <= this.chunkPos + this.chunk.length)
      return this.chunk.slice(t - this.chunkPos, e - this.chunkPos);
    if (t >= this.chunk2Pos && e <= this.chunk2Pos + this.chunk2.length)
      return this.chunk2.slice(t - this.chunk2Pos, e - this.chunk2Pos);
    if (t >= this.range.from && e <= this.range.to)
      return this.input.read(t, e);
    let i = "";
    for (let s of this.ranges) {
      if (s.from >= e)
        break;
      s.to > t && (i += this.input.read(Math.max(s.from, t), Math.min(s.to, e)));
    }
    return i;
  }
}
class Ge {
  constructor(t, e) {
    this.data = t, this.id = e;
  }
  token(t, e) {
    let { parser: i } = e.p;
    Ag(this.data, t, e, this.id, i.data, i.tokenPrecTable);
  }
}
Ge.prototype.contextual = Ge.prototype.fallback = Ge.prototype.extend = !1;
Ge.prototype.fallback = Ge.prototype.extend = !1;
function Ag(n, t, e, i, s, r) {
  let o = 0, l = 1 << i, { dialect: h } = e.p.parser;
  t:
    for (; l & n[o]; ) {
      let a = n[o + 1];
      for (let d = o + 3; d < a; d += 2)
        if ((n[d + 1] & l) > 0) {
          let p = n[d];
          if (h.allows(p) && (t.token.value == -1 || t.token.value == p || Og(p, t.token.value, s, r))) {
            t.acceptToken(p);
            break;
          }
        }
      let c = t.next, f = 0, u = n[o + 2];
      if (t.next < 0 && u > f && n[a + u * 3 - 3] == 65535) {
        o = n[a + u * 3 - 1];
        continue t;
      }
      for (; f < u; ) {
        let d = f + u >> 1, p = a + d + (d << 1), m = n[p], g = n[p + 1] || 65536;
        if (c < m)
          u = d;
        else if (c >= g)
          f = d + 1;
        else {
          o = n[p + 2], t.advance();
          continue t;
        }
      }
      break;
    }
}
function _o(n, t, e) {
  for (let i = t, s; (s = n[i]) != 65535; i++)
    if (s == e)
      return i - t;
  return -1;
}
function Og(n, t, e, i) {
  let s = _o(e, i, t);
  return s < 0 || _o(e, i, n) < s;
}
const kt = typeof process < "u" && process.env && /\bparse\b/.test(process.env.LOG);
let en = null;
function zo(n, t, e) {
  let i = n.cursor(st.IncludeAnonymous);
  for (i.moveTo(t); ; )
    if (!(e < 0 ? i.childBefore(t) : i.childAfter(t)))
      for (; ; ) {
        if ((e < 0 ? i.to < t : i.from > t) && !i.type.isError)
          return e < 0 ? Math.max(0, Math.min(
            i.to - 1,
            t - 25
            /* Safety.Margin */
          )) : Math.min(n.length, Math.max(
            i.from + 1,
            t + 25
            /* Safety.Margin */
          ));
        if (e < 0 ? i.prevSibling() : i.nextSibling())
          break;
        if (!i.parent())
          return e < 0 ? 0 : n.length;
      }
}
class Mg {
  constructor(t, e) {
    this.fragments = t, this.nodeSet = e, this.i = 0, this.fragment = null, this.safeFrom = -1, this.safeTo = -1, this.trees = [], this.start = [], this.index = [], this.nextFragment();
  }
  nextFragment() {
    let t = this.fragment = this.i == this.fragments.length ? null : this.fragments[this.i++];
    if (t) {
      for (this.safeFrom = t.openStart ? zo(t.tree, t.from + t.offset, 1) - t.offset : t.from, this.safeTo = t.openEnd ? zo(t.tree, t.to + t.offset, -1) - t.offset : t.to; this.trees.length; )
        this.trees.pop(), this.start.pop(), this.index.pop();
      this.trees.push(t.tree), this.start.push(-t.offset), this.index.push(0), this.nextStart = this.safeFrom;
    } else
      this.nextStart = 1e9;
  }
  // `pos` must be >= any previously given `pos` for this cursor
  nodeAt(t) {
    if (t < this.nextStart)
      return null;
    for (; this.fragment && this.safeTo <= t; )
      this.nextFragment();
    if (!this.fragment)
      return null;
    for (; ; ) {
      let e = this.trees.length - 1;
      if (e < 0)
        return this.nextFragment(), null;
      let i = this.trees[e], s = this.index[e];
      if (s == i.children.length) {
        this.trees.pop(), this.start.pop(), this.index.pop();
        continue;
      }
      let r = i.children[s], o = this.start[e] + i.positions[s];
      if (o > t)
        return this.nextStart = o, null;
      if (r instanceof X) {
        if (o == t) {
          if (o < this.safeFrom)
            return null;
          let l = o + r.length;
          if (l <= this.safeTo) {
            let h = r.prop(R.lookAhead);
            if (!h || l + h < this.fragment.to)
              return r;
          }
        }
        this.index[e]++, o + r.length >= Math.max(this.safeFrom, t) && (this.trees.push(r), this.start.push(o), this.index.push(0));
      } else
        this.index[e]++, this.nextStart = o + r.length;
    }
  }
}
class Tg {
  constructor(t, e) {
    this.stream = e, this.tokens = [], this.mainToken = null, this.actions = [], this.tokens = t.tokenizers.map((i) => new ls());
  }
  getActions(t) {
    let e = 0, i = null, { parser: s } = t.p, { tokenizers: r } = s, o = s.stateSlot(
      t.state,
      3
      /* ParseState.TokenizerMask */
    ), l = t.curContext ? t.curContext.hash : 0, h = 0;
    for (let a = 0; a < r.length; a++) {
      if (!(1 << a & o))
        continue;
      let c = r[a], f = this.tokens[a];
      if (!(i && !c.fallback) && ((c.contextual || f.start != t.pos || f.mask != o || f.context != l) && (this.updateCachedToken(f, c, t), f.mask = o, f.context = l), f.lookAhead > f.end + 25 && (h = Math.max(f.lookAhead, h)), f.value != 0)) {
        let u = e;
        if (f.extended > -1 && (e = this.addActions(t, f.extended, f.end, e)), e = this.addActions(t, f.value, f.end, e), !c.extend && (i = f, e > u))
          break;
      }
    }
    for (; this.actions.length > e; )
      this.actions.pop();
    return h && t.setLookAhead(h), !i && t.pos == this.stream.end && (i = new ls(), i.value = t.p.parser.eofTerm, i.start = i.end = t.pos, e = this.addActions(t, i.value, i.end, e)), this.mainToken = i, this.actions;
  }
  getMainToken(t) {
    if (this.mainToken)
      return this.mainToken;
    let e = new ls(), { pos: i, p: s } = t;
    return e.start = i, e.end = Math.min(i + 1, s.stream.end), e.value = i == s.stream.end ? s.parser.eofTerm : 0, e;
  }
  updateCachedToken(t, e, i) {
    let s = this.stream.clipPos(i.pos);
    if (e.token(this.stream.reset(s, t), i), t.value > -1) {
      let { parser: r } = i.p;
      for (let o = 0; o < r.specialized.length; o++)
        if (r.specialized[o] == t.value) {
          let l = r.specializers[o](this.stream.read(t.start, t.end), i);
          if (l >= 0 && i.p.parser.dialect.allows(l >> 1)) {
            l & 1 ? t.extended = l >> 1 : t.value = l >> 1;
            break;
          }
        }
    } else
      t.value = 0, t.end = this.stream.clipPos(s + 1);
  }
  putAction(t, e, i, s) {
    for (let r = 0; r < s; r += 3)
      if (this.actions[r] == t)
        return s;
    return this.actions[s++] = t, this.actions[s++] = e, this.actions[s++] = i, s;
  }
  addActions(t, e, i, s) {
    let { state: r } = t, { parser: o } = t.p, { data: l } = o;
    for (let h = 0; h < 2; h++)
      for (let a = o.stateSlot(
        r,
        h ? 2 : 1
        /* ParseState.Actions */
      ); ; a += 3) {
        if (l[a] == 65535)
          if (l[a + 1] == 1)
            a = Xt(l, a + 2);
          else {
            s == 0 && l[a + 1] == 2 && (s = this.putAction(Xt(l, a + 2), e, i, s));
            break;
          }
        l[a] == e && (s = this.putAction(Xt(l, a + 1), e, i, s));
      }
    return s;
  }
}
class Dg {
  constructor(t, e, i, s) {
    this.parser = t, this.input = e, this.ranges = s, this.recovering = 0, this.nextStackID = 9812, this.minStackPos = 0, this.reused = [], this.stoppedAt = null, this.lastBigReductionStart = -1, this.lastBigReductionSize = 0, this.bigReductionCount = 0, this.stream = new Cg(e, s), this.tokens = new Tg(t, this.stream), this.topTerm = t.top[1];
    let { from: r } = s[0];
    this.stacks = [As.start(this, t.top[0], r)], this.fragments = i.length && this.stream.end - r > t.bufferLength * 4 ? new Mg(i, t.nodeSet) : null;
  }
  get parsedPos() {
    return this.minStackPos;
  }
  // Move the parser forward. This will process all parse stacks at
  // `this.pos` and try to advance them to a further position. If no
  // stack for such a position is found, it'll start error-recovery.
  //
  // When the parse is finished, this will return a syntax tree. When
  // not, it returns `null`.
  advance() {
    let t = this.stacks, e = this.minStackPos, i = this.stacks = [], s, r;
    if (this.bigReductionCount > 300 && t.length == 1) {
      let [o] = t;
      for (; o.forceReduce() && o.stack.length && o.stack[o.stack.length - 2] >= this.lastBigReductionStart; )
        ;
      this.bigReductionCount = this.lastBigReductionSize = 0;
    }
    for (let o = 0; o < t.length; o++) {
      let l = t[o];
      for (; ; ) {
        if (this.tokens.mainToken = null, l.pos > e)
          i.push(l);
        else {
          if (this.advanceStack(l, i, t))
            continue;
          {
            s || (s = [], r = []), s.push(l);
            let h = this.tokens.getMainToken(l);
            r.push(h.value, h.end);
          }
        }
        break;
      }
    }
    if (!i.length) {
      let o = s && Bg(s);
      if (o)
        return kt && console.log("Finish with " + this.stackID(o)), this.stackToTree(o);
      if (this.parser.strict)
        throw kt && s && console.log("Stuck with token " + (this.tokens.mainToken ? this.parser.getName(this.tokens.mainToken.value) : "none")), new SyntaxError("No parse at " + e);
      this.recovering || (this.recovering = 5);
    }
    if (this.recovering && s) {
      let o = this.stoppedAt != null && s[0].pos > this.stoppedAt ? s[0] : this.runRecovery(s, r, i);
      if (o)
        return kt && console.log("Force-finish " + this.stackID(o)), this.stackToTree(o.forceAll());
    }
    if (this.recovering) {
      let o = this.recovering == 1 ? 1 : this.recovering * 3;
      if (i.length > o)
        for (i.sort((l, h) => h.score - l.score); i.length > o; )
          i.pop();
      i.some((l) => l.reducePos > e) && this.recovering--;
    } else if (i.length > 1) {
      t:
        for (let o = 0; o < i.length - 1; o++) {
          let l = i[o];
          for (let h = o + 1; h < i.length; h++) {
            let a = i[h];
            if (l.sameState(a) || l.buffer.length > 500 && a.buffer.length > 500)
              if ((l.score - a.score || l.buffer.length - a.buffer.length) > 0)
                i.splice(h--, 1);
              else {
                i.splice(o--, 1);
                continue t;
              }
          }
        }
      i.length > 12 && i.splice(
        12,
        i.length - 12
        /* Rec.MaxStackCount */
      );
    }
    this.minStackPos = i[0].pos;
    for (let o = 1; o < i.length; o++)
      i[o].pos < this.minStackPos && (this.minStackPos = i[o].pos);
    return null;
  }
  stopAt(t) {
    if (this.stoppedAt != null && this.stoppedAt < t)
      throw new RangeError("Can't move stoppedAt forward");
    this.stoppedAt = t;
  }
  // Returns an updated version of the given stack, or null if the
  // stack can't advance normally. When `split` and `stacks` are
  // given, stacks split off by ambiguous operations will be pushed to
  // `split`, or added to `stacks` if they move `pos` forward.
  advanceStack(t, e, i) {
    let s = t.pos, { parser: r } = this, o = kt ? this.stackID(t) + " -> " : "";
    if (this.stoppedAt != null && s > this.stoppedAt)
      return t.forceReduce() ? t : null;
    if (this.fragments) {
      let a = t.curContext && t.curContext.tracker.strict, c = a ? t.curContext.hash : 0;
      for (let f = this.fragments.nodeAt(s); f; ) {
        let u = this.parser.nodeSet.types[f.type.id] == f.type ? r.getGoto(t.state, f.type.id) : -1;
        if (u > -1 && f.length && (!a || (f.prop(R.contextHash) || 0) == c))
          return t.useNode(f, u), kt && console.log(o + this.stackID(t) + ` (via reuse of ${r.getName(f.type.id)})`), !0;
        if (!(f instanceof X) || f.children.length == 0 || f.positions[0] > 0)
          break;
        let d = f.children[0];
        if (d instanceof X && f.positions[0] == 0)
          f = d;
        else
          break;
      }
    }
    let l = r.stateSlot(
      t.state,
      4
      /* ParseState.DefaultReduce */
    );
    if (l > 0)
      return t.reduce(l), kt && console.log(o + this.stackID(t) + ` (via always-reduce ${r.getName(
        l & 65535
        /* Action.ValueMask */
      )})`), !0;
    if (t.stack.length >= 8400)
      for (; t.stack.length > 6e3 && t.forceReduce(); )
        ;
    let h = this.tokens.getActions(t);
    for (let a = 0; a < h.length; ) {
      let c = h[a++], f = h[a++], u = h[a++], d = a == h.length || !i, p = d ? t : t.split(), m = this.tokens.mainToken;
      if (p.apply(c, f, m ? m.start : p.pos, u), kt && console.log(o + this.stackID(p) + ` (via ${c & 65536 ? `reduce of ${r.getName(
        c & 65535
        /* Action.ValueMask */
      )}` : "shift"} for ${r.getName(f)} @ ${s}${p == t ? "" : ", split"})`), d)
        return !0;
      p.pos > s ? e.push(p) : i.push(p);
    }
    return !1;
  }
  // Advance a given stack forward as far as it will go. Returns the
  // (possibly updated) stack if it got stuck, or null if it moved
  // forward and was given to `pushStackDedup`.
  advanceFully(t, e) {
    let i = t.pos;
    for (; ; ) {
      if (!this.advanceStack(t, null, null))
        return !1;
      if (t.pos > i)
        return Wo(t, e), !0;
    }
  }
  runRecovery(t, e, i) {
    let s = null, r = !1;
    for (let o = 0; o < t.length; o++) {
      let l = t[o], h = e[o << 1], a = e[(o << 1) + 1], c = kt ? this.stackID(l) + " -> " : "";
      if (l.deadEnd && (r || (r = !0, l.restart(), kt && console.log(c + this.stackID(l) + " (restarted)"), this.advanceFully(l, i))))
        continue;
      let f = l.split(), u = c;
      for (let d = 0; f.forceReduce() && d < 10 && (kt && console.log(u + this.stackID(f) + " (via force-reduce)"), !this.advanceFully(f, i)); d++)
        kt && (u = this.stackID(f) + " -> ");
      for (let d of l.recoverByInsert(h))
        kt && console.log(c + this.stackID(d) + " (via recover-insert)"), this.advanceFully(d, i);
      this.stream.end > l.pos ? (a == l.pos && (a++, h = 0), l.recoverByDelete(h, a), kt && console.log(c + this.stackID(l) + ` (via recover-delete ${this.parser.getName(h)})`), Wo(l, i)) : (!s || s.score < l.score) && (s = l);
    }
    return s;
  }
  // Convert the stack's buffer to a syntax tree.
  stackToTree(t) {
    return t.close(), X.build({
      buffer: Os.create(t),
      nodeSet: this.parser.nodeSet,
      topID: this.topTerm,
      maxBufferLength: this.parser.bufferLength,
      reused: this.reused,
      start: this.ranges[0].from,
      length: t.pos - this.ranges[0].from,
      minRepeatType: this.parser.minRepeatTerm
    });
  }
  stackID(t) {
    let e = (en || (en = /* @__PURE__ */ new WeakMap())).get(t);
    return e || en.set(t, e = String.fromCodePoint(this.nextStackID++)), e + t;
  }
}
function Wo(n, t) {
  for (let e = 0; e < t.length; e++) {
    let i = t[e];
    if (i.pos == n.pos && i.sameState(n)) {
      t[e].score < n.score && (t[e] = n);
      return;
    }
  }
  t.push(n);
}
class Pg {
  constructor(t, e, i) {
    this.source = t, this.flags = e, this.disabled = i;
  }
  allows(t) {
    return !this.disabled || this.disabled[t] == 0;
  }
}
class Ms extends kh {
  /**
  @internal
  */
  constructor(t) {
    if (super(), this.wrappers = [], t.version != 14)
      throw new RangeError(`Parser version (${t.version}) doesn't match runtime version (14)`);
    let e = t.nodeNames.split(" ");
    this.minRepeatTerm = e.length;
    for (let l = 0; l < t.repeatNodeCount; l++)
      e.push("");
    let i = Object.keys(t.topRules).map((l) => t.topRules[l][1]), s = [];
    for (let l = 0; l < e.length; l++)
      s.push([]);
    function r(l, h, a) {
      s[l].push([h, h.deserialize(String(a))]);
    }
    if (t.nodeProps)
      for (let l of t.nodeProps) {
        let h = l[0];
        typeof h == "string" && (h = R[h]);
        for (let a = 1; a < l.length; ) {
          let c = l[a++];
          if (c >= 0)
            r(c, h, l[a++]);
          else {
            let f = l[a + -c];
            for (let u = -c; u > 0; u--)
              r(l[a++], h, f);
            a++;
          }
        }
      }
    this.nodeSet = new rr(e.map((l, h) => bt.define({
      name: h >= this.minRepeatTerm ? void 0 : l,
      id: h,
      props: s[h],
      top: i.indexOf(h) > -1,
      error: h == 0,
      skipped: t.skippedNodes && t.skippedNodes.indexOf(h) > -1
    }))), t.propSources && (this.nodeSet = this.nodeSet.extend(...t.propSources)), this.strict = !1, this.bufferLength = mh;
    let o = Qi(t.tokenData);
    this.context = t.context, this.specializerSpecs = t.specialized || [], this.specialized = new Uint16Array(this.specializerSpecs.length);
    for (let l = 0; l < this.specializerSpecs.length; l++)
      this.specialized[l] = this.specializerSpecs[l].term;
    this.specializers = this.specializerSpecs.map(jo), this.states = Qi(t.states, Uint32Array), this.data = Qi(t.stateData), this.goto = Qi(t.goto), this.maxTerm = t.maxTerm, this.tokenizers = t.tokenizers.map((l) => typeof l == "number" ? new Ge(o, l) : l), this.topRules = t.topRules, this.dialects = t.dialects || {}, this.dynamicPrecedences = t.dynamicPrecedences || null, this.tokenPrecTable = t.tokenPrec, this.termNames = t.termNames || null, this.maxNode = this.nodeSet.types.length - 1, this.dialect = this.parseDialect(), this.top = this.topRules[Object.keys(this.topRules)[0]];
  }
  createParse(t, e, i) {
    let s = new Dg(this, t, e, i);
    for (let r of this.wrappers)
      s = r(s, t, e, i);
    return s;
  }
  /**
  Get a goto table entry @internal
  */
  getGoto(t, e, i = !1) {
    let s = this.goto;
    if (e >= s[0])
      return -1;
    for (let r = s[e + 1]; ; ) {
      let o = s[r++], l = o & 1, h = s[r++];
      if (l && i)
        return h;
      for (let a = r + (o >> 1); r < a; r++)
        if (s[r] == t)
          return h;
      if (l)
        return -1;
    }
  }
  /**
  Check if this state has an action for a given terminal @internal
  */
  hasAction(t, e) {
    let i = this.data;
    for (let s = 0; s < 2; s++)
      for (let r = this.stateSlot(
        t,
        s ? 2 : 1
        /* ParseState.Actions */
      ), o; ; r += 3) {
        if ((o = i[r]) == 65535)
          if (i[r + 1] == 1)
            o = i[r = Xt(i, r + 2)];
          else {
            if (i[r + 1] == 2)
              return Xt(i, r + 2);
            break;
          }
        if (o == e || o == 0)
          return Xt(i, r + 1);
      }
    return 0;
  }
  /**
  @internal
  */
  stateSlot(t, e) {
    return this.states[t * 6 + e];
  }
  /**
  @internal
  */
  stateFlag(t, e) {
    return (this.stateSlot(
      t,
      0
      /* ParseState.Flags */
    ) & e) > 0;
  }
  /**
  @internal
  */
  validAction(t, e) {
    return !!this.allActions(t, (i) => i == e ? !0 : null);
  }
  /**
  @internal
  */
  allActions(t, e) {
    let i = this.stateSlot(
      t,
      4
      /* ParseState.DefaultReduce */
    ), s = i ? e(i) : void 0;
    for (let r = this.stateSlot(
      t,
      1
      /* ParseState.Actions */
    ); s == null; r += 3) {
      if (this.data[r] == 65535)
        if (this.data[r + 1] == 1)
          r = Xt(this.data, r + 2);
        else
          break;
      s = e(Xt(this.data, r + 1));
    }
    return s;
  }
  /**
  Get the states that can follow this one through shift actions or
  goto jumps. @internal
  */
  nextStates(t) {
    let e = [];
    for (let i = this.stateSlot(
      t,
      1
      /* ParseState.Actions */
    ); ; i += 3) {
      if (this.data[i] == 65535)
        if (this.data[i + 1] == 1)
          i = Xt(this.data, i + 2);
        else
          break;
      if (!(this.data[i + 2] & 1)) {
        let s = this.data[i + 1];
        e.some((r, o) => o & 1 && r == s) || e.push(this.data[i], s);
      }
    }
    return e;
  }
  /**
  Configure the parser. Returns a new parser instance that has the
  given settings modified. Settings not provided in `config` are
  kept from the original parser.
  */
  configure(t) {
    let e = Object.assign(Object.create(Ms.prototype), this);
    if (t.props && (e.nodeSet = this.nodeSet.extend(...t.props)), t.top) {
      let i = this.topRules[t.top];
      if (!i)
        throw new RangeError(`Invalid top rule name ${t.top}`);
      e.top = i;
    }
    return t.tokenizers && (e.tokenizers = this.tokenizers.map((i) => {
      let s = t.tokenizers.find((r) => r.from == i);
      return s ? s.to : i;
    })), t.specializers && (e.specializers = this.specializers.slice(), e.specializerSpecs = this.specializerSpecs.map((i, s) => {
      let r = t.specializers.find((l) => l.from == i.external);
      if (!r)
        return i;
      let o = Object.assign(Object.assign({}, i), { external: r.to });
      return e.specializers[s] = jo(o), o;
    })), t.contextTracker && (e.context = t.contextTracker), t.dialect && (e.dialect = this.parseDialect(t.dialect)), t.strict != null && (e.strict = t.strict), t.wrap && (e.wrappers = e.wrappers.concat(t.wrap)), t.bufferLength != null && (e.bufferLength = t.bufferLength), e;
  }
  /**
  Tells you whether any [parse wrappers](#lr.ParserConfig.wrap)
  are registered for this parser.
  */
  hasWrappers() {
    return this.wrappers.length > 0;
  }
  /**
  Returns the name associated with a given term. This will only
  work for all terms when the parser was generated with the
  `--names` option. By default, only the names of tagged terms are
  stored.
  */
  getName(t) {
    return this.termNames ? this.termNames[t] : String(t <= this.maxNode && this.nodeSet.types[t].name || t);
  }
  /**
  The eof term id is always allocated directly after the node
  types. @internal
  */
  get eofTerm() {
    return this.maxNode + 1;
  }
  /**
  The type of top node produced by the parser.
  */
  get topNode() {
    return this.nodeSet.types[this.top[1]];
  }
  /**
  @internal
  */
  dynamicPrecedence(t) {
    let e = this.dynamicPrecedences;
    return e == null ? 0 : e[t] || 0;
  }
  /**
  @internal
  */
  parseDialect(t) {
    let e = Object.keys(this.dialects), i = e.map(() => !1);
    if (t)
      for (let r of t.split(" ")) {
        let o = e.indexOf(r);
        o >= 0 && (i[o] = !0);
      }
    let s = null;
    for (let r = 0; r < e.length; r++)
      if (!i[r])
        for (let o = this.dialects[e[r]], l; (l = this.data[o++]) != 65535; )
          (s || (s = new Uint8Array(this.maxTerm + 1)))[l] = 1;
    return new Pg(t, i, s);
  }
  /**
  Used by the output of the parser generator. Not available to
  user code. @hide
  */
  static deserialize(t) {
    return new Ms(t);
  }
}
function Xt(n, t) {
  return n[t] | n[t + 1] << 16;
}
function Bg(n) {
  let t = null;
  for (let e of n) {
    let i = e.p.stoppedAt;
    (e.pos == e.p.stream.end || i != null && e.pos > i) && e.p.parser.stateFlag(
      e.state,
      2
      /* StateFlag.Accepting */
    ) && (!t || t.score < e.score) && (t = e);
  }
  return t;
}
function jo(n) {
  if (n.external) {
    let t = n.extend ? 1 : 0;
    return (e, i) => n.external(e, i) << 1 | t;
  }
  return n.get;
}
const Rg = xh({
  String: w.string,
  Number: w.number,
  "True False": w.bool,
  PropertyName: w.propertyName,
  Null: w.null,
  ",": w.separator,
  "[ ]": w.squareBracket,
  "{ }": w.brace
}), Lg = Ms.deserialize({
  version: 14,
  states: "$bOVQPOOOOQO'#Cb'#CbOnQPO'#CeOvQPO'#CjOOQO'#Cp'#CpQOQPOOOOQO'#Cg'#CgO}QPO'#CfO!SQPO'#CrOOQO,59P,59PO![QPO,59PO!aQPO'#CuOOQO,59U,59UO!iQPO,59UOVQPO,59QOqQPO'#CkO!nQPO,59^OOQO1G.k1G.kOVQPO'#ClO!vQPO,59aOOQO1G.p1G.pOOQO1G.l1G.lOOQO,59V,59VOOQO-E6i-E6iOOQO,59W,59WOOQO-E6j-E6j",
  stateData: "#O~OcOS~OQSORSOSSOTSOWQO]ROePO~OVXOeUO~O[[O~PVOg^O~Oh_OVfX~OVaO~OhbO[iX~O[dO~Oh_OVfa~OhbO[ia~O",
  goto: "!kjPPPPPPkPPkqwPPk{!RPPP!XP!ePP!hXSOR^bQWQRf_TVQ_Q`WRg`QcZRicQTOQZRQe^RhbRYQR]R",
  nodeNames: "⚠ JsonText True False Null Number String } { Object Property PropertyName ] [ Array",
  maxTerm: 25,
  nodeProps: [
    ["openedBy", 7, "{", 12, "["],
    ["closedBy", 8, "}", 13, "]"]
  ],
  propSources: [Rg],
  skippedNodes: [0],
  repeatNodeCount: 2,
  tokenData: "(|~RaXY!WYZ!W]^!Wpq!Wrs!]|}$u}!O$z!Q!R%T!R![&c![!]&t!}#O&y#P#Q'O#Y#Z'T#b#c'r#h#i(Z#o#p(r#q#r(w~!]Oc~~!`Wpq!]qr!]rs!xs#O!]#O#P!}#P;'S!];'S;=`$o<%lO!]~!}Oe~~#QXrs!]!P!Q!]#O#P!]#U#V!]#Y#Z!]#b#c!]#f#g!]#h#i!]#i#j#m~#pR!Q![#y!c!i#y#T#Z#y~#|R!Q![$V!c!i$V#T#Z$V~$YR!Q![$c!c!i$c#T#Z$c~$fR!Q![!]!c!i!]#T#Z!]~$rP;=`<%l!]~$zOh~~$}Q!Q!R%T!R![&c~%YRT~!O!P%c!g!h%w#X#Y%w~%fP!Q![%i~%nRT~!Q![%i!g!h%w#X#Y%w~%zR{|&T}!O&T!Q![&Z~&WP!Q![&Z~&`PT~!Q![&Z~&hST~!O!P%c!Q![&c!g!h%w#X#Y%w~&yOg~~'OO]~~'TO[~~'WP#T#U'Z~'^P#`#a'a~'dP#g#h'g~'jP#X#Y'm~'rOR~~'uP#i#j'x~'{P#`#a(O~(RP#`#a(U~(ZOS~~(^P#f#g(a~(dP#i#j(g~(jP#X#Y(m~(rOQ~~(wOW~~(|OV~",
  tokenizers: [0],
  topRules: { JsonText: [0, 1] },
  tokenPrec: 0
}), Eg = /* @__PURE__ */ ks.define({
  name: "json",
  parser: /* @__PURE__ */ Lg.configure({
    props: [
      /* @__PURE__ */ Ah.add({
        Object: /* @__PURE__ */ Mo({ except: /^\s*\}/ }),
        Array: /* @__PURE__ */ Mo({ except: /^\s*\]/ })
      }),
      /* @__PURE__ */ Mh.add({
        "Object Array": Gd
      })
    ]
  }),
  languageData: {
    closeBrackets: { brackets: ["[", "{", '"'] },
    indentOnInput: /^\s*[\}\]]$/
  }
});
function Ng() {
  return new Nd(Eg);
}
function Ut() {
  var n = arguments[0];
  typeof n == "string" && (n = document.createElement(n));
  var t = 1, e = arguments[1];
  if (e && typeof e == "object" && e.nodeType == null && !Array.isArray(e)) {
    for (var i in e)
      if (Object.prototype.hasOwnProperty.call(e, i)) {
        var s = e[i];
        typeof s == "string" ? n.setAttribute(i, s) : s != null && (n[i] = s);
      }
    t++;
  }
  for (; t < arguments.length; t++)
    aa(n, arguments[t]);
  return n;
}
function aa(n, t) {
  if (typeof t == "string")
    n.appendChild(document.createTextNode(t));
  else if (t != null)
    if (t.nodeType != null)
      n.appendChild(t);
    else if (Array.isArray(t))
      for (var e = 0; e < t.length; e++)
        aa(n, t[e]);
    else
      throw new RangeError("Unsupported child node: " + t);
}
class Ig {
  constructor(t, e, i) {
    this.from = t, this.to = e, this.diagnostic = i;
  }
}
class Pe {
  constructor(t, e, i) {
    this.diagnostics = t, this.panel = e, this.selected = i;
  }
  static init(t, e, i) {
    let s = t, r = i.facet(ua).markerFilter;
    r && (s = r(s));
    let o = N.set(s.map((l) => l.from == l.to || l.from == l.to - 1 && i.doc.lineAt(l.from).to == l.from ? N.widget({
      widget: new Kg(l),
      diagnostic: l
    }).range(l.from) : N.mark({
      attributes: { class: "cm-lintRange cm-lintRange-" + l.severity + (l.markClass ? " " + l.markClass : "") },
      diagnostic: l
    }).range(l.from, l.to)), !0);
    return new Pe(o, e, Ze(o));
  }
}
function Ze(n, t = null, e = 0) {
  let i = null;
  return n.between(e, 1e9, (s, r, { spec: o }) => {
    if (!(t && o.diagnostic != t))
      return i = new Ig(s, r, o.diagnostic), !1;
  }), i;
}
function Vg(n, t) {
  let e = n.startState.doc.lineAt(t.pos);
  return !!(n.effects.some((i) => i.is(ca)) || n.changes.touchesRange(e.from, e.to));
}
function Hg(n, t) {
  return n.field(St, !1) ? t : t.concat(z.appendConfig.of(Ug));
}
const ca = /* @__PURE__ */ z.define(), mr = /* @__PURE__ */ z.define(), fa = /* @__PURE__ */ z.define(), St = /* @__PURE__ */ Ht.define({
  create() {
    return new Pe(N.none, null, null);
  },
  update(n, t) {
    if (t.docChanged) {
      let e = n.diagnostics.map(t.changes), i = null;
      if (n.selected) {
        let s = t.changes.mapPos(n.selected.from, 1);
        i = Ze(e, n.selected.diagnostic, s) || Ze(e, null, s);
      }
      n = new Pe(e, n.panel, i);
    }
    for (let e of t.effects)
      e.is(ca) ? n = Pe.init(e.value, n.panel, t.state) : e.is(mr) ? n = new Pe(n.diagnostics, e.value ? Vs.open : null, n.selected) : e.is(fa) && (n = new Pe(n.diagnostics, n.panel, e.value));
    return n;
  },
  provide: (n) => [
    En.from(n, (t) => t.panel),
    T.decorations.from(n, (t) => t.diagnostics)
  ]
}), $g = /* @__PURE__ */ N.mark({ class: "cm-lintRange cm-lintRange-active" });
function Fg(n, t, e) {
  let { diagnostics: i } = n.state.field(St), s = [], r = 2e8, o = 0;
  i.between(t - (e < 0 ? 1 : 0), t + (e > 0 ? 1 : 0), (h, a, { spec: c }) => {
    t >= h && t <= a && (h == a || (t > h || e > 0) && (t < a || e < 0)) && (s.push(c.diagnostic), r = Math.min(h, r), o = Math.max(a, o));
  });
  let l = n.state.facet(ua).tooltipFilter;
  return l && (s = l(s)), s.length ? {
    pos: r,
    end: o,
    above: n.state.doc.lineAt(r).to < o,
    create() {
      return { dom: _g(n, s) };
    }
  } : null;
}
function _g(n, t) {
  return Ut("ul", { class: "cm-tooltip-lint" }, t.map((e) => pa(n, e, !1)));
}
const zg = (n) => {
  let t = n.state.field(St, !1);
  (!t || !t.panel) && n.dispatch({ effects: Hg(n.state, [mr.of(!0)]) });
  let e = od(n, Vs.open);
  return e && e.dom.querySelector(".cm-panel-lint ul").focus(), !0;
}, Ko = (n) => {
  let t = n.state.field(St, !1);
  return !t || !t.panel ? !1 : (n.dispatch({ effects: mr.of(!1) }), !0);
}, Wg = (n) => {
  let t = n.state.field(St, !1);
  if (!t)
    return !1;
  let e = n.state.selection.main, i = t.diagnostics.iter(e.to + 1);
  return !i.value && (i = t.diagnostics.iter(0), !i.value || i.from == e.from && i.to == e.to) ? !1 : (n.dispatch({ selection: { anchor: i.from, head: i.to }, scrollIntoView: !0 }), !0);
}, jg = [
  { key: "Mod-Shift-m", run: zg, preventDefault: !0 },
  { key: "F8", run: Wg }
], ua = /* @__PURE__ */ O.define({
  combine(n) {
    return Object.assign({ sources: n.map((t) => t.source) }, Ds(n.map((t) => t.config), {
      delay: 750,
      markerFilter: null,
      tooltipFilter: null,
      needsRefresh: null
    }, {
      needsRefresh: (t, e) => t ? e ? (i) => t(i) || e(i) : t : e
    }));
  }
});
function da(n) {
  let t = [];
  if (n)
    t:
      for (let { name: e } of n) {
        for (let i = 0; i < e.length; i++) {
          let s = e[i];
          if (/[a-zA-Z]/.test(s) && !t.some((r) => r.toLowerCase() == s.toLowerCase())) {
            t.push(s);
            continue t;
          }
        }
        t.push("");
      }
  return t;
}
function pa(n, t, e) {
  var i;
  let s = e ? da(t.actions) : [];
  return Ut("li", { class: "cm-diagnostic cm-diagnostic-" + t.severity }, Ut("span", { class: "cm-diagnosticText" }, t.renderMessage ? t.renderMessage() : t.message), (i = t.actions) === null || i === void 0 ? void 0 : i.map((r, o) => {
    let l = !1, h = (u) => {
      if (u.preventDefault(), l)
        return;
      l = !0;
      let d = Ze(n.state.field(St).diagnostics, t);
      d && r.apply(n, d.from, d.to);
    }, { name: a } = r, c = s[o] ? a.indexOf(s[o]) : -1, f = c < 0 ? a : [
      a.slice(0, c),
      Ut("u", a.slice(c, c + 1)),
      a.slice(c + 1)
    ];
    return Ut("button", {
      type: "button",
      class: "cm-diagnosticAction",
      onclick: h,
      onmousedown: h,
      "aria-label": ` Action: ${a}${c < 0 ? "" : ` (access key "${s[o]})"`}.`
    }, f);
  }), t.source && Ut("div", { class: "cm-diagnosticSource" }, t.source));
}
class Kg extends Se {
  constructor(t) {
    super(), this.diagnostic = t;
  }
  eq(t) {
    return t.diagnostic == this.diagnostic;
  }
  toDOM() {
    return Ut("span", { class: "cm-lintPoint cm-lintPoint-" + this.diagnostic.severity });
  }
}
class qo {
  constructor(t, e) {
    this.diagnostic = e, this.id = "item_" + Math.floor(Math.random() * 4294967295).toString(16), this.dom = pa(t, e, !0), this.dom.id = this.id, this.dom.setAttribute("role", "option");
  }
}
class Vs {
  constructor(t) {
    this.view = t, this.items = [];
    let e = (s) => {
      if (s.keyCode == 27)
        Ko(this.view), this.view.focus();
      else if (s.keyCode == 38 || s.keyCode == 33)
        this.moveSelection((this.selectedIndex - 1 + this.items.length) % this.items.length);
      else if (s.keyCode == 40 || s.keyCode == 34)
        this.moveSelection((this.selectedIndex + 1) % this.items.length);
      else if (s.keyCode == 36)
        this.moveSelection(0);
      else if (s.keyCode == 35)
        this.moveSelection(this.items.length - 1);
      else if (s.keyCode == 13)
        this.view.focus();
      else if (s.keyCode >= 65 && s.keyCode <= 90 && this.selectedIndex >= 0) {
        let { diagnostic: r } = this.items[this.selectedIndex], o = da(r.actions);
        for (let l = 0; l < o.length; l++)
          if (o[l].toUpperCase().charCodeAt(0) == s.keyCode) {
            let h = Ze(this.view.state.field(St).diagnostics, r);
            h && r.actions[l].apply(t, h.from, h.to);
          }
      } else
        return;
      s.preventDefault();
    }, i = (s) => {
      for (let r = 0; r < this.items.length; r++)
        this.items[r].dom.contains(s.target) && this.moveSelection(r);
    };
    this.list = Ut("ul", {
      tabIndex: 0,
      role: "listbox",
      "aria-label": this.view.state.phrase("Diagnostics"),
      onkeydown: e,
      onclick: i
    }), this.dom = Ut("div", { class: "cm-panel-lint" }, this.list, Ut("button", {
      type: "button",
      name: "close",
      "aria-label": this.view.state.phrase("close"),
      onclick: () => Ko(this.view)
    }, "×")), this.update();
  }
  get selectedIndex() {
    let t = this.view.state.field(St).selected;
    if (!t)
      return -1;
    for (let e = 0; e < this.items.length; e++)
      if (this.items[e].diagnostic == t.diagnostic)
        return e;
    return -1;
  }
  update() {
    let { diagnostics: t, selected: e } = this.view.state.field(St), i = 0, s = !1, r = null;
    for (t.between(0, this.view.state.doc.length, (o, l, { spec: h }) => {
      let a = -1, c;
      for (let f = i; f < this.items.length; f++)
        if (this.items[f].diagnostic == h.diagnostic) {
          a = f;
          break;
        }
      a < 0 ? (c = new qo(this.view, h.diagnostic), this.items.splice(i, 0, c), s = !0) : (c = this.items[a], a > i && (this.items.splice(i, a - i), s = !0)), e && c.diagnostic == e.diagnostic ? c.dom.hasAttribute("aria-selected") || (c.dom.setAttribute("aria-selected", "true"), r = c) : c.dom.hasAttribute("aria-selected") && c.dom.removeAttribute("aria-selected"), i++;
    }); i < this.items.length && !(this.items.length == 1 && this.items[0].diagnostic.from < 0); )
      s = !0, this.items.pop();
    this.items.length == 0 && (this.items.push(new qo(this.view, {
      from: -1,
      to: -1,
      severity: "info",
      message: this.view.state.phrase("No diagnostics")
    })), s = !0), r ? (this.list.setAttribute("aria-activedescendant", r.id), this.view.requestMeasure({
      key: this,
      read: () => ({ sel: r.dom.getBoundingClientRect(), panel: this.list.getBoundingClientRect() }),
      write: ({ sel: o, panel: l }) => {
        let h = l.height / this.list.offsetHeight;
        o.top < l.top ? this.list.scrollTop -= (l.top - o.top) / h : o.bottom > l.bottom && (this.list.scrollTop += (o.bottom - l.bottom) / h);
      }
    })) : this.selectedIndex < 0 && this.list.removeAttribute("aria-activedescendant"), s && this.sync();
  }
  sync() {
    let t = this.list.firstChild;
    function e() {
      let i = t;
      t = i.nextSibling, i.remove();
    }
    for (let i of this.items)
      if (i.dom.parentNode == this.list) {
        for (; t != i.dom; )
          e();
        t = i.dom.nextSibling;
      } else
        this.list.insertBefore(i.dom, t);
    for (; t; )
      e();
  }
  moveSelection(t) {
    if (this.selectedIndex < 0)
      return;
    let e = this.view.state.field(St), i = Ze(e.diagnostics, this.items[t].diagnostic);
    i && this.view.dispatch({
      selection: { anchor: i.from, head: i.to },
      scrollIntoView: !0,
      effects: fa.of(i)
    });
  }
  static open(t) {
    return new Vs(t);
  }
}
function qg(n, t = 'viewBox="0 0 40 40"') {
  return `url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" ${t}>${encodeURIComponent(n)}</svg>')`;
}
function Ji(n) {
  return qg(`<path d="m0 2.5 l2 -1.5 l1 0 l2 1.5 l1 0" stroke="${n}" fill="none" stroke-width=".7"/>`, 'width="6" height="3"');
}
const Gg = /* @__PURE__ */ T.baseTheme({
  ".cm-diagnostic": {
    padding: "3px 6px 3px 8px",
    marginLeft: "-1px",
    display: "block",
    whiteSpace: "pre-wrap"
  },
  ".cm-diagnostic-error": { borderLeft: "5px solid #d11" },
  ".cm-diagnostic-warning": { borderLeft: "5px solid orange" },
  ".cm-diagnostic-info": { borderLeft: "5px solid #999" },
  ".cm-diagnostic-hint": { borderLeft: "5px solid #66d" },
  ".cm-diagnosticAction": {
    font: "inherit",
    border: "none",
    padding: "2px 4px",
    backgroundColor: "#444",
    color: "white",
    borderRadius: "3px",
    marginLeft: "8px",
    cursor: "pointer"
  },
  ".cm-diagnosticSource": {
    fontSize: "70%",
    opacity: 0.7
  },
  ".cm-lintRange": {
    backgroundPosition: "left bottom",
    backgroundRepeat: "repeat-x",
    paddingBottom: "0.7px"
  },
  ".cm-lintRange-error": { backgroundImage: /* @__PURE__ */ Ji("#d11") },
  ".cm-lintRange-warning": { backgroundImage: /* @__PURE__ */ Ji("orange") },
  ".cm-lintRange-info": { backgroundImage: /* @__PURE__ */ Ji("#999") },
  ".cm-lintRange-hint": { backgroundImage: /* @__PURE__ */ Ji("#66d") },
  ".cm-lintRange-active": { backgroundColor: "#ffdd9980" },
  ".cm-tooltip-lint": {
    padding: 0,
    margin: 0
  },
  ".cm-lintPoint": {
    position: "relative",
    "&:after": {
      content: '""',
      position: "absolute",
      bottom: 0,
      left: "-2px",
      borderLeft: "3px solid transparent",
      borderRight: "3px solid transparent",
      borderBottom: "4px solid #d11"
    }
  },
  ".cm-lintPoint-warning": {
    "&:after": { borderBottomColor: "orange" }
  },
  ".cm-lintPoint-info": {
    "&:after": { borderBottomColor: "#999" }
  },
  ".cm-lintPoint-hint": {
    "&:after": { borderBottomColor: "#66d" }
  },
  ".cm-panel.cm-panel-lint": {
    position: "relative",
    "& ul": {
      maxHeight: "100px",
      overflowY: "auto",
      "& [aria-selected]": {
        backgroundColor: "#ddd",
        "& u": { textDecoration: "underline" }
      },
      "&:focus [aria-selected]": {
        background_fallback: "#bdf",
        backgroundColor: "Highlight",
        color_fallback: "white",
        color: "HighlightText"
      },
      "& u": { textDecoration: "none" },
      padding: 0,
      margin: 0
    },
    "& [name=close]": {
      position: "absolute",
      top: "0",
      right: "2px",
      background: "inherit",
      border: "none",
      font: "inherit",
      padding: 0,
      margin: 0
    }
  }
}), Ug = [
  St,
  /* @__PURE__ */ T.decorations.compute([St], (n) => {
    let { selected: t, panel: e } = n.field(St);
    return !t || !e || t.from == t.to ? N.none : N.set([
      $g.range(t.from, t.to)
    ]);
  }),
  /* @__PURE__ */ nd(Fg, { hideOn: Vg }),
  Gg
], Yg = "#e5c07b", Go = "#e06c75", Qg = "#56b6c2", Jg = "#ffffff", hs = "#abb2bf", Kn = "#7d8799", Xg = "#61afef", Zg = "#98c379", Uo = "#d19a66", tm = "#c678dd", em = "#21252b", Yo = "#2c313a", Qo = "#282c34", sn = "#353a42", im = "#3E4451", Jo = "#528bff", sm = /* @__PURE__ */ T.theme({
  "&": {
    color: hs,
    backgroundColor: Qo
  },
  ".cm-content": {
    caretColor: Jo
  },
  ".cm-cursor, .cm-dropCursor": { borderLeftColor: Jo },
  "&.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection": { backgroundColor: im },
  ".cm-panels": { backgroundColor: em, color: hs },
  ".cm-panels.cm-panels-top": { borderBottom: "2px solid black" },
  ".cm-panels.cm-panels-bottom": { borderTop: "2px solid black" },
  ".cm-searchMatch": {
    backgroundColor: "#72a1ff59",
    outline: "1px solid #457dff"
  },
  ".cm-searchMatch.cm-searchMatch-selected": {
    backgroundColor: "#6199ff2f"
  },
  ".cm-activeLine": { backgroundColor: "#6699ff0b" },
  ".cm-selectionMatch": { backgroundColor: "#aafe661a" },
  "&.cm-focused .cm-matchingBracket, &.cm-focused .cm-nonmatchingBracket": {
    backgroundColor: "#bad0f847"
  },
  ".cm-gutters": {
    backgroundColor: Qo,
    color: Kn,
    border: "none"
  },
  ".cm-activeLineGutter": {
    backgroundColor: Yo
  },
  ".cm-foldPlaceholder": {
    backgroundColor: "transparent",
    border: "none",
    color: "#ddd"
  },
  ".cm-tooltip": {
    border: "none",
    backgroundColor: sn
  },
  ".cm-tooltip .cm-tooltip-arrow:before": {
    borderTopColor: "transparent",
    borderBottomColor: "transparent"
  },
  ".cm-tooltip .cm-tooltip-arrow:after": {
    borderTopColor: sn,
    borderBottomColor: sn
  },
  ".cm-tooltip-autocomplete": {
    "& > ul > li[aria-selected]": {
      backgroundColor: Yo,
      color: hs
    }
  }
}, { dark: !0 }), nm = /* @__PURE__ */ Pi.define([
  {
    tag: w.keyword,
    color: tm
  },
  {
    tag: [w.name, w.deleted, w.character, w.propertyName, w.macroName],
    color: Go
  },
  {
    tag: [/* @__PURE__ */ w.function(w.variableName), w.labelName],
    color: Xg
  },
  {
    tag: [w.color, /* @__PURE__ */ w.constant(w.name), /* @__PURE__ */ w.standard(w.name)],
    color: Uo
  },
  {
    tag: [/* @__PURE__ */ w.definition(w.name), w.separator],
    color: hs
  },
  {
    tag: [w.typeName, w.className, w.number, w.changed, w.annotation, w.modifier, w.self, w.namespace],
    color: Yg
  },
  {
    tag: [w.operator, w.operatorKeyword, w.url, w.escape, w.regexp, w.link, /* @__PURE__ */ w.special(w.string)],
    color: Qg
  },
  {
    tag: [w.meta, w.comment],
    color: Kn
  },
  {
    tag: w.strong,
    fontWeight: "bold"
  },
  {
    tag: w.emphasis,
    fontStyle: "italic"
  },
  {
    tag: w.strikethrough,
    textDecoration: "line-through"
  },
  {
    tag: w.link,
    color: Kn,
    textDecoration: "underline"
  },
  {
    tag: w.heading,
    fontWeight: "bold",
    color: Go
  },
  {
    tag: [w.atom, w.bool, /* @__PURE__ */ w.special(w.variableName)],
    color: Uo
  },
  {
    tag: [w.processingInstruction, w.string, w.inserted],
    color: Zg
  },
  {
    tag: w.invalid,
    color: Jg
  }
]), ga = lt(!1);
window.__hst_controls_dark || (window.__hst_controls_dark = []);
window.__hst_controls_dark.push(ga);
var Xo;
(Xo = window.__hst_controls_dark_ready) == null || Xo.call(window);
const rm = {
  name: "HstJson",
  inheritAttrs: !1
}, om = /* @__PURE__ */ et({
  ...rm,
  props: {
    title: {},
    modelValue: {}
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = n, i = t;
    let s;
    const r = lt(""), o = lt(!1), l = lt(), h = {
      light: [T.baseTheme({}), Do(ap)],
      dark: [sm, Do(nm)]
    }, a = new Ai(), c = [
      gd(),
      Uu(),
      zu(),
      Ng(),
      mp(),
      Kd(),
      rp(),
      fh.of([
        ...vg,
        ...ep,
        ...jg
      ]),
      T.updateListener.of((f) => {
        r.value = f.view.state.doc.toString();
      }),
      a.of(h.light)
    ];
    return ya(() => {
      s = new T({
        doc: JSON.stringify(e.modelValue, null, 2),
        extensions: c,
        parent: l.value
      }), ba(() => {
        s.dispatch({
          effects: [
            a.reconfigure(h[ga.value ? "dark" : "light"])
          ]
        });
      });
    }), as(() => e.modelValue, () => {
      let f;
      try {
        f = JSON.stringify(JSON.parse(r.value)) === JSON.stringify(e.modelValue);
      } catch {
        f = !1;
      }
      f || s.dispatch({ changes: [{ from: 0, to: s.state.doc.length, insert: JSON.stringify(e.modelValue, null, 2) }] });
    }, { deep: !0 }), as(() => r.value, () => {
      o.value = !1;
      try {
        i("update:modelValue", JSON.parse(r.value));
      } catch {
        o.value = !0;
      }
    }), (f, u) => (D(), Q(Vt, {
      title: f.title,
      class: dt(["histoire-json htw-cursor-text", f.$attrs.class]),
      style: Pt(f.$attrs.style)
    }, {
      actions: G(() => [
        o.value ? Et((D(), Q(Ct(Gn), {
          key: 0,
          icon: "carbon:warning-alt",
          class: "htw-text-orange-500"
        }, null, 512)), [
          [Ct(me), "JSON error"]
        ]) : te("", !0),
        ht(f.$slots, "actions", {}, void 0, !0)
      ]),
      default: G(() => [
        B("div", He({
          ref_key: "editorElement",
          ref: l,
          class: "__histoire-json-code htw-w-full htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 focus-within:htw-border-primary-500 dark:focus-within:htw-border-primary-500 htw-rounded-sm htw-box-border htw-overflow-auto htw-resize-y htw-min-h-32 htw-h-48 htw-relative"
        }, { ...f.$attrs, class: null, style: null }), null, 16)
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
}), lm = (n, t) => {
  const e = n.__vccOpts || n;
  for (const [i, s] of t)
    e[i] = s;
  return e;
}, hm = /* @__PURE__ */ lm(om, [["__scopeId", "data-v-935458a7"]]), am = { class: "htw-flex htw-flex-row htw-gap-1" }, cm = ["value"], fm = {
  name: "HstColorSelect",
  inheritAttrs: !1
}, um = /* @__PURE__ */ et({
  ...fm,
  props: {
    title: {},
    modelValue: {}
  },
  emits: {
    "update:modelValue": (n) => !0
  },
  setup(n, { emit: t }) {
    const e = n, i = t, s = nt({
      get: () => e.modelValue,
      set: (h) => {
        i("update:modelValue", h);
      }
    });
    function r(h, a = 15) {
      let c = !1, f;
      const u = () => {
        f == null ? c = !1 : (h(...f), f = null, setTimeout(u, a));
      };
      return (...d) => {
        if (c) {
          f = d;
          return;
        }
        h(...d), c = !0, setTimeout(u, a);
      };
    }
    const o = r((h) => {
      i("update:modelValue", h);
    });
    function l(h) {
      o(h);
    }
    return (h, a) => (D(), Q(Vt, {
      title: h.title,
      class: dt(["histoire-select htw-cursor-text htw-items-center", h.$attrs.class]),
      style: Pt(h.$attrs.style)
    }, {
      actions: G(() => [
        ht(h.$slots, "actions")
      ]),
      default: G(() => [
        B("div", am, [
          Et(B("input", He({ ...h.$attrs, class: null, style: null }, {
            "onUpdate:modelValue": a[0] || (a[0] = (c) => s.value = c),
            type: "text",
            class: "htw-text-inherit htw-bg-transparent htw-w-full htw-outline-none htw-px-2 htw-py-1 -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 focus:htw-border-primary-500 dark:focus:htw-border-primary-500 htw-rounded-sm"
          }), null, 16), [
            [qn, s.value]
          ]),
          B("input", {
            type: "color",
            value: h.modelValue,
            onInput: a[1] || (a[1] = (c) => l(c.target.value))
          }, null, 40, cm)
        ])
      ]),
      _: 3
    }, 8, ["title", "class", "style"]));
  }
}), dm = Zo, pm = Da, gm = Ea, mm = Ha, wm = _a, ym = Wa, bm = Ga, km = Qa, xm = nc, vm = dc, Sm = xc, Cm = Tc, Am = Le, Om = Lc, Mm = hm, Tm = um, Nm = {
  HstButton: dm,
  HstButtonGroup: pm,
  HstCheckbox: gm,
  HstCheckboxList: mm,
  HstText: wm,
  HstNumber: ym,
  HstSlider: bm,
  HstTextarea: km,
  HstSelect: xm,
  HstRadio: Om,
  HstJson: Mm,
  HstColorShades: vm,
  HstTokenList: Sm,
  HstTokenGrid: Cm,
  HstCopyIcon: Am,
  HstColorSelect: Tm
};
export {
  dm as HstButton,
  pm as HstButtonGroup,
  gm as HstCheckbox,
  mm as HstCheckboxList,
  Tm as HstColorSelect,
  vm as HstColorShades,
  Am as HstCopyIcon,
  Mm as HstJson,
  ym as HstNumber,
  Om as HstRadio,
  xm as HstSelect,
  bm as HstSlider,
  wm as HstText,
  km as HstTextarea,
  Cm as HstTokenGrid,
  Sm as HstTokenList,
  Nm as components
};
