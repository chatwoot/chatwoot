(function (global, factory) {
  if (typeof define === "function" && define.amd) {
    define("VETable/lang/afZA", ["exports"], factory);
  } else if (typeof exports !== "undefined") {
    factory(exports);
  } else {
    var mod = {
      exports: {}
    };
    factory(mod.exports);
    global.VETable = global.VETable || {};
    global.VETable.lang = global.VETable.lang || {};
    global.VETable.lang.afZA = mod.exports.default;
  }
})(typeof globalThis !== "undefined" ? globalThis : typeof self !== "undefined" ? self : this, function (_exports) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  var _default = {
    pagination: {
      goto: "Gaan na",
      page: "",
      itemsPerPage: " / bladsy",
      total: function total(_total) {
        return "Totaall " + _total;
      },
      prev5: "Vorige 5 Bladsye",
      next5: "Volgende 5 Bladsye"
    },
    table: {
      confirmFilter: "Bevestig",
      resetFilter: "Stel terug"
    }
  };
  _exports.default = _default;
});