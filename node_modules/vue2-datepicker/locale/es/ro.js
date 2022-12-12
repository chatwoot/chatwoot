import DatePicker from 'vue2-datepicker';
import ro from 'date-format-parse/lib/locale/ro';

var lang = {
  formatLocale: ro,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ro', lang);

export default lang;
