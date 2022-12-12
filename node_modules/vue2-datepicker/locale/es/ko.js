import DatePicker from 'vue2-datepicker';
import ko from 'date-format-parse/lib/locale/ko';

var lang = {
  formatLocale: ko,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: false
};
DatePicker.locale('ko', lang);

export default lang;
