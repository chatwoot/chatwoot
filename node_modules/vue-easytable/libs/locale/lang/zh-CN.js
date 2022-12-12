(function (global, factory) {
  if (typeof define === "function" && define.amd) {
    define("VETable/lang/zhCN", ["exports"], factory);
  } else if (typeof exports !== "undefined") {
    factory(exports);
  } else {
    var mod = {
      exports: {}
    };
    factory(mod.exports);
    global.VETable = global.VETable || {};
    global.VETable.lang = global.VETable.lang || {};
    global.VETable.lang.zhCN = mod.exports.default;
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
      page: "页",
      itemsPerPage: " 条/页",
      total: function total(_total) {
        return "\u5171 " + _total + " \u6761";
      },
      prev5: "向前 5 页",
      next5: "向后 5 页"
    },
    table: {
      confirmFilter: '筛选',
      resetFilter: '重置'
    }
  };
  _exports.default = _default;
});