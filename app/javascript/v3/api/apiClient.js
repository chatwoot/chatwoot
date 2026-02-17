import axios from 'axios';

const { apiHost = 'https://chatwoot.dev.konko.ai' } =
  window.chatwootConfig || {};
const wootAPI = axios.create({
  baseURL: `${apiHost}/`,
  withCredentials: true,
});

export default wootAPI;
