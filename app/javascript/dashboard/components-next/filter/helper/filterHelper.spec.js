import { ref } from 'vue';
import ContactAPI from 'dashboard/api/contacts';
import CtwaCampaignsAPI from 'dashboard/api/ctwaCampaigns';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useConversationFilterContext } from '../provider';
import {
  CONVERSATION_ATTRIBUTES,
  getCustomAttributeInputType,
  buildAttributesFilterTypes,
  replaceUnderscoreWithSpace,
} from './filterHelper';

vi.mock('dashboard/api/contacts', () => ({
  default: {
    search: vi.fn(),
  },
}));

vi.mock('dashboard/api/ctwaCampaigns', () => ({
  default: {
    get: vi.fn(),
  },
}));

vi.mock('dashboard/composables/store.js', () => ({
  useMapGetter: vi.fn(),
}));

vi.mock('next/icon/provider', () => ({
  useChannelIcon: () => ref('i-test-channel'),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params = {}) => {
      if (key === 'FILTER.CONTACT_FALLBACK') return `Contact #${params.id}`;
      return key;
    },
  }),
}));

describe('filterHelper', () => {
  describe('getCustomAttributeInputType', () => {
    it('returns date for date type', () => {
      expect(getCustomAttributeInputType('date')).toBe('date');
    });

    it('returns plainText for text type', () => {
      expect(getCustomAttributeInputType('text')).toBe('plainText');
    });

    it('returns searchSelect for list type', () => {
      expect(getCustomAttributeInputType('list')).toBe('searchSelect');
    });

    it('returns booleanSelect for checkbox type', () => {
      expect(getCustomAttributeInputType('checkbox')).toBe('booleanSelect');
    });

    it('returns plainText for unknown type', () => {
      expect(getCustomAttributeInputType('unknown')).toBe('plainText');
    });
  });

  describe('buildAttributesFilterTypes', () => {
    const mockGetOperatorTypes = type => {
      return type === 'list' ? ['is', 'is_not'] : ['contains', 'not_contains'];
    };

    it('builds filter types for text attributes', () => {
      const attributes = [
        {
          attributeKey: 'test_key',
          attributeDisplayName: 'Test Name',
          attributeDisplayType: 'text',
          attributeValues: [],
        },
      ];

      const result = buildAttributesFilterTypes(
        attributes,
        mockGetOperatorTypes
      );

      expect(result).toEqual([
        {
          attributeKey: 'test_key',
          value: 'test_key',
          attributeName: 'Test Name',
          label: 'Test Name',
          inputType: 'plainText',
          filterOperators: ['contains', 'not_contains'],
          options: [],
          attributeModel: 'customAttributes',
        },
      ]);
    });

    it('builds filter types for list attributes with options', () => {
      const attributes = [
        {
          attributeKey: 'list_key',
          attributeDisplayName: 'List Name',
          attributeDisplayType: 'list',
          attributeValues: ['option1', 'option2'],
        },
      ];

      const result = buildAttributesFilterTypes(
        attributes,
        mockGetOperatorTypes
      );

      expect(result).toEqual([
        {
          attributeKey: 'list_key',
          value: 'list_key',
          attributeName: 'List Name',
          label: 'List Name',
          inputType: 'searchSelect',
          filterOperators: ['is', 'is_not'],
          options: [
            { id: 'option1', name: 'option1' },
            { id: 'option2', name: 'option2' },
          ],
          attributeModel: 'customAttributes',
        },
      ]);
    });

    it('handles multiple attributes', () => {
      const attributes = [
        {
          attributeKey: 'date_key',
          attributeDisplayName: 'Date Name',
          attributeDisplayType: 'date',
          attributeValues: [],
        },
        {
          attributeKey: 'checkbox_key',
          attributeDisplayName: 'Checkbox Name',
          attributeDisplayType: 'checkbox',
          attributeValues: [],
        },
      ];

      const result = buildAttributesFilterTypes(
        attributes,
        mockGetOperatorTypes
      );

      expect(result).toHaveLength(2);
      expect(result[0].inputType).toBe('date');
      expect(result[1].inputType).toBe('booleanSelect');
    });

    it('handles empty attributes array', () => {
      const result = buildAttributesFilterTypes([], mockGetOperatorTypes);
      expect(result).toEqual([]);
    });

    it('excludes custom attributes colliding with campaign_source_ids', () => {
      const attributes = [
        {
          attributeKey: 'campaign_source_ids',
          attributeDisplayName: 'Colliding Attribute',
          attributeDisplayType: 'text',
          attributeValues: [],
        },
      ];

      const result = buildAttributesFilterTypes(
        attributes,
        mockGetOperatorTypes
      );

      expect(result).toEqual([]);
    });
  });

  describe('replaceUnderscoreWithSpace', () => {
    it('replaces underscores with spaces', () => {
      expect(replaceUnderscoreWithSpace('test_key')).toBe('test key');
    });

    it('returns empty string if input is null', () => {
      expect(replaceUnderscoreWithSpace(null)).toBe('');
    });
  });
});

