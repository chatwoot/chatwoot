import DatePicker from 'vue2-datepicker';
import ar from 'date-format-parse/lib/locale/ar';

var lang = {
  formatLocale: ar,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ar', lang);

export default lang;
