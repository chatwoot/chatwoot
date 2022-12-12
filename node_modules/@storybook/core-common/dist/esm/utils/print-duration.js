import prettyTime from 'pretty-hrtime';
export var printDuration = function (startTime) {
  return prettyTime(process.hrtime(startTime)).replace(' ms', ' milliseconds').replace(' s', ' seconds').replace(' m', ' minutes');
};