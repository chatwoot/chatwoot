import { processAggregate, getEnvironmentData } from './helpers';

const v2Reporter = (results, options, callback) => {
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

export default v2Reporter;
