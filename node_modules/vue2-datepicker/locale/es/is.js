import DatePicker from 'vue2-datepicker';
import is from 'date-format-parse/lib/locale/is';

var lang = {
  formatLocale: is,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('is', lang);

export default lang;
