import axios from 'axios';
import { actions } from '../actions';
import * as types from '../../../mutation-types';
import categoriesList from './fixtures';
const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#index', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: categoriesList });
      await actions.index({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.ADD_MANY_CATEGORIES, categoriesList.payload],
        [types.default.ADD_MANY_CATEGORIES_ID, [1]],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.index({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  //   describe('#create', () => {
  //     it('sends correct actions if API is success', async () => {
  //       axios.post.mockResolvedValue({ data: categoriesList[0] });
  //       await actions.create({ commit }, categoriesList[0]);
  //       expect(commit.mock.calls).toEqual([
  //         [types.default.SET_UI_FLAG, { isCreating: true }],
  //         [types.default.ADD_ARTICLE, categoriesList[0]],
  //         [types.default.ADD_ARTICLE_ID, 1],
  //         [types.default.SET_UI_FLAG, { isCreating: false }],
  //       ]);
  //     });
  //     it('sends correct actions if API is error', async () => {
  //       axios.post.mockRejectedValue({ message: 'Incorrect header' });
  //       await expect(
  //         actions.create({ commit }, categoriesList[0])
  //       ).rejects.toThrow(Error);
  //       expect(commit.mock.calls).toEqual([
  //         [types.default.SET_UI_FLAG, { isCreating: true }],
  //         [types.default.SET_UI_FLAG, { isCreating: false }],
  //       ]);
  //     });
  //   });

  //   describe('#update', () => {
  //     it('sends correct actions if API is success', async () => {
  //       axios.patch.mockResolvedValue({ data: categoriesList[0] });
  //       await actions.update({ commit }, categoriesList[0]);
  //       expect(commit.mock.calls).toEqual([
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isUpdating: true }, articleId: 1 },
  //         ],
  //         [types.default.UPDATE_ARTICLE, categoriesList[0]],
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isUpdating: false }, articleId: 1 },
  //         ],
  //       ]);
  //     });
  //     it('sends correct actions if API is error', async () => {
  //       axios.patch.mockRejectedValue({ message: 'Incorrect header' });
  //       await expect(
  //         actions.update({ commit }, categoriesList[0])
  //       ).rejects.toThrow(Error);
  //       expect(commit.mock.calls).toEqual([
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isUpdating: true }, articleId: 1 },
  //         ],
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isUpdating: false }, articleId: 1 },
  //         ],
  //       ]);
  //     });
  //   });

  //   describe('#delete', () => {
  //     it('sends correct actions if API is success', async () => {
  //       axios.delete.mockResolvedValue({ data: categoriesList[0] });
  //       await actions.delete({ commit }, categoriesList[0].id);
  //       expect(commit.mock.calls).toEqual([
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isDeleting: true }, articleId: 1 },
  //         ],
  //         [types.default.REMOVE_ARTICLE, categoriesList[0].id],
  //         [types.default.REMOVE_ARTICLE_ID, categoriesList[0].id],
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isDeleting: false }, articleId: 1 },
  //         ],
  //       ]);
  //     });
  //     it('sends correct actions if API is error', async () => {
  //       axios.delete.mockRejectedValue({ message: 'Incorrect header' });
  //       await expect(
  //         actions.delete({ commit }, categoriesList[0].id)
  //       ).rejects.toThrow(Error);
  //       expect(commit.mock.calls).toEqual([
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isDeleting: true }, articleId: 1 },
  //         ],
  //         [
  //           types.default.ADD_ARTICLE_FLAG,
  //           { uiFlags: { isDeleting: false }, articleId: 1 },
  //         ],
  //       ]);
  //     });
  //   });
});
