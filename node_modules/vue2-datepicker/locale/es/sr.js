import DatePicker from 'vue2-datepicker';
import sr from 'date-format-parse/lib/locale/sr';

var lang = {
  formatLocale: sr,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('sr', lang);

export default lang;
