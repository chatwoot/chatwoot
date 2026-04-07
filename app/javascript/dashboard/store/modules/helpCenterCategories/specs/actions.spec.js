import axios from 'axios';
import { actions } from '../actions';
import * as types from '../../../mutation-types';
import { categoriesPayload } from './fixtures';
const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#index', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: categoriesPayload });
      await actions.index({ commit }, { portalSlug: 'room-rental' });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.CLEAR_CATEGORIES],
        [types.default.ADD_MANY_CATEGORIES, categoriesPayload.payload],
        [types.default.ADD_MANY_CATEGORIES_ID, [1, 2]],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.index({ commit }, { portalSlug: 'room-rental' })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isFetching: true }],
        [types.default.SET_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: categoriesPayload });
      await actions.create({ commit }, categoriesPayload);
      const { id: categoryId } = categoriesPayload;
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isCreating: true }],
        [types.default.ADD_CATEGORY, categoriesPayload.payload],
        [types.default.ADD_CATEGORY_ID, categoryId],
        [types.default.SET_UI_FLAG, { isCreating: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.create({ commit }, 'web-docs', categoriesPayload.payload[0])
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_UI_FLAG, { isCreating: true }],
        [types.default.SET_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: categoriesPayload });
      await actions.update(
        { commit },
        {
          portalSlug: 'room-rental',
          categoryId: 1,
          categoryObj: categoriesPayload.payload[0],
        }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_CATEGORY_FLAG,
          {
            uiFlags: {
              isUpdating: true,
            },
            categoryId: 1,
          },
        ],
        [types.default.UPDATE_CATEGORY, categoriesPayload.payload],
        [
          types.default.ADD_CATEGORY_FLAG,
          {
            uiFlags: {
              isUpdating: false,
            },
            categoryId: 1,
          },
        ],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update(
          { commit },
          {
            portalSlug: 'room-rental',
            categoryId: 1,
            categoryObj: categoriesPayload.payload[0],
          }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_CATEGORY_FLAG,
          { uiFlags: { isUpdating: true }, categoryId: 1 },
        ],
        [
          types.default.ADD_CATEGORY_FLAG,
          { uiFlags: { isUpdating: false }, categoryId: 1 },
        ],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: categoriesPayload });
      await actions.delete(
        { commit },
        {
          portalSlug: 'room-rental',
          categoryId: categoriesPayload.payload[0].id,
        }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_CATEGORY_FLAG,
          { uiFlags: { isDeleting: true }, categoryId: 1 },
        ],
        [types.default.REMOVE_CATEGORY, categoriesPayload.payload[0].id],
        [types.default.REMOVE_CATEGORY_ID, categoriesPayload.payload[0].id],
        [
          types.default.ADD_CATEGORY_FLAG,
          { uiFlags: { isDeleting: false }, categoryId: 1 },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete(
          { commit },
          {
            portalSlug: 'room-rental',
            categoryId: categoriesPayload.payload[0].id,
          }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [
          types.default.ADD_CATEGORY_FLAG,
          { uiFlags: { isDeleting: true }, categoryId: 1 },
        ],
        [
          types.default.ADD_CATEGORY_FLAG,
          { uiFlags: { isDeleting: false }, categoryId: 1 },
        ],
      ]);
    });
  });

  describe('#reorder', () => {
    const state = {
      categories: {
        byId: {
          1: { id: 1, name: 'Category 1', position: 10 },
          2: { id: 2, name: 'Category 2', position: 20 },
        },
      },
    };

    it('commits SET_CATEGORY_POSITIONS and calls API when reorder is successful', async () => {
      axios.post.mockResolvedValue({ data: {} });
      const reorderedGroup = { 2: 1, 1: 2 };

      await actions.reorder(
        { commit, state },
        {
          portalSlug: 'room-rental',
          reorderedGroup,
        }
      );

      expect(commit).toHaveBeenCalledWith(
        types.default.SET_CATEGORY_POSITIONS,
        reorderedGroup
      );
      expect(axios.post).toHaveBeenCalledWith(
        expect.stringContaining('/portals/room-rental/categories/reorder'),
        {
          positions_hash: { 2: 1, 1: 2 },
        }
      );
    });

    it('rolls back positions and throws when API call fails', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      const reorderedGroup = { 2: 1, 1: 2 };

      await expect(
        actions.reorder(
          { commit, state },
          {
            portalSlug: 'room-rental',
            reorderedGroup,
          }
        )
      ).rejects.toEqual({ message: 'Incorrect header' });

      expect(commit).toHaveBeenCalledWith(
        types.default.SET_CATEGORY_POSITIONS,
        reorderedGroup
      );
      expect(commit).toHaveBeenCalledWith(
        types.default.SET_CATEGORY_POSITIONS,
        { 1: 10, 2: 20 }
      );
    });
  });
});
