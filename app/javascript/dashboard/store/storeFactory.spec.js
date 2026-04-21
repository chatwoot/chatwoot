import { setActivePinia, createPinia } from 'pinia';
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
  describe('createStore with type parameter', () => {
    beforeEach(() => {
      setActivePinia(createPinia());
    });

    it('creates Vuex store by default', () => {
      const API = {};
      const store = createStore({ name: 'test', API });

      expect(store.namespaced).toBe(true);
      expect(store.state).toBeDefined();
      expect(store.mutations).toBeDefined();
    });

    it('creates Pinia store when type is "pinia"', () => {
      const API = {
        get: vi.fn(),
        show: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
      };

      const useTestStore = createStore({
        name: 'test',
        API,
        type: 'pinia',
      });

      const store = useTestStore();

      expect(store.records).toBeDefined();
      expect(store.get).toBeTypeOf('function');
      expect(store.setUIFlag).toBeTypeOf('function');
    });

    it('creates Vuex store when type is "vuex"', () => {
      const API = {};
      const store = createStore({
        name: 'test',
        API,
        type: 'vuex',
      });

      expect(store.namespaced).toBe(true);
      expect(store.state).toBeDefined();
    });
  });

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
        expect(commit).toHaveBeenCalledWith(mutationTypes.UPSERT, data);
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

  describe('createStore - Vuex type', () => {
    it('creates a complete Vuex store with default options', () => {
      const API = {};
      const store = createStore({ name: 'test', API, type: 'vuex' });

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

    it('creates a Vuex store with custom actions and getters', () => {
      const API = {};
      const customGetters = { customGetter: () => 'custom' };
      const customActions = () => ({
        customAction: () => 'custom',
      });

      const store = createStore({
        name: 'test',
        API,
        type: 'vuex',
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

    it('creates a Vuex store with custom mutations', () => {
      const API = {};
      const customMutations = {
        CUSTOM_MUTATION: state => {
          state.custom = true;
        },
      };

      const store = createStore({
        name: 'test',
        API,
        type: 'vuex',
        mutations: customMutations,
      });

      expect(store.mutations).toHaveProperty('CUSTOM_MUTATION');
    });
  });

  describe('createStore - Pinia type', () => {
    let API;

    beforeEach(() => {
      setActivePinia(createPinia());
      API = {
        get: vi.fn(),
        show: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
      };
    });

    it('creates a Pinia store with correct structure', () => {
      const useTestStore = createStore({
        name: 'test',
        API,
        type: 'pinia',
      });

      const store = useTestStore();

      expect(store.records).toEqual([]);
      expect(store.meta).toEqual({});
      expect(store.uiFlags).toEqual({
        fetchingList: false,
        fetchingItem: false,
        creatingItem: false,
        updatingItem: false,
        deletingItem: false,
      });
    });

    it('has standard getters', () => {
      const useTestStore = createStore({
        name: 'test',
        API,
        type: 'pinia',
      });

      const store = useTestStore();
      store.records = [{ id: 2 }, { id: 1 }, { id: 3 }];
      store.meta = { totalCount: 10, page: 1 };
      store.uiFlags = { fetchingList: true };

      expect(store.getRecords).toEqual([{ id: 3 }, { id: 2 }, { id: 1 }]);
      expect(store.getRecord(2)).toEqual({ id: 2 });
      expect(store.getRecord(4)).toEqual({});
      expect(store.getUIFlags).toEqual({ fetchingList: true });
      expect(store.getMeta).toEqual({ totalCount: 10, page: 1 });
    });

    it('has custom getters', () => {
      const useTestStore = createStore({
        name: 'test',
        API,
        type: 'pinia',
        getters: {
          customGetter: state => state.records.length,
        },
      });

      const store = useTestStore();
      store.records = [{ id: 1 }, { id: 2 }];

      expect(store.customGetter).toBe(2);
    });

    describe('setUIFlag action', () => {
      it('updates UI flags correctly', () => {
        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        store.setUIFlag({ fetchingList: true });
        expect(store.uiFlags.fetchingList).toBe(true);

        store.setUIFlag({ creatingItem: true });
        expect(store.uiFlags.fetchingList).toBe(true);
        expect(store.uiFlags.creatingItem).toBe(true);
      });
    });

    describe('setMeta action', () => {
      it('updates meta with snake_case input', () => {
        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        store.setMeta({ total_count: '10', page: '2' });
        expect(store.meta.totalCount).toBe(10);
        expect(store.meta.page).toBe(2);
      });

      it('updates meta with camelCase input', () => {
        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        store.setMeta({ totalCount: 15, page: 3 });
        expect(store.meta.totalCount).toBe(15);
        expect(store.meta.page).toBe(3);
      });
    });

    describe('get action', () => {
      it('fetches records successfully', async () => {
        const payload = [{ id: 1, name: 'Test' }];
        const meta = { total_count: 1, page: 1 };
        API.get.mockResolvedValue({ data: { payload, meta } });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        await store.get({ page: 1 });

        expect(API.get).toHaveBeenCalledWith({ page: 1 });
        expect(store.records).toEqual(payload);
        expect(store.meta.totalCount).toBe(1);
        expect(store.meta.page).toBe(1);
        expect(store.uiFlags.fetchingList).toBe(false);
      });

      it('handles API response without meta', async () => {
        const data = [{ id: 1, name: 'Test' }];
        API.get.mockResolvedValue({ data });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        await store.get();

        expect(store.records).toEqual(data);
      });

      it('handles errors and resets UI flags', async () => {
        const error = new Error('API Error');
        API.get.mockRejectedValue(error);
        throwErrorMessage.mockReturnValue('Error thrown');

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        const result = await store.get();

        expect(throwErrorMessage).toHaveBeenCalledWith(error);
        expect(store.uiFlags.fetchingList).toBe(false);
        expect(result).toBe('Error thrown');
      });
    });

    describe('show action', () => {
      it('fetches and upserts a record', async () => {
        const data = { id: 1, name: 'Test' };
        API.show.mockResolvedValue({ data });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        const result = await store.show(1);

        expect(API.show).toHaveBeenCalledWith(1);
        expect(store.records).toContainEqual(data);
        expect(result).toEqual(data);
        expect(store.uiFlags.fetchingItem).toBe(false);
      });

      it('updates existing record', async () => {
        const data = { id: 1, name: 'Updated' };
        API.show.mockResolvedValue({ data });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();
        store.records = [{ id: 1, name: 'Original' }];

        await store.show(1);

        expect(store.records).toHaveLength(1);
        expect(store.records[0].name).toBe('Updated');
      });

      it('handles payload wrapper', async () => {
        const record = { id: 1, name: 'Test' };
        API.show.mockResolvedValue({ data: { payload: record } });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        const result = await store.show(1);

        expect(result).toEqual(record);
        expect(store.records).toContainEqual(record);
      });
    });

    describe('create action', () => {
      it('creates a new record', async () => {
        const data = { id: 1, name: 'New' };
        API.create.mockResolvedValue({ data });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        const result = await store.create({ name: 'New' });

        expect(API.create).toHaveBeenCalledWith({ name: 'New' });
        expect(store.records).toContainEqual(data);
        expect(result).toEqual(data);
        expect(store.uiFlags.creatingItem).toBe(false);
      });

      it('handles payload wrapper', async () => {
        const record = { id: 1, name: 'New' };
        API.create.mockResolvedValue({ data: { payload: record } });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();

        const result = await store.create({ name: 'New' });

        expect(result).toEqual(record);
        expect(store.records).toContainEqual(record);
      });
    });

    describe('update action', () => {
      it('updates an existing record', async () => {
        const data = { id: 1, name: 'Updated' };
        API.update.mockResolvedValue({ data });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();
        store.records = [{ id: 1, name: 'Original' }];

        const result = await store.update({ id: 1, name: 'Updated' });

        expect(API.update).toHaveBeenCalledWith(1, { name: 'Updated' });
        expect(store.records[0].name).toBe('Updated');
        expect(result).toEqual(data);
        expect(store.uiFlags.updatingItem).toBe(false);
      });

      it('handles payload wrapper', async () => {
        const record = { id: 1, name: 'Updated' };
        API.update.mockResolvedValue({ data: { payload: record } });

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();
        store.records = [{ id: 1, name: 'Original' }];

        const result = await store.update({ id: 1, name: 'Updated' });

        expect(result).toEqual(record);
        expect(store.records[0]).toEqual(record);
      });
    });

    describe('delete action', () => {
      it('deletes a record', async () => {
        API.delete.mockResolvedValue({});

        const useTestStore = createStore({ name: 'test', API, type: 'pinia' });
        const store = useTestStore();
        store.records = [{ id: 1 }, { id: 2 }, { id: 3 }];

        const result = await store.delete(2);

        expect(API.delete).toHaveBeenCalledWith(2);
        expect(store.records).toHaveLength(2);
        expect(store.records).not.toContainEqual({ id: 2 });
        expect(result).toBe(2);
        expect(store.uiFlags.deletingItem).toBe(false);
      });
    });

    describe('custom actions', () => {
      it('includes custom actions', async () => {
        const useTestStore = createStore({
          name: 'test',
          API,
          type: 'pinia',
          actions: () => ({
            customAction() {
              return 'custom result';
            },
          }),
        });

        const store = useTestStore();
        const result = store.customAction();

        expect(result).toBe('custom result');
      });

      it('custom actions can access store state', () => {
        const useTestStore = createStore({
          name: 'test',
          API,
          type: 'pinia',
          actions: () => ({
            getRecordCount() {
              return this.records.length;
            },
          }),
        });

        const store = useTestStore();
        store.records = [{ id: 1 }, { id: 2 }];

        expect(store.getRecordCount()).toBe(2);
      });
    });
  });
});
