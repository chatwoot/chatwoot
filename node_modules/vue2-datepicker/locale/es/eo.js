import DatePicker from 'vue2-datepicker';
import eo from 'date-format-parse/lib/locale/eo';

var lang = {
  formatLocale: eo,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('eo', lang);

export default lang;
