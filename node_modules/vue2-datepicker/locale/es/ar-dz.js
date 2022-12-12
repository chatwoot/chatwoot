import DatePicker from 'vue2-datepicker';
import arDZ from 'date-format-parse/lib/locale/ar-dz';

var lang = {
  formatLocale: arDZ,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ar-dz', lang);

export default lang;
