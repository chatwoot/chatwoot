import DatePicker from 'vue2-datepicker';
import gl from 'date-format-parse/lib/locale/gl';

var lang = {
  formatLocale: gl,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('gl', lang);

export default lang;
