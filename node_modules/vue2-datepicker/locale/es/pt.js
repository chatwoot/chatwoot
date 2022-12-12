import DatePicker from 'vue2-datepicker';
import pt from 'date-format-parse/lib/locale/pt';

var lang = {
  formatLocale: pt,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('pt', lang);

export default lang;
