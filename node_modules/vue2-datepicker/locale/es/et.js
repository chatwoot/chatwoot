import DatePicker from 'vue2-datepicker';
import et from 'date-format-parse/lib/locale/et';

var lang = {
  formatLocale: et,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('et', lang);

export default lang;
