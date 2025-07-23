import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import AiMessageFeedbacksAPI from '../aiMessageFeedbacks';

describe('AiMessageFeedbacksAPI', () => {
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      get: vi.fn(() => Promise.resolve({ status: 200, data: {} })),
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

    describe('create', () => {
      it('should make a POST request to create AI feedback', async () => {
        const messageId = 123;
        const feedbackData = {
          rating: 'positive',
          feedback_text: 'This AI response was very helpful',
        };
        const mockResponse = {
          id: messageId,
          content_attributes: {
            ai_feedback: {
              rating: 'positive',
              feedback_text: 'This AI response was very helpful',
              agent_id: 1,
              created_at: '2024-01-01T00:00:00Z',
            },
          },
        };

        axiosMock.post.mockResolvedValue({ status: 200, data: mockResponse });

        const response = await AiMessageFeedbacksAPI.create(
          messageId,
          feedbackData
        );

        expect(response.status).toBe(200);
        expect(response.data).toEqual(mockResponse);
        expect(axiosMock.post).toHaveBeenCalledTimes(1);
        expect(axiosMock.post).toHaveBeenCalledWith(AiMessageFeedbacksAPI.url, {
          message_id: messageId,
          ai_feedback: feedbackData,
        });
      });

      it('should handle successful feedback creation with correct payload structure', async () => {
        const messageId = 456;
        const feedbackData = {
          rating: 'negative',
          feedback_text: 'This response was not accurate',
        };
        const mockResponse = {
          id: messageId,
          content_attributes: {
            ai_feedback: {
              rating: 'negative',
              feedback_text: 'This response was not accurate',
              agent_id: 2,
              created_at: '2024-01-01T12:00:00Z',
            },
          },
        };

        axiosMock.post.mockResolvedValue({ status: 200, data: mockResponse });

        const response = await AiMessageFeedbacksAPI.create(
          messageId,
          feedbackData
        );

        expect(response.data).toHaveProperty('id', messageId);
        expect(response.data.content_attributes).toHaveProperty('ai_feedback');
        expect(response.data.content_attributes.ai_feedback).toHaveProperty(
          'rating',
          'negative'
        );
        expect(response.data.content_attributes.ai_feedback).toHaveProperty(
          'feedback_text',
          'This response was not accurate'
        );
        expect(response.data.content_attributes.ai_feedback).toHaveProperty(
          'agent_id'
        );
        expect(response.data.content_attributes.ai_feedback).toHaveProperty(
          'created_at'
        );
      });

      it('should handle partial feedback data (rating only)', async () => {
        const messageId = 789;
        const feedbackData = {
          rating: 'positive',
        };

        axiosMock.post.mockResolvedValue({
          status: 200,
          data: { id: messageId },
        });

        await AiMessageFeedbacksAPI.create(messageId, feedbackData);

        expect(axiosMock.post).toHaveBeenCalledWith(AiMessageFeedbacksAPI.url, {
          message_id: messageId,
          ai_feedback: { rating: 'positive' },
        });
      });

      it('should handle partial feedback data (feedback_text only)', async () => {
        const messageId = 101;
        const feedbackData = {
          feedback_text: 'Good response but could be improved',
        };

        axiosMock.post.mockResolvedValue({
          status: 200,
          data: { id: messageId },
        });

        await AiMessageFeedbacksAPI.create(messageId, feedbackData);

        expect(axiosMock.post).toHaveBeenCalledWith(AiMessageFeedbacksAPI.url, {
          message_id: messageId,
          ai_feedback: { feedback_text: 'Good response but could be improved' },
        });
      });

      it('should handle authorization errors (403) gracefully', async () => {
        const messageId = 123;
        const feedbackData = { rating: 'positive' };
        const mockError = new Error('Request failed with status code 403');

        axiosMock.post.mockRejectedValue(mockError);

        await expect(
          AiMessageFeedbacksAPI.create(messageId, feedbackData)
        ).rejects.toThrow('Request failed with status code 403');
      });

      it('should handle not found errors (404) gracefully', async () => {
        const messageId = 999999;
        const feedbackData = { rating: 'positive' };
        const mockError = new Error('Request failed with status code 404');

        axiosMock.post.mockRejectedValue(mockError);

        await expect(
          AiMessageFeedbacksAPI.create(messageId, feedbackData)
        ).rejects.toThrow('Request failed with status code 404');
      });

      it('should handle network errors gracefully', async () => {
        const messageId = 123;
        const feedbackData = { rating: 'positive' };
        const mockError = new Error('Network Error');

        axiosMock.post.mockRejectedValue(mockError);

        await expect(
          AiMessageFeedbacksAPI.create(messageId, feedbackData)
        ).rejects.toThrow('Network Error');
      });
    });

    describe('update', () => {
      it('should make a PATCH request to update AI feedback', async () => {
        const messageId = 123;
        const feedbackData = {
          rating: 'negative',
          feedback_text: 'Updated: This response was not helpful',
        };
        const mockResponse = {
          id: messageId,
          content_attributes: {
            ai_feedback: {
              rating: 'negative',
              feedback_text: 'Updated: This response was not helpful',
              agent_id: 1,
              created_at: '2024-01-01T00:00:00Z',
              updated_at: '2024-01-01T12:00:00Z',
            },
          },
        };

        axiosMock.patch.mockResolvedValue({ status: 200, data: mockResponse });

        const response = await AiMessageFeedbacksAPI.update(
          messageId,
          feedbackData
        );

        expect(response.status).toBe(200);
        expect(response.data).toEqual(mockResponse);
        expect(axiosMock.patch).toHaveBeenCalledTimes(1);
        expect(axiosMock.patch).toHaveBeenCalledWith(
          AiMessageFeedbacksAPI.url,
          {
            message_id: messageId,
            ai_feedback: feedbackData,
          }
        );
      });

      it('should handle successful update with updated timestamps', async () => {
        const messageId = 456;
        const feedbackData = {
          rating: 'positive',
          feedback_text: 'Actually, this was helpful after all',
        };
        const mockResponse = {
          id: messageId,
          content_attributes: {
            ai_feedback: {
              rating: 'positive',
              feedback_text: 'Actually, this was helpful after all',
              agent_id: 1,
              created_at: '2024-01-01T00:00:00Z',
              updated_at: '2024-01-01T15:30:00Z',
            },
          },
        };

        axiosMock.patch.mockResolvedValue({ status: 200, data: mockResponse });

        const response = await AiMessageFeedbacksAPI.update(
          messageId,
          feedbackData
        );

        expect(response.data.content_attributes.ai_feedback).toHaveProperty(
          'updated_at'
        );
        expect(response.data.content_attributes.ai_feedback.updated_at).toBe(
          '2024-01-01T15:30:00Z'
        );
      });

      it('should handle unauthorized update attempts (401)', async () => {
        const messageId = 123;
        const feedbackData = { rating: 'neutral' };
        const mockError = new Error('Request failed with status code 401');

        axiosMock.patch.mockRejectedValue(mockError);

        await expect(
          AiMessageFeedbacksAPI.update(messageId, feedbackData)
        ).rejects.toThrow('Request failed with status code 401');
      });

      it('should handle feedback not found (404)', async () => {
        const messageId = 123;
        const feedbackData = { rating: 'positive' };
        const mockError = new Error('Request failed with status code 404');

        axiosMock.patch.mockRejectedValue(mockError);

        await expect(
          AiMessageFeedbacksAPI.update(messageId, feedbackData)
        ).rejects.toThrow('Request failed with status code 404');
      });

      it('should send correct payload structure for updates', async () => {
        const messageId = 789;
        const feedbackData = {
          rating: 'neutral',
          feedback_text: 'Updated feedback text',
        };

        axiosMock.patch.mockResolvedValue({
          status: 200,
          data: { id: messageId },
        });

        await AiMessageFeedbacksAPI.update(messageId, feedbackData);

        const callArgs = axiosMock.patch.mock.calls[0];
        expect(callArgs[0]).toBe(AiMessageFeedbacksAPI.url);
        expect(callArgs[1]).toEqual({
          message_id: messageId,
          ai_feedback: feedbackData,
        });
        expect(callArgs[1]).toHaveProperty('message_id', messageId);
        expect(callArgs[1].ai_feedback).toHaveProperty('rating', 'neutral');
        expect(callArgs[1].ai_feedback).toHaveProperty(
          'feedback_text',
          'Updated feedback text'
        );
      });
    });

    describe('delete', () => {
      it('should make a DELETE request to remove AI feedback', async () => {
        const messageId = 123;

        axiosMock.delete.mockResolvedValue({ status: 200, data: {} });

        const response = await AiMessageFeedbacksAPI.delete(messageId);

        expect(response.status).toBe(200);
        expect(axiosMock.delete).toHaveBeenCalledTimes(1);
        expect(axiosMock.delete).toHaveBeenCalledWith(
          `${AiMessageFeedbacksAPI.url}/${messageId}`
        );
      });

      it('should handle successful deletion', async () => {
        const messageId = 456;

        axiosMock.delete.mockResolvedValue({ status: 200, data: {} });

        const response = await AiMessageFeedbacksAPI.delete(messageId);

        expect(response.status).toBe(200);
        expect(response.data).toEqual({});
      });

      it('should handle unauthorized deletion attempts (401)', async () => {
        const messageId = 123;
        const mockError = new Error('Request failed with status code 401');

        axiosMock.delete.mockRejectedValue(mockError);

        await expect(AiMessageFeedbacksAPI.delete(messageId)).rejects.toThrow(
          'Request failed with status code 401'
        );
      });

      it('should handle feedback not found (404)', async () => {
        const messageId = 999999;
        const mockError = new Error('Request failed with status code 404');

        axiosMock.delete.mockRejectedValue(mockError);

        await expect(AiMessageFeedbacksAPI.delete(messageId)).rejects.toThrow(
          'Request failed with status code 404'
        );
      });

      it('should construct correct delete URL', async () => {
        const messageId = 789;

        axiosMock.delete.mockResolvedValue({ status: 200, data: {} });

        await AiMessageFeedbacksAPI.delete(messageId);

        const callArgs = axiosMock.delete.mock.calls[0];
        expect(callArgs[0]).toBe(`${AiMessageFeedbacksAPI.url}/${messageId}`);
      });
    });

    describe('URL construction', () => {
      it('should verify correct URL construction for account-scoped API', () => {
        // The URL should follow the pattern for account-scoped resources
        const expectedPattern =
          /\/api\/v1\/(accounts\/\d+\/)?ai_message_feedbacks/;
        expect(AiMessageFeedbacksAPI.url).toMatch(expectedPattern);
      });

      it('should inherit from ApiClient with correct configuration', () => {
        expect(AiMessageFeedbacksAPI).toHaveProperty('url');
        expect(typeof AiMessageFeedbacksAPI.create).toBe('function');
        expect(typeof AiMessageFeedbacksAPI.update).toBe('function');
        expect(typeof AiMessageFeedbacksAPI.delete).toBe('function');
      });
    });

    describe('edge cases and error handling', () => {
      it('should handle empty feedback data gracefully', async () => {
        const messageId = 123;
        const emptyFeedback = {};

        axiosMock.post.mockResolvedValue({
          status: 200,
          data: { id: messageId },
        });

        await AiMessageFeedbacksAPI.create(messageId, emptyFeedback);

        expect(axiosMock.post).toHaveBeenCalledWith(AiMessageFeedbacksAPI.url, {
          message_id: messageId,
          ai_feedback: {},
        });
      });

      it('should handle null feedback data', async () => {
        const messageId = 123;
        const nullFeedback = null;

        axiosMock.post.mockResolvedValue({
          status: 200,
          data: { id: messageId },
        });

        await AiMessageFeedbacksAPI.create(messageId, nullFeedback);

        expect(axiosMock.post).toHaveBeenCalledWith(AiMessageFeedbacksAPI.url, {
          message_id: messageId,
          ai_feedback: null,
        });
      });

      it('should handle server errors (500) gracefully', async () => {
        const messageId = 123;
        const feedbackData = { rating: 'positive' };
        const mockError = new Error('Request failed with status code 500');

        axiosMock.post.mockRejectedValue(mockError);

        await expect(
          AiMessageFeedbacksAPI.create(messageId, feedbackData)
        ).rejects.toThrow('Request failed with status code 500');
      });

      it('should handle validation errors (422) gracefully', async () => {
        const messageId = 123;
        const invalidFeedback = { rating: 'invalid_rating' };
        const mockError = {
          response: {
            status: 422,
            data: {
              errors: {
                rating: ['is not included in the list'],
              },
            },
          },
        };

        axiosMock.post.mockRejectedValue(mockError);

        await expect(
          AiMessageFeedbacksAPI.create(messageId, invalidFeedback)
        ).rejects.toMatchObject({
          response: {
            status: 422,
            data: {
              errors: {
                rating: ['is not included in the list'],
              },
            },
          },
        });
      });
    });
  });
});
