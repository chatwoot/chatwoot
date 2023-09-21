import axios from 'axios';

const { apiHost = '' } = window.chatwootConfig || {};
const wootAPI = axios.create({ baseURL: `${apiHost}/` });

export default wootAPI;
