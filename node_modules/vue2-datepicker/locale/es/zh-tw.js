import DatePicker from 'vue2-datepicker';
import zhTW from 'date-format-parse/lib/locale/zh-tw';

var lang = {
  formatLocale: zhTW,
  yearFormat: 'YYYY年',
  monthFormat: 'MMM',
  monthBeforeYear: false
};
DatePicker.locale('zh-tw', lang);

export default lang;
