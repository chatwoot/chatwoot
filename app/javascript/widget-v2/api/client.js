import axios from 'axios';

const searchParams = new URLSearchParams(window.location.search);

export const websiteToken =
  searchParams.get('website_token') || window.chatwootWebChannel?.websiteToken;

export const client = axios.create({ baseURL: '' });

client.defaults.headers.common['X-Auth-Token'] = window.authToken;

client.interceptors.request.use(config => {
  config.params = { website_token: websiteToken, ...config.params };
  return config;
});

export const setAuthToken = token => {
  window.authToken = token;
  client.defaults.headers.common['X-Auth-Token'] = token;
};
