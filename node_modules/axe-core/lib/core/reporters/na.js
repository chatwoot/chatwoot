import { processAggregate, getEnvironmentData } from './helpers';

const naReporter = (results, options, callback) => {
  console.warn(
    '"na" reporter will be deprecated in axe v4.0. Use the "v2" reporter instead.'
  );

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  var out = processAggregate(results, options);
  callback({
    ...getEnvironmentData(),
    toolOptions: options,
    violations: out.violations,
    passes: out.passes,
    incomplete: out.incomplete,
    inapplicable: out.inapplicable
  });
};

export default naReporter;
