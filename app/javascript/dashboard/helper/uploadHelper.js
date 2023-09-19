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
 * @returns {Promise} A promise that resolves with the server's response when the upload is successful, or rejects if there's an error.
 */
export async function uploadFile(file, accountId) {
  // Create a new FormData instance.
  let formData = new FormData();

  if (!accountId) {
    accountId = window.location.pathname.split('/')[3];
  }

  // Append the file to the FormData instance under the key 'attachment'.
  formData.append('attachment', file);

  // Use axios to send a POST request to the upload endpoint.
  const { data } = await axios.post(
    `/api/${API_VERSION}/accounts/${accountId}/upload`,
    formData,
    {
      headers: HEADERS,
    }
  );

  return {
    fileUrl: data.file_url,
    blobKey: data.blob_key,
    blobId: data.blob_id,
  };
}
