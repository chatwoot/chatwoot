import DatePicker from 'vue2-datepicker';
import te from 'date-format-parse/lib/locale/te';

var lang = {
  formatLocale: te,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('te', lang);

export default lang;
