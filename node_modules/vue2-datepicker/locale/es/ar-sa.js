import DatePicker from 'vue2-datepicker';
import arSA from 'date-format-parse/lib/locale/ar-sa';

var lang = {
  formatLocale: arSA,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ar-sa', lang);

export default lang;
