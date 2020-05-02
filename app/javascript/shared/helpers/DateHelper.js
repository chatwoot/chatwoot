import moment from 'moment';

class DateHelper {
  constructor(date) {
    this.date = moment(date * 1000);
    this.today = moment();
    this.yesterday = moment().subtract(1, 'day');
  }

  format(dateFormat = 'MMM DD, YYYY') {
    if (moment(this.date).isSame(this.today, 'day')) {
      return 'TODAY';
    }
    if (moment(this.date).isSame(this.yesterday, 'day')) {
      return 'YESTERDAY';
    }
    return this.date.format(dateFormat);
  }
}

export default DateHelper;
