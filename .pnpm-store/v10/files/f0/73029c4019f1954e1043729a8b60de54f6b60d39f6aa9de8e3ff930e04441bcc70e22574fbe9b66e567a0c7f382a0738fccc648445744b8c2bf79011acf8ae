import { computed as t, h as s, defineComponent as i } from "vue";
const n = {
  path: "/",
  name: void 0,
  redirectedFrom: void 0,
  params: {},
  query: {},
  hash: "",
  fullPath: "/",
  matched: [],
  meta: {},
  href: "/"
}, c = i({
  name: "RouterLinkStub",
  compatConfig: { MODE: 3 },
  props: {
    to: {
      type: [String, Object],
      required: !0
    },
    custom: {
      type: Boolean,
      default: !1
    }
  },
  render() {
    var e, a;
    const o = t(() => n), r = (a = (e = this.$slots) == null ? void 0 : e.default) == null ? void 0 : a.call(e, {
      route: o,
      href: t(() => o.value.href),
      isActive: t(() => !1),
      isExactActive: t(() => !1),
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      navigate: async () => {
      }
    });
    return this.custom ? r : s("a", void 0, r);
  }
});
export {
  c as RouterLinkStub
};
