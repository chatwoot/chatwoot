import DatePicker from 'vue2-datepicker';
import he from 'date-format-parse/lib/locale/he';

var lang = {
  formatLocale: he,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('he', lang);

export default lang;
