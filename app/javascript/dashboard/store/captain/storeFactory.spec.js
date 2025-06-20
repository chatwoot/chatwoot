import { throwErrorMessage } from 'dashboard/store/utils/api';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import {
  generateMutationTypes,
  createInitialState,
  createGetters,
  createMutations,
  createCrudActions,
  createStore,
} from './storeFactory';

vi.mock('dashboard/store/utils/api', () => ({
  throwErrorMessage: vi.fn(),
}));

vi.mock('shared/helpers/vuex/mutationHelpers', () => ({
  set: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  destroy: vi.fn(),
  setSingleRecord: vi.fn(),
}));

describe('storeFactory', () => {
  describe('generateMutationTypes', () => {
    it('generates correct mutation types with capitalized name', () => {
      const result = generateMutationTypes('test');
      expect(result).toEqual({
        SET_UI_FLAG: 'SET_TEST_UI_FLAG',
        SET: 'SET_TEST',
        ADD: 'ADD_TEST',
        EDIT: 'EDIT_TEST',
        DELETE: 'DELETE_TEST',
        SET_META: 'SET_TEST_META',
        UPSERT: 'UPSERT_TEST',
      });
    });
  });

  describe('createInitialState', () => {
    it('returns the correct initial state structure', () => {
      const result = createInitialState();
      expect(result).toEqual({
        records: [],
        meta: {},
        uiFlags: {
          fetchingList: false,
          fetchingItem: false,
          creatingItem: false,
          updatingItem: false,
          deletingItem: false,
        },
      });
    });
  });

  describe('createGetters', () => {
    it('returns getters with correct implementations', () => {
      const getters = createGetters();

      const state = {
        records: [{ id: 2 }, { id: 1 }, { id: 3 }],
        uiFlags: { fetchingList: true },
        meta: { totalCount: 10, page: 1 },
      };
      expect(getters.getRecords(state)).toEqual([
        { id: 3 },
        { id: 2 },
        { id: 1 },
      ]);

      expect(getters.getRecord(state)(2)).toEqual({ id: 2 });
      expect(getters.getRecord(state)(4)).toEqual({});

      expect(getters.getUIFlags(state)).toEqual({
        fetchingList: true,
      });

      expect(getters.getMeta(state)).toEqual({
        totalCount: 10,
        page: 1,
      });
    });
  });

  describe('createMutations', () => {
    it('creates mutations with correct implementations', () => {
      const mutationTypes = generateMutationTypes('test');
      const mutations = createMutations(mutationTypes);

      const state = { uiFlags: { fetchingList: false } };
      mutations[mutationTypes.SET_UI_FLAG](state, { fetchingList: true });
      expect(state.uiFlags).toEqual({ fetchingList: true });

      const metaState = { meta: {} };
      mutations[mutationTypes.SET_META](metaState, {
        total_count: '10',
        page: '2',
      });
      expect(metaState.meta).toEqual({ totalCount: 10, page: 2 });

      expect(mutations[mutationTypes.SET]).toBe(MutationHelpers.set);
      expect(mutations[mutationTypes.ADD]).toBe(MutationHelpers.create);
      expect(mutations[mutationTypes.EDIT]).toBe(MutationHelpers.update);
      expect(mutations[mutationTypes.DELETE]).toBe(MutationHelpers.destroy);
      expect(mutations[mutationTypes.UPSERT]).toBe(
        MutationHelpers.setSingleRecord
      );
    });
  });

  describe('createCrudActions', () => {
    let API;
    let commit;
    let mutationTypes;
    let actions;

    beforeEach(() => {
      API = {
        get: vi.fn(),
        show: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
      };
      commit = vi.fn();
      mutationTypes = generateMutationTypes('test');
      actions = createCrudActions(API, mutationTypes);
    });

    describe('get action', () => {
      it('handles successful API response', async () => {
        const payload = [{ id: 1 }];
        const meta = { total_count: 10, page: 1 };
        API.get.mockResolvedValue({ data: { payload, meta } });

        const result = await actions.get({ commit });

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingList: true,
        });
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET, payload);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_META, meta);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingList: false,
        });
        expect(result).toEqual(payload);
      });

      it('handles API error', async () => {
        const error = new Error('API Error');
        API.get.mockRejectedValue(error);
        throwErrorMessage.mockReturnValue('Error thrown');

        const result = await actions.get({ commit });

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingList: true,
        });
        expect(throwErrorMessage).toHaveBeenCalledWith(error);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingList: false,
        });
        expect(result).toEqual('Error thrown');
      });
    });

    describe('show action', () => {
      it('handles successful API response', async () => {
        const data = { id: 1, name: 'Test' };
        API.show.mockResolvedValue({ data });

        const result = await actions.show({ commit }, 1);

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingItem: true,
        });
        expect(commit).toHaveBeenCalledWith(mutationTypes.ADD, data);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingItem: false,
        });
        expect(result).toEqual(data);
      });

      it('handles API error', async () => {
        const error = new Error('API Error');
        API.show.mockRejectedValue(error);
        throwErrorMessage.mockReturnValue('Error thrown');

        const result = await actions.show({ commit }, 1);

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingItem: true,
        });
        expect(throwErrorMessage).toHaveBeenCalledWith(error);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          fetchingItem: false,
        });
        expect(result).toEqual('Error thrown');
      });
    });

    describe('create action', () => {
      it('handles successful API response', async () => {
        const data = { id: 1, name: 'Test' };
        API.create.mockResolvedValue({ data });

        const result = await actions.create({ commit }, { name: 'Test' });

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          creatingItem: true,
        });
        expect(commit).toHaveBeenCalledWith(mutationTypes.UPSERT, data);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          creatingItem: false,
        });
        expect(result).toEqual(data);
      });

      it('handles API error', async () => {
        const error = new Error('API Error');
        API.create.mockRejectedValue(error);
        throwErrorMessage.mockReturnValue('Error thrown');

        const result = await actions.create({ commit }, { name: 'Test' });

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          creatingItem: true,
        });
        expect(throwErrorMessage).toHaveBeenCalledWith(error);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          creatingItem: false,
        });
        expect(result).toEqual('Error thrown');
      });
    });

    describe('update action', () => {
      it('handles successful API response', async () => {
        const data = { id: 1, name: 'Updated' };
        API.update.mockResolvedValue({ data });

        const result = await actions.update(
          { commit },
          { id: 1, name: 'Updated' }
        );

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          updatingItem: true,
        });
        expect(API.update).toHaveBeenCalledWith(1, { name: 'Updated' });
        expect(commit).toHaveBeenCalledWith(mutationTypes.EDIT, data);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          updatingItem: false,
        });
        expect(result).toEqual(data);
      });

      it('handles API error', async () => {
        const error = new Error('API Error');
        API.update.mockRejectedValue(error);
        throwErrorMessage.mockReturnValue('Error thrown');

        const result = await actions.update(
          { commit },
          { id: 1, name: 'Updated' }
        );

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          updatingItem: true,
        });
        expect(throwErrorMessage).toHaveBeenCalledWith(error);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          updatingItem: false,
        });
        expect(result).toEqual('Error thrown');
      });
    });

    describe('delete action', () => {
      it('handles successful API response', async () => {
        API.delete.mockResolvedValue({});

        const result = await actions.delete({ commit }, 1);

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          deletingItem: true,
        });
        expect(API.delete).toHaveBeenCalledWith(1);
        expect(commit).toHaveBeenCalledWith(mutationTypes.DELETE, 1);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          deletingItem: false,
        });
        expect(result).toEqual(1);
      });

      it('handles API error', async () => {
        const error = new Error('API Error');
        API.delete.mockRejectedValue(error);
        throwErrorMessage.mockReturnValue('Error thrown');

        const result = await actions.delete({ commit }, 1);

        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          deletingItem: true,
        });
        expect(throwErrorMessage).toHaveBeenCalledWith(error);
        expect(commit).toHaveBeenCalledWith(mutationTypes.SET_UI_FLAG, {
          deletingItem: false,
        });
        expect(result).toEqual('Error thrown');
      });
    });
  });

  describe('createStore', () => {
    it('creates a complete store with default options', () => {
      const API = {};
      const store = createStore({ name: 'test', API });

      expect(store.namespaced).toBe(true);
      expect(store.state).toEqual(createInitialState());
      expect(Object.keys(store.getters)).toEqual([
        'getRecords',
        'getRecord',
        'getUIFlags',
        'getMeta',
      ]);
      expect(Object.keys(store.mutations)).toEqual([
        'SET_TEST_UI_FLAG',
        'SET_TEST_META',
        'SET_TEST',
        'ADD_TEST',
        'EDIT_TEST',
        'DELETE_TEST',
        'UPSERT_TEST',
      ]);
      expect(Object.keys(store.actions)).toEqual([
        'get',
        'show',
        'create',
        'update',
        'delete',
      ]);
    });

    it('creates a store with custom actions and getters', () => {
      const API = {};
      const customGetters = { customGetter: () => 'custom' };
      const customActions = () => ({
        customAction: () => 'custom',
      });

      const store = createStore({
        name: 'test',
        API,
        getters: customGetters,
        actions: customActions,
      });

      expect(store.getters).toHaveProperty('customGetter');
      expect(store.actions).toHaveProperty('customAction');
      expect(Object.keys(store.getters)).toEqual([
        'getRecords',
        'getRecord',
        'getUIFlags',
        'getMeta',
        'customGetter',
      ]);
      expect(Object.keys(store.actions)).toEqual([
        'get',
        'show',
        'create',
        'update',
        'delete',
        'customAction',
      ]);
    });
  });
});
