import { u as _root, x as isObject_1, y as isSymbol_1, W as WithTooltip, T as TooltipNote, F as Form, I as Icons, z as getControlId, a as __rest } from './index-9ef3b84b.js';
import React__default, { useRef, useMemo, useEffect, useState, useCallback, useLayoutEffect } from 'react';
import { styled } from '@storybook/theming';
import 'memoizerific';
import '@storybook/csf';
import 'qs';
import '@storybook/client-logger';

function u() {
  return (u = Object.assign || function (e) {
    for (var r = 1; r < arguments.length; r++) {
      var t = arguments[r];

      for (var n in t) Object.prototype.hasOwnProperty.call(t, n) && (e[n] = t[n]);
    }

    return e;
  }).apply(this, arguments);
}

function c(e, r) {
  if (null == e) return {};
  var t,
      n,
      o = {},
      a = Object.keys(e);

  for (n = 0; n < a.length; n++) r.indexOf(t = a[n]) >= 0 || (o[t] = e[t]);

  return o;
}

function i(e) {
  var t = useRef(e),
      n = useRef(function (e) {
    t.current && t.current(e);
  });
  return t.current = e, n.current;
}

var s = function (e, r, t) {
  return void 0 === r && (r = 0), void 0 === t && (t = 1), e > t ? t : e < r ? r : e;
},
    f = function (e) {
  return "touches" in e;
},
    v = function (e) {
  return e && e.ownerDocument.defaultView || self;
},
    d = function (e, r, t) {
  var n = e.getBoundingClientRect(),
      o = f(r) ? function (e, r) {
    for (var t = 0; t < e.length; t++) if (e[t].identifier === r) return e[t];

    return e[0];
  }(r.touches, t) : r;
  return {
    left: s((o.pageX - (n.left + v(e).pageXOffset)) / n.width),
    top: s((o.pageY - (n.top + v(e).pageYOffset)) / n.height)
  };
},
    h = function (e) {
  !f(e) && e.preventDefault();
},
    m = React__default.memo(function (o) {
  var a = o.onMove,
      l = o.onKey,
      s = c(o, ["onMove", "onKey"]),
      m = useRef(null),
      g = i(a),
      p = i(l),
      b = useRef(null),
      _ = useRef(!1),
      x = useMemo(function () {
    var e = function (e) {
      h(e), (f(e) ? e.touches.length > 0 : e.buttons > 0) && m.current ? g(d(m.current, e, b.current)) : t(!1);
    },
        r = function () {
      return t(!1);
    };

    function t(t) {
      var n = _.current,
          o = v(m.current),
          a = t ? o.addEventListener : o.removeEventListener;
      a(n ? "touchmove" : "mousemove", e), a(n ? "touchend" : "mouseup", r);
    }

    return [function (e) {
      var r = e.nativeEvent,
          n = m.current;

      if (n && (h(r), !function (e, r) {
        return r && !f(e);
      }(r, _.current) && n)) {
        if (f(r)) {
          _.current = !0;
          var o = r.changedTouches || [];
          o.length && (b.current = o[0].identifier);
        }

        n.focus(), g(d(n, r, b.current)), t(!0);
      }
    }, function (e) {
      var r = e.which || e.keyCode;
      r < 37 || r > 40 || (e.preventDefault(), p({
        left: 39 === r ? .05 : 37 === r ? -.05 : 0,
        top: 40 === r ? .05 : 38 === r ? -.05 : 0
      }));
    }, t];
  }, [p, g]),
      C = x[0],
      E = x[1],
      H = x[2];

  return useEffect(function () {
    return H;
  }, [H]), React__default.createElement("div", u({}, s, {
    onTouchStart: C,
    onMouseDown: C,
    className: "react-colorful__interactive",
    ref: m,
    onKeyDown: E,
    tabIndex: 0,
    role: "slider"
  }));
}),
    g = function (e) {
  return e.filter(Boolean).join(" ");
},
    p = function (r) {
  var t = r.color,
      n = r.left,
      o = r.top,
      a = void 0 === o ? .5 : o,
      l = g(["react-colorful__pointer", r.className]);
  return React__default.createElement("div", {
    className: l,
    style: {
      top: 100 * a + "%",
      left: 100 * n + "%"
    }
  }, React__default.createElement("div", {
    className: "react-colorful__pointer-fill",
    style: {
      backgroundColor: t
    }
  }));
},
    b = function (e, r, t) {
  return void 0 === r && (r = 0), void 0 === t && (t = Math.pow(10, r)), Math.round(t * e) / t;
},
    _ = {
  grad: .9,
  turn: 360,
  rad: 360 / (2 * Math.PI)
},
    x = function (e) {
  return "#" === e[0] && (e = e.substr(1)), e.length < 6 ? {
    r: parseInt(e[0] + e[0], 16),
    g: parseInt(e[1] + e[1], 16),
    b: parseInt(e[2] + e[2], 16),
    a: 1
  } : {
    r: parseInt(e.substr(0, 2), 16),
    g: parseInt(e.substr(2, 2), 16),
    b: parseInt(e.substr(4, 2), 16),
    a: 1
  };
},
    C = function (e, r) {
  return void 0 === r && (r = "deg"), Number(e) * (_[r] || 1);
},
    E = function (e) {
  var r = /hsla?\(?\s*(-?\d*\.?\d+)(deg|rad|grad|turn)?[,\s]+(-?\d*\.?\d+)%?[,\s]+(-?\d*\.?\d+)%?,?\s*[/\s]*(-?\d*\.?\d+)?(%)?\s*\)?/i.exec(e);
  return r ? M({
    h: C(r[1], r[2]),
    s: Number(r[3]),
    l: Number(r[4]),
    a: void 0 === r[5] ? 1 : Number(r[5]) / (r[6] ? 100 : 1)
  }) : {
    h: 0,
    s: 0,
    v: 0,
    a: 1
  };
},
    M = function (e) {
  var r = e.s,
      t = e.l;
  return {
    h: e.h,
    s: (r *= (t < 50 ? t : 100 - t) / 100) > 0 ? 2 * r / (t + r) * 100 : 0,
    v: t + r,
    a: e.a
  };
},
    N = function (e) {
  var r = e.s,
      t = e.v,
      n = e.a,
      o = (200 - r) * t / 100;
  return {
    h: b(e.h),
    s: b(o > 0 && o < 200 ? r * t / 100 / (o <= 100 ? o : 200 - o) * 100 : 0),
    l: b(o / 2),
    a: b(n, 2)
  };
},
    w = function (e) {
  var r = N(e);
  return "hsl(" + r.h + ", " + r.s + "%, " + r.l + "%)";
},
    y = function (e) {
  var r = N(e);
  return "hsla(" + r.h + ", " + r.s + "%, " + r.l + "%, " + r.a + ")";
},
    q = function (e) {
  var r = e.h,
      t = e.s,
      n = e.v,
      o = e.a;
  r = r / 360 * 6, t /= 100, n /= 100;
  var a = Math.floor(r),
      l = n * (1 - t),
      u = n * (1 - (r - a) * t),
      c = n * (1 - (1 - r + a) * t),
      i = a % 6;
  return {
    r: b(255 * [n, u, l, l, c, n][i]),
    g: b(255 * [c, n, n, u, l, l][i]),
    b: b(255 * [l, l, c, n, n, u][i]),
    a: b(o, 2)
  };
},
    I = function (e) {
  var r = /rgba?\(?\s*(-?\d*\.?\d+)(%)?[,\s]+(-?\d*\.?\d+)(%)?[,\s]+(-?\d*\.?\d+)(%)?,?\s*[/\s]*(-?\d*\.?\d+)?(%)?\s*\)?/i.exec(e);
  return r ? B({
    r: Number(r[1]) / (r[2] ? 100 / 255 : 1),
    g: Number(r[3]) / (r[4] ? 100 / 255 : 1),
    b: Number(r[5]) / (r[6] ? 100 / 255 : 1),
    a: void 0 === r[7] ? 1 : Number(r[7]) / (r[8] ? 100 : 1)
  }) : {
    h: 0,
    s: 0,
    v: 0,
    a: 1
  };
},
    z = function (e) {
  var r = e.toString(16);
  return r.length < 2 ? "0" + r : r;
},
    B = function (e) {
  var r = e.r,
      t = e.g,
      n = e.b,
      o = e.a,
      a = Math.max(r, t, n),
      l = a - Math.min(r, t, n),
      u = l ? a === r ? (t - n) / l : a === t ? 2 + (n - r) / l : 4 + (r - t) / l : 0;
  return {
    h: b(60 * (u < 0 ? u + 6 : u)),
    s: b(a ? l / a * 100 : 0),
    v: b(a / 255 * 100),
    a: o
  };
},
    K = React__default.memo(function (r) {
  var t = r.hue,
      n = r.onChange,
      o = g(["react-colorful__hue", r.className]);
  return React__default.createElement("div", {
    className: o
  }, React__default.createElement(m, {
    onMove: function (e) {
      n({
        h: 360 * e.left
      });
    },
    onKey: function (e) {
      n({
        h: s(t + 360 * e.left, 0, 360)
      });
    },
    "aria-label": "Hue",
    "aria-valuetext": b(t)
  }, React__default.createElement(p, {
    className: "react-colorful__hue-pointer",
    left: t / 360,
    color: w({
      h: t,
      s: 100,
      v: 100,
      a: 1
    })
  })));
}),
    L = React__default.memo(function (r) {
  var t = r.hsva,
      n = r.onChange,
      o = {
    backgroundColor: w({
      h: t.h,
      s: 100,
      v: 100,
      a: 1
    })
  };
  return React__default.createElement("div", {
    className: "react-colorful__saturation",
    style: o
  }, React__default.createElement(m, {
    onMove: function (e) {
      n({
        s: 100 * e.left,
        v: 100 - 100 * e.top
      });
    },
    onKey: function (e) {
      n({
        s: s(t.s + 100 * e.left, 0, 100),
        v: s(t.v - 100 * e.top, 0, 100)
      });
    },
    "aria-label": "Color",
    "aria-valuetext": "Saturation " + b(t.s) + "%, Brightness " + b(t.v) + "%"
  }, React__default.createElement(p, {
    className: "react-colorful__saturation-pointer",
    top: 1 - t.v / 100,
    left: t.s / 100,
    color: w(t)
  })));
}),
    A = function (e, r) {
  if (e === r) return !0;

  for (var t in e) if (e[t] !== r[t]) return !1;

  return !0;
},
    S = function (e, r) {
  return e.replace(/\s/g, "") === r.replace(/\s/g, "");
};

