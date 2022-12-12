import DatePicker from 'vue2-datepicker';
import fr from 'date-format-parse/lib/locale/fr';

var lang = {
  formatLocale: fr,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('fr', lang);

export default lang;
