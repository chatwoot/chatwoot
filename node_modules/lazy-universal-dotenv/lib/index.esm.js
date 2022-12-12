/*! lazy-universal-dotenv v3.0.1 by Storybook Team */
import 'core-js/modules/es.array.filter';
import 'core-js/modules/es.array.for-each';
import 'core-js/modules/es.array.join';
import 'core-js/modules/es.object.assign';
import 'core-js/modules/es.object.keys';
import 'core-js/modules/web.dom-collections.for-each';
import fs from 'fs';
import path from 'path';
import appRoot from 'app-root-dir';
import dotenv from 'dotenv';
import expand from 'dotenv-expand';

var dotEnvBase = path.join(appRoot.get(), ".env");
function getEnvironment(_temp) {
  var _ref = _temp === void 0 ? {} : _temp,
      nodeEnv = _ref.nodeEnv,
      buildTarget = _ref.buildTarget,
      raw = {},
      stringified = {},
      NODE_ENV = typeof nodeEnv == "undefined" ? process.env.NODE_ENV : nodeEnv,
      BUILD_TARGET = typeof nodeEnv == "undefined" ? process.env.BUILD_TARGET : buildTarget,
      dotenvFiles = [BUILD_TARGET && NODE_ENV && dotEnvBase + "." + BUILD_TARGET + "." + NODE_ENV + ".local", BUILD_TARGET && NODE_ENV && dotEnvBase + "." + BUILD_TARGET + "." + NODE_ENV, BUILD_TARGET && NODE_ENV !== "test" && dotEnvBase + "." + BUILD_TARGET + ".local", BUILD_TARGET && dotEnvBase + "." + BUILD_TARGET, NODE_ENV && dotEnvBase + "." + NODE_ENV + ".local", NODE_ENV && dotEnvBase + "." + NODE_ENV, NODE_ENV !== "test" && dotEnvBase + ".local", dotEnvBase].filter(Boolean);

  dotenvFiles.forEach(function (dotenvFile) {
    if (fs.existsSync(dotenvFile)) {
      var config = dotenv.config({
        path: dotenvFile
      });
      raw = Object.assign({}, raw, expand(config).parsed);
    }
  });
  Object.keys(raw).forEach(function (key) {
    stringified[key] = JSON.stringify(raw[key]);
  });
  return {
    raw: raw,
    stringified: stringified,
    webpack: {
      "process.env": stringified
    }
  };
}

export { getEnvironment };
//# sourceMappingURL=index.esm.js.map