function T(e, t, l) {
  var u = i(l),
      c = useState(function () {
    return e.toHsva(t);
  }),
      s = c[0],
      f = c[1],
      v = useRef({
    color: t,
    hsva: s
  });
  useEffect(function () {
    if (!e.equal(t, v.current.color)) {
      var r = e.toHsva(t);
      v.current = {
        hsva: r,
        color: t
      }, f(r);
    }
  }, [t, e]), useEffect(function () {
    var r;
    A(s, v.current.hsva) || e.equal(r = e.fromHsva(s), v.current.color) || (v.current = {
      hsva: s,
      color: r
    }, u(r));
  }, [s, e, u]);
  var d = useCallback(function (e) {
    f(function (r) {
      return Object.assign({}, r, e);
    });
  }, []);
  return [s, d];
}

var P = "undefined" != typeof window ? useLayoutEffect : useEffect,
    X = function () {
  return "undefined" != typeof __webpack_nonce__ ? __webpack_nonce__ : void 0;
},
    R = new Map(),
    V = function (e) {
  P(function () {
    var r = e.current ? e.current.ownerDocument : document;

    if (void 0 !== r && !R.has(r)) {
      var t = r.createElement("style");
      t.innerHTML = '.react-colorful{position:relative;display:flex;flex-direction:column;width:200px;height:200px;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none;cursor:default}.react-colorful__saturation{position:relative;flex-grow:1;border-color:transparent;border-bottom:12px solid #000;border-radius:8px 8px 0 0;background-image:linear-gradient(0deg,#000,transparent),linear-gradient(90deg,#fff,hsla(0,0%,100%,0))}.react-colorful__alpha-gradient,.react-colorful__pointer-fill{content:"";position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none;border-radius:inherit}.react-colorful__alpha-gradient,.react-colorful__saturation{box-shadow:inset 0 0 0 1px rgba(0,0,0,.05)}.react-colorful__alpha,.react-colorful__hue{position:relative;height:24px}.react-colorful__hue{background:linear-gradient(90deg,red 0,#ff0 17%,#0f0 33%,#0ff 50%,#00f 67%,#f0f 83%,red)}.react-colorful__last-control{border-radius:0 0 8px 8px}.react-colorful__interactive{position:absolute;left:0;top:0;right:0;bottom:0;border-radius:inherit;outline:none;touch-action:none}.react-colorful__pointer{position:absolute;z-index:1;box-sizing:border-box;width:28px;height:28px;transform:translate(-50%,-50%);background-color:#fff;border:2px solid #fff;border-radius:50%;box-shadow:0 2px 4px rgba(0,0,0,.2)}.react-colorful__interactive:focus .react-colorful__pointer{transform:translate(-50%,-50%) scale(1.1)}.react-colorful__alpha,.react-colorful__alpha-pointer{background-color:#fff;background-image:url(\'data:image/svg+xml;charset=utf-8,<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill-opacity=".05"><path d="M8 0h8v8H8zM0 8h8v8H0z"/></svg>\')}.react-colorful__saturation-pointer{z-index:3}.react-colorful__hue-pointer{z-index:2}', R.set(r, t);
      var n = X();
      n && t.setAttribute("nonce", n), r.head.appendChild(t);
    }
  }, []);
},
    $ = function (t) {
  var n = t.className,
      o = t.colorModel,
      a = t.color,
      l = void 0 === a ? o.defaultColor : a,
      i = t.onChange,
      s = c(t, ["className", "colorModel", "color", "onChange"]),
      f = useRef(null);
  V(f);
  var v = T(o, l, i),
      d = v[0],
      h = v[1],
      m = g(["react-colorful", n]);
  return React__default.createElement("div", u({}, s, {
    ref: f,
    className: m
  }), React__default.createElement(L, {
    hsva: d,
    onChange: h
  }), React__default.createElement(K, {
    hue: d.h,
    onChange: h,
    className: "react-colorful__last-control"
  }));
},
    G = {
  defaultColor: "000",
  toHsva: function (e) {
    return B(x(e));
  },
  fromHsva: function (e) {
    return t = (r = q(e)).g, n = r.b, "#" + z(r.r) + z(t) + z(n);
    var r, t, n;
  },
  equal: function (e, r) {
    return e.toLowerCase() === r.toLowerCase() || A(x(e), x(r));
  }
},
    J = function (r) {
  return React__default.createElement($, u({}, r, {
    colorModel: G
  }));
},
    Q = function (r) {
  var t = r.className,
      n = r.hsva,
      o = r.onChange,
      a = {
    backgroundImage: "linear-gradient(90deg, " + y(Object.assign({}, n, {
      a: 0
    })) + ", " + y(Object.assign({}, n, {
      a: 1
    })) + ")"
  },
      l = g(["react-colorful__alpha", t]);
  return React__default.createElement("div", {
    className: l
  }, React__default.createElement("div", {
    className: "react-colorful__alpha-gradient",
    style: a
  }), React__default.createElement(m, {
    onMove: function (e) {
      o({
        a: e.left
      });
    },
    onKey: function (e) {
      o({
        a: s(n.a + e.left)
      });
    },
    "aria-label": "Alpha",
    "aria-valuetext": b(100 * n.a) + "%"
  }, React__default.createElement(p, {
    className: "react-colorful__alpha-pointer",
    left: n.a,
    color: y(n)
  })));
},
    U = function (t) {
  var n = t.className,
      o = t.colorModel,
      a = t.color,
      l = void 0 === a ? o.defaultColor : a,
      i = t.onChange,
      s = c(t, ["className", "colorModel", "color", "onChange"]),
      f = useRef(null);
  V(f);
  var v = T(o, l, i),
      d = v[0],
      h = v[1],
      m = g(["react-colorful", n]);
  return React__default.createElement("div", u({}, s, {
    ref: f,
    className: m
  }), React__default.createElement(L, {
    hsva: d,
    onChange: h
  }), React__default.createElement(K, {
    hue: d.h,
    onChange: h
  }), React__default.createElement(Q, {
    hsva: d,
    onChange: h,
    className: "react-colorful__last-control"
  }));
},
    ee = {
  defaultColor: "hsla(0, 0%, 0%, 1)",
  toHsva: E,
  fromHsva: y,
  equal: S
},
    re = function (r) {
  return React__default.createElement(U, u({}, r, {
    colorModel: ee
  }));
},
    ge = {
  defaultColor: "rgba(0, 0, 0, 1)",
  toHsva: I,
  fromHsva: function (e) {
    var r = q(e);
    return "rgba(" + r.r + ", " + r.g + ", " + r.b + ", " + r.a + ")";
  },
  equal: S
},
    pe = function (r) {
  return React__default.createElement(U, u({}, r, {
    colorModel: ge
  }));
};

