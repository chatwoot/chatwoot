// Month and weekday names for vue-datepicker-next in the app language, built
// from Intl so they cover every language the dashboard ships instead of the few
// the library bundles. A picker reads its locale once, from its `lang` prop, so
// each one binds `currentDatePickerLang()` there to follow a language switch
// while it is mounted; the global default only covers a picker that does not.
import { watch } from 'vue';
import DatePicker from 'vue-datepicker-next';
import {
  currentDateLocale,
  dateTimeFormat,
  formatLocalized,
} from 'shared/helpers/localizedDate';

// 2024-01-07 was a Sunday, the first day the library's arrays expect.
const sundayOffset = day => new Date(2024, 0, 7 + day);
const monthOf = month => new Date(2024, month, 1);
const range = length => Array.from({ length }, (_, index) => index);

export const datePickerLang = locale => {
  const parts = dateTimeFormat(locale, {
    month: 'long',
    year: 'numeric',
  })
    .formatToParts(new Date(2024, 0, 1))
    .map(part => part.type);
  const monthFirst = parts.indexOf('month') < parts.indexOf('year');
  return {
    formatLocale: {
      months: range(12).map(m => formatLocalized(monthOf(m), 'LLLL')),
      monthsShort: range(12).map(m => formatLocalized(monthOf(m), 'LLL')),
      weekdays: range(7).map(d => formatLocalized(sundayOffset(d), 'EEEE')),
      weekdaysShort: range(7).map(d => formatLocalized(sundayOffset(d), 'EEE')),
      weekdaysMin: range(7).map(d =>
        formatLocalized(sundayOffset(d), 'EEEEEE')
      ),
      firstDayOfWeek: 0,
      firstWeekContainsDate: 1,
    },
    yearFormat: 'YYYY',
    monthFormat: 'MMM',
    monthBeforeYear: monthFirst,
  };
};

const langs = new Map();

/** @returns {object} The `lang` prop for a picker, for the current app language. */
export const currentDatePickerLang = () => {
  const locale = currentDateLocale();
  if (!langs.has(locale)) langs.set(locale, datePickerLang(locale));
  return langs.get(locale);
};

export const bindDatePickerLocale = () =>
  watch(
    currentDateLocale,
    locale => DatePicker.locale(locale, currentDatePickerLang()),
    { immediate: true }
  );
