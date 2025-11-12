import types from '../../../mutation-types';
import Companies from '../index';

const { mutations } = Companies;

describe('#mutations', () => {
  describe('#SET_COMPANY_UI_FLAG', () => {
    it('sets UI flags correctly', () => {
      const state = {
        uiFlags: {
          isFetching: false,
          isFetchingItem: false,
          isUpdating: false,
          isDeleting: false,
        },
      };
      mutations[types.SET_COMPANY_UI_FLAG](state, { isFetching: true });
      expect(state.uiFlags).toEqual({
        isFetching: true,
        isFetchingItem: false,
        isUpdating: false,
        isDeleting: false,
      });
    });

    it('merges multiple UI flags', () => {
      const state = {
        uiFlags: {
          isFetching: false,
          isUpdating: false,
        },
      };
      mutations[types.SET_COMPANY_UI_FLAG](state, {
        isFetching: true,
        isUpdating: true,
      });
      expect(state.uiFlags).toEqual({
        isFetching: true,
        isUpdating: true,
      });
    });
  });

  describe('#CLEAR_COMPANIES', () => {
    it('clears all company records and sort order', () => {
      const state = {
        records: {
          2: { id: 76, name: 'Company 2' },
          1: { id: 25, name: 'Company 1' },
        },
        sortOrder: [1, 2],
      };
      mutations[types.CLEAR_COMPANIES](state);
      expect(state.records).toEqual({});
      expect(state.sortOrder).toEqual([]);
    });
  });

  describe('#SET_COMPANY_META', () => {
    it('sets meta data correctly', () => {
      const state = {
        meta: {
          count: 0,
          currentPage: 1,
        },
      };
      mutations[types.SET_COMPANY_META](state, {
        count: 150,
        current_page: 5,
      });
      expect(state.meta).toEqual({
        count: 150,
        currentPage: 5,
      });
    });
  });

  describe('#SET_COMPANIES', () => {
    it('sets company records and sort order', () => {
      const state = { records: {}, sortOrder: [] };
      mutations[types.SET_COMPANIES](state, [
        {
          id: 2,
          name: 'Bogan Inc',
          domain: 'kertzmann-kuhic.example',
        },
        {
          id: 1,
          name: 'Bartoletti, Schulist and Sauer',
          domain: 'wisoky-turcotte.example',
        },
      ]);
      expect(state.records).toEqual({
        1: {
          id: 1,
          name: 'Bartoletti, Schulist and Sauer',
          domain: 'wisoky-turcotte.example',
        },
        2: {
          id: 2,
          name: 'Bogan Inc',
          domain: 'kertzmann-kuhic.example',
        },
      });
      expect(state.sortOrder).toEqual([2, 1]);
    });

    it('merges with existing company data', () => {
      const state = {
        records: {
          1: {
            id: 1,
            name: 'Old Name',
            contacts_count: 1,
          },
        },
        sortOrder: [],
      };
      mutations[types.SET_COMPANIES](state, [
        {
          id: 1,
          name: 'New Name',
          domain: 'example.com',
        },
      ]);
      expect(state.records[1]).toEqual({
        id: 1,
        name: 'New Name',
        contacts_count: 1,
        domain: 'example.com',
      });
    });
  });

  describe('#SET_COMPANY_ITEM', () => {
    it('adds a new company to records', () => {
      const state = {
        records: {
          1: { id: 1, name: 'Company 1' },
        },
        sortOrder: [1],
      };
      mutations[types.SET_COMPANY_ITEM](state, {
        id: 2,
        name: 'Bogan Inc',
        domain: 'kertzmann-kuhic.example',
      });
      expect(state.records).toEqual({
        1: { id: 1, name: 'Company 1' },
        2: {
          id: 2,
          name: 'Bogan Inc',
          domain: 'kertzmann-kuhic.example',
        },
      });
      expect(state.sortOrder).toEqual([1, 2]);
    });

    it('updates existing company without duplicating in sortOrder', () => {
      const state = {
        records: {
          1: { id: 1, name: 'Old Name', domain: 'old.example' },
        },
        sortOrder: [1],
      };
      mutations[types.SET_COMPANY_ITEM](state, {
        id: 1,
        name: 'Updated Name',
        domain: 'new.example',
      });
      expect(state.records[1]).toEqual({
        id: 1,
        name: 'Updated Name',
        domain: 'new.example',
      });
      expect(state.sortOrder).toEqual([1]);
    });
  });

  describe('#EDIT_COMPANY', () => {
    it('updates company data', () => {
      const state = {
        records: {
          1: {
            id: 1,
            name: 'Old Name',
            domain: 'old.example',
          },
        },
      };
      mutations[types.EDIT_COMPANY](state, {
        id: 1,
        name: 'Updated Name',
        domain: 'updated.example',
      });
      expect(state.records[1]).toEqual({
        id: 1,
        name: 'Updated Name',
        domain: 'updated.example',
      });
    });
  });

  describe('#DELETE_COMPANY', () => {
    it('removes company from records and sortOrder', () => {
      const state = {
        records: {
          1: { id: 1, name: 'Company 1' },
          2: { id: 2, name: 'Company 2' },
          3: { id: 3, name: 'Company 3' },
        },
        sortOrder: [1, 2, 3],
      };
      mutations[types.DELETE_COMPANY](state, 2);
      expect(state.records).toEqual({
        1: { id: 1, name: 'Company 1' },
        3: { id: 3, name: 'Company 3' },
      });
      expect(state.sortOrder).toEqual([1, 3]);
    });
  });
});
