/* global axios */

export default {
  get() {
    return axios.get('/api/v1/branding');
  },
  update(formData) {
    // Use FormData with proper headers for multipart/form-data
    return axios.put('/api/v1/branding', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  },
};

