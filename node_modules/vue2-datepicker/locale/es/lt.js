import DatePicker from 'vue2-datepicker';
import lt from 'date-format-parse/lib/locale/lt';

var lang = {
  formatLocale: lt,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('lt', lang);

export default lang;
