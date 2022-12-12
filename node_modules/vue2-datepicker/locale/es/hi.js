import DatePicker from 'vue2-datepicker';
import hi from 'date-format-parse/lib/locale/hi';

var lang = {
  formatLocale: hi,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('hi', lang);

export default lang;
