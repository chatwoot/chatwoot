(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('vue2-datepicker')) :
	typeof define === 'function' && define.amd ? define(['vue2-datepicker'], factory) :
	(global = global || self, (global.DatePicker = global.DatePicker || {}, global.DatePicker.lang = global.DatePicker.lang || {}, global.DatePicker.lang.bm = factory(global.DatePicker)));
}(this, (function (DatePicker) { 'use strict';

	DatePicker = DatePicker && DatePicker.hasOwnProperty('default') ? DatePicker['default'] : DatePicker;

	function unwrapExports (x) {
		return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x['default'] : x;
	}

	function createCommonjsModule(fn, module) {
		return module = { exports: {} }, fn(module, module.exports), module.exports;
	}

	var bm = createCommonjsModule(function (module, exports) {

	Object.defineProperty(exports, "__esModule", {
	  value: true
	});
	exports["default"] = void 0;
	var locale = {
	  months: ['Zanwuyekalo', 'Fewuruyekalo', 'Marisikalo', 'Awirilikalo', 'Mɛkalo', 'Zuwɛnkalo', 'Zuluyekalo', 'Utikalo', 'Sɛtanburukalo', 'ɔkutɔburukalo', 'Nowanburukalo', 'Desanburukalo'],
	  monthsShort: ['Zan', 'Few', 'Mar', 'Awi', 'Mɛ', 'Zuw', 'Zul', 'Uti', 'Sɛt', 'ɔku', 'Now', 'Des'],
	  weekdays: ['Kari', 'Ntɛnɛn', 'Tarata', 'Araba', 'Alamisa', 'Juma', 'Sibiri'],
	  weekdaysShort: ['Kar', 'Ntɛ', 'Tar', 'Ara', 'Ala', 'Jum', 'Sib'],
	  weekdaysMin: ['Ka', 'Nt', 'Ta', 'Ar', 'Al', 'Ju', 'Si'],
	  firstDayOfWeek: 1,
	  firstWeekContainsDate: 4
	};
	var _default = locale;
	exports["default"] = _default;
	module.exports = exports.default;
	});

	var bm$1 = unwrapExports(bm);

	var lang = {
	  formatLocale: bm$1,
	  yearFormat: 'YYYY',
	  monthFormat: 'MMM',
	  monthBeforeYear: true
	};
	DatePicker.locale('bm', lang);

	return lang;

})));
