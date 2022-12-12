import DatePicker from 'vue2-datepicker';
import de from 'date-format-parse/lib/locale/de';

var lang = {
  formatLocale: de,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('de', lang);

export default lang;
