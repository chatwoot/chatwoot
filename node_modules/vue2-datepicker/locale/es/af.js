import DatePicker from 'vue2-datepicker';
import af from 'date-format-parse/lib/locale/af';

var lang = {
  formatLocale: af,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('af', lang);

export default lang;
