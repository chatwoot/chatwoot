import DatePicker from 'vue2-datepicker';
import ru from 'date-format-parse/lib/locale/ru';

var lang = {
  formatLocale: ru,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('ru', lang);

export default lang;
