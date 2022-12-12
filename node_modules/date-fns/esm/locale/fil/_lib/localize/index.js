import buildLocalizeFn from "../../../_lib/buildLocalizeFn/index.js";
import buildLocalizeArrayFn from "../../../_lib/buildLocalizeArrayFn/index.js";
var weekdayValues = {
  narrow: ['Li', 'Lu', 'Ma', 'Mi', 'Hu', 'Bi', 'Sa'],
  short: ['Lin', 'Lun', 'Mar', 'Miy', 'Huw', 'Biy', 'Sab'],
  long: ['Linggo', 'Lunes', 'Martes', 'Miyerkules', 'Huwebes', 'Biyernes', 'Sabado']
};
var monthValues = {
  short: ['Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun', 'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis'],
  long: ['Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre']
};
var timeOfDayValues = {
  uppercase: ['NU', 'NT', 'NH', 'NG'],
  lowercase: ['nu', 'nt', 'nh', 'ng'],
  long: ['ng umaga', 'ng tanghali', 'ng hapon', 'ng gabi']
};

function ordinalNumber(dirtyNumber) {
  var number = Number(dirtyNumber);
  return 'ika-' + number;
}

var localize = {
  ordinalNumber: ordinalNumber,
  weekday: buildLocalizeFn(weekdayValues, 'long'),
  weekdays: buildLocalizeArrayFn(weekdayValues, 'long'),
  month: buildLocalizeFn(monthValues, 'long'),
  months: buildLocalizeArrayFn(monthValues, 'long'),
  timeOfDay: buildLocalizeFn(timeOfDayValues, 'long', function (hours) {
    if (hours > 12) {
      var modulo = hours % 12;

      if (modulo < 6) {
        return 2;
      } else {
        return 3;
      }
    } else if (hours < 12) {
      return 0;
    } else {
      return 1;
    }
  }),
  timesOfDay: buildLocalizeArrayFn(timeOfDayValues, 'long')
};
export default localize;