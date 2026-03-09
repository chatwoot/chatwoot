import axios from 'axios';
import { actions } from '../../draftMessages';
import types from '../../../mutation-types';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

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
});