var colorName = {
  "aliceblue": [240, 248, 255],
  "antiquewhite": [250, 235, 215],
  "aqua": [0, 255, 255],
  "aquamarine": [127, 255, 212],
  "azure": [240, 255, 255],
  "beige": [245, 245, 220],
  "bisque": [255, 228, 196],
  "black": [0, 0, 0],
  "blanchedalmond": [255, 235, 205],
  "blue": [0, 0, 255],
  "blueviolet": [138, 43, 226],
  "brown": [165, 42, 42],
  "burlywood": [222, 184, 135],
  "cadetblue": [95, 158, 160],
  "chartreuse": [127, 255, 0],
  "chocolate": [210, 105, 30],
  "coral": [255, 127, 80],
  "cornflowerblue": [100, 149, 237],
  "cornsilk": [255, 248, 220],
  "crimson": [220, 20, 60],
  "cyan": [0, 255, 255],
  "darkblue": [0, 0, 139],
  "darkcyan": [0, 139, 139],
  "darkgoldenrod": [184, 134, 11],
  "darkgray": [169, 169, 169],
  "darkgreen": [0, 100, 0],
  "darkgrey": [169, 169, 169],
  "darkkhaki": [189, 183, 107],
  "darkmagenta": [139, 0, 139],
  "darkolivegreen": [85, 107, 47],
  "darkorange": [255, 140, 0],
  "darkorchid": [153, 50, 204],
  "darkred": [139, 0, 0],
  "darksalmon": [233, 150, 122],
  "darkseagreen": [143, 188, 143],
  "darkslateblue": [72, 61, 139],
  "darkslategray": [47, 79, 79],
  "darkslategrey": [47, 79, 79],
  "darkturquoise": [0, 206, 209],
  "darkviolet": [148, 0, 211],
  "deeppink": [255, 20, 147],
  "deepskyblue": [0, 191, 255],
  "dimgray": [105, 105, 105],
  "dimgrey": [105, 105, 105],
  "dodgerblue": [30, 144, 255],
  "firebrick": [178, 34, 34],
  "floralwhite": [255, 250, 240],
  "forestgreen": [34, 139, 34],
  "fuchsia": [255, 0, 255],
  "gainsboro": [220, 220, 220],
  "ghostwhite": [248, 248, 255],
  "gold": [255, 215, 0],
  "goldenrod": [218, 165, 32],
  "gray": [128, 128, 128],
  "green": [0, 128, 0],
  "greenyellow": [173, 255, 47],
  "grey": [128, 128, 128],
  "honeydew": [240, 255, 240],
  "hotpink": [255, 105, 180],
  "indianred": [205, 92, 92],
  "indigo": [75, 0, 130],
  "ivory": [255, 255, 240],
  "khaki": [240, 230, 140],
  "lavender": [230, 230, 250],
  "lavenderblush": [255, 240, 245],
  "lawngreen": [124, 252, 0],
  "lemonchiffon": [255, 250, 205],
  "lightblue": [173, 216, 230],
  "lightcoral": [240, 128, 128],
  "lightcyan": [224, 255, 255],
  "lightgoldenrodyellow": [250, 250, 210],
  "lightgray": [211, 211, 211],
  "lightgreen": [144, 238, 144],
  "lightgrey": [211, 211, 211],
  "lightpink": [255, 182, 193],
  "lightsalmon": [255, 160, 122],
  "lightseagreen": [32, 178, 170],
  "lightskyblue": [135, 206, 250],
  "lightslategray": [119, 136, 153],
  "lightslategrey": [119, 136, 153],
  "lightsteelblue": [176, 196, 222],
  "lightyellow": [255, 255, 224],
  "lime": [0, 255, 0],
  "limegreen": [50, 205, 50],
  "linen": [250, 240, 230],
  "magenta": [255, 0, 255],
  "maroon": [128, 0, 0],
  "mediumaquamarine": [102, 205, 170],
  "mediumblue": [0, 0, 205],
  "mediumorchid": [186, 85, 211],
  "mediumpurple": [147, 112, 219],
  "mediumseagreen": [60, 179, 113],
  "mediumslateblue": [123, 104, 238],
  "mediumspringgreen": [0, 250, 154],
  "mediumturquoise": [72, 209, 204],
  "mediumvioletred": [199, 21, 133],
  "midnightblue": [25, 25, 112],
  "mintcream": [245, 255, 250],
  "mistyrose": [255, 228, 225],
  "moccasin": [255, 228, 181],
  "navajowhite": [255, 222, 173],
  "navy": [0, 0, 128],
  "oldlace": [253, 245, 230],
  "olive": [128, 128, 0],
  "olivedrab": [107, 142, 35],
  "orange": [255, 165, 0],
  "orangered": [255, 69, 0],
  "orchid": [218, 112, 214],
  "palegoldenrod": [238, 232, 170],
  "palegreen": [152, 251, 152],
  "paleturquoise": [175, 238, 238],
  "palevioletred": [219, 112, 147],
  "papayawhip": [255, 239, 213],
  "peachpuff": [255, 218, 185],
  "peru": [205, 133, 63],
  "pink": [255, 192, 203],
  "plum": [221, 160, 221],
  "powderblue": [176, 224, 230],
  "purple": [128, 0, 128],
  "rebeccapurple": [102, 51, 153],
  "red": [255, 0, 0],
  "rosybrown": [188, 143, 143],
  "royalblue": [65, 105, 225],
  "saddlebrown": [139, 69, 19],
  "salmon": [250, 128, 114],
  "sandybrown": [244, 164, 96],
  "seagreen": [46, 139, 87],
  "seashell": [255, 245, 238],
  "sienna": [160, 82, 45],
  "silver": [192, 192, 192],
  "skyblue": [135, 206, 235],
  "slateblue": [106, 90, 205],
  "slategray": [112, 128, 144],
  "slategrey": [112, 128, 144],
  "snow": [255, 250, 250],
  "springgreen": [0, 255, 127],
  "steelblue": [70, 130, 180],
  "tan": [210, 180, 140],
  "teal": [0, 128, 128],
  "thistle": [216, 191, 216],
  "tomato": [255, 99, 71],
  "turquoise": [64, 224, 208],
  "violet": [238, 130, 238],
  "wheat": [245, 222, 179],
  "white": [255, 255, 255],
  "whitesmoke": [245, 245, 245],
  "yellow": [255, 255, 0],
  "yellowgreen": [154, 205, 50]
};
/* MIT license */

/* eslint-disable no-mixed-operators */

const cssKeywords = colorName; // NOTE: conversions should only return primitive values (i.e. arrays, or
//       values that give correct `typeof` results).
//       do not use box values types (i.e. Number(), String(), etc.)

const reverseKeywords = {};

for (const key of Object.keys(cssKeywords)) {
  reverseKeywords[cssKeywords[key]] = key;
}

const convert$1 = {
  rgb: {
    channels: 3,
    labels: 'rgb'
  },
  hsl: {
    channels: 3,
    labels: 'hsl'
  },
  hsv: {
    channels: 3,
    labels: 'hsv'
  },
  hwb: {
    channels: 3,
    labels: 'hwb'
  },
  cmyk: {
    channels: 4,
    labels: 'cmyk'
  },
  xyz: {
    channels: 3,
    labels: 'xyz'
  },
  lab: {
    channels: 3,
    labels: 'lab'
  },
  lch: {
    channels: 3,
    labels: 'lch'
  },
  hex: {
    channels: 1,
    labels: ['hex']
  },
  keyword: {
    channels: 1,
    labels: ['keyword']
  },
  ansi16: {
    channels: 1,
    labels: ['ansi16']
  },
  ansi256: {
    channels: 1,
    labels: ['ansi256']
  },
  hcg: {
    channels: 3,
    labels: ['h', 'c', 'g']
  },
  apple: {
    channels: 3,
    labels: ['r16', 'g16', 'b16']
  },
  gray: {
    channels: 1,
    labels: ['gray']
  }
};
var conversions$2 = convert$1; // Hide .channels and .labels properties

for (const model of Object.keys(convert$1)) {
  if (!('channels' in convert$1[model])) {
    throw new Error('missing channels property: ' + model);
  }

  if (!('labels' in convert$1[model])) {
    throw new Error('missing channel labels property: ' + model);
  }

  if (convert$1[model].labels.length !== convert$1[model].channels) {
    throw new Error('channel and label counts mismatch: ' + model);
  }

  const {
    channels,
    labels
  } = convert$1[model];
  delete convert$1[model].channels;
  delete convert$1[model].labels;
  Object.defineProperty(convert$1[model], 'channels', {
    value: channels
  });
  Object.defineProperty(convert$1[model], 'labels', {
    value: labels
  });
}

convert$1.rgb.hsl = function (rgb) {
  const r = rgb[0] / 255;
  const g = rgb[1] / 255;
  const b = rgb[2] / 255;
  const min = Math.min(r, g, b);
  const max = Math.max(r, g, b);
  const delta = max - min;
  let h;
  let s;

  if (max === min) {
    h = 0;
  } else if (r === max) {
    h = (g - b) / delta;
  } else if (g === max) {
    h = 2 + (b - r) / delta;
  } else if (b === max) {
    h = 4 + (r - g) / delta;
  }

  h = Math.min(h * 60, 360);

  if (h < 0) {
    h += 360;
  }

  const l = (min + max) / 2;

  if (max === min) {
    s = 0;
  } else if (l <= 0.5) {
    s = delta / (max + min);
  } else {
    s = delta / (2 - max - min);
  }

  return [h, s * 100, l * 100];
};

convert$1.rgb.hsv = function (rgb) {
  let rdif;
  let gdif;
  let bdif;
  let h;
  let s;
  const r = rgb[0] / 255;
  const g = rgb[1] / 255;
  const b = rgb[2] / 255;
  const v = Math.max(r, g, b);
  const diff = v - Math.min(r, g, b);

  const diffc = function (c) {
    return (v - c) / 6 / diff + 1 / 2;
  };

  if (diff === 0) {
    h = 0;
    s = 0;
  } else {
    s = diff / v;
    rdif = diffc(r);
    gdif = diffc(g);
    bdif = diffc(b);

    if (r === v) {
      h = bdif - gdif;
    } else if (g === v) {
      h = 1 / 3 + rdif - bdif;
    } else if (b === v) {
      h = 2 / 3 + gdif - rdif;
    }

    if (h < 0) {
      h += 1;
    } else if (h > 1) {
      h -= 1;
    }
  }

  return [h * 360, s * 100, v * 100];
};

convert$1.rgb.hwb = function (rgb) {
  const r = rgb[0];
  const g = rgb[1];
  let b = rgb[2];
  const h = convert$1.rgb.hsl(rgb)[0];
  const w = 1 / 255 * Math.min(r, Math.min(g, b));
  b = 1 - 1 / 255 * Math.max(r, Math.max(g, b));
  return [h, w * 100, b * 100];
};

