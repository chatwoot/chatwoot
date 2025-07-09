var n = {
  tr: {
    regexp: /[\u0069]/g,
    map: {
      i: "İ"
    }
  },
  az: {
    regexp: /[\u0069]/g,
    map: {
      i: "İ"
    }
  },
  lt: {
    regexp: /[\u0069\u006A\u012F]\u0307|\u0069\u0307[\u0300\u0301\u0303]/g,
    map: {
      i̇: "I",
      j̇: "J",
      į̇: "Į",
      i̇̀: "Ì",
      i̇́: "Í",
      i̇̃: "Ĩ"
    }
  }
};
function t(u, p) {
  var e = n[p.toLowerCase()];
  return r(e ? u.replace(e.regexp, function(a) {
    return e.map[a];
  }) : u);
}
function r(u) {
  return u.toUpperCase();
}
export {
  t as localeUpperCase,
  r as upperCase
};
