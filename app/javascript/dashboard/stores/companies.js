import camelcaseKeys from 'camelcase-keys';
import CompanyAPI from 'dashboard/api/companies';
import { createStore } from 'dashboard/store/storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import snakecaseKeys from 'snakecase-keys';

const createInitialUIFlags = () => ({
  fetchingList: false,
  fetchingItem: false,
  updatingItem: false,
  creatingItem: false,
  deletingItem: false,
  deletingAvatar: false,
  deletingCustomAttributes: false,
  fetchingContacts: false,
  searchingContacts: false,
  creatingContact: false,
  removingContact: false,
});

const camelizeCompany = data =>
  camelcaseKeys(data || {}, { deep: true, stopPaths: ['custom_attributes'] });

const camelizeContact = data =>
  camelcaseKeys(data || {}, {
    deep: true,
    stopPaths: ['custom_attributes', 'additional_attributes'],
  });

const normalizeMeta = meta => ({
  ...camelcaseKeys(meta || {}),
  totalCount: Number(meta?.total_count || meta?.totalCount || meta?.count || 0),
  page: Number(meta?.page || meta?.current_page || 1),
});

const appendFormData = (formData, key, value) => {
  if (value === undefined || value == null || value === '') return;
  if (
    value instanceof File ||
    value instanceof Blob ||
    typeof value !== 'object'
  ) {
    formData.append(key, value);
    return;
  }
  Object.entries(value).forEach(([k, v]) =>
    appendFormData(formData, `${key}[${k}]`, v)
  );
};

const buildCompanyRequestPayload = ({ avatar, customAttributes, ...rest }) => {
  const payload = {
    ...snakecaseKeys(rest, { deep: true }),
    ...(customAttributes && { custom_attributes: customAttributes }),
    ...(avatar && { avatar }),
  };
  if (!avatar) return { company: payload };

  const formData = new FormData();
  Object.entries(payload).forEach(([k, v]) =>
    appendFormData(formData, `company[${k}]`, v)
  );
  return formData;
};