convert$1.rgb.cmyk = function (rgb) {
  const r = rgb[0] / 255;
  const g = rgb[1] / 255;
  const b = rgb[2] / 255;
  const k = Math.min(1 - r, 1 - g, 1 - b);
  const c = (1 - r - k) / (1 - k) || 0;
  const m = (1 - g - k) / (1 - k) || 0;
  const y = (1 - b - k) / (1 - k) || 0;
  return [c * 100, m * 100, y * 100, k * 100];
};

function comparativeDistance(x, y) {
  /*
  	See https://en.m.wikipedia.org/wiki/Euclidean_distance#Squared_Euclidean_distance
  */
  return (x[0] - y[0]) ** 2 + (x[1] - y[1]) ** 2 + (x[2] - y[2]) ** 2;
}

convert$1.rgb.keyword = function (rgb) {
  const reversed = reverseKeywords[rgb];

  if (reversed) {
    return reversed;
  }

  let currentClosestDistance = Infinity;
  let currentClosestKeyword;

  for (const keyword of Object.keys(cssKeywords)) {
    const value = cssKeywords[keyword]; // Compute comparative distance

    const distance = comparativeDistance(rgb, value); // Check if its less, if so set as closest

    if (distance < currentClosestDistance) {
      currentClosestDistance = distance;
      currentClosestKeyword = keyword;
    }
  }

  return currentClosestKeyword;
};

convert$1.keyword.rgb = function (keyword) {
  return cssKeywords[keyword];
};

convert$1.rgb.xyz = function (rgb) {
  let r = rgb[0] / 255;
  let g = rgb[1] / 255;
  let b = rgb[2] / 255; // Assume sRGB

  r = r > 0.04045 ? ((r + 0.055) / 1.055) ** 2.4 : r / 12.92;
  g = g > 0.04045 ? ((g + 0.055) / 1.055) ** 2.4 : g / 12.92;
  b = b > 0.04045 ? ((b + 0.055) / 1.055) ** 2.4 : b / 12.92;
  const x = r * 0.4124 + g * 0.3576 + b * 0.1805;
  const y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  const z = r * 0.0193 + g * 0.1192 + b * 0.9505;
  return [x * 100, y * 100, z * 100];
};

convert$1.rgb.lab = function (rgb) {
  const xyz = convert$1.rgb.xyz(rgb);
  let x = xyz[0];
  let y = xyz[1];
  let z = xyz[2];
  x /= 95.047;
  y /= 100;
  z /= 108.883;
  x = x > 0.008856 ? x ** (1 / 3) : 7.787 * x + 16 / 116;
  y = y > 0.008856 ? y ** (1 / 3) : 7.787 * y + 16 / 116;
  z = z > 0.008856 ? z ** (1 / 3) : 7.787 * z + 16 / 116;
  const l = 116 * y - 16;
  const a = 500 * (x - y);
  const b = 200 * (y - z);
  return [l, a, b];
};

convert$1.hsl.rgb = function (hsl) {
  const h = hsl[0] / 360;
  const s = hsl[1] / 100;
  const l = hsl[2] / 100;
  let t2;
  let t3;
  let val;

  if (s === 0) {
    val = l * 255;
    return [val, val, val];
  }

  if (l < 0.5) {
    t2 = l * (1 + s);
  } else {
    t2 = l + s - l * s;
  }

  const t1 = 2 * l - t2;
  const rgb = [0, 0, 0];

  for (let i = 0; i < 3; i++) {
    t3 = h + 1 / 3 * -(i - 1);

    if (t3 < 0) {
      t3++;
    }

    if (t3 > 1) {
      t3--;
    }

    if (6 * t3 < 1) {
      val = t1 + (t2 - t1) * 6 * t3;
    } else if (2 * t3 < 1) {
      val = t2;
    } else if (3 * t3 < 2) {
      val = t1 + (t2 - t1) * (2 / 3 - t3) * 6;
    } else {
      val = t1;
    }

    rgb[i] = val * 255;
  }

  return rgb;
};

convert$1.hsl.hsv = function (hsl) {
  const h = hsl[0];
  let s = hsl[1] / 100;
  let l = hsl[2] / 100;
  let smin = s;
  const lmin = Math.max(l, 0.01);
  l *= 2;
  s *= l <= 1 ? l : 2 - l;
  smin *= lmin <= 1 ? lmin : 2 - lmin;
  const v = (l + s) / 2;
  const sv = l === 0 ? 2 * smin / (lmin + smin) : 2 * s / (l + s);
  return [h, sv * 100, v * 100];
};

convert$1.hsv.rgb = function (hsv) {
  const h = hsv[0] / 60;
  const s = hsv[1] / 100;
  let v = hsv[2] / 100;
  const hi = Math.floor(h) % 6;
  const f = h - Math.floor(h);
  const p = 255 * v * (1 - s);
  const q = 255 * v * (1 - s * f);
  const t = 255 * v * (1 - s * (1 - f));
  v *= 255;

  switch (hi) {
    case 0:
      return [v, t, p];

    case 1:
      return [q, v, p];

    case 2:
      return [p, v, t];

    case 3:
      return [p, q, v];

    case 4:
      return [t, p, v];

    case 5:
      return [v, p, q];
  }
};

convert$1.hsv.hsl = function (hsv) {
  const h = hsv[0];
  const s = hsv[1] / 100;
  const v = hsv[2] / 100;
  const vmin = Math.max(v, 0.01);
  let sl;
  let l;
  l = (2 - s) * v;
  const lmin = (2 - s) * vmin;
  sl = s * vmin;
  sl /= lmin <= 1 ? lmin : 2 - lmin;
  sl = sl || 0;
  l /= 2;
  return [h, sl * 100, l * 100];
}; // http://dev.w3.org/csswg/css-color/#hwb-to-rgb


convert$1.hwb.rgb = function (hwb) {
  const h = hwb[0] / 360;
  let wh = hwb[1] / 100;
  let bl = hwb[2] / 100;
  const ratio = wh + bl;
  let f; // Wh + bl cant be > 1

  if (ratio > 1) {
    wh /= ratio;
    bl /= ratio;
  }

  const i = Math.floor(6 * h);
  const v = 1 - bl;
  f = 6 * h - i;

  if ((i & 0x01) !== 0) {
    f = 1 - f;
  }

  const n = wh + f * (v - wh); // Linear interpolation

  let r;
  let g;
  let b;
  /* eslint-disable max-statements-per-line,no-multi-spaces */

  switch (i) {
    default:
    case 6:
    case 0:
      r = v;
      g = n;
      b = wh;
      break;

    case 1:
      r = n;
      g = v;
      b = wh;
      break;

    case 2:
      r = wh;
      g = v;
      b = n;
      break;

    case 3:
      r = wh;
      g = n;
      b = v;
      break;

    case 4:
      r = n;
      g = wh;
      b = v;
      break;

    case 5:
      r = v;
      g = wh;
      b = n;
      break;
  }
  /* eslint-enable max-statements-per-line,no-multi-spaces */


  return [r * 255, g * 255, b * 255];
};

convert$1.cmyk.rgb = function (cmyk) {
  const c = cmyk[0] / 100;
  const m = cmyk[1] / 100;
  const y = cmyk[2] / 100;
  const k = cmyk[3] / 100;
  const r = 1 - Math.min(1, c * (1 - k) + k);
  const g = 1 - Math.min(1, m * (1 - k) + k);
  const b = 1 - Math.min(1, y * (1 - k) + k);
  return [r * 255, g * 255, b * 255];
};

convert$1.xyz.rgb = function (xyz) {
  const x = xyz[0] / 100;
  const y = xyz[1] / 100;
  const z = xyz[2] / 100;
  let r;
  let g;
  let b;
  r = x * 3.2406 + y * -1.5372 + z * -0.4986;
  g = x * -0.9689 + y * 1.8758 + z * 0.0415;
  b = x * 0.0557 + y * -0.2040 + z * 1.0570; // Assume sRGB

  r = r > 0.0031308 ? 1.055 * r ** (1.0 / 2.4) - 0.055 : r * 12.92;
  g = g > 0.0031308 ? 1.055 * g ** (1.0 / 2.4) - 0.055 : g * 12.92;
  b = b > 0.0031308 ? 1.055 * b ** (1.0 / 2.4) - 0.055 : b * 12.92;
  r = Math.min(Math.max(0, r), 1);
  g = Math.min(Math.max(0, g), 1);
  b = Math.min(Math.max(0, b), 1);
  return [r * 255, g * 255, b * 255];
};

convert$1.xyz.lab = function (xyz) {
  let x = xyz[0];
  let y = xyz[1];
  let z = xyz[2];
  x /= 95.047;
  y /= 100;
  z /= 108.883;
  x = x > 0.008856 ? x ** (1 / 3) : 7.787 * x + 16 / 116;
  y = y > 0.008856 ? y ** (1 / 3) : 7.787 * y + 16 / 116;
  z = z > 0.008856 ? z ** (1 / 3) : 7.787 * z + 16 / 116;
  const l = 116 * y - 16;
  const a = 500 * (x - y);
  const b = 200 * (y - z);
  return [l, a, b];
};

