import DatePicker from 'vue2-datepicker';
import hr from 'date-format-parse/lib/locale/hr';

var lang = {
  formatLocale: hr,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('hr', lang);

export default lang;
