const reporters = {};
let defaultReporter;

export function hasReporter(reporterName) {
  return reporters.hasOwnProperty(reporterName);
}

export function getReporter(reporter) {
  if (typeof reporter === 'string' && reporters[reporter]) {
    return reporters[reporter];
  }

  if (typeof reporter === 'function') {
    return reporter;
  }

  return defaultReporter;
}

export function addReporter(name, cb, isDefault) {
  reporters[name] = cb;
  if (isDefault) {
    defaultReporter = cb;
  }
}
