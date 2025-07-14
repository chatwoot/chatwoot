import l from "dompurify";
function m(t, e) {
  const o = t.hooks ?? {};
  let n;
  for (n in o) {
    const u = o[n];
    u !== void 0 && e.addHook(n, u);
  }
}
function c() {
  return l();
}
function p(t = {}, e = c) {
  const o = e();
  m(t, o);
  const n = function(u, i) {
    const r = i.value;
    if (i.oldValue === r)
      return;
    const a = `${r}`, s = i.arg, d = t.namedConfigurations, f = t.default ?? {};
    if (d && s !== void 0) {
      u.innerHTML = o.sanitize(
        a,
        d[s] ?? f
      );
      return;
    }
    u.innerHTML = o.sanitize(
      a,
      f
    );
  };
  return {
    mounted: n,
    updated: n
  };
}
const k = {
  install(t, e = {}, o = c) {
    t.directive(
      "dompurify-html",
      p(e, o)
    );
  }
};
export {
  p as buildVueDompurifyHTMLDirective,
  k as default,
  k as vueDompurifyHTMLPlugin
};
