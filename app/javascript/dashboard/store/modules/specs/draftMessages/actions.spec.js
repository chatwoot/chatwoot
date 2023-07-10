import axios from 'axios';
import { actions } from '../../draftMessages';
import types from '../../../mutation-types';
import { data } from './fixtures';

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
        { draftMessages: data }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.SET_DRAFT_MESSAGES,
          {
            draftMessages: {
              'draft-32-REPLY': 'Hey how ',
              'draft-31-REPLY': 'Nice',
            },
          },
        ],
      ]);
    });
  });
});
