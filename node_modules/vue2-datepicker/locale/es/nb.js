import DatePicker from 'vue2-datepicker';
import nb from 'date-format-parse/lib/locale/nb';

var lang = {
  formatLocale: nb,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('nb', lang);

export default lang;
