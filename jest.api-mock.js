import axios from 'axios';

jest.mock('axios');

beforeEach(() => {
  axios.get.mockResolvedValue(Promise.resolve());
  axios.post.mockResolvedValue(Promise.resolve());
  axios.patch.mockResolvedValue(Promise.resolve());
  axios.delete.mockResolvedValue(Promise.resolve());
  window.axios = axios;
});

afterEach(() => {
  jest.clearAllMocks();
});
