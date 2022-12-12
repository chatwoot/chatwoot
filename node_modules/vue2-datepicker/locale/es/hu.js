import DatePicker from 'vue2-datepicker';
import hu from 'date-format-parse/lib/locale/hu';

var lang = {
  formatLocale: hu,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: false
};
DatePicker.locale('hu', lang);

export default lang;
