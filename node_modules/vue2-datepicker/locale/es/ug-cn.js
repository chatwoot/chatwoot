import DatePicker from 'vue2-datepicker';
import ugCN from 'date-format-parse/lib/locale/ug-cn';

var lang = {
  formatLocale: ugCN,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ug-cn', lang);

export default lang;
