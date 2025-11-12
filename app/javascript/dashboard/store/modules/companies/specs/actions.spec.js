import axios from 'axios';
import Companies from '../index';
import types from '../../../mutation-types';
import companyList from './fixtures';

const { actions } = Companies;

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#search', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: companyList,
          meta: { count: 100, current_page: 1 },
        },
      });
      await actions.search(
        { commit },
        { search: 'Bogan', page: 1, sort: 'name' }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isFetching: true }],
        [types.CLEAR_COMPANIES],
        [types.SET_COMPANIES, companyList],
        [types.SET_COMPANY_META, { count: 100, current_page: 1 }],
        [types.SET_COMPANY_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct mutations if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.search(
        { commit },
        { search: 'test', page: 1, sort: 'name' }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isFetching: true }],
        [types.SET_COMPANY_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#get', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: companyList,
          meta: { count: 150, current_page: 2 },
        },
      });
      await actions.get({ commit }, { page: 2, sort: 'name' });
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isFetching: true }],
        [types.CLEAR_COMPANIES],
        [types.SET_COMPANIES, companyList],
        [types.SET_COMPANY_META, { count: 150, current_page: 2 }],
        [types.SET_COMPANY_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct mutations if API is error', async () => {
      const consoleErrorSpy = vi
        .spyOn(console, 'error')
        .mockImplementation(() => {});
      axios.get.mockRejectedValue({ message: 'Network error' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isFetching: true }],
        [types.SET_COMPANY_UI_FLAG, { isFetching: false }],
      ]);
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Error fetching companies:',
        { message: 'Network error' }
      );
      consoleErrorSpy.mockRestore();
    });

    it('uses default parameters when none provided', async () => {
      axios.get.mockResolvedValue({
        data: {
          payload: companyList,
          meta: { count: 100, current_page: 1 },
        },
      });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isFetching: true }],
        [types.CLEAR_COMPANIES],
        [types.SET_COMPANIES, companyList],
        [types.SET_COMPANY_META, { count: 100, current_page: 1 }],
        [types.SET_COMPANY_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#show', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: companyList[0] } });
      await actions.show({ commit }, { id: companyList[0].id });
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isFetchingItem: true }],
        [types.SET_COMPANY_ITEM, companyList[0]],
        [types.SET_COMPANY_UI_FLAG, { isFetchingItem: false }],
      ]);
    });

    it('sends correct mutations if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Not found' });
      await actions.show({ commit }, { id: 999 });
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isFetchingItem: true }],
        [types.SET_COMPANY_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct mutations if API is success', async () => {
      const updatedCompany = {
        ...companyList[0],
        name: 'Updated Company Name',
      };
      axios.patch.mockResolvedValue({ data: { payload: updatedCompany } });
      await actions.update(
        { commit },
        {
          id: companyList[0].id,
          name: 'Updated Company Name',
          domain: 'updated.example',
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isUpdating: true }],
        [types.EDIT_COMPANY, updatedCompany],
        [types.SET_COMPANY_UI_FLAG, { isUpdating: false }],
      ]);
    });

    it('throws error if API returns error', async () => {
      const error = {
        response: { data: { message: 'Company name already exists' } },
      };
      axios.patch.mockRejectedValue(error);
      await expect(
        actions.update({ commit }, { id: 25, name: 'Duplicate Name' })
      ).rejects.toThrow();
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isUpdating: true }],
        [types.SET_COMPANY_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct mutations if API is success', async () => {
      const newCompany = {
        id: 200,
        name: 'New Company',
        domain: 'new-company.example',
      };
      axios.post.mockResolvedValue({
        data: { payload: { company: newCompany } },
      });
      const result = await actions.create(
        { commit },
        {
          name: 'New Company',
          domain: 'new-company.example',
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isCreating: true }],
        [types.SET_COMPANY_ITEM, newCompany],
        [types.SET_COMPANY_UI_FLAG, { isCreating: false }],
      ]);
      expect(result).toEqual(newCompany);
    });

    it('throws error if API returns error', async () => {
      const error = {
        response: { data: { message: 'Validation failed' } },
      };
      axios.post.mockRejectedValue(error);
      await expect(
        actions.create({ commit }, { name: 'Invalid Company' })
      ).rejects.toThrow();
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isCreating: true }],
        [types.SET_COMPANY_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct mutations if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.delete({ commit }, 2);
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isDeleting: true }],
        [types.SET_COMPANY_UI_FLAG, { isDeleting: false }],
      ]);
    });

    it('throws error if API returns error', async () => {
      const error = {
        response: { data: { message: 'Cannot delete company with contacts' } },
      };
      axios.delete.mockRejectedValue(error);
      await expect(actions.delete({ commit }, 2)).rejects.toThrow();
      expect(commit.mock.calls).toEqual([
        [types.SET_COMPANY_UI_FLAG, { isDeleting: true }],
        [types.SET_COMPANY_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});
