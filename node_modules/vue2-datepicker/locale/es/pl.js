import DatePicker from 'vue2-datepicker';
import pl from 'date-format-parse/lib/locale/pl';

var lang = {
  formatLocale: pl,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('pl', lang);

export default lang;
