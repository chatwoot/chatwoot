(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('vue2-datepicker')) :
	typeof define === 'function' && define.amd ? define(['vue2-datepicker'], factory) :
	(global = global || self, (global.DatePicker = global.DatePicker || {}, global.DatePicker.lang = global.DatePicker.lang || {}, global.DatePicker.lang.gu = factory(global.DatePicker)));
}(this, (function (DatePicker) { 'use strict';

	DatePicker = DatePicker && DatePicker.hasOwnProperty('default') ? DatePicker['default'] : DatePicker;

	function unwrapExports (x) {
		return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x['default'] : x;
	}

	function createCommonjsModule(fn, module) {
		return module = { exports: {} }, fn(module, module.exports), module.exports;
	}

	var gu = createCommonjsModule(function (module, exports) {

	Object.defineProperty(exports, "__esModule", {
	  value: true
	});
	exports["default"] = void 0;
	var locale = {
	  months: ['જાન્યુઆરી', 'ફેબ્રુઆરી', 'માર્ચ', 'એપ્રિલ', 'મે', 'જૂન', 'જુલાઈ', 'ઑગસ્ટ', 'સપ્ટેમ્બર', 'ઑક્ટ્બર', 'નવેમ્બર', 'ડિસેમ્બર'],
	  monthsShort: ['જાન્યુ.', 'ફેબ્રુ.', 'માર્ચ', 'એપ્રિ.', 'મે', 'જૂન', 'જુલા.', 'ઑગ.', 'સપ્ટે.', 'ઑક્ટ્.', 'નવે.', 'ડિસે.'],
	  weekdays: ['રવિવાર', 'સોમવાર', 'મંગળવાર', 'બુધ્વાર', 'ગુરુવાર', 'શુક્રવાર', 'શનિવાર'],
	  weekdaysShort: ['રવિ', 'સોમ', 'મંગળ', 'બુધ્', 'ગુરુ', 'શુક્ર', 'શનિ'],
	  weekdaysMin: ['ર', 'સો', 'મં', 'બુ', 'ગુ', 'શુ', 'શ'],
	  firstDayOfWeek: 0,
	  firstWeekContainsDate: 6
	};
	var _default = locale;
	exports["default"] = _default;
	module.exports = exports.default;
	});

	var gu$1 = unwrapExports(gu);

	var lang = {
	  formatLocale: gu$1,
	  yearFormat: 'YYYY',
	  monthFormat: 'MMM',
	  monthBeforeYear: true
	};
	DatePicker.locale('gu', lang);

	return lang;

})));
