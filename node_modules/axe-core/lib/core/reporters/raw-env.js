import { getEnvironmentData } from './helpers';
import rawReporter from './raw';

const rawEnvReporter = (results, options, callback) => {
  if (typeof options === 'function') {
    callback = options;
    options = {};
  }
  function rawCallback(raw) {
    const env = getEnvironmentData();
    callback({ raw, env });
  }

  rawReporter(results, options, rawCallback);
};

export default rawEnvReporter;