convert$1.lab.xyz = function (lab) {
  const l = lab[0];
  const a = lab[1];
  const b = lab[2];
  let x;
  let y;
  let z;
  y = (l + 16) / 116;
  x = a / 500 + y;
  z = y - b / 200;
  const y2 = y ** 3;
  const x2 = x ** 3;
  const z2 = z ** 3;
  y = y2 > 0.008856 ? y2 : (y - 16 / 116) / 7.787;
  x = x2 > 0.008856 ? x2 : (x - 16 / 116) / 7.787;
  z = z2 > 0.008856 ? z2 : (z - 16 / 116) / 7.787;
  x *= 95.047;
  y *= 100;
  z *= 108.883;
  return [x, y, z];
};

convert$1.lab.lch = function (lab) {
  const l = lab[0];
  const a = lab[1];
  const b = lab[2];
  let h;
  const hr = Math.atan2(b, a);
  h = hr * 360 / 2 / Math.PI;

  if (h < 0) {
    h += 360;
  }

  const c = Math.sqrt(a * a + b * b);
  return [l, c, h];
};

convert$1.lch.lab = function (lch) {
  const l = lch[0];
  const c = lch[1];
  const h = lch[2];
  const hr = h / 360 * 2 * Math.PI;
  const a = c * Math.cos(hr);
  const b = c * Math.sin(hr);
  return [l, a, b];
};

convert$1.rgb.ansi16 = function (args, saturation = null) {
  const [r, g, b] = args;
  let value = saturation === null ? convert$1.rgb.hsv(args)[2] : saturation; // Hsv -> ansi16 optimization

  value = Math.round(value / 50);

  if (value === 0) {
    return 30;
  }

  let ansi = 30 + (Math.round(b / 255) << 2 | Math.round(g / 255) << 1 | Math.round(r / 255));

  if (value === 2) {
    ansi += 60;
  }

  return ansi;
};

convert$1.hsv.ansi16 = function (args) {
  // Optimization here; we already know the value and don't need to get
  // it converted for us.
  return convert$1.rgb.ansi16(convert$1.hsv.rgb(args), args[2]);
};

convert$1.rgb.ansi256 = function (args) {
  const r = args[0];
  const g = args[1];
  const b = args[2]; // We use the extended greyscale palette here, with the exception of
  // black and white. normal palette only has 4 greyscale shades.

  if (r === g && g === b) {
    if (r < 8) {
      return 16;
    }

    if (r > 248) {
      return 231;
    }

    return Math.round((r - 8) / 247 * 24) + 232;
  }

  const ansi = 16 + 36 * Math.round(r / 255 * 5) + 6 * Math.round(g / 255 * 5) + Math.round(b / 255 * 5);
  return ansi;
};

convert$1.ansi16.rgb = function (args) {
  let color = args % 10; // Handle greyscale

  if (color === 0 || color === 7) {
    if (args > 50) {
      color += 3.5;
    }

    color = color / 10.5 * 255;
    return [color, color, color];
  }

  const mult = (~~(args > 50) + 1) * 0.5;
  const r = (color & 1) * mult * 255;
  const g = (color >> 1 & 1) * mult * 255;
  const b = (color >> 2 & 1) * mult * 255;
  return [r, g, b];
};

convert$1.ansi256.rgb = function (args) {
  // Handle greyscale
  if (args >= 232) {
    const c = (args - 232) * 10 + 8;
    return [c, c, c];
  }

  args -= 16;
  let rem;
  const r = Math.floor(args / 36) / 5 * 255;
  const g = Math.floor((rem = args % 36) / 6) / 5 * 255;
  const b = rem % 6 / 5 * 255;
  return [r, g, b];
};

convert$1.rgb.hex = function (args) {
  const integer = ((Math.round(args[0]) & 0xFF) << 16) + ((Math.round(args[1]) & 0xFF) << 8) + (Math.round(args[2]) & 0xFF);
  const string = integer.toString(16).toUpperCase();
  return '000000'.substring(string.length) + string;
};

convert$1.hex.rgb = function (args) {
  const match = args.toString(16).match(/[a-f0-9]{6}|[a-f0-9]{3}/i);

  if (!match) {
    return [0, 0, 0];
  }

  let colorString = match[0];

  if (match[0].length === 3) {
    colorString = colorString.split('').map(char => {
      return char + char;
    }).join('');
  }

  const integer = parseInt(colorString, 16);
  const r = integer >> 16 & 0xFF;
  const g = integer >> 8 & 0xFF;
  const b = integer & 0xFF;
  return [r, g, b];
};

convert$1.rgb.hcg = function (rgb) {
  const r = rgb[0] / 255;
  const g = rgb[1] / 255;
  const b = rgb[2] / 255;
  const max = Math.max(Math.max(r, g), b);
  const min = Math.min(Math.min(r, g), b);
  const chroma = max - min;
  let grayscale;
  let hue;

  if (chroma < 1) {
    grayscale = min / (1 - chroma);
  } else {
    grayscale = 0;
  }

  if (chroma <= 0) {
    hue = 0;
  } else if (max === r) {
    hue = (g - b) / chroma % 6;
  } else if (max === g) {
    hue = 2 + (b - r) / chroma;
  } else {
    hue = 4 + (r - g) / chroma;
  }

  hue /= 6;
  hue %= 1;
  return [hue * 360, chroma * 100, grayscale * 100];
};

convert$1.hsl.hcg = function (hsl) {
  const s = hsl[1] / 100;
  const l = hsl[2] / 100;
  const c = l < 0.5 ? 2.0 * s * l : 2.0 * s * (1.0 - l);
  let f = 0;

  if (c < 1.0) {
    f = (l - 0.5 * c) / (1.0 - c);
  }

  return [hsl[0], c * 100, f * 100];
};

convert$1.hsv.hcg = function (hsv) {
  const s = hsv[1] / 100;
  const v = hsv[2] / 100;
  const c = s * v;
  let f = 0;

  if (c < 1.0) {
    f = (v - c) / (1 - c);
  }

  return [hsv[0], c * 100, f * 100];
};

convert$1.hcg.rgb = function (hcg) {
  const h = hcg[0] / 360;
  const c = hcg[1] / 100;
  const g = hcg[2] / 100;

  if (c === 0.0) {
    return [g * 255, g * 255, g * 255];
  }

  const pure = [0, 0, 0];
  const hi = h % 1 * 6;
  const v = hi % 1;
  const w = 1 - v;
  let mg = 0;
  /* eslint-disable max-statements-per-line */

  switch (Math.floor(hi)) {
    case 0:
      pure[0] = 1;
      pure[1] = v;
      pure[2] = 0;
      break;

    case 1:
      pure[0] = w;
      pure[1] = 1;
      pure[2] = 0;
      break;

    case 2:
      pure[0] = 0;
      pure[1] = 1;
      pure[2] = v;
      break;

    case 3:
      pure[0] = 0;
      pure[1] = w;
      pure[2] = 1;
      break;

    case 4:
      pure[0] = v;
      pure[1] = 0;
      pure[2] = 1;
      break;

    default:
      pure[0] = 1;
      pure[1] = 0;
      pure[2] = w;
  }
  /* eslint-enable max-statements-per-line */


  mg = (1.0 - c) * g;
  return [(c * pure[0] + mg) * 255, (c * pure[1] + mg) * 255, (c * pure[2] + mg) * 255];
};

convert$1.hcg.hsv = function (hcg) {
  const c = hcg[1] / 100;
  const g = hcg[2] / 100;
  const v = c + g * (1.0 - c);
  let f = 0;

  if (v > 0.0) {
    f = c / v;
  }

  return [hcg[0], f * 100, v * 100];
};

convert$1.hcg.hsl = function (hcg) {
  const c = hcg[1] / 100;
  const g = hcg[2] / 100;
  const l = g * (1.0 - c) + 0.5 * c;
  let s = 0;

  if (l > 0.0 && l < 0.5) {
    s = c / (2 * l);
  } else if (l >= 0.5 && l < 1.0) {
    s = c / (2 * (1 - l));
  }

  return [hcg[0], s * 100, l * 100];
};

convert$1.hcg.hwb = function (hcg) {
  const c = hcg[1] / 100;
  const g = hcg[2] / 100;
  const v = c + g * (1.0 - c);
  return [hcg[0], (v - c) * 100, (1 - v) * 100];
};

convert$1.hwb.hcg = function (hwb) {
  const w = hwb[1] / 100;
  const b = hwb[2] / 100;
  const v = 1 - b;
  const c = v - w;
  let g = 0;

  if (c < 1) {
    g = (v - c) / (1 - c);
  }

  return [hwb[0], c * 100, g * 100];
};

convert$1.apple.rgb = function (apple) {
  return [apple[0] / 65535 * 255, apple[1] / 65535 * 255, apple[2] / 65535 * 255];
};

convert$1.rgb.apple = function (rgb) {
  return [rgb[0] / 255 * 65535, rgb[1] / 255 * 65535, rgb[2] / 255 * 65535];
};

convert$1.gray.rgb = function (args) {
  return [args[0] / 100 * 255, args[0] / 100 * 255, args[0] / 100 * 255];
};

convert$1.gray.hsl = function (args) {
  return [0, 0, args[0]];
};

convert$1.gray.hsv = convert$1.gray.hsl;

convert$1.gray.hwb = function (gray) {
  return [0, 100, gray[0]];
};

convert$1.gray.cmyk = function (gray) {
  return [0, 0, 0, gray[0]];
};

convert$1.gray.lab = function (gray) {
  return [gray[0], 0, 0];
};

