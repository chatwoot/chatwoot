import mockAxios from 'jest-mock-axios';

beforeEach(() => {
  window.axios = mockAxios;
  global.axios = mockAxios;
});

afterEach(() => {
  // cleaning up the mess left behind the previous test
  mockAxios.reset();
});
