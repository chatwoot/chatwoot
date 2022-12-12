import DatePicker from 'vue2-datepicker';
import ka from 'date-format-parse/lib/locale/ka';

var lang = {
  formatLocale: ka,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ka', lang);

export default lang;