convert$1.gray.hex = function (gray) {
  const val = Math.round(gray[0] / 100 * 255) & 0xFF;
  const integer = (val << 16) + (val << 8) + val;
  const string = integer.toString(16).toUpperCase();
  return '000000'.substring(string.length) + string;
};

convert$1.rgb.gray = function (rgb) {
  const val = (rgb[0] + rgb[1] + rgb[2]) / 3;
  return [val / 255 * 100];
};

const conversions$1 = conversions$2;
/*
	This function routes a model to all other models.

	all functions that are routed have a property `.conversion` attached
	to the returned synthetic function. This property is an array
	of strings, each with the steps in between the 'from' and 'to'
	color models (inclusive).

	conversions that are not possible simply are not included.
*/

function buildGraph() {
  const graph = {}; // https://jsperf.com/object-keys-vs-for-in-with-closure/3

  const models = Object.keys(conversions$1);

  for (let len = models.length, i = 0; i < len; i++) {
    graph[models[i]] = {
      // http://jsperf.com/1-vs-infinity
      // micro-opt, but this is simple.
      distance: -1,
      parent: null
    };
  }

  return graph;
} // https://en.wikipedia.org/wiki/Breadth-first_search


function deriveBFS(fromModel) {
  const graph = buildGraph();
  const queue = [fromModel]; // Unshift -> queue -> pop

  graph[fromModel].distance = 0;

  while (queue.length) {
    const current = queue.pop();
    const adjacents = Object.keys(conversions$1[current]);

    for (let len = adjacents.length, i = 0; i < len; i++) {
      const adjacent = adjacents[i];
      const node = graph[adjacent];

      if (node.distance === -1) {
        node.distance = graph[current].distance + 1;
        node.parent = current;
        queue.unshift(adjacent);
      }
    }
  }

  return graph;
}

function link(from, to) {
  return function (args) {
    return to(from(args));
  };
}

function wrapConversion(toModel, graph) {
  const path = [graph[toModel].parent, toModel];
  let fn = conversions$1[graph[toModel].parent][toModel];
  let cur = graph[toModel].parent;

  while (graph[cur].parent) {
    path.unshift(graph[cur].parent);
    fn = link(conversions$1[graph[cur].parent][cur], fn);
    cur = graph[cur].parent;
  }

  fn.conversion = path;
  return fn;
}

var route$1 = function (fromModel) {
  const graph = deriveBFS(fromModel);
  const conversion = {};
  const models = Object.keys(graph);

  for (let len = models.length, i = 0; i < len; i++) {
    const toModel = models[i];
    const node = graph[toModel];

    if (node.parent === null) {
      // No possible conversion, or this node is the source model.
      continue;
    }

    conversion[toModel] = wrapConversion(toModel, graph);
  }

  return conversion;
};

const conversions = conversions$2;
const route = route$1;
const convert = {};
const models = Object.keys(conversions);

function wrapRaw(fn) {
  const wrappedFn = function (...args) {
    const arg0 = args[0];

    if (arg0 === undefined || arg0 === null) {
      return arg0;
    }

    if (arg0.length > 1) {
      args = arg0;
    }

    return fn(args);
  }; // Preserve .conversion property if there is one


  if ('conversion' in fn) {
    wrappedFn.conversion = fn.conversion;
  }

  return wrappedFn;
}

function wrapRounded(fn) {
  const wrappedFn = function (...args) {
    const arg0 = args[0];

    if (arg0 === undefined || arg0 === null) {
      return arg0;
    }

    if (arg0.length > 1) {
      args = arg0;
    }

    const result = fn(args); // We're assuming the result is an array here.
    // see notice in conversions.js; don't use box types
    // in conversion functions.

    if (typeof result === 'object') {
      for (let len = result.length, i = 0; i < len; i++) {
        result[i] = Math.round(result[i]);
      }
    }

    return result;
  }; // Preserve .conversion property if there is one


  if ('conversion' in fn) {
    wrappedFn.conversion = fn.conversion;
  }

  return wrappedFn;
}

models.forEach(fromModel => {
  convert[fromModel] = {};
  Object.defineProperty(convert[fromModel], 'channels', {
    value: conversions[fromModel].channels
  });
  Object.defineProperty(convert[fromModel], 'labels', {
    value: conversions[fromModel].labels
  });
  const routes = route(fromModel);
  const routeModels = Object.keys(routes);
  routeModels.forEach(toModel => {
    const fn = routes[toModel];
    convert[fromModel][toModel] = wrapRounded(fn);
    convert[fromModel][toModel].raw = wrapRaw(fn);
  });
});
var colorConvert = convert;
var root = _root;
/**
 * Gets the timestamp of the number of milliseconds that have elapsed since
 * the Unix epoch (1 January 1970 00:00:00 UTC).
 *
 * @static
 * @memberOf _
 * @since 2.4.0
 * @category Date
 * @returns {number} Returns the timestamp.
 * @example
 *
 * _.defer(function(stamp) {
 *   console.log(_.now() - stamp);
 * }, _.now());
 * // => Logs the number of milliseconds it took for the deferred invocation.
 */

var now$1 = function () {
  return root.Date.now();
};

var now_1 = now$1;
/** Used to match a single whitespace character. */

var reWhitespace = /\s/;
/**
 * Used by `_.trim` and `_.trimEnd` to get the index of the last non-whitespace
 * character of `string`.
 *
 * @private
 * @param {string} string The string to inspect.
 * @returns {number} Returns the index of the last non-whitespace character.
 */

function trimmedEndIndex$1(string) {
  var index = string.length;

  while (index-- && reWhitespace.test(string.charAt(index))) {}

  return index;
}

var _trimmedEndIndex = trimmedEndIndex$1;
var trimmedEndIndex = _trimmedEndIndex;
/** Used to match leading whitespace. */

var reTrimStart = /^\s+/;
/**
 * The base implementation of `_.trim`.
 *
 * @private
 * @param {string} string The string to trim.
 * @returns {string} Returns the trimmed string.
 */

function baseTrim$1(string) {
  return string ? string.slice(0, trimmedEndIndex(string) + 1).replace(reTrimStart, '') : string;
}

var _baseTrim = baseTrim$1;
var baseTrim = _baseTrim,
    isObject$2 = isObject_1,
    isSymbol = isSymbol_1;
/** Used as references for various `Number` constants. */

var NAN = 0 / 0;
/** Used to detect bad signed hexadecimal string values. */

var reIsBadHex = /^[-+]0x[0-9a-f]+$/i;
/** Used to detect binary string values. */

var reIsBinary = /^0b[01]+$/i;
/** Used to detect octal string values. */

var reIsOctal = /^0o[0-7]+$/i;
/** Built-in method references without a dependency on `root`. */

var freeParseInt = parseInt;
/**
 * Converts `value` to a number.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to process.
 * @returns {number} Returns the number.
 * @example
 *
 * _.toNumber(3.2);
 * // => 3.2
 *
 * _.toNumber(Number.MIN_VALUE);
 * // => 5e-324
 *
 * _.toNumber(Infinity);
 * // => Infinity
 *
 * _.toNumber('3.2');
 * // => 3.2
 */

function toNumber$1(value) {
  if (typeof value == 'number') {
    return value;
  }

  if (isSymbol(value)) {
    return NAN;
  }

  if (isObject$2(value)) {
    var other = typeof value.valueOf == 'function' ? value.valueOf() : value;
    value = isObject$2(other) ? other + '' : other;
  }

  if (typeof value != 'string') {
    return value === 0 ? value : +value;
  }

  value = baseTrim(value);
  var isBinary = reIsBinary.test(value);
  return isBinary || reIsOctal.test(value) ? freeParseInt(value.slice(2), isBinary ? 2 : 8) : reIsBadHex.test(value) ? NAN : +value;
}

var toNumber_1 = toNumber$1;
var isObject$1 = isObject_1,
    now = now_1,
    toNumber = toNumber_1;
/** Error message constants. */

var FUNC_ERROR_TEXT$1 = 'Expected a function';
/* Built-in method references for those with the same name as other `lodash` methods. */

var nativeMax = Math.max,
    nativeMin = Math.min;
/**
 * Creates a debounced function that delays invoking `func` until after `wait`
 * milliseconds have elapsed since the last time the debounced function was
 * invoked. The debounced function comes with a `cancel` method to cancel
 * delayed `func` invocations and a `flush` method to immediately invoke them.
 * Provide `options` to indicate whether `func` should be invoked on the
 * leading and/or trailing edge of the `wait` timeout. The `func` is invoked
 * with the last arguments provided to the debounced function. Subsequent
 * calls to the debounced function return the result of the last `func`
 * invocation.
 *
 * **Note:** If `leading` and `trailing` options are `true`, `func` is
 * invoked on the trailing edge of the timeout only if the debounced function
 * is invoked more than once during the `wait` timeout.
 *
 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
 *
 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
 * for details over the differences between `_.debounce` and `_.throttle`.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Function
 * @param {Function} func The function to debounce.
 * @param {number} [wait=0] The number of milliseconds to delay.
 * @param {Object} [options={}] The options object.
 * @param {boolean} [options.leading=false]
 *  Specify invoking on the leading edge of the timeout.
 * @param {number} [options.maxWait]
 *  The maximum time `func` is allowed to be delayed before it's invoked.
 * @param {boolean} [options.trailing=true]
 *  Specify invoking on the trailing edge of the timeout.
 * @returns {Function} Returns the new debounced function.
 * @example
 *
 * // Avoid costly calculations while the window size is in flux.
 * jQuery(window).on('resize', _.debounce(calculateLayout, 150));
 *
 * // Invoke `sendMail` when clicked, debouncing subsequent calls.
 * jQuery(element).on('click', _.debounce(sendMail, 300, {
 *   'leading': true,
 *   'trailing': false
 * }));
 *
 * // Ensure `batchLog` is invoked once after 1 second of debounced calls.
 * var debounced = _.debounce(batchLog, 250, { 'maxWait': 1000 });
 * var source = new EventSource('/stream');
 * jQuery(source).on('message', debounced);
 *
 * // Cancel the trailing debounced invocation.
 * jQuery(window).on('popstate', debounced.cancel);
 */

