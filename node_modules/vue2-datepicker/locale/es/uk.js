import DatePicker from 'vue2-datepicker';
import uk from 'date-format-parse/lib/locale/uk';

var lang = {
  formatLocale: uk,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('uk', lang);

export default lang;
