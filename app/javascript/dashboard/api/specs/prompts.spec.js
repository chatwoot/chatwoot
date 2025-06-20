import { describe, it, expect, vi, beforeEach } from 'vitest';
import PromptAPI from '../prompts';

describe('PromptAPI', () => {
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      get: vi.fn(() => Promise.resolve({ status: 200, data: [] })),
      post: vi.fn(() => Promise.resolve({ status: 200, data: {} })),
      patch: vi.fn(() => Promise.resolve({ status: 200, data: {} })),
      delete: vi.fn(() => Promise.resolve({ status: 200, data: {} })),
    };

    beforeEach(() => {
      window.axios = axiosMock;
      vi.clearAllMocks();
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    describe('get', () => {
      it('should make a GET request to the correct endpoint', async () => {
        const mockData = [
          { id: 1, prompt_key: 'greeting', text: 'Hello there!' },
          { id: 2, prompt_key: 'closing', text: 'Thanks for contacting us!' },
        ];

        axiosMock.get.mockResolvedValue({ status: 200, data: mockData });

        const response = await PromptAPI.get();

        expect(response.status).toBe(200);
        expect(response.data).toEqual(mockData);
        expect(axiosMock.get).toHaveBeenCalledTimes(1);
        expect(axiosMock.get).toHaveBeenCalledWith(PromptAPI.url);
      });

      it('should handle successful response and parse data correctly', async () => {
        const mockData = [
          {
            id: 1,
            prompt_key: 'greeting',
            text: 'Hello! How can I help you today?',
            account_id: 1,
            created_at: '2024-01-01T00:00:00Z',
            updated_at: '2024-01-01T00:00:00Z',
          },
        ];

        axiosMock.get.mockResolvedValue({ status: 200, data: mockData });

        const response = await PromptAPI.get();

        expect(response.data).toHaveLength(1);
        expect(response.data[0]).toHaveProperty('id', 1);
        expect(response.data[0]).toHaveProperty('prompt_key', 'greeting');
        expect(response.data[0]).toHaveProperty('text', 'Hello! How can I help you today?');
      });

      it('should handle network errors gracefully', async () => {
        const mockError = new Error('Network Error');
        axiosMock.get.mockRejectedValue(mockError);

        await expect(PromptAPI.get()).rejects.toThrow('Network Error');
      });

      it('should handle server errors (500) gracefully', async () => {
        const mockError = new Error('Request failed with status code 500');
        axiosMock.get.mockRejectedValue(mockError);

        await expect(PromptAPI.get()).rejects.toThrow('Request failed with status code 500');
      });

      it('should handle authentication errors (401) gracefully', async () => {
        const mockError = new Error('Request failed with status code 401');
        axiosMock.get.mockRejectedValue(mockError);

        await expect(PromptAPI.get()).rejects.toThrow('Request failed with status code 401');
      });

      it('should verify the correct URL construction', () => {
        // In test environment, window.location might not have account info
        // so the URL might be either /api/v2/prompts or /api/v2/accounts/{id}/prompts
        const expectedPattern = /\/api\/v2\/(accounts\/\d+\/)?prompts/;
        expect(PromptAPI.url).toMatch(expectedPattern);
      });
    });

    describe('update', () => {
      it('should make a PATCH request to the correct endpoint with data', async () => {
        const promptId = 1;
        const updateData = {
          text: 'Updated greeting message',
          prompt_key: 'greeting_updated',
        };
        const mockResponse = {
          id: promptId,
          ...updateData,
          account_id: 1,
          updated_at: '2024-01-02T00:00:00Z',
        };

        axiosMock.patch.mockResolvedValue({ status: 200, data: mockResponse });

        const response = await PromptAPI.update(promptId, updateData);

        expect(response.status).toBe(200);
        expect(response.data).toEqual(mockResponse);
        expect(axiosMock.patch).toHaveBeenCalledTimes(1);
        expect(axiosMock.patch).toHaveBeenCalledWith(`${PromptAPI.url}/${promptId}`, updateData);
      });

      it('should handle successful update with updated object', async () => {
        const promptId = 2;
        const updateData = {
          text: 'Thank you for contacting us! We will get back to you soon.',
          prompt_key: 'closing',
        };
        const mockResponse = {
          id: promptId,
          text: updateData.text,
          prompt_key: updateData.prompt_key,
          account_id: 1,
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-02T12:30:00Z',
        };

        axiosMock.patch.mockResolvedValue({ status: 200, data: mockResponse });

        const response = await PromptAPI.update(promptId, updateData);

        expect(response.data).toHaveProperty('id', promptId);
        expect(response.data).toHaveProperty('text', updateData.text);
        expect(response.data).toHaveProperty('prompt_key', updateData.prompt_key);
        expect(response.data).toHaveProperty('updated_at');
      });

      it('should handle validation errors (422) gracefully', async () => {
        const promptId = 1;
        const invalidData = {
          text: '', // Invalid: empty text
          prompt_key: 'greeting',
        };
        const mockError = {
          response: {
            status: 422,
            data: {
              errors: {
                text: ["can't be blank"],
              },
            },
          },
        };

        axiosMock.patch.mockRejectedValue(mockError);

        await expect(PromptAPI.update(promptId, invalidData)).rejects.toMatchObject({
          response: {
            status: 422,
            data: {
              errors: {
                text: ["can't be blank"],
              },
            },
          },
        });
      });

      it('should handle authorization errors (404) gracefully', async () => {
        const promptId = 999; // Non-existent or unauthorized prompt
        const updateData = {
          text: 'Updated text',
          prompt_key: 'greeting',
        };
        const mockError = new Error('Request failed with status code 404');

        axiosMock.patch.mockRejectedValue(mockError);

        await expect(PromptAPI.update(promptId, updateData)).rejects.toThrow('Request failed with status code 404');
      });

      it('should send correct payload with proper structure', async () => {
        const promptId = 1;
        const updateData = {
          text: 'Hello! How may I assist you today?',
          prompt_key: 'greeting_formal',
        };

        axiosMock.patch.mockResolvedValue({ status: 200, data: { id: promptId, ...updateData } });

        await PromptAPI.update(promptId, updateData);

        const callArgs = axiosMock.patch.mock.calls[0];
        expect(callArgs[0]).toBe(`${PromptAPI.url}/${promptId}`);
        expect(callArgs[1]).toEqual(updateData);
        expect(callArgs[1]).toHaveProperty('text');
        expect(callArgs[1]).toHaveProperty('prompt_key');
      });
    });
  });
}); 