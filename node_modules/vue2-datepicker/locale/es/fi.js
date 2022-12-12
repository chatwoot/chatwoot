import DatePicker from 'vue2-datepicker';
import fi from 'date-format-parse/lib/locale/fi';

var lang = {
  formatLocale: fi,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('fi', lang);

export default lang;
