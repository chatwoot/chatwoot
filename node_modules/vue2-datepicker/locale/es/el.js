import DatePicker from 'vue2-datepicker';
import el from 'date-format-parse/lib/locale/el';

var lang = {
  formatLocale: el,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('el', lang);

export default lang;
