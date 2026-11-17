import axios from 'axios';
import { actions } from '../../inboxes';
import * as types from '../../../mutation-types';
import inboxList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      const mockedGet = vi.fn(url => {
        if (url === '/api/v1/inboxes') {
          return Promise.resolve({ data: { payload: inboxList } });
        }
        if (url === '/api/v1/accounts//cache_keys') {
          return Promise.resolve({ data: { cache_keys: { inboxes: 0 } } });
        }
        // Return default value or throw an error for unexpected requests
        return Promise.reject(new Error('Unexpected request: ' + url));
      });

      axios.get = mockedGet;

      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: false }],
        [types.default.SET_INBOXES, inboxList],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#createWebsiteChannel', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: inboxList[0] });
      await actions.createWebsiteChannel({ commit }, inboxList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.ADD_INBOXES, inboxList[0]],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.createWebsiteChannel({ commit })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#createWhatsAppEmbeddedSignup', () => {
    const signupResponse = {
      success: true,
      id: 42,
      name: 'Shop WhatsApp',
      channel_type: 'whatsapp',
    };

    it('adds a newly created inbox', async () => {
      axios.post.mockResolvedValue({ data: signupResponse });
      await actions.createWhatsAppEmbeddedSignup(
        { commit, state: { records: [] } },
        { code: 'code' }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.ADD_INBOXES, signupResponse],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });

    it('does not add an inbox the signup reconnected', async () => {
      axios.post.mockResolvedValue({ data: signupResponse });
      await actions.createWhatsAppEmbeddedSignup(
        { commit, state: { records: [{ id: 42 }] } },
        { code: 'code' }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#createVoiceChannel', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: inboxList[0] });
      await actions.createVoiceChannel({ commit }, inboxList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.ADD_INBOXES, inboxList[0]],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.createVoiceChannel({ commit })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#createFBChannel', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: inboxList[0] });
      await actions.createFBChannel({ commit }, inboxList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.ADD_INBOXES, inboxList[0]],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      const error = { response: { data: { error: 'Incorrect header' } } };
      axios.post.mockRejectedValue(error);
      await expect(actions.createFBChannel({ commit })).rejects.toBe(error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#updateInbox', () => {
    it('sends correct actions if API is success', async () => {
      const updatedInbox = inboxList[0];
      updatedInbox.enable_auto_assignment = false;

      axios.patch.mockResolvedValue({ data: updatedInbox });
      await actions.updateInbox(
        { commit },
        { id: updatedInbox.id, inbox: { enable_auto_assignment: false } }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdating: true }],
        [types.default.EDIT_INBOXES, updatedInbox],
        [types.default.SET_INBOXES_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.updateInbox(
          { commit },
          { id: inboxList[0].id, inbox: { enable_auto_assignment: false } }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdating: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#updateInboxIMAP', () => {
    it('sends correct actions if API is success', async () => {
      const updatedInbox = inboxList[0];

      axios.patch.mockResolvedValue({ data: updatedInbox });
      await actions.updateInboxIMAP(
        { commit },
        { id: updatedInbox.id, inbox: { channel: { imap_enabled: true } } }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingIMAP: true }],
        [types.default.EDIT_INBOXES, updatedInbox],
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingIMAP: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.updateInboxIMAP(
          { commit },
          { id: inboxList[0].id, inbox: { channel: { imap_enabled: true } } }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingIMAP: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingIMAP: false }],
      ]);
    });
  });

  describe('#updateInboxSMTP', () => {
    it('sends correct actions if API is success', async () => {
      const updatedInbox = inboxList[0];

      axios.patch.mockResolvedValue({ data: updatedInbox });
      await actions.updateInboxSMTP(
        { commit },
        { id: updatedInbox.id, inbox: { channel: { smtp_enabled: true } } }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingSMTP: true }],
        [types.default.EDIT_INBOXES, updatedInbox],
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingSMTP: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.updateInboxSMTP(
          { commit },
          { id: inboxList[0].id, inbox: { channel: { smtp_enabled: true } } }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingSMTP: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isUpdatingSMTP: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: inboxList[0] });
      await actions.delete({ commit }, { id: inboxList[0].id });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_INBOXES, inboxList[0].id],
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('asks the API to release the WhatsApp number when requested', async () => {
      axios.delete.mockResolvedValue({});
      await actions.delete(
        { commit },
        { id: inboxList[0].id, releaseWhatsappNumber: true }
      );
      expect(axios.delete).toHaveBeenCalledWith(
        expect.stringContaining(`/inboxes/${inboxList[0].id}`),
        { params: { release_whatsapp_number: true } }
      );
    });
    it("rejects with the API's error message so the reason can be shown", async () => {
      axios.delete.mockRejectedValue({
        response: { data: { message: 'Meta could not release the number' } },
      });
      await expect(
        actions.delete({ commit }, { id: inboxList[0].id })
      ).rejects.toThrow('Meta could not release the number');
      expect(commit.mock.calls).toEqual([
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: true }],
        [types.default.SET_INBOXES_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#deleteInboxAvatar', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue();
      await expect(
        actions.deleteInboxAvatar({}, inboxList[0].id)
      ).resolves.toBe();
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.deleteInboxAvatar({}, inboxList[0].id)
      ).rejects.toThrow(Error);
    });
  });

  describe('#syncTemplates', () => {
    it('sends correct API call when sync is successful', async () => {
      axios.post.mockResolvedValue({
        data: { message: 'Template sync initiated successfully' },
      });

      await actions.syncTemplates({ commit }, 123);

      expect(axios.post).toHaveBeenCalledWith(
        '/api/v1/inboxes/123/sync_templates'
      );
    });

    it('throws error when API call fails', async () => {
      const errorMessage =
        'Template sync is only available for WhatsApp channels';
      axios.post.mockRejectedValue(new Error(errorMessage));

      await expect(actions.syncTemplates({ commit }, 123)).rejects.toThrow(
        errorMessage
      );
    });
  });
});
