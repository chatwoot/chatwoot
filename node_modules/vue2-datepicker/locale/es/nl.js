import DatePicker from 'vue2-datepicker';
import nl from 'date-format-parse/lib/locale/nl';

var lang = {
  formatLocale: nl,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('nl', lang);

export default lang;
