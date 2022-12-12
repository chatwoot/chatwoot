import DatePicker from 'vue2-datepicker';
import sv from 'date-format-parse/lib/locale/sv';

var lang = {
  formatLocale: sv,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('sv', lang);

export default lang;
