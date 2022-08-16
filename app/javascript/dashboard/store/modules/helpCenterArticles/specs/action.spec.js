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
  describe('#index', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: articleList,
          meta: {
            current_page: '1',
            articles_count: 5,
          },
        },
      });
      await actions.index(
        { commit },
        { pageNumber: 1, portalSlug: 'test', locale: 'en' }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.CLEAR_ARTICLES],
        [
          types.default.ADD_MANY_ARTICLES,
          [
            {
              id: 1,
              category_id: 1,
              title: 'Documents are required to complete KYC',
            },
          ],
        ],
        [
          types.default.SET_ARTICLES_META,
          { current_page: '1', articles_count: 5 },
        ],
        [types.default.ADD_MANY_ARTICLES_ID, [1]],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.index(
          { commit },
          { pageNumber: 1, portalSlug: 'test', locale: 'en' }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: articleList[0] });
      await actions.create({ commit }, articleList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isCreating: true }],
        [types.default.ADD_ARTICLE, articleList[0]],
        [types.default.ADD_ARTICLE_ID, 1],
        [types.default.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit }, articleList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isCreating: true }],
        [types.default.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: articleList[0] });
      await actions.update({ commit }, articleList[0]);
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isUpdating: true }, articleId: 1 },
        ],
        [types.default.UPDATE_ARTICLE, articleList[0]],
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isUpdating: false }, articleId: 1 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, articleList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isUpdating: true }, articleId: 1 },
        ],
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isUpdating: false }, articleId: 1 },
        ],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: articleList[0] });
      await actions.delete({ commit }, articleList[0].id);
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isDeleting: true }, articleId: 1 },
        ],
        [types.default.REMOVE_ARTICLE, articleList[0].id],
        [types.default.REMOVE_ARTICLE_ID, articleList[0].id],
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isDeleting: false }, articleId: 1 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, articleList[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isDeleting: true }, articleId: 1 },
        ],
        [
          types.default.ADD_ARTICLE_FLAG,
          { uiFlags: { isDeleting: false }, articleId: 1 },
        ],
      ]);
    });
  });
});
