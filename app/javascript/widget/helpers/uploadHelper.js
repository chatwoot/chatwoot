/* global axios */

const API_VERSION = 'v1';
const HEADERS = {
  'Content-Type': 'multipart/form-data',
};

export async function uploadFile(file) {
  let formData = new FormData();
  formData.append('attachment', file);

  return axios.post(`/api/${API_VERSION}/uploads`, formData, {
    headers: HEADERS,
  });
}
