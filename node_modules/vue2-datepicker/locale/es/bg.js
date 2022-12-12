import DatePicker from 'vue2-datepicker';
import bg from 'date-format-parse/lib/locale/bg';

var lang = {
  formatLocale: bg,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('bg', lang);

export default lang;