export const useCompaniesStore = createStore({
  name: 'companies',
  type: 'pinia',
  API: CompanyAPI,

  getters: {
    getCompaniesList: state => state.records,
  },

  actions: () => ({
    setMeta(meta) {
      this.meta = normalizeMeta(meta);
    },

    setActiveCompanyId(companyId) {
      this.activeCompanyId = Number(companyId);
    },

    ensureActiveCompanyContext(companyId) {
      if (this.activeCompanyId === null) {
        this.setActiveCompanyId(companyId);
      }
    },

    upsertCompanyRecord(record) {
      const index = this.records.findIndex(r => r.id === record.id);
      if (index === -1) this.records.push(record);
      else this.records[index] = record;
    },

    updateCompanyContactsCount(companyId, contactsCount) {
      const company = this.getRecord(companyId);
      if (!company.id) return;
      this.upsertCompanyRecord({ ...company, contactsCount });
    },

    clearContactSearchResults() {
      this.contactSearchResults = [];
      this.contactSearchMeta = {};
      this.activeContactSearchQuery = '';
      this.contactSearchRequestToken =
        (this.contactSearchRequestToken || 0) + 1;
    },

    async get({ page = 1, sort = 'name' } = {}) {
      this.setUIFlag({ fetchingList: true });
      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.get({ page, sort });
        this.records = camelizeCompany(payload);
        this.setMeta(meta);
        return this.records;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },

    async show(id) {
      this.setUIFlag({ fetchingItem: true });
      this.setActiveCompanyId(id);
      const activeCompanyId = Number(id);
      const requestToken = (this.companyDetailRequestToken || 0) + 1;
      this.companyDetailRequestToken = requestToken;
      try {
        const {
          data: { payload },
        } = await CompanyAPI.show(id);
        const company = camelizeCompany(payload);

        if (
          this.companyDetailRequestToken !== requestToken ||
          this.activeCompanyId !== activeCompanyId
        ) {
          return company;
        }

        this.upsertCompanyRecord(company);
        this.setActiveCompanyId(company.id);
        return company;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        if (this.companyDetailRequestToken === requestToken) {
          this.setUIFlag({ fetchingItem: false });
        }
      }
    },

    async update({ id, ...companyAttrs }) {
      this.setUIFlag({ updatingItem: true });
      try {
        const {
          data: { payload },
        } = await CompanyAPI.update(
          id,
          buildCompanyRequestPayload(companyAttrs)
        );
        const company = camelizeCompany(payload);
        this.upsertCompanyRecord(company);
        return company;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ updatingItem: false });
      }
    },

    async create(companyAttrs) {
      this.setUIFlag({ creatingItem: true });
      try {
        const {
          data: { payload },
        } = await CompanyAPI.create(buildCompanyRequestPayload(companyAttrs));
        const company = camelizeCompany(payload);
        this.upsertCompanyRecord(company);
        return company;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ creatingItem: false });
      }
    },

    async delete(id) {
      this.setUIFlag({ deletingItem: true });
      try {
        await CompanyAPI.delete(id);
        this.records = this.records.filter(r => r.id !== Number(id));
        if (this.activeCompanyId === Number(id)) this.resetCompanyDetailState();
        return Number(id);
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ deletingItem: false });
      }
    },

    async search({ search, page = 1, sort = 'name' }) {
      this.setUIFlag({ fetchingList: true });
      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.search(search, page, sort);
        this.records = camelizeCompany(payload);
        this.setMeta(meta);
        return this.records;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },

    async deleteCompanyAvatar(companyId) {
      this.setUIFlag({ deletingAvatar: true });
      this.ensureActiveCompanyContext(companyId);
      try {
        const {
          data: { payload },
        } = await CompanyAPI.destroyAvatar(companyId);
        const company = camelizeCompany(payload);
        this.upsertCompanyRecord(company);
        return company;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ deletingAvatar: false });
      }
    },

    async getCompanyContacts(companyId, page = 1) {
      this.setUIFlag({ fetchingContacts: true });
      this.ensureActiveCompanyContext(companyId);
      const activeCompanyId = Number(companyId);
      const requestToken = (this.companyContactsRequestToken || 0) + 1;
      this.companyContactsRequestToken = requestToken;

      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.listContacts(companyId, page);
        const contacts = camelizeContact(payload);
        const normalizedMeta = normalizeMeta(meta);

        if (
          this.companyContactsRequestToken !== requestToken ||
          this.activeCompanyId !== activeCompanyId
        ) {
          return contacts;
        }

        this.companyContacts = contacts;
        this.companyContactsMeta = normalizedMeta;
        this.updateCompanyContactsCount(companyId, normalizedMeta.totalCount);
        return contacts;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        if (this.companyContactsRequestToken === requestToken) {
          this.setUIFlag({ fetchingContacts: false });
        }
      }
    },

    async searchCompanyContactCandidates({ companyId, search, page = 1 }) {
      const query = search?.trim() || '';
      if (!query) {
        this.clearContactSearchResults();
        return [];
      }

      this.setUIFlag({ searchingContacts: true });
      this.ensureActiveCompanyContext(companyId);
      this.activeContactSearchQuery = query;
      const activeCompanyId = Number(companyId);
      const requestToken = (this.contactSearchRequestToken || 0) + 1;
      this.contactSearchRequestToken = requestToken;

      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.searchContacts(companyId, query, page);
        const contacts = camelizeContact(payload);
        const normalizedMeta = normalizeMeta(meta);

        if (
          this.contactSearchRequestToken !== requestToken ||
          this.activeCompanyId !== activeCompanyId ||
          this.activeContactSearchQuery !== query
        ) {
          return contacts;
        }

        this.contactSearchResults = contacts;
        this.contactSearchMeta = normalizedMeta;
        return contacts;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        if (this.contactSearchRequestToken === requestToken) {
          this.setUIFlag({ searchingContacts: false });
        }
      }
    },

    async attachContactToCompany(companyId, contactId) {
      this.setUIFlag({ creatingContact: true });
      this.ensureActiveCompanyContext(companyId);
      const activeCompanyId = Number(companyId);
      try {
        const {
          data: { payload },
        } = await CompanyAPI.createContact(companyId, {
          contact_id: contactId,
        });
        const contact = camelizeContact(payload);
        if (this.activeCompanyId === activeCompanyId) {
          await this.getCompanyContacts(companyId, 1);
          if (this.activeCompanyId === activeCompanyId) {
            this.clearContactSearchResults();
          }
        }
        return contact;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ creatingContact: false });
      }
    },

    async removeContactFromCompany(companyId, contactId, page = null) {
      this.setUIFlag({ removingContact: true });
      this.ensureActiveCompanyContext(companyId);
      const activeCompanyId = Number(companyId);
      try {
        await CompanyAPI.removeContact(companyId, contactId);
        if (this.activeCompanyId === activeCompanyId) {
          await this.getCompanyContacts(
            companyId,
            page || this.companyContactsMeta?.page || 1
          );
        }
        return Number(contactId);
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ removingContact: false });
      }
    },

    async deleteCustomAttributes({ id, customAttributes }) {
      this.setUIFlag({ deletingCustomAttributes: true });
      try {
        const {
          data: { payload },
        } = await CompanyAPI.destroyCustomAttributes(id, customAttributes);
        const company = camelizeCompany(payload);
        this.upsertCompanyRecord(company);
        return company;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ deletingCustomAttributes: false });
      }
    },

    resetCompanyDetailState() {
      const { fetchingList } = this.uiFlags;
      this.activeCompanyId = null;
      this.companyDetailRequestToken =
        (this.companyDetailRequestToken || 0) + 1;
      this.companyContactsRequestToken =
        (this.companyContactsRequestToken || 0) + 1;
      this.contactSearchRequestToken =
        (this.contactSearchRequestToken || 0) + 1;
      this.companyContacts = [];
      this.companyContactsMeta = {};
      this.contactSearchResults = [];
      this.contactSearchMeta = {};
      this.activeContactSearchQuery = '';
      this.uiFlags = { ...createInitialUIFlags(), fetchingList };
    },
  }),
});
