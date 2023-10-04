import axios from 'axios';
import { actions } from '../../draftMessages';
import types from '../../../mutation-types';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#set', () => {
    it('sends correct actions', async () => {
      await actions.set(
        {
          commit,
          state: {
            draftMessages: {},
          },
        },
        { key: 'draft-32-REPLY', message: 'Hey how ' }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.SET_DRAFT_MESSAGES,
          {
            key: 'draft-32-REPLY',
            message: 'Hey how ',
          },
        ],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions', async () => {
      await actions.delete(
        {
          commit,
          state: {
            draftMessages: {},
          },
        },
        { key: 'draft-32-REPLY' }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.SET_DRAFT_MESSAGES,
          {
            key: 'draft-32-REPLY',
          },
        ],
      ]);
    });
  });

  describe('#setReplyEditorMode', () => {
    it('sends correct actions', async () => {
      await actions.setReplyEditorMode(
        {
          commit,
          state: {
            draftMessages: {},
          },
        },
        { mode: 'reply' }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.SET_REPLY_EDITOR_MODE,
          {
            mode: 'reply',
          },
        ],
      ]);
    });
  });

  describe('#setInReplyTo', () => {
    it('sends correct actions', async () => {
      await actions.setInReplyTo(
        {
          commit,
          state: {
            inReplyTo: {},
          },
        },
        { conversationId: 45534, inReplyToMessage: 24332 }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.SET_IN_REPLY_TO,
          {
            conversationId: 45534,
            inReplyToMessage: 24332,
          },
        ],
      ]);
    });
  });

  describe('#deleteInReplyTo', () => {
    it('sends correct actions', async () => {
      await actions.deleteInReplyTo(
        {
          commit,
          state: {
            inReplyTo: {},
          },
        },
        { conversationId: 45534 }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.REMOVE_IN_REPLY_TO,
          {
            conversationId: 45534,
          },
        ],
      ]);
    });
  });
});
