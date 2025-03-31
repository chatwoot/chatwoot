import inspector from 'node:inspector';
import { provider } from 'std-env';
import { l as loadProvider } from './load-provider-Bl5rgjsL.js';

const session = new inspector.Session();
let enabled = false;
var index = {
  startCoverage({ isolate }) {
    if (isolate === false && enabled) {
      return;
    }
    enabled = true;
    session.connect();
    session.post("Profiler.enable");
    session.post("Profiler.startPreciseCoverage", {
      callCount: true,
      detailed: true
    });
  },
  takeCoverage() {
    return new Promise((resolve, reject) => {
      session.post("Profiler.takePreciseCoverage", async (error, coverage) => {
        if (error) {
          return reject(error);
        }
        const result = coverage.result.filter(filterResult);
        resolve({ result });
      });
      if (provider === "stackblitz") {
        resolve({ result: [] });
      }
    });
  },
  stopCoverage({ isolate }) {
    if (isolate === false) {
      return;
    }
    session.post("Profiler.stopPreciseCoverage");
    session.post("Profiler.disable");
    session.disconnect();
  },
  async getProvider() {
    return loadProvider();
  }
};
function filterResult(coverage) {
  if (!coverage.url.startsWith("file://")) {
    return false;
  }
  if (coverage.url.includes("/node_modules/")) {
    return false;
  }
  return true;
}

export { index as default };
