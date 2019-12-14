import moment from 'moment';

class DateHelper {
  constructor(date) {
    this.date = moment(date * 1000);
  }

  format(dateFormat = 'MMM DD, YYYY') {
    return this.date.format(dateFormat);
  }
}

export default DateHelper;