function debounce$1(func, wait, options) {
  var lastArgs,
      lastThis,
      maxWait,
      result,
      timerId,
      lastCallTime,
      lastInvokeTime = 0,
      leading = false,
      maxing = false,
      trailing = true;

  if (typeof func != 'function') {
    throw new TypeError(FUNC_ERROR_TEXT$1);
  }

  wait = toNumber(wait) || 0;

  if (isObject$1(options)) {
    leading = !!options.leading;
    maxing = 'maxWait' in options;
    maxWait = maxing ? nativeMax(toNumber(options.maxWait) || 0, wait) : maxWait;
    trailing = 'trailing' in options ? !!options.trailing : trailing;
  }

  function invokeFunc(time) {
    var args = lastArgs,
        thisArg = lastThis;
    lastArgs = lastThis = undefined;
    lastInvokeTime = time;
    result = func.apply(thisArg, args);
    return result;
  }

  function leadingEdge(time) {
    // Reset any `maxWait` timer.
    lastInvokeTime = time; // Start the timer for the trailing edge.

    timerId = setTimeout(timerExpired, wait); // Invoke the leading edge.

    return leading ? invokeFunc(time) : result;
  }

  function remainingWait(time) {
    var timeSinceLastCall = time - lastCallTime,
        timeSinceLastInvoke = time - lastInvokeTime,
        timeWaiting = wait - timeSinceLastCall;
    return maxing ? nativeMin(timeWaiting, maxWait - timeSinceLastInvoke) : timeWaiting;
  }

  function shouldInvoke(time) {
    var timeSinceLastCall = time - lastCallTime,
        timeSinceLastInvoke = time - lastInvokeTime; // Either this is the first call, activity has stopped and we're at the
    // trailing edge, the system time has gone backwards and we're treating
    // it as the trailing edge, or we've hit the `maxWait` limit.

    return lastCallTime === undefined || timeSinceLastCall >= wait || timeSinceLastCall < 0 || maxing && timeSinceLastInvoke >= maxWait;
  }

  function timerExpired() {
    var time = now();

    if (shouldInvoke(time)) {
      return trailingEdge(time);
    } // Restart the timer.


    timerId = setTimeout(timerExpired, remainingWait(time));
  }

  function trailingEdge(time) {
    timerId = undefined; // Only invoke if we have `lastArgs` which means `func` has been
    // debounced at least once.

    if (trailing && lastArgs) {
      return invokeFunc(time);
    }

    lastArgs = lastThis = undefined;
    return result;
  }

  function cancel() {
    if (timerId !== undefined) {
      clearTimeout(timerId);
    }

    lastInvokeTime = 0;
    lastArgs = lastCallTime = lastThis = timerId = undefined;
  }

  function flush() {
    return timerId === undefined ? result : trailingEdge(now());
  }

  function debounced() {
    var time = now(),
        isInvoking = shouldInvoke(time);
    lastArgs = arguments;
    lastThis = this;
    lastCallTime = time;

    if (isInvoking) {
      if (timerId === undefined) {
        return leadingEdge(lastCallTime);
      }

      if (maxing) {
        // Handle invocations in a tight loop.
        clearTimeout(timerId);
        timerId = setTimeout(timerExpired, wait);
        return invokeFunc(lastCallTime);
      }
    }

    if (timerId === undefined) {
      timerId = setTimeout(timerExpired, wait);
    }

    return result;
  }

  debounced.cancel = cancel;
  debounced.flush = flush;
  return debounced;
}

var debounce_1 = debounce$1;
var debounce = debounce_1,
    isObject = isObject_1;
/** Error message constants. */

var FUNC_ERROR_TEXT = 'Expected a function';
/**
 * Creates a throttled function that only invokes `func` at most once per
 * every `wait` milliseconds. The throttled function comes with a `cancel`
 * method to cancel delayed `func` invocations and a `flush` method to
 * immediately invoke them. Provide `options` to indicate whether `func`
 * should be invoked on the leading and/or trailing edge of the `wait`
 * timeout. The `func` is invoked with the last arguments provided to the
 * throttled function. Subsequent calls to the throttled function return the
 * result of the last `func` invocation.
 *
 * **Note:** If `leading` and `trailing` options are `true`, `func` is
 * invoked on the trailing edge of the timeout only if the throttled function
 * is invoked more than once during the `wait` timeout.
 *
 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
 *
 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
 * for details over the differences between `_.throttle` and `_.debounce`.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Function
 * @param {Function} func The function to throttle.
 * @param {number} [wait=0] The number of milliseconds to throttle invocations to.
 * @param {Object} [options={}] The options object.
 * @param {boolean} [options.leading=true]
 *  Specify invoking on the leading edge of the timeout.
 * @param {boolean} [options.trailing=true]
 *  Specify invoking on the trailing edge of the timeout.
 * @returns {Function} Returns the new throttled function.
 * @example
 *
 * // Avoid excessively updating the position while scrolling.
 * jQuery(window).on('scroll', _.throttle(updatePosition, 100));
 *
 * // Invoke `renewToken` when the click event is fired, but not more than once every 5 minutes.
 * var throttled = _.throttle(renewToken, 300000, { 'trailing': false });
 * jQuery(element).on('click', throttled);
 *
 * // Cancel the trailing throttled invocation.
 * jQuery(window).on('popstate', throttled.cancel);
 */

function throttle(func, wait, options) {
  var leading = true,
      trailing = true;

  if (typeof func != 'function') {
    throw new TypeError(FUNC_ERROR_TEXT);
  }

  if (isObject(options)) {
    leading = 'leading' in options ? !!options.leading : leading;
    trailing = 'trailing' in options ? !!options.trailing : trailing;
  }

  return debounce(func, wait, {
    'leading': leading,
    'maxWait': wait,
    'trailing': trailing
  });
}

var throttle_1 = throttle;
const Wrapper = styled.div({
  position: 'relative',
  maxWidth: 250
});
const PickerTooltip = styled(WithTooltip)({
  position: 'absolute',
  zIndex: 1,
  top: 4,
  left: 4
});
const TooltipContent = styled.div({
  width: 200,
  margin: 5,
  '.react-colorful__saturation': {
    borderRadius: '4px 4px 0 0'
  },
  '.react-colorful__hue': {
    boxShadow: 'inset 0 0 0 1px rgb(0 0 0 / 5%)'
  },
  '.react-colorful__last-control': {
    borderRadius: '0 0 4px 4px'
  }
});
const Note = styled(TooltipNote)(({
  theme
}) => ({
  fontFamily: theme.typography.fonts.base
}));
const Swatches = styled.div({
  display: 'grid',
  gridTemplateColumns: 'repeat(9, 16px)',
  gap: 6,
  padding: 3,
  marginTop: 5,
  width: 200
});
const SwatchColor = styled.div(({
  theme,
  active
}) => ({
  width: 16,
  height: 16,
  boxShadow: active ? `${theme.appBorderColor} 0 0 0 1px inset, ${theme.color.mediumdark}50 0 0 0 4px` : `${theme.appBorderColor} 0 0 0 1px inset`,
  borderRadius: theme.appBorderRadius
}));
const swatchBackground = `url('data:image/svg+xml;charset=utf-8,<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill-opacity=".05"><path d="M8 0h8v8H8zM0 8h8v8H0z"/></svg>')`;

const Swatch = _a => {
  var {
    value,
    active,
    onClick,
    style
  } = _a,
      props = __rest(_a, ["value", "active", "onClick", "style"]);

  const backgroundImage = `linear-gradient(${value}, ${value}), ${swatchBackground}, linear-gradient(#fff, #fff)`;
  return React__default.createElement(SwatchColor, Object.assign({}, props, {
    active,
    onClick
  }, {
    style: Object.assign(Object.assign({}, style), {
      backgroundImage
    })
  }));
};

const Input = styled(Form.Input)(({
  theme
}) => ({
  width: '100%',
  paddingLeft: 30,
  paddingRight: 30,
  boxSizing: 'border-box',
  fontFamily: theme.typography.fonts.base
}));
const ToggleIcon = styled(Icons)(({
  theme
}) => ({
  position: 'absolute',
  zIndex: 1,
  top: 6,
  right: 7,
  width: 20,
  height: 20,
  padding: 4,
  boxSizing: 'border-box',
  cursor: 'pointer',
  color: theme.input.color
}));
var ColorSpace;

(function (ColorSpace) {
  ColorSpace["RGB"] = "rgb";
  ColorSpace["HSL"] = "hsl";
  ColorSpace["HEX"] = "hex";
})(ColorSpace || (ColorSpace = {}));

