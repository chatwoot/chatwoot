(function (global, factory) {
  if (typeof define === "function" && define.amd) {
    define("VETable/lang/zhTW", ["exports"], factory);
  } else if (typeof exports !== "undefined") {
    factory(exports);
  } else {
    var mod = {
      exports: {}
    };
    factory(mod.exports);
    global.VETable = global.VETable || {};
    global.VETable.lang = global.VETable.lang || {};
    global.VETable.lang.zhTW = mod.exports.default;
  }
})(typeof globalThis !== "undefined" ? globalThis : typeof self !== "undefined" ? self : this, function (_exports) {
  "use strict";

  Object.defineProperty(_exports, "__esModule", {
    value: true
  });
  _exports.default = void 0;
  var _default = {
    pagination: {
      goto: "前往",
      page: "頁",
      itemsPerPage: " 筆/頁",
      total: function total(_total) {
        return "\u5171 " + _total + " \u7B46";
      },
      prev5: "往前 5 頁",
      next5: "往後 5 頁"
    },
    table: {
      confirmFilter: '篩選',
      resetFilter: '置'
    }
  };
  _exports.default = _default;
});