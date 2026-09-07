/* global axios */

/**
 * Constants and Configuration
 */

// Version for the API endpoint.
const API_VERSION = 'v1';

// Default headers to be used in the axios request.
const HEADERS = {
  'Content-Type': 'multipart/form-data',
};

/**
 * Uploads a file to the server.
 *
 * This function sends a POST request to a given API endpoint and uploads the specified file.
 * The function uses FormData to wrap the file and axios to send the request.
 *
 * @param {File} file - The file to be uploaded. It should be a File object (typically coming from a file input element).
 * @param {string} accountId - The account ID.
 * @param {Function} [onProgress] - Called with the upload progress as a fraction between 0 and 1.
 * @param {AbortSignal} [signal] - Aborts the request when the upload is cancelled.
 * @returns {Promise} A promise that resolves with the server's response when the upload is successful, or rejects if there's an error.
 */
export async function uploadFile(file, accountId, onProgress, signal) {
  if (!accountId) {
    accountId = window.location.pathname.split('/')[3];
  }

  // Append the file to the FormData instance under the key 'attachment'.
  let formData = new FormData();
  formData.append('attachment', file);

  const { data } = await axios.post(
    `/api/${API_VERSION}/accounts/${accountId}/upload`,
    formData,
    {
      headers: HEADERS,
      signal,
      onUploadProgress: event => {
        if (onProgress && event.total) {
          onProgress(Math.min(1, event.loaded / event.total));
        }
      },
    }
  );

  return {
    fileUrl: data.file_url,
    blobKey: data.blob_key,
    blobId: data.blob_id,
  };
}

/**
 * Uploads an image from an external URL.
 *
 * @param {string} url - The external URL of the image.
 * @param {string} accountId - The account ID.
 * @param {AbortSignal} [signal] - Aborts the request when the upload is cancelled.
 * @returns {Promise} A promise that resolves with the server's response.
 */
export async function uploadExternalImage(url, accountId, signal) {
  if (!accountId) {
    accountId = window.location.pathname.split('/')[3];
  }

  const { data } = await axios.post(
    `/api/${API_VERSION}/accounts/${accountId}/upload`,
    { external_url: url },
    { headers: { 'Content-Type': 'application/json' }, signal }
  );

  return {
    fileUrl: data.file_url,
    blobKey: data.blob_key,
    blobId: data.blob_id,
  };
}