const COLOR_SPACES = Object.values(ColorSpace);
const COLOR_REGEXP = /\(([0-9]+),\s*([0-9]+)%?,\s*([0-9]+)%?,?\s*([0-9.]+)?\)/;
const RGB_REGEXP = /^\s*rgba?\(([0-9]+),\s*([0-9]+),\s*([0-9]+),?\s*([0-9.]+)?\)\s*$/i;
const HSL_REGEXP = /^\s*hsla?\(([0-9]+),\s*([0-9]+)%,\s*([0-9]+)%,?\s*([0-9.]+)?\)\s*$/i;
const HEX_REGEXP = /^\s*#?([0-9a-f]{3}|[0-9a-f]{6})\s*$/i;
const SHORTHEX_REGEXP = /^\s*#?([0-9a-f]{3})\s*$/i;
const ColorPicker = {
  [ColorSpace.HEX]: J,
  [ColorSpace.RGB]: pe,
  [ColorSpace.HSL]: re
};
const fallbackColor = {
  [ColorSpace.HEX]: 'transparent',
  [ColorSpace.RGB]: 'rgba(0, 0, 0, 0)',
  [ColorSpace.HSL]: 'hsla(0, 0%, 0%, 0)'
};

const stringToArgs = value => {
  const match = value === null || value === void 0 ? void 0 : value.match(COLOR_REGEXP);
  if (!match) return [0, 0, 0, 1];
  const [, x, y, z, a = 1] = match;
  return [x, y, z, a].map(Number);
};

const parseValue = value => {
  if (!value) return undefined;
  let valid = true;

  if (RGB_REGEXP.test(value)) {
    const [r, g, b, a] = stringToArgs(value);
    const [h, s, l] = colorConvert.rgb.hsl([r, g, b]) || [0, 0, 0];
    return {
      valid,
      value,
      keyword: colorConvert.rgb.keyword([r, g, b]),
      colorSpace: ColorSpace.RGB,
      [ColorSpace.RGB]: value,
      [ColorSpace.HSL]: `hsla(${h}, ${s}%, ${l}%, ${a})`,
      [ColorSpace.HEX]: `#${colorConvert.rgb.hex([r, g, b]).toLowerCase()}`
    };
  }

  if (HSL_REGEXP.test(value)) {
    const [h, s, l, a] = stringToArgs(value);
    const [r, g, b] = colorConvert.hsl.rgb([h, s, l]) || [0, 0, 0];
    return {
      valid,
      value,
      keyword: colorConvert.hsl.keyword([h, s, l]),
      colorSpace: ColorSpace.HSL,
      [ColorSpace.RGB]: `rgba(${r}, ${g}, ${b}, ${a})`,
      [ColorSpace.HSL]: value,
      [ColorSpace.HEX]: `#${colorConvert.hsl.hex([h, s, l]).toLowerCase()}`
    };
  }

  const plain = value.replace('#', '');
  const rgb = colorConvert.keyword.rgb(plain) || colorConvert.hex.rgb(plain);
  const hsl = colorConvert.rgb.hsl(rgb);
  let mapped = value;
  if (/[^#a-f0-9]/i.test(value)) mapped = plain;else if (HEX_REGEXP.test(value)) mapped = `#${plain}`;

  if (mapped.startsWith('#')) {
    valid = HEX_REGEXP.test(mapped);
  } else {
    try {
      colorConvert.keyword.hex(mapped);
    } catch (e) {
      valid = false;
    }
  }

  return {
    valid,
    value: mapped,
    keyword: colorConvert.rgb.keyword(rgb),
    colorSpace: ColorSpace.HEX,
    [ColorSpace.RGB]: `rgba(${rgb[0]}, ${rgb[1]}, ${rgb[2]}, 1)`,
    [ColorSpace.HSL]: `hsla(${hsl[0]}, ${hsl[1]}%, ${hsl[2]}%, 1)`,
    [ColorSpace.HEX]: mapped
  };
};

const getRealValue = (value, color, colorSpace) => {
  if (!value || !(color === null || color === void 0 ? void 0 : color.valid)) return fallbackColor[colorSpace];
  if (colorSpace !== ColorSpace.HEX) return (color === null || color === void 0 ? void 0 : color[colorSpace]) || fallbackColor[colorSpace];

  if (!color.hex.startsWith('#')) {
    try {
      return `#${colorConvert.keyword.hex(color.hex)}`;
    } catch (e) {
      return fallbackColor.hex;
    }
  }

  const short = color.hex.match(SHORTHEX_REGEXP);
  if (!short) return HEX_REGEXP.test(color.hex) ? color.hex : fallbackColor.hex;
  const [r, g, b] = short[1].split('');
  return `#${r}${r}${g}${g}${b}${b}`;
};

const useColorInput = (initialValue, onChange) => {
  const [value, setValue] = useState(initialValue || '');
  const [color, setColor] = useState(() => parseValue(value));
  const [colorSpace, setColorSpace] = useState((color === null || color === void 0 ? void 0 : color.colorSpace) || ColorSpace.HEX); // Reset state when initialValue becomes undefined (when resetting controls)

  useEffect(() => {
    if (initialValue !== undefined) return;
    setValue('');
    setColor(undefined);
    setColorSpace(ColorSpace.HEX);
  }, [initialValue]);
  const realValue = useMemo(() => getRealValue(value, color, colorSpace).toLowerCase(), [value, color, colorSpace]);
  const updateValue = useCallback(update => {
    const parsed = parseValue(update);
    setValue((parsed === null || parsed === void 0 ? void 0 : parsed.value) || update || '');
    if (!parsed) return;
    setColor(parsed);
    setColorSpace(parsed.colorSpace);
    onChange(parsed.value);
  }, [onChange]);
  const cycleColorSpace = useCallback(() => {
    let next = COLOR_SPACES.indexOf(colorSpace) + 1;
    if (next >= COLOR_SPACES.length) next = 0;
    setColorSpace(COLOR_SPACES[next]);
    const update = (color === null || color === void 0 ? void 0 : color[COLOR_SPACES[next]]) || '';
    setValue(update);
    onChange(update);
  }, [color, colorSpace, onChange]);
  return {
    value,
    realValue,
    updateValue,
    color,
    colorSpace,
    cycleColorSpace
  };
};

const id = value => value.replace(/\s*/, '').toLowerCase();

const usePresets = (presetColors, currentColor, colorSpace) => {
  const [selectedColors, setSelectedColors] = useState((currentColor === null || currentColor === void 0 ? void 0 : currentColor.valid) ? [currentColor] : []); // Reset state when currentColor becomes undefined (when resetting controls)

  useEffect(() => {
    if (currentColor !== undefined) return;
    setSelectedColors([]);
  }, [currentColor]);
  const presets = useMemo(() => {
    const initialPresets = (presetColors || []).map(preset => {
      if (typeof preset === 'string') return parseValue(preset);
      if (preset.title) return Object.assign(Object.assign({}, parseValue(preset.color)), {
        keyword: preset.title
      });
      return parseValue(preset.color);
    });
    return initialPresets.concat(selectedColors).filter(Boolean).slice(-27);
  }, [presetColors, selectedColors]);
  const addPreset = useCallback(color => {
    if (!(color === null || color === void 0 ? void 0 : color.valid)) return;
    if (presets.some(preset => id(preset[colorSpace]) === id(color[colorSpace]))) return;
    setSelectedColors(arr => arr.concat(color));
  }, [colorSpace, presets]);
  return {
    presets,
    addPreset
  };
};

const ColorControl = ({
  name,
  value: initialValue,
  onChange,
  onFocus,
  onBlur,
  presetColors,
  startOpen
}) => {
  const {
    value,
    realValue,
    updateValue,
    color,
    colorSpace,
    cycleColorSpace
  } = useColorInput(initialValue, throttle_1(onChange, 200));
  const {
    presets,
    addPreset
  } = usePresets(presetColors, color, colorSpace);
  const Picker = ColorPicker[colorSpace];
  return React__default.createElement(Wrapper, null, React__default.createElement(PickerTooltip, {
    trigger: "click",
    startOpen: startOpen,
    closeOnClick: true,
    onVisibilityChange: () => addPreset(color),
    tooltip: React__default.createElement(TooltipContent, null, React__default.createElement(Picker, Object.assign({
      color: realValue === 'transparent' ? '#000000' : realValue
    }, {
      onChange: updateValue,
      onFocus,
      onBlur
    })), presets.length > 0 && React__default.createElement(Swatches, null, presets.map((preset, index) => React__default.createElement(WithTooltip // eslint-disable-next-line react/no-array-index-key
    , {
      // eslint-disable-next-line react/no-array-index-key
      key: `${preset.value}-${index}`,
      hasChrome: false,
      tooltip: React__default.createElement(Note, {
        note: preset.keyword || preset.value
      })
    }, React__default.createElement(Swatch, {
      value: preset[colorSpace],
      active: color && id(preset[colorSpace]) === id(color[colorSpace]),
      onClick: () => updateValue(preset.value)
    })))))
  }, React__default.createElement(Swatch, {
    value: realValue,
    style: {
      margin: 4
    }
  })), React__default.createElement(Input, {
    id: getControlId(name),
    value: value,
    onChange: e => updateValue(e.target.value),
    onFocus: e => e.target.select(),
    placeholder: "Choose color..."
  }), value ? React__default.createElement(ToggleIcon, {
    icon: "markup",
    onClick: cycleColorSpace
  }) : null);
};

export { ColorControl, ColorControl as default };
