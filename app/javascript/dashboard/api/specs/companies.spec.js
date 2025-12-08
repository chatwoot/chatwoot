import companyAPI, {
  buildCompanyParams,
  buildSearchParams,
} from '../companies';
import ApiClient from '../ApiClient';

describe('#CompanyAPI', () => {
  it('creates correct instance', () => {
    expect(companyAPI).toBeInstanceOf(ApiClient);
    expect(companyAPI).toHaveProperty('get');
    expect(companyAPI).toHaveProperty('show');
    expect(companyAPI).toHaveProperty('create');
    expect(companyAPI).toHaveProperty('update');
    expect(companyAPI).toHaveProperty('delete');
    expect(companyAPI).toHaveProperty('search');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#get with default params', () => {
      companyAPI.get({});
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies?page=1&sort=name'
      );
    });

    it('#get with page and sort params', () => {
      companyAPI.get({ page: 2, sort: 'domain' });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies?page=2&sort=domain'
      );
    });

    it('#get with descending sort', () => {
      companyAPI.get({ page: 1, sort: '-created_at' });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies?page=1&sort=-created_at'
      );
    });

    it('#search with query', () => {
      companyAPI.search('acme', 1, 'name');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/search?q=acme&page=1&sort=name'
      );
    });

    it('#search with special characters in query', () => {
      companyAPI.search('acme & co', 2, 'domain');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/search?q=acme%20%26%20co&page=2&sort=domain'
      );
    });

    it('#search with descending sort', () => {
      companyAPI.search('test', 1, '-created_at');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/search?q=test&page=1&sort=-created_at'
      );
    });

    it('#search with empty query', () => {
      companyAPI.search('', 1, 'name');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/companies/search?q=&page=1&sort=name'
      );
    });
  });
});

describe('#buildCompanyParams', () => {
  it('returns correct string with page only', () => {
    expect(buildCompanyParams(1)).toBe('page=1');
  });

  it('returns correct string with page and sort', () => {
    expect(buildCompanyParams(1, 'name')).toBe('page=1&sort=name');
  });

  it('returns correct string with different page', () => {
    expect(buildCompanyParams(3, 'domain')).toBe('page=3&sort=domain');
  });

  it('returns correct string with descending sort', () => {
    expect(buildCompanyParams(1, '-created_at')).toBe(
      'page=1&sort=-created_at'
    );
  });

  it('returns correct string without sort parameter', () => {
    expect(buildCompanyParams(2, '')).toBe('page=2');
  });
});

describe('#buildSearchParams', () => {
  it('returns correct string with all parameters', () => {
    expect(buildSearchParams('acme', 1, 'name')).toBe(
      'q=acme&page=1&sort=name'
    );
  });

  it('returns correct string with special characters', () => {
    expect(buildSearchParams('acme & co', 2, 'domain')).toBe(
      'q=acme%20%26%20co&page=2&sort=domain'
    );
  });

  it('returns correct string with empty query', () => {
    expect(buildSearchParams('', 1, 'name')).toBe('q=&page=1&sort=name');
  });

  it('returns correct string without sort parameter', () => {
    expect(buildSearchParams('test', 1, '')).toBe('q=test&page=1');
  });

  it('returns correct string with descending sort', () => {
    expect(buildSearchParams('company', 3, '-created_at')).toBe(
      'q=company&page=3&sort=-created_at'
    );
  });

  it('encodes special characters correctly', () => {
    expect(buildSearchParams('test@example.com', 1, 'name')).toBe(
      'q=test%40example.com&page=1&sort=name'
    );
  });
});
