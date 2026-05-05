import { setActivePinia, createPinia } from 'pinia';
import CompanyAPI from 'dashboard/api/companies';
import { useCompaniesStore } from './companies';

vi.mock('dashboard/api/companies', () => ({
  default: {
    show: vi.fn(),
    update: vi.fn(),
    destroyAvatar: vi.fn(),
    listContacts: vi.fn(),
    searchContacts: vi.fn(),
    createContact: vi.fn(),
    removeContact: vi.fn(),
    destroyCustomAttributes: vi.fn(),
  },
}));

vi.mock('dashboard/store/utils/api', () => ({
  throwErrorMessage: vi.fn(error => error),
}));

const createDeferred = () => {
  let resolve;
  const promise = new Promise(res => {
    resolve = res;
  });

  return { promise, resolve };
};

describe('companies store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  it('keeps the latest active company when show requests resolve out of order', async () => {
    const firstRequest = createDeferred();
    const secondRequest = createDeferred();

    CompanyAPI.show
      .mockImplementationOnce(() => firstRequest.promise)
      .mockImplementationOnce(() => secondRequest.promise);

    const companiesStore = useCompaniesStore();

    const staleRequest = companiesStore.show(1);
    const currentRequest = companiesStore.show(2);

    secondRequest.resolve({
      data: {
        payload: {
          id: 2,
          name: 'Beta Company',
        },
      },
    });

    await currentRequest;

    expect(companiesStore.activeCompanyId).toBe(2);
    expect(companiesStore.getUIFlags.fetchingItem).toBe(false);

    firstRequest.resolve({
      data: {
        payload: {
          id: 1,
          name: 'Alpha Company',
        },
      },
    });

    await staleRequest;

    expect(companiesStore.activeCompanyId).toBe(2);
    expect(companiesStore.getRecord(1)).toEqual({});
    expect(companiesStore.getRecord(2)).toEqual(
      expect.objectContaining({ id: 2, name: 'Beta Company' })
    );
    expect(companiesStore.getUIFlags.fetchingItem).toBe(false);
  });

  it('keeps avatar files intact when building multipart update params', async () => {
    CompanyAPI.update.mockResolvedValueOnce({
      data: {
        payload: {
          id: 1,
          name: 'Acme',
        },
      },
    });

    const companiesStore = useCompaniesStore();
    const avatar = new File(['avatar'], 'avatar.png', { type: 'image/png' });

    await companiesStore.update({
      id: 1,
      name: 'Acme',
      avatar,
    });

    const formData = CompanyAPI.update.mock.calls[0][1];
    expect(formData.get('company[avatar]')).toBe(avatar);
    expect(formData.get('company[name]')).toBe('Acme');
  });

  it('preserves custom attribute keys when building update params', async () => {
    CompanyAPI.update.mockResolvedValueOnce({
      data: {
        payload: {
          id: 1,
          name: 'Acme',
          custom_attributes: {
            subscriptionPlan: 'Enterprise',
          },
        },
      },
    });

    const companiesStore = useCompaniesStore();

    await companiesStore.update({
      id: 1,
      customAttributes: {
        subscriptionPlan: 'Enterprise',
      },
    });

    expect(CompanyAPI.update).toHaveBeenCalledWith(1, {
      company: {
        custom_attributes: {
          subscriptionPlan: 'Enterprise',
        },
      },
    });
  });

  it('links an existing contact and refreshes company contacts', async () => {
    CompanyAPI.createContact.mockResolvedValueOnce({
      data: {
        payload: {
          id: 2,
          name: 'Jane Contact',
          company_id: 1,
          linked_to_current_company: true,
        },
      },
    });
    CompanyAPI.listContacts.mockResolvedValueOnce({
      data: {
        payload: [
          {
            id: 2,
            name: 'Jane Contact',
            company_id: 1,
            linked_to_current_company: true,
          },
        ],
        meta: { total_count: 1, page: 1 },
      },
    });

    const companiesStore = useCompaniesStore();
    companiesStore.setActiveCompanyId(1);

    await companiesStore.attachContactToCompany(1, 2);

    expect(CompanyAPI.createContact).toHaveBeenCalledWith(1, {
      contact_id: 2,
    });
    expect(CompanyAPI.listContacts).toHaveBeenCalledWith(1, 1);
    expect(companiesStore.companyContacts).toEqual([
      expect.objectContaining({
        id: 2,
        companyId: 1,
        linkedToCurrentCompany: true,
      }),
    ]);
  });

  it('removes a company custom attribute and updates the company record', async () => {
    CompanyAPI.destroyCustomAttributes.mockResolvedValueOnce({
      data: {
        payload: {
          id: 1,
          name: 'Acme',
          custom_attributes: {
            region: 'us',
          },
        },
      },
    });

    const companiesStore = useCompaniesStore();

    await companiesStore.deleteCustomAttributes({
      id: 1,
      customAttributes: ['plan'],
    });

    expect(CompanyAPI.destroyCustomAttributes).toHaveBeenCalledWith(1, [
      'plan',
    ]);
    expect(companiesStore.getRecord(1)).toEqual(
      expect.objectContaining({
        id: 1,
        customAttributes: {
          region: 'us',
        },
      })
    );
  });
});