const storeValues = {
  'attributes/getConversationAttributes': ref([]),
  'labels/getLabels': ref([]),
  'agents/getAgents': ref([]),
  'inboxes/getInboxes': ref([]),
  'teams/getTeams': ref([]),
  'campaigns/getAllCampaigns': ref([]),
};

const flushPromises = () =>
  new Promise(resolve => {
    setTimeout(resolve);
  });

describe('useConversationFilterContext', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useMapGetter.mockImplementation(key => storeValues[key] || ref([]));
    CtwaCampaignsAPI.get.mockResolvedValue({ data: { payload: [] } });
  });

  it('exposes contact as an async searchable conversation filter', () => {
    const { filterTypes } = useConversationFilterContext();
    const contactFilter = filterTypes.value.find(
      filter => filter.attributeKey === CONVERSATION_ATTRIBUTES.CONTACT_ID
    );

    expect(contactFilter).toMatchObject({
      attributeKey: 'contact_id',
      label: 'FILTER.ATTRIBUTES.CONTACT',
      inputType: 'asyncSearchSelect',
      dataType: 'number',
      attributeModel: 'standard',
    });
    expect(
      contactFilter.filterOperators.map(operator => operator.value)
    ).toEqual(['equal_to', 'not_equal_to']);
  });

  it('uses the existing contact search API for contact filter options', async () => {
    ContactAPI.search.mockResolvedValue({
      data: {
        payload: [
          { id: 1, name: 'Jane Doe' },
          { id: 2, email: 'alex@example.com' },
          { id: 3 },
        ],
      },
    });

    const { filterTypes } = useConversationFilterContext();
    const contactFilter = filterTypes.value.find(
      filter => filter.attributeKey === CONVERSATION_ATTRIBUTES.CONTACT_ID
    );
    const options = await contactFilter.searchOptions('jane');

    expect(ContactAPI.search).toHaveBeenCalledWith('jane', 1, 'name', '', {
      signal: expect.any(AbortSignal),
    });
    expect(options).toEqual([
      { id: 1, name: 'Jane Doe' },
      { id: 2, name: 'alex@example.com' },
      { id: 3, name: 'Contact #3' },
    ]);
  });

  it('exposes the CTWA campaign filter with containment and presence operators', () => {
    const { filterTypes } = useConversationFilterContext();
    const campaignFilter = filterTypes.value.find(
      filter =>
        filter.attributeKey === CONVERSATION_ATTRIBUTES.CAMPAIGN_SOURCE_IDS
    );

    expect(campaignFilter).toMatchObject({
      attributeKey: 'campaign_source_ids',
      label: 'FILTER.ATTRIBUTES.CAMPAIGN_SOURCE',
      inputType: 'searchSelect',
      dataType: 'text',
      attributeModel: 'additional',
    });
    expect(
      campaignFilter.filterOperators.map(operator => operator.value)
    ).toEqual(['contains', 'does_not_contain', 'is_present', 'is_not_present']);
  });

  it('builds CTWA campaign options with quoted source_id tokens and headline names', async () => {
    CtwaCampaignsAPI.get.mockResolvedValue({
      data: {
        payload: [
          { source_id: '120247112194560621', headline: 'Summer promo' },
          { source_id: '120252613195760416', headline: null },
        ],
      },
    });

    const { filterTypes } = useConversationFilterContext();
    await flushPromises();

    const campaignFilter = filterTypes.value.find(
      filter =>
        filter.attributeKey === CONVERSATION_ATTRIBUTES.CAMPAIGN_SOURCE_IDS
    );

    expect(CtwaCampaignsAPI.get).toHaveBeenCalled();
    expect(campaignFilter.options).toEqual([
      { id: '"120247112194560621"', name: 'Summer promo' },
      { id: '"120252613195760416"', name: '120252613195760416' },
    ]);
  });

  it('keeps CTWA campaign options empty when the endpoint fails', async () => {
    CtwaCampaignsAPI.get.mockRejectedValue(new Error('boom'));

    const { filterTypes } = useConversationFilterContext();
    await flushPromises();

    const campaignFilter = filterTypes.value.find(
      filter =>
        filter.attributeKey === CONVERSATION_ATTRIBUTES.CAMPAIGN_SOURCE_IDS
    );

    expect(campaignFilter.options).toEqual([]);
  });
});
