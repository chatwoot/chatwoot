import { ref } from 'vue';
import ContactAPI from 'dashboard/api/contacts';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useConversationFilterContext } from '../provider';
import {
  CONVERSATION_ATTRIBUTES,
  getCustomAttributeInputType,
  buildAttributesFilterTypes,
  replaceUnderscoreWithSpace,
  buildFiltersFromRecommendations,
  buildRecommendationGroups,
} from './filterHelper';

vi.mock('dashboard/api/contacts', () => ({
  default: {
    search: vi.fn(),
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
  describe('buildFiltersFromRecommendations', () => {
    const filterTypes = [
      {
        attributeKey: 'priority',
        inputType: 'multiSelect',
        options: [
          { id: 'high', name: 'High' },
          { id: 'urgent', name: 'Urgent' },
        ],
      },
      {
        attributeKey: 'assignee_id',
        inputType: 'searchSelect',
        options: [{ id: 7, name: 'Priya' }],
      },
      { attributeKey: 'created_at', inputType: 'date' },
    ];

    it('maps recommended values to the options the filter rows use', () => {
      const recommendations = [
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: ['urgent'],
        },
        {
          attribute_key: 'assignee_id',
          filter_operator: 'not_equal_to',
          values: [7],
        },
        {
          attribute_key: 'created_at',
          filter_operator: 'days_before',
          values: [3],
        },
      ];

      expect(
        buildFiltersFromRecommendations(recommendations, filterTypes)
      ).toEqual([
        {
          attributeKey: 'priority',
          filterOperator: 'equal_to',
          values: [{ id: 'urgent', name: 'Urgent' }],
          queryOperator: 'and',
        },
        {
          attributeKey: 'assignee_id',
          filterOperator: 'not_equal_to',
          values: { id: 7, name: 'Priya' },
          queryOperator: 'and',
        },
        {
          attributeKey: 'created_at',
          filterOperator: 'days_before',
          values: '3',
          queryOperator: 'and',
        },
      ]);
    });

    it('leaves values empty when the recommendation has none or needs none', () => {
      const recommendations = [
        { attribute_key: 'priority', filter_operator: 'equal_to', values: [] },
        {
          attribute_key: 'assignee_id',
          filter_operator: 'is_not_present',
          values: [],
        },
      ];

      expect(
        buildFiltersFromRecommendations(recommendations, filterTypes).map(
          filter => filter.values
        )
      ).toEqual([[], []]);
    });

    it('expands a date preset into date rows for the field', () => {
      const dateFilterTypes = [
        {
          attributeKey: 'created_at',
          inputType: 'date',
          attributeModel: 'standard',
        },
      ];
      const recommendations = [
        { attribute_key: 'created_at', date_preset: 'yesterday' },
      ];

      expect(
        buildFiltersFromRecommendations(
          recommendations,
          dateFilterTypes,
          new Date(2026, 10, 4)
        )
      ).toEqual([
        {
          attributeKey: 'created_at',
          attributeModel: 'standard',
          filterOperator: 'is_greater_than',
          values: '2026-11-02',
          queryOperator: 'and',
        },
        {
          attributeKey: 'created_at',
          attributeModel: 'standard',
          filterOperator: 'is_less_than',
          values: '2026-11-04',
          queryOperator: 'and',
        },
      ]);
    });

    it('keeps the list of texts for a multi-text input', () => {
      const recommendations = [
        {
          attribute_key: 'content',
          filter_operator: 'contains',
          values: ['refund'],
        },
      ];

      expect(
        buildFiltersFromRecommendations(recommendations, [
          { attributeKey: 'content', inputType: 'multiText' },
        ])[0].values
      ).toEqual(['refund']);
    });

    it('groups the rows of each recommendation with a readable label', () => {
      const recommendations = [
        {
          attribute_key: 'priority',
          filter_operator: 'equal_to',
          values: ['urgent'],
        },
        { attribute_key: 'created_at', date_preset: 'yesterday' },
      ];
      const groupFilterTypes = [
        {
          attributeKey: 'priority',
          label: 'Priority',
          icon: 'i-priority',
          inputType: 'multiSelect',
          options: [{ id: 'urgent', name: 'Urgent' }],
          filterOperators: [{ value: 'equal_to', label: 'Equal to' }],
        },
        {
          attributeKey: 'created_at',
          label: 'Created at',
          inputType: 'date',
          filterOperators: [
            { value: 'is_greater_than', label: 'Is greater than' },
            { value: 'is_less_than', label: 'Is less than' },
          ],
        },
      ];

      const groups = buildRecommendationGroups(
        recommendations,
        groupFilterTypes,
        new Date(2026, 10, 4)
      );

      expect(groups.map(({ label, icon }) => ({ label, icon }))).toEqual([
        { label: 'Priority Equal to Urgent', icon: 'i-priority' },
        {
          label:
            'Created at Is greater than 2026-11-02, Created at Is less than 2026-11-04',
          icon: undefined,
        },
      ]);
      expect(groups[1].rows).toHaveLength(2);
    });

    it('drops attributes the filter form does not offer', () => {
      const recommendations = [
        { attribute_key: 'unknown', filter_operator: 'equal_to', values: [] },
      ];

      expect(
        buildFiltersFromRecommendations(recommendations, filterTypes)
      ).toEqual([]);
    });
  });

  describe('getCustomAttributeInputType', () => {
    it('returns number for number type', () => {
      expect(getCustomAttributeInputType('number')).toBe('number');
    });
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
          attributeDisplayType: 'text',
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
          attributeDisplayType: 'list',
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

describe('useConversationFilterContext', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useMapGetter.mockImplementation(key => storeValues[key] || ref([]));
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
});
