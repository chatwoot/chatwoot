export { M as ModuleMocker, c as createCompilerHints } from './chunk-mocker.js';
import { M as MockerRegistry } from './chunk-registry.js';
import { c as cleanUrl } from './chunk-utils.js';
export { M as ModuleMockerServerInterceptor } from './chunk-interceptor-native.js';
import './index.js';
import './chunk-pathe.UZ-hd4nF.js';

class ModuleMockerMSWInterceptor {
  constructor(options = {}) {
    this.options = options;
    if (!options.globalThisAccessor) {
      options.globalThisAccessor = '"__vitest_mocker__"';
    }
  }
  mocks = new MockerRegistry();
  startPromise;
  worker;
  async register(module) {
    await this.init();
    this.mocks.add(module);
  }
  async delete(url) {
    await this.init();
    this.mocks.delete(url);
  }
  invalidate() {
    this.mocks.clear();
  }
  async resolveManualMock(mock) {
    const exports = Object.keys(await mock.resolve());
    const module = `const module = globalThis[${this.options.globalThisAccessor}].getFactoryModule("${mock.url}");`;
    const keys = exports.map((name) => {
      if (name === "default") {
        return `export default module["default"];`;
      }
      return `export const ${name} = module["${name}"];`;
    }).join("\n");
    const text = `${module}
${keys}`;
    return new Response(text, {
      headers: {
        "Content-Type": "application/javascript"
      }
    });
  }
  async init() {
    if (this.worker) {
      return this.worker;
    }
    if (this.startPromise) {
      return this.startPromise;
    }
    const worker = this.options.mswWorker;
    this.startPromise = Promise.all([
      worker ? {
        setupWorker(handler) {
          worker.use(handler);
          return worker;
        }
      } : import('msw/browser'),
      import('msw/core/http')
    ]).then(([{ setupWorker }, { http }]) => {
      const worker2 = setupWorker(
        http.get(/.+/, async ({ request }) => {
          const path = cleanQuery(request.url.slice(location.origin.length));
          if (!this.mocks.has(path)) {
            return passthrough();
          }
          const mock = this.mocks.get(path);
          switch (mock.type) {
            case "manual":
              return this.resolveManualMock(mock);
            case "automock":
            case "autospy":
              return Response.redirect(injectQuery(path, `mock=${mock.type}`));
            case "redirect":
              return Response.redirect(mock.redirect);
            default:
              throw new Error(`Unknown mock type: ${mock.type}`);
          }
        })
      );
      return worker2.start(this.options.mswOptions).then(() => worker2);
    }).finally(() => {
      this.worker = worker;
      this.startPromise = undefined;
    });
    return await this.startPromise;
  }
}
const trailingSeparatorRE = /[?&]$/;
const timestampRE = /\bt=\d{13}&?\b/;
const versionRE = /\bv=\w{8}&?\b/;
function cleanQuery(url) {
  return url.replace(timestampRE, "").replace(versionRE, "").replace(trailingSeparatorRE, "");
}
function passthrough() {
  return new Response(null, {
    status: 302,
    statusText: "Passthrough",
    headers: {
      "x-msw-intention": "passthrough"
    }
  });
}
const replacePercentageRE = /%/g;
function injectQuery(url, queryToInject) {
  const resolvedUrl = new URL(
    url.replace(replacePercentageRE, "%25"),
    location.href
  );
  const { search, hash } = resolvedUrl;
  const pathname = cleanUrl(url);
  return `${pathname}?${queryToInject}${search ? `&${search.slice(1)}` : ""}${hash ?? ""}`;
}

export { ModuleMockerMSWInterceptor };
