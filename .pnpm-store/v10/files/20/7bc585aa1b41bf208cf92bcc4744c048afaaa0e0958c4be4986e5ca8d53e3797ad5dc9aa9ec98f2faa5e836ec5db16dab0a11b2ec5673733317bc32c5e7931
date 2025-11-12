var o = {
  tr: {
    regexp: /\u0130|\u0049|\u0049\u0307/g,
    map: {
      İ: "i",
      I: "ı",
      İ: "i"
    }
  },
  az: {
    regexp: /\u0130/g,
    map: {
      İ: "i",
      I: "ı",
      İ: "i"
    }
  },
  lt: {
    regexp: /\u0049|\u004A|\u012E|\u00CC|\u00CD|\u0128/g,
    map: {
      I: "i̇",
      J: "j̇",
      Į: "į̇",
      Ì: "i̇̀",
      Í: "i̇́",
      Ĩ: "i̇̃"
    }
  }
};
function t(u, a) {
  var e = o[a.toLowerCase()];
  return r(e ? u.replace(e.regexp, function(n) {
    return e.map[n];
  }) : u);
}
function r(u) {
  return u.toLowerCase();
}
export {
  t as localeLowerCase,
  r as lowerCase
};
