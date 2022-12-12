import DatePicker from 'vue2-datepicker';
import da from 'date-format-parse/lib/locale/da';

var lang = {
  formatLocale: da,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('da', lang);

export default lang;
