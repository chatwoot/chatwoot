import mockAxios from 'jest-mock-axios';

beforeEach(() => {
  window.axios = mockAxios;
});
