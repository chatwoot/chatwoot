class AxiosHelper {
  constructor() {
    this.axiosMock = {
      post: jest.fn(() => Promise.resolve()),
      get: jest.fn(() => Promise.resolve()),
      patch: jest.fn(() => Promise.resolve()),
    };
  }

  beforeEach() {
    window.axios = this.axiosMock;
  }

  // eslint-disable-next-line class-methods-use-this
  afterEach() {
    window.axios = null;
  }
}

export default new AxiosHelper();
