/* global axios */

const DEFAULT_API_VERSION = 'v1';
const DEFAULT_OPTIONS = {
  apiVersion: DEFAULT_API_VERSION,
  enterprise: false,
  accountScoped: false,
  cancelPreviousRequests: false,
};

class ApiClient {
  constructor(resource, options = {}) {
    this.options = { ...DEFAULT_OPTIONS, ...options };
    this.apiVersion = `/api/${this.options.apiVersion}`;
    this.resource = resource;
    this.abortControllers = new Map();
    this.activeRequests = new Map();
  }

  get url() {
    return `${this.baseUrl()}/${this.resource}`;
  }

  // eslint-disable-next-line class-methods-use-this
  get accountIdFromRoute() {
    const isInsideAccountScopedURLs =
      window.location.pathname.includes('/app/accounts');

    if (isInsideAccountScopedURLs) {
      return window.location.pathname.split('/')[3];
    }

    return '';
  }

  baseUrl() {
    let url = this.apiVersion;

    if (this.options.enterprise) {
      url = `/enterprise${url}`;
    }

    if (this.options.accountScoped && this.accountIdFromRoute) {
      url = `${url}/accounts/${this.accountIdFromRoute}`;
    }

    return url;
  }

  generateRequestKey(method, id = '', customRequestKey = '') {
    if (customRequestKey) return customRequestKey;
    return `${method}-${this.url}${id ? `/${id}` : ''}`;
  }

  cancelRequest(requestKey) {
    const controller = this.abortControllers.get(requestKey);
    if (controller) {
      controller.abort();
      this.abortControllers.delete(requestKey);
      return true;
    }
    return false;
  }

  setupRequest(method, options = {}) {
    if (!this.options.cancelPreviousRequests) {
      return {};
    }
    const { id, customRequestKey } = options;
    const requestKey = this.generateRequestKey(method, id, customRequestKey);

    const previousRequests = this.activeRequests.get(method) || [];
    const remainingRequests = previousRequests.filter(key => {
      if (key === requestKey) {
        this.cancelRequest(key);
        return false;
      }
      return true;
    });

    this.activeRequests.set(method, [...remainingRequests, requestKey]);

    const controller = new AbortController();
    this.abortControllers.set(requestKey, controller);

    return { requestKey, signal: controller.signal };
  }

  async request(method, config = {}) {
    const { id, data, customRequestKey, ...axiosConfig } = config;
    const { requestKey, signal } = this.setupRequest(method, {
      id,
      customRequestKey,
    });
    try {
      const url = id ? `${this.url}/${id}` : this.url;
      return await axios({
        method,
        url,
        data,
        signal,
        ...axiosConfig,
      });
    } finally {
      this.abortControllers.delete(requestKey);
      if (this.options.cancelPreviousRequests) {
        const methodRequests = this.activeRequests.get(method) || [];
        this.activeRequests.set(
          method,
          methodRequests.filter(key => key !== requestKey)
        );
      }
    }
  }

  get(config = {}) {
    return this.request('GET', config);
  }

  show(id, config = {}) {
    return this.request('GET', { ...config, id });
  }

  create(data, config = {}) {
    return this.request('POST', { ...config, data });
  }

  update(id, data, config = {}) {
    return this.request('PATCH', { ...config, id, data });
  }

  delete(id, config = {}) {
    return this.request('DELETE', { ...config, id });
  }

  cancelAllRequests() {
    this.abortControllers.forEach(controller => controller.abort());
    this.abortControllers.clear();
    this.activeRequests.clear();
  }

  // Get all active request keys
  getActiveRequests() {
    return Array.from(this.abortControllers.keys());
  }

  destroy() {
    this.cancelAllRequests();
  }
}

export default ApiClient;
