import axios from 'axios';
import { actions } from '../actions';
import * as types from '../../../mutation-types';
const articleList = [
  {
    id: 1,
    category_id: 1,
    title: 'Documents are required to complete KYC',
  },
];
const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: articleList } });
      await actions.fetchAllArticles({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [
          types.default.ADD_HELP_CENTER_ARTICLE,
          {
            id: 1,
            category_id: 1,
            title: 'Documents are required to complete KYC',
          },
        ],
        [types.default.ADD_HELP_CENTER_ARTICLE_ID, 1],
        [
          types.default.ADD_HELP_CENTER_ARTICLE_FLAG,
          { uiFlags: {}, helpCenterId: 1 },
        ],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.fetchAllArticles({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
});
