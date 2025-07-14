(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('vue-datepicker-next')) :
  typeof define === 'function' && define.amd ? define(['vue-datepicker-next'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, (global.DatePicker = global.DatePicker || {}, global.DatePicker.lang = global.DatePicker.lang || {}, global.DatePicker.lang.zhCn = factory(global.DatePicker)));
}(this, (function (DatePicker) { 'use strict';

  function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

  var DatePicker__default = /*#__PURE__*/_interopDefaultLegacy(DatePicker);

  var locale = {
    months: ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'],
    monthsShort: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
    weekdays: ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'],
    weekdaysShort: ['周日', '周一', '周二', '周三', '周四', '周五', '周六'],
    weekdaysMin: ['日', '一', '二', '三', '四', '五', '六'],
    firstDayOfWeek: 1,
    firstWeekContainsDate: 4,
    meridiemParse: /上午|下午/,
    meridiem: function meridiem(hour) {
      if (hour < 12) {
        return '上午';
      }

      return '下午';
    },
    isPM: function isPM(input) {
      return input === '下午';
    }
  };

  const lang = {
      formatLocale: locale,
      yearFormat: 'YYYY年',
      monthFormat: 'MMM',
      monthBeforeYear: false,
  };
  DatePicker__default['default'].locale('zh-cn', lang);

  return lang;

})));
