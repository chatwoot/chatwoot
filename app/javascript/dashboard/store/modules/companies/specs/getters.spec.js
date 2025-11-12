import Companies from '../index';
import companyList from './fixtures';

const { getters } = Companies;

describe('#getters', () => {
  it('getCompaniesList', () => {
    const state = {
      records: { 25: companyList[0], 100: companyList[2] },
      sortOrder: [100, 25],
    };
    expect(getters.getCompaniesList(state)).toEqual([
      {
        id: 3,
        name: 'Test Company',
        contactsCount: 5,
        domain: 'test-company.example',
        description: 'Enterprise-level testing solutions',
        avatarUrl: 'https://example.com/avatar.png',
        createdAt: '2025-11-10T10:00:00.000Z',
        updatedAt: '2025-11-10T10:00:00.000Z',
      },
      {
        id: 1,
        name: 'Bartoletti, Schulist and Sauer',
        contactsCount: 2,
        domain: 'wisoky-turcotte.example',
        description: 'User-friendly neutral matrices',
        avatarUrl: '',
        createdAt: '2025-11-11T11:35:39.262Z',
        updatedAt: '2025-11-11T11:51:11.261Z',
      },
    ]);
  });

  it('getCompanyById', () => {
    const state = {
      records: { 76: companyList[1] },
    };
    expect(getters.getCompanyById(state)(76)).toEqual({
      id: 2,
      name: 'Bogan Inc',
      contactsCount: 0,
      domain: 'kertzmann-kuhic.example',
      description: 'Grass-roots user-facing data-warehouse',
      avatarUrl: '',
      createdAt: '2025-11-11T16:32:18.962Z',
      updatedAt: '2025-11-11T16:32:18.962Z',
    });
  });

  it('getCompanyById returns empty object for non-existent company', () => {
    const state = {
      records: {},
    };
    expect(getters.getCompanyById(state)(999)).toEqual({});
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isFetchingItem: false,
        isUpdating: true,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isFetchingItem: false,
      isUpdating: true,
      isDeleting: false,
    });
  });

  it('getMeta', () => {
    const state = {
      meta: {
        count: 150,
        currentPage: 3,
      },
    };
    expect(getters.getMeta(state)).toEqual({
      count: 150,
      currentPage: 3,
    });
  });
});
