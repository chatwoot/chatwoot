import { mount } from '@vue/test-utils';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import APICampaignsPage from './APICampaignsPage.vue';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

const mockCampaigns = [
  {
    id: 1,
    title: 'Test API Campaign 1',
    status: 'completed',
    scheduled_at: '2025-06-01T10:00:00Z',
    inbox: { name: 'API Inbox 1', channel_type: 'Api::Base' },
  },
  {
    id: 2,
    title: 'Test API Campaign 2',
    status: 'scheduled',
    scheduled_at: '2025-06-05T15:00:00Z',
    inbox: { name: 'API Inbox 2', channel_type: 'Api::Base' },
  },
];

// Mock the composables with a dynamic campaigns result we can tweak per test
let campaignsReturnValue = mockCampaigns;
vi.mock('dashboard/composables/store', () => ({
  useStoreGetters: () => ({
    'campaigns/getCampaigns': {
      value: vi.fn(type =>
        type === CAMPAIGN_TYPES.ONE_OFF ? campaignsReturnValue : []
      ),
    },
  }),
  useMapGetter: vi.fn(path => {
    const mockData = {
      'campaigns/getUIFlags': {
        value: { isFetching: false, isDeleting: false },
      },
    };
    return mockData[path] || { value: {} };
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: vi.fn(key => key),
  }),
}));

vi.mock('@vueuse/core', () => ({
  useToggle: () => {
    const state = { value: false };
    const toggle = vi.fn(newState => {
      state.value = newState !== undefined ? newState : !state.value;
    });
    return [state, toggle];
  },
}));

const createWrapper = () => {
  return mount(APICampaignsPage, {
    global: {
      stubs: {
        Spinner: { template: '<div>Loading...</div>' },
        CampaignLayout: {
          template: '<div><slot name="action" /><slot /></div>',
          props: ['headerTitle', 'buttonLabel'],
        },
        CampaignList: {
          template: '<div data-testid="campaign-list"><slot /></div>',
          props: ['campaigns', 'showEmptyResult'],
        },
        APICampaignDialog: {
          template: '<div data-testid="api-campaign-dialog"><slot /></div>',
        },
        ConfirmDeleteCampaignDialog: {
          template: '<div data-testid="delete-dialog"><slot /></div>',
        },
        APICampaignEmptyState: {
          template: '<div data-testid="empty-state">No campaigns</div>',
        },
      },
    },
  });
};
describe('APICampaignsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders correctly', () => {
    const wrapper = createWrapper();
    expect(wrapper.exists()).toBe(true);
  });

  it('displays campaigns when available', () => {
    campaignsReturnValue = mockCampaigns;
    const wrapper = createWrapper();

    // Should have campaigns available
    expect(wrapper.vm.APICampaigns?.length).toBe(2);
    expect(wrapper.vm.hasNoAPICampaigns).toBe(false);
  });

  it('shows empty state when no campaigns', () => {
    // Use empty campaigns
    campaignsReturnValue = [];
    const wrapper = createWrapper();
    expect(wrapper.vm.hasNoAPICampaigns).toBe(true);
  });

  it('handles campaign deletion', () => {
    const wrapper = createWrapper();

    const testCampaign = mockCampaigns[0];

    // Mock the confirmDeleteCampaignDialogRef
    wrapper.vm.confirmDeleteCampaignDialogRef = {
      dialogRef: {
        open: vi.fn(),
        close: vi.fn(),
      },
    };

    wrapper.vm.handleDelete(testCampaign);

    expect(wrapper.vm.selectedCampaign).toEqual(testCampaign);
    expect(
      wrapper.vm.confirmDeleteCampaignDialogRef.dialogRef.open
    ).toHaveBeenCalled();
  });

  it('computes loading state correctly', () => {
    const wrapper = createWrapper();

    expect(wrapper.vm.isFetchingCampaigns).toBe(false);
  });

  it('toggles API campaign dialog', () => {
    const wrapper = createWrapper();

    // Should start closed
    expect(wrapper.vm.showAPICampaignDialog.value).toBe(false);

    // Toggle it
    wrapper.vm.toggleAPICampaignDialog();
    expect(wrapper.vm.showAPICampaignDialog.value).toBe(true);

    // Toggle with explicit value
    wrapper.vm.toggleAPICampaignDialog(false);
    expect(wrapper.vm.showAPICampaignDialog.value).toBe(false);
  });
});
