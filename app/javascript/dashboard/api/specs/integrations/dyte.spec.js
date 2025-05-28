import DyteAPIClient from '../../integrations/dyte';
import ApiClient from '../../ApiClient';

describe('#accountAPI', () => {
  it('creates correct instance', () => {
    expect(DyteAPIClient).toBeInstanceOf(ApiClient);
    expect(DyteAPIClient).toHaveProperty('createAMeeting');
    expect(DyteAPIClient).toHaveProperty('addParticipantToMeeting');
  });

  describe('createAMeeting', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('creates a valid request', () => {
      DyteAPIClient.createAMeeting(1);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/dyte/create_a_meeting',
        {
          conversation_id: 1,
        }
      );
    });
  });

  describe('addParticipantToMeeting', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('creates a valid request', () => {
      DyteAPIClient.addParticipantToMeeting(1);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/dyte/add_participant_to_meeting',
        {
          message_id: 1,
        }
      );
    });
  });
});
