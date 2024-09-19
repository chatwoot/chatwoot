import { uploadFile } from '../uploadHelper';
import axios from 'axios';

global.axios = axios;
vi.mock('axios');

describe('#Upload Helpers', () => {
  afterEach(() => {
    // Cleaning up the mock after each test
    axios.post.mockReset();
  });

  it('should send a POST request with correct data', async () => {
    const mockFile = new File(['dummy content'], 'example.png', {
      type: 'image/png',
    });
    const mockResponse = {
      data: {
        file_url: 'https://example.com/fileUrl',
        blob_key: 'blobKey123',
        blob_id: 'blobId456',
      },
    };

    axios.post.mockResolvedValueOnce(mockResponse);

    const result = await uploadFile(mockFile, '1602');

    expect(axios.post).toHaveBeenCalledWith(
      '/api/v1/accounts/1602/upload',
      expect.any(FormData),
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );

    expect(result).toEqual({
      fileUrl: 'https://example.com/fileUrl',
      blobKey: 'blobKey123',
      blobId: 'blobId456',
    });
  });

  it('should handle errors', async () => {
    const mockFile = new File(['dummy content'], 'example.png', {
      type: 'image/png',
    });
    const mockError = new Error('Failed to upload');

    axios.post.mockRejectedValueOnce(mockError);

    await expect(uploadFile(mockFile)).rejects.toThrow('Failed to upload');
  });
});
