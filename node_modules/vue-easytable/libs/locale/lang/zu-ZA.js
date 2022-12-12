(function (global, factory) {
  if (typeof define === "function" && define.amd) {
    define("VETable/lang/zuZA", ["exports"], factory);
  } else if (typeof exports !== "undefined") {
    factory(exports);
  } else {
    var mod = {
      exports: {}
    };
    factory(mod.exports);
    global.VETable = global.VETable || {};
    global.VETable.lang = global.VETable.lang || {};
    global.VETable.lang.zuZA = mod.exports.default;
  }
})(typeof globalThis !== "undefined" ? globalThis : typeof self !== "undefined" ? self : this, function (_exports) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  var _default = {
    pagination: {
      goto: "Iya ku",
      page: "",
      itemsPerPage: " / Emakhasi",
      total: function total(_total) {
        return "Okuphelele " + _total;
      },
      prev5: "5 Esedlule Emakhasi",
      next5: "5 Emakhasi Lalandzelako"
    },
    table: {
      confirmFilter: "Qiniseka",
      resetFilter: "Setha Kabusha"
    }
  };
  _exports.default = _default;
});