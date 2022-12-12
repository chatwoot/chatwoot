import DatePicker from 'vue2-datepicker';
import ms from 'date-format-parse/lib/locale/ms';

var lang = {
  formatLocale: ms,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ms', lang);

export default lang;
