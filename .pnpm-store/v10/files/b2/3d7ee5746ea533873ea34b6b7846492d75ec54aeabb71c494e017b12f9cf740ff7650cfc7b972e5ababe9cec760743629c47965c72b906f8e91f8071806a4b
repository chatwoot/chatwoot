import { defineComponent as F, reactive as B, unref as b, openBlock as H, createElementBlock as I, normalizeClass as j, createElementVNode as U, createCommentVNode as V } from "vue";
const S = {
  a: ["class", "href", "id", "style", "target"],
  address: ["class", "id", "style"],
  b: ["class", "id", "style"],
  blockquote: ["class", "id", "style"],
  br: ["class", "id", "style"],
  caption: ["class", "id", "style"],
  cite: ["class", "id", "style"],
  code: ["class", "id", "style"],
  col: [
    "align",
    "bgcolor",
    "char",
    "charoff",
    "class",
    "id",
    "style",
    "valign",
    "width"
  ],
  colgroup: [
    "align",
    "bgcolor",
    "char",
    "charoff",
    "class",
    "id",
    "style",
    "valign",
    "width"
  ],
  center: ["class", "id", "style"],
  dd: ["class", "id", "style"],
  div: ["align", "class", "dir", "id", "style"],
  dt: ["class", "id", "style"],
  em: ["class", "id", "style"],
  font: ["class", "color", "face", "id", "size", "style"],
  h1: ["align", "class", "dir", "id", "style"],
  h2: ["align", "class", "dir", "id", "style"],
  h3: ["align", "class", "dir", "id", "style"],
  h4: ["align", "class", "dir", "id", "style"],
  h5: ["align", "class", "dir", "id", "style"],
  h6: ["align", "class", "dir", "id", "style"],
  hr: ["align", "size", "width"],
  i: ["class", "id", "style"],
  img: [
    "align",
    "alt",
    "border",
    "class",
    "height",
    "hspace",
    "id",
    "src",
    "style",
    "title",
    "usemap",
    "vspace",
    "width"
  ],
  label: ["class", "id", "style"],
  legend: ["class", "id", "style"],
  li: ["class", "dir", "id", "style", "type"],
  ol: ["class", "dir", "id", "style", "type", "start", "reversed"],
  p: ["align", "class", "dir", "id", "style"],
  pre: ["class", "id", "style"],
  span: ["class", "id", "style"],
  strong: ["class", "id", "style"],
  style: [],
  sub: ["class", "id", "style"],
  sup: ["class", "id", "style"],
  table: [
    "align",
    "bgcolor",
    "border",
    "cellpadding",
    "cellspacing",
    "class",
    "dir",
    "frame",
    "id",
    "rules",
    "style",
    "width"
  ],
  tbody: ["class", "id", "style"],
  td: [
    "abbr",
    "align",
    "bgcolor",
    "class",
    "colspan",
    "dir",
    "height",
    "id",
    "lang",
    "rowspan",
    "scope",
    "style",
    "valign",
    "width"
  ],
  tfoot: [
    "align",
    "bgcolor",
    "char",
    "charoff",
    "class",
    "id",
    "style",
    "valign"
  ],
  th: [
    "abbr",
    "align",
    "bgcolor",
    "class",
    "colspan",
    "dir",
    "height",
    "id",
    "lang",
    "rowspan",
    "scope",
    "style",
    "valign",
    "width"
  ],
  thead: [
    "align",
    "bgcolol",
    "char",
    "charoff",
    "class",
    "id",
    "style",
    "valign"
  ],
  tr: [
    "align",
    "bgcolor",
    "char",
    "charoff",
    "class",
    "dir",
    "id",
    "style",
    "valign"
  ],
  u: ["class", "id", "style"],
  ul: ["class", "dir", "id", "style"]
}, D = [
  "script",
  "iframe",
  "textarea",
  "title",
  "noscript",
  "noembed",
  "svg"
], W = [
  "azimuth",
  "background",
  "background-blend-mode",
  "background-clip",
  "background-color",
  "background-image",
  "background-origin",
  "background-position",
  "background-position-x",
  "background-position-y",
  "background-repeat",
  "background-repeat-x",
  "background-repeat-y",
  "background-size",
  "border",
  "border-bottom",
  "border-bottom-color",
  "border-bottom-left-radius",
  "border-bottom-right-radius",
  "border-bottom-style",
  "border-bottom-width",
  "border-collapse",
  "border-color",
  "border-left",
  "border-left-color",
  "border-left-style",
  "border-left-width",
  "border-radius",
  "border-right",
  "border-right-color",
  "border-right-style",
  "border-right-width",
  "border-spacing",
  "border-style",
  "border-top",
  "border-top-color",
  "border-top-left-radius",
  "border-top-right-radius",
  "border-top-style",
  "border-top-width",
  "border-width",
  "box-sizing",
  "break-after",
  "break-before",
  "break-inside",
  "caption-side",
  "clear",
  "color",
  "column-count",
  "column-fill",
  "column-gap",
  "column-rule",
  "column-rule-color",
  "column-rule-style",
  "column-rule-width",
  "column-span",
  "column-width",
  "columns",
  "direction",
  "display",
  "elevation",
  "empty-cells",
  "float",
  "font",
  "font-family",
  "font-feature-settings",
  "font-kerning",
  "font-size",
  "font-size-adjust",
  "font-stretch",
  "font-style",
  "font-synthesis",
  "font-variant",
  "font-variant-alternates",
  "font-variant-caps",
  "font-variant-east-asian",
  "font-variant-ligatures",
  "font-variant-numeric",
  "font-weight",
  "height",
  "image-orientation",
  "image-resolution",
  "ime-mode",
  "isolation",
  "layout-flow",
  "layout-grid",
  "layout-grid-char",
  "layout-grid-char-spacing",
  "layout-grid-line",
  "layout-grid-mode",
  "layout-grid-type",
  "letter-spacing",
  "line-break",
  "line-height",
  "list-style",
  "list-style-position",
  "list-style-type",
  "margin",
  "margin-bottom",
  "margin-left",
  "margin-right",
  "margin-top",
  "marker-offset",
  "max-height",
  "max-width",
  "min-height",
  "min-width",
  "mix-blend-mode",
  "object-fit",
  "object-position",
  "opacity",
  "outline",
  "outline-color",
  "outline-style",
  "outline-width",
  "overflow",
  "overflow-x",
  "overflow-y",
  "padding",
  "padding-bottom",
  "padding-left",
  "padding-right",
  "padding-top",
  "page-break-after",
  "page-break-before",
  "page-break-inside",
  "pause",
  "pause-after",
  "pause-before",
  "pitch",
  "pitch-range",
  "quotes",
  "richness",
  "speak",
  "speak-header",
  "speak-numeral",
  "speak-punctuation",
  "speech-rate",
  "stress",
  "table-layout",
  "text-align",
  "text-align-last",
  "text-autospace",
  "text-combine-upright",
  "text-decoration",
  "text-decoration-color",
  "text-decoration-line",
  "text-decoration-skip",
  "text-decoration-style",
  "text-emphasis",
  "text-emphasis-color",
  "text-emphasis-style",
  "text-indent",
  "text-justify",
  "text-kashida-space",
  "text-orientation",
  "text-overflow",
  "text-transform",
  "text-underline-position",
  "text-wrap",
  "text-wrap-mode",
  "text-wrap-style",
  "unicode-bidi",
  "vertical-align",
  "voice-family",
  "white-space",
  "white-space-collapse",
  "width",
  "word-break",
  "word-spacing",
  "word-wrap",
  "writing-mode",
  "zoom"
];
function Y(t, o) {
  return o ? t.split(",").map((i) => i.trim()).map((i) => {
    const s = i.replace(/\./g, "." + o + "_").replace(/#/g, "#" + o + "_");
    return s.toLowerCase().startsWith("body") ? "#" + o + " " + s.substring(4) : "#" + o + " " + s;
  }).join(",") : t;
}
function G(t, o, i) {
  return t.trim().replace(/expression\((.*?)\)/g, "").replace(/url\(["']?(.*?)["']?\)/g, (s, l) => i ? `url("${encodeURI(i(decodeURI(l)))}")` : o.includes(l.toLowerCase().split(":")[0]) ? s : "");
}
function q(t, o, i, s, l) {
  if (!t)
    return;
  const n = [];
  for (let a = 0; a < t.length; a++) {
    const p = t[a];
    n.push(p);
  }
  for (const a of n)
    if (i.includes(a)) {
      const p = t.getPropertyValue(a);
      t.setProperty(a, G(p, o, l), s ? t.getPropertyPriority(a) : void 0);
    } else
      t.removeProperty(a);
}
function P(t, o, i, s, l, n) {
  t.selectorText = Y(t.selectorText, o), q(t.style, i, s, l, n);
}
const O = ["http", "https", "mailto"];
function J(t, { dropAllHtmlTags: o = !1, rewriteExternalLinks: i, rewriteExternalResources: s, id: l = "msg_" + String.fromCharCode(...new Array(24).fill(void 0).map(() => Math.random() * 25 % 25 + 65)), allowedSchemas: n = O, allowedCssProperties: a = W, preserveCssPriority: p = !0, noWrapper: h = !1 }) {
  var A, _, z, R, M;
  h && (l = "");
  const c = new DOMParser().parseFromString(t, "text/html");
  n = Array.isArray(n) ? n.map((e) => e.toLowerCase()) : O;
  const v = c.createNodeIterator(c.documentElement, NodeFilter.SHOW_COMMENT);
  let d;
  for (; d = v.nextNode(); )
    (A = d.parentNode) == null || A.removeChild(d);
  const k = [...D];
  o && k.push("style"), c.querySelectorAll(k.join(", ")).forEach((e) => e.remove()), c.querySelectorAll("head > style").forEach((e) => {
    c.body.appendChild(e);
  });
  const L = [], N = c.createNodeIterator(c.body, NodeFilter.SHOW_ELEMENT, {
    acceptNode: () => NodeFilter.FILTER_ACCEPT
  });
  for (; d = N.nextNode(); ) {
    const e = d, g = e.tagName.toLowerCase();
    if (!(g === "body" || g === "html")) {
      if (o) {
        if (d.textContent) {
          const f = c.createTextNode(d.textContent);
          (_ = d.parentNode) == null || _.replaceChild(f, d);
        } else
          (z = d.parentNode) == null || z.removeChild(d);
        continue;
      }
      if (g in S) {
        const f = S[g];
        for (const r of e.getAttributeNames())
          if (!f.includes(r))
            e.removeAttribute(r);
          else if (r === "class" && !h)
            e.setAttribute(r, ((R = e.getAttribute(r)) == null ? void 0 : R.split(" ").map((u) => l + "_" + u).join(" ")) ?? "");
          else if (r === "id" && !h)
            e.setAttribute(r, l + "_" + (e.getAttribute(r) ?? ""));
          else if (r === "href" || r === "src") {
            const u = e.getAttribute(r) ?? "";
            r === "href" && i ? e.setAttribute(r, i(u)) : r === "src" && s ? e.setAttribute(r, s(u)) : n.includes(u.toLowerCase().split(":")[0]) || e.removeAttribute(r);
          }
        q(e.style, n, a, p, s), g === "a" && (e.setAttribute("rel", "noopener noreferrer"), e.setAttribute("target", "_blank"));
      } else
        e.insertAdjacentHTML("afterend", e.innerHTML), L.push(e);
    }
  }
  for (const e of L)
    try {
      try {
        (M = e.parentNode) == null || M.removeChild(e);
      } catch {
        e.outerHTML = "";
      }
    } catch {
      try {
        e.remove();
      } catch {
      }
    }
  if (c.querySelectorAll("body style").forEach((e) => {
    const g = e, f = g.sheet, r = [];
    if (!f.cssRules) {
      g.textContent = "";
      return;
    }
    for (let u = 0; u < f.cssRules.length; u++) {
      const y = f.cssRules[u];
      if ("selectorText" in y)
        P(y, l, n, a, p, s), r.push(y);
      else if ("cssRules" in y && "media" in y) {
        const m = y, E = [];
        for (let w = 0; w < m.cssRules.length; w++) {
          const x = m.cssRules[w];
          x.type === x.STYLE_RULE && (P(x, l, n, a, p, s), E.push(x));
        }
        for (; m.cssRules.length > 0; )
          m.deleteRule(0);
        for (const w of E)
          m.insertRule(w.cssText, m.cssRules.length);
        r.push(m);
      }
    }
    g.textContent = r.map((u) => u.cssText).join(`
`);
  }), h)
    return c.body.innerHTML;
  {
    const e = c.createElement("div");
    return e.id = l, e.innerHTML = c.body.innerHTML, e.outerHTML;
  }
}
function K(t) {
  const o = document.createElement("div");
  return o.textContent = t, o.innerHTML;
}
function Q(t, o, i) {
  let s = t ?? "";
  return (s == null ? void 0 : s.length) === 0 && o && (s = K(o).split(`
`).map((l) => "<p>" + l + "</p>").join(`
`)), J(s, i ?? {});
}
const X = ["innerHTML"], Z = ["title"], $ = /* @__PURE__ */ F({
  __name: "Letter",
  props: {
    className: {},
    html: {},
    text: {},
    useIframe: { type: Boolean },
    iframeTitle: {},
    rewriteExternalLinks: {},
    rewriteExternalResources: {},
    allowedCssProperties: {},
    allowedSchemas: {},
    preserveCssPriority: { type: Boolean }
  },
  setup(t) {
    const o = t, {
      className: i,
      html: s,
      text: l,
      useIframe: n,
      iframeTitle: a,
      rewriteExternalLinks: p,
      rewriteExternalResources: h,
      allowedSchemas: c,
      allowedCssProperties: v,
      preserveCssPriority: d
    } = B(o), C = Q(s, l, {
      rewriteExternalResources: h,
      rewriteExternalLinks: p,
      allowedSchemas: c,
      preserveCssPriority: d,
      allowedCssProperties: v
    }), T = "data:text/html;charset=utf-8," + encodeURIComponent(C);
    return (L, N) => b(n) ? b(n) ? (H(), I("div", {
      key: 1,
      class: j([b(i)])
    }, [
      U("iframe", {
        src: T,
        title: b(a)
      }, null, 8, Z)
    ], 2)) : V("", !0) : (H(), I("div", {
      key: 0,
      class: j([b(i)]),
      innerHTML: b(C)
    }, null, 10, X));
  }
}), se = {
  install: (t) => {
    t.component("Letter", $);
  }
};
export {
  $ as Letter,
  se as default
};
