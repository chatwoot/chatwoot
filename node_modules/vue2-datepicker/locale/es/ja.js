import DatePicker from 'vue2-datepicker';
import ja from 'date-format-parse/lib/locale/ja';

var lang = {
  formatLocale: ja,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: false
};
DatePicker.locale('ja', lang);

export default lang;
