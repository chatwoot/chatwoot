import DatePicker from 'vue2-datepicker';
import id from 'date-format-parse/lib/locale/id';

var lang = {
  formatLocale: id,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('id', lang);

export default lang;
