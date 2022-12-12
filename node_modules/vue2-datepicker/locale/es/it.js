import DatePicker from 'vue2-datepicker';
import it from 'date-format-parse/lib/locale/it';

var lang = {
  formatLocale: it,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('it', lang);

export default lang;
