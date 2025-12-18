import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import VoiceAPI from './voiceAPIClient';
import ContactsAPI from '../../contacts';

describe('VoiceAPI', () => {
  const originalAxios = window.axios;
  const axiosMock = {
    post: vi.fn(() => Promise.resolve({ data: {} })),
    get: vi.fn(() => Promise.resolve({ data: {} })),
    delete: vi.fn(() => Promise.resolve({ data: {} })),
  };

  beforeEach(() => {
    window.axios = axiosMock;
    vi.clearAllMocks();
  });

  afterEach(() => {
    window.axios = originalAxios;
    vi.restoreAllMocks();
  });

  describe('constructor', () => {
    it('extends ApiClient with correct parameters', () => {
      expect(VoiceAPI.resource).toBe('voice');
      expect(VoiceAPI.options).toEqual({ accountScoped: true });
    });
  });

  describe('initiateCall', () => {
    it('delegates to ContactsAPI.initiateCall', async () => {
      const contactId = 123;
      const inboxId = 456;
      const mockData = { conversation_id: 789, call_sid: 'test-sid' };

      const spy = vi
        .spyOn(ContactsAPI, 'initiateCall')
        .mockResolvedValue({ data: mockData });

      const result = await VoiceAPI.initiateCall(contactId, inboxId);

      expect(spy).toHaveBeenCalledWith(contactId, inboxId);
      expect(result).toEqual(mockData);
    });

    it('handles errors from ContactsAPI', async () => {
      const error = new Error('Contact not found');
      const spy = vi
        .spyOn(ContactsAPI, 'initiateCall')
        .mockRejectedValue(error);

      await expect(VoiceAPI.initiateCall(123, 456)).rejects.toThrow(
        'Contact not found'
      );
      expect(spy).toHaveBeenCalled();
    });
  });

  describe('leaveConference', () => {
    it('sends DELETE request to conference endpoint', async () => {
      const inboxId = 456;
      const conversationId = 789;
      const mockData = { success: true };

      axiosMock.delete.mockResolvedValue({ data: mockData });

      const result = await VoiceAPI.leaveConference(inboxId, conversationId);

      expect(axiosMock.delete).toHaveBeenCalledWith(
        expect.stringContaining(`/inboxes/${inboxId}/conference`),
        {
          params: { conversation_id: conversationId },
        }
      );
      expect(result).toEqual(mockData);
    });

    it('handles errors during conference leave', async () => {
      const error = new Error('Failed to leave conference');
      axiosMock.delete.mockRejectedValue(error);

      await expect(VoiceAPI.leaveConference(456, 789)).rejects.toThrow(
        'Failed to leave conference'
      );
    });
  });

  describe('joinConference', () => {
    it('sends POST request to conference endpoint', async () => {
      const params = {
        conversationId: 789,
        inboxId: 456,
        callSid: 'test-call-sid',
      };
      const mockData = { conference_sid: 'test-conference-sid' };

      axiosMock.post.mockResolvedValue({ data: mockData });

      const result = await VoiceAPI.joinConference(params);

      expect(axiosMock.post).toHaveBeenCalledWith(
        expect.stringContaining(`/inboxes/${params.inboxId}/conference`),
        {
          conversation_id: params.conversationId,
          call_sid: params.callSid,
        }
      );
      expect(result).toEqual(mockData);
    });

    it('handles errors during conference join', async () => {
      const error = new Error('Failed to join conference');
      axiosMock.post.mockRejectedValue(error);

      await expect(
        VoiceAPI.joinConference({
          conversationId: 789,
          inboxId: 456,
          callSid: 'test-sid',
        })
      ).rejects.toThrow('Failed to join conference');
    });
  });

  describe('getToken', () => {
    it('sends GET request to token endpoint', async () => {
      const inboxId = 456;
      const mockData = { token: 'test-token-123', account_id: 'test-account' };

      axiosMock.get.mockResolvedValue({ data: mockData });

      const result = await VoiceAPI.getToken(inboxId);

      expect(axiosMock.get).toHaveBeenCalledWith(
        expect.stringContaining(`/inboxes/${inboxId}/conference/token`)
      );
      expect(result).toEqual(mockData);
    });

    it('rejects when inboxId is not provided', async () => {
      await expect(VoiceAPI.getToken(null)).rejects.toThrow(
        'Inbox ID is required'
      );
      await expect(VoiceAPI.getToken(undefined)).rejects.toThrow(
        'Inbox ID is required'
      );
      expect(axiosMock.get).not.toHaveBeenCalled();
    });

    it('handles errors during token fetch', async () => {
      const error = new Error('Token generation failed');
      axiosMock.get.mockRejectedValue(error);

      await expect(VoiceAPI.getToken(456)).rejects.toThrow(
        'Token generation failed'
      );
    });
  });
});
