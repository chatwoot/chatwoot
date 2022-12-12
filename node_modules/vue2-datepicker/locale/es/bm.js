import DatePicker from 'vue2-datepicker';
import bm from 'date-format-parse/lib/locale/bm';

var lang = {
  formatLocale: bm,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('bm', lang);

export default lang;
