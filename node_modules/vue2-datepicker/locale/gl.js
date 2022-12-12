(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('vue2-datepicker')) :
	typeof define === 'function' && define.amd ? define(['vue2-datepicker'], factory) :
	(global = global || self, (global.DatePicker = global.DatePicker || {}, global.DatePicker.lang = global.DatePicker.lang || {}, global.DatePicker.lang.gl = factory(global.DatePicker)));
}(this, (function (DatePicker) { 'use strict';

	DatePicker = DatePicker && DatePicker.hasOwnProperty('default') ? DatePicker['default'] : DatePicker;

	function unwrapExports (x) {
		return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x['default'] : x;
	}

	function createCommonjsModule(fn, module) {
		return module = { exports: {} }, fn(module, module.exports), module.exports;
	}

	var gl = createCommonjsModule(function (module, exports) {

	Object.defineProperty(exports, "__esModule", {
	  value: true
	});
	exports["default"] = void 0;
	var locale = {
	  months: ['xaneiro', 'febreiro', 'marzo', 'abril', 'maio', 'xuño', 'xullo', 'agosto', 'setembro', 'outubro', 'novembro', 'decembro'],
	  monthsShort: ['xan.', 'feb.', 'mar.', 'abr.', 'mai.', 'xuñ.', 'xul.', 'ago.', 'set.', 'out.', 'nov.', 'dec.'],
	  weekdays: ['domingo', 'luns', 'martes', 'mércores', 'xoves', 'venres', 'sábado'],
	  weekdaysShort: ['dom.', 'lun.', 'mar.', 'mér.', 'xov.', 'ven.', 'sáb.'],
	  weekdaysMin: ['do', 'lu', 'ma', 'mé', 'xo', 've', 'sá'],
	  firstDayOfWeek: 1,
	  firstWeekContainsDate: 4
	};
	var _default = locale;
	exports["default"] = _default;
	module.exports = exports.default;
	});

	var gl$1 = unwrapExports(gl);

	var lang = {
	  formatLocale: gl$1,
	  yearFormat: 'YYYY',
	  monthFormat: 'MMM',
	  monthBeforeYear: true
	};
	DatePicker.locale('gl', lang);

	return lang;

})));
