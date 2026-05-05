import { defineStore } from 'pinia';
import CompanyAPI from 'dashboard/api/companies';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';

const createInitialUIFlags = () => ({
  fetchingList: false,
  fetchingItem: false,
  updatingItem: false,
  deletingItem: false,
  deletingAvatar: false,
  deletingCustomAttributes: false,
  fetchingContacts: false,
  searchingContacts: false,
  creatingContact: false,
  removingContact: false,
});

const createInitialState = () => ({
  records: [],
  meta: {},
  companyContacts: [],
  companyContactsMeta: {},
  contactSearchResults: [],
  contactSearchMeta: {},
  uiFlags: createInitialUIFlags(),
  activeCompanyId: null,
  companyDetailRequestToken: 0,
  companyContactsRequestToken: 0,
  contactSearchRequestToken: 0,
  activeContactSearchQuery: '',
});

const normalizeCompanyRecord = record =>
  camelcaseKeys(record || {}, {
    deep: true,
    stopPaths: ['custom_attributes'],
  });

const normalizeCompanyCollection = collection =>
  camelcaseKeys(collection || [], {
    deep: true,
    stopPaths: ['custom_attributes'],
  });

const normalizeContactRecord = record =>
  camelcaseKeys(record || {}, {
    deep: true,
    stopPaths: ['custom_attributes', 'additional_attributes'],
  });

const normalizeContactCollection = collection =>
  camelcaseKeys(collection || [], {
    deep: true,
    stopPaths: ['custom_attributes', 'additional_attributes'],
  });

const normalizeMeta = meta => ({
  ...camelcaseKeys(meta || {}),
  totalCount: Number(meta?.total_count || meta?.totalCount || meta?.count || 0),
  page: Number(meta?.page || meta?.current_page || 1),
});

const upsertRecord = (records, record) => {
  const index = records.findIndex(
    existingRecord => existingRecord.id === record.id
  );

  if (index === -1) {
    return [...records, record];
  }

  return records.map(existingRecord =>
    existingRecord.id === record.id ? record : existingRecord
  );
};

const appendFormDataValue = (formData, key, value) => {
  if (value === undefined || value === null || value === '') {
    return;
  }

  if (value instanceof File || value instanceof Blob) {
    formData.append(key, value);
    return;
  }

  if (typeof value === 'object') {
    Object.entries(value).forEach(([nestedKey, nestedValue]) => {
      appendFormDataValue(formData, `${key}[${nestedKey}]`, nestedValue);
    });
    return;
  }

  formData.append(key, value);
};

const buildCompanyFormData = payload => {
  const formData = new FormData();

  Object.entries(payload).forEach(([key, value]) => {
    appendFormDataValue(formData, `company[${key}]`, value);
  });

  return formData;
};

const buildCompanyPayload = companyAttrs => {
  const { avatar, customAttributes, ...attrsToDecamelize } = companyAttrs;

  return {
    ...snakecaseKeys(attrsToDecamelize, { deep: true }),
    ...(customAttributes && { custom_attributes: customAttributes }),
    ...(avatar && { avatar }),
  };
};

const buildCompanyRequestPayload = companyAttrs => {
  const payload = buildCompanyPayload(companyAttrs);

  return companyAttrs.avatar
    ? buildCompanyFormData(payload)
    : { company: payload };
};

export const useCompaniesStore = defineStore('companies', {
  state: createInitialState,

  getters: {
    getRecord: state => id =>
      state.records.find(record => record.id === Number(id)) || {},
    getUIFlags: state => state.uiFlags,
    getMeta: state => state.meta,
    getCompaniesList: state => state.records,
  },

  actions: {
    setUIFlag(data) {
      this.uiFlags = {
        ...this.uiFlags,
        ...data,
      };
    },

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
      this.records = upsertRecord(this.records, record);
    },

    updateCompanyContactsCount(companyId, contactsCount) {
      const company = this.getRecord(companyId);
      if (!company.id) {
        return;
      }

      this.upsertCompanyRecord({
        ...company,
        contactsCount,
      });
    },

    clearContactSearchResults() {
      this.contactSearchResults = [];
      this.contactSearchMeta = {};
      this.activeContactSearchQuery = '';
      this.contactSearchRequestToken += 1;
    },

    async get({ page = 1, sort = 'name' } = {}) {
      this.setUIFlag({ fetchingList: true });
      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.get({ page, sort });
        this.records = normalizeCompanyCollection(payload);
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
      const requestToken = this.companyDetailRequestToken + 1;
      this.companyDetailRequestToken = requestToken;
      try {
        const {
          data: { payload },
        } = await CompanyAPI.show(id);
        const company = normalizeCompanyRecord(payload);

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
          data: { payload: updatedPayload },
        } = await CompanyAPI.update(
          id,
          buildCompanyRequestPayload(companyAttrs)
        );
        const company = normalizeCompanyRecord(updatedPayload);
        this.upsertCompanyRecord(company);
        return company;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ updatingItem: false });
      }
    },

    async delete(id) {
      this.setUIFlag({ deletingItem: true });
      try {
        await CompanyAPI.delete(id);
        this.records = this.records.filter(record => record.id !== Number(id));
        if (this.activeCompanyId === Number(id)) {
          this.resetCompanyDetailState();
        }
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
        this.records = normalizeCompanyCollection(payload);
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
        const company = normalizeCompanyRecord(payload);
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
      const requestToken = this.companyContactsRequestToken + 1;
      this.companyContactsRequestToken = requestToken;

      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.listContacts(companyId, page);
        const contacts = normalizeContactCollection(payload);
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
      const requestToken = this.contactSearchRequestToken + 1;
      this.contactSearchRequestToken = requestToken;

      try {
        const {
          data: { payload, meta },
        } = await CompanyAPI.searchContacts(companyId, query, page);
        const contacts = normalizeContactCollection(payload);
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
      try {
        const {
          data: { payload },
        } = await CompanyAPI.createContact(companyId, {
          contact_id: contactId,
        });
        const contact = normalizeContactRecord(payload);
        await this.getCompanyContacts(companyId, 1);
        this.clearContactSearchResults();
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
      try {
        await CompanyAPI.removeContact(companyId, contactId);
        await this.getCompanyContacts(
          companyId,
          page || this.companyContactsMeta.page || 1
        );
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
        const company = normalizeCompanyRecord(payload);
        this.upsertCompanyRecord(company);
        return company;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        this.setUIFlag({ deletingCustomAttributes: false });
      }
    },

    resetCompanyDetailState() {
      this.activeCompanyId = null;
      this.companyDetailRequestToken += 1;
      this.companyContactsRequestToken += 1;
      this.contactSearchRequestToken += 1;
      this.companyContacts = [];
      this.companyContactsMeta = {};
      this.contactSearchResults = [];
      this.contactSearchMeta = {};
      this.activeContactSearchQuery = '';
      this.setUIFlag({
        fetchingItem: false,
        updatingItem: false,
        deletingItem: false,
        deletingAvatar: false,
        deletingCustomAttributes: false,
        fetchingContacts: false,
        searchingContacts: false,
        creatingContact: false,
        removingContact: false,
      });
    },
  },
});
