import DatePicker from 'vue2-datepicker';
import ptBR from 'date-format-parse/lib/locale/pt-br';

var lang = {
  formatLocale: ptBR,
  yearFormat: 'YYYY',
  monthFormat: 'MMM',
  monthBeforeYear: true
};
DatePicker.locale('pt-br', lang);

export default lang;
