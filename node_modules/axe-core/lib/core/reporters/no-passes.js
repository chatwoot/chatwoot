import { processAggregate, getEnvironmentData } from './helpers';

const noPassesReporter = (results, options, callback) => {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }
  // limit result processing to types we want to include in the output
  options.resultTypes = ['violations'];

  var out = processAggregate(results, options);

  callback({
    ...getEnvironmentData(),
    toolOptions: options,
    violations: out.violations
  });
};

export default noPassesReporter;
