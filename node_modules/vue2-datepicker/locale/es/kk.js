import DatePicker from 'vue2-datepicker';
import kk from 'date-format-parse/lib/locale/kk';

var lang = {
  formatLocale: kk,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('kk', lang);

export default lang;
