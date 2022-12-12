import DatePicker from 'vue2-datepicker';
import th from 'date-format-parse/lib/locale/th';

var lang = {
  formatLocale: th,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('th', lang);

export default lang;
