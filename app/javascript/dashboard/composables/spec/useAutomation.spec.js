import { useAutomation } from '../useAutomation';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from '../useI18n';
import * as automationHelper from 'dashboard/helper/automationHelper';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables');
vi.mock('../useI18n');
vi.mock('dashboard/helper/automationHelper');

describe('useAutomation', () => {
  const mockAgents = [
    { id: 1, name: 'Agent 1', email: 'agent1@paperlayer.test' },
    { id: 2, name: 'Agent 2', email: 'agent2@paperlayer.test' },
  ];
  const mockCampaigns = [
    { id: 1, name: 'Campaign 1' },
    { id: 2, name: 'Campaign 2' },
  ];
  const mockContacts = [
    { id: 1, name: 'Contact 1', email: 'contact1@paperlayer.test' },
    { id: 2, name: 'Contact 2', email: 'contact2@paperlayer.test' },
  ];
  const mockInboxes = [
    { id: 1, name: 'Inbox 1', channel_type: 'Channel::WebWidget' },
    { id: 2, name: 'Inbox 2', channel_type: 'Channel::Email' },
  ];
  const mockLabels = [
    { id: 1, title: 'Label 1' },
    { id: 2, title: 'Label 2' },
  ];
  const mockTeams = [
    { id: 1, name: 'Team 1' },
    { id: 2, name: 'Team 2' },
  ];
  const mockSLAPolicies = [
    { id: 1, name: 'SLA 1' },
    { id: 2, name: 'SLA 2' },
  ];
  const mockAttributes = [
    { id: 1, name: 'Attribute 1' },
    { id: 2, name: 'Attribute 2' },
  ];

  beforeEach(() => {
    useStoreGetters.mockReturnValue({
      'attributes/getAttributes': { value: mockAttributes },
    });
    useMapGetter.mockImplementation(getter => {
      const getterMap = {
        'agents/getAgents': mockAgents,
        'campaigns/getAllCampaigns': mockCampaigns,
        'contacts/getContacts': mockContacts,
        'inboxes/getInboxes': mockInboxes,
        'labels/getLabels': mockLabels,
        'teams/getTeams': mockTeams,
        'sla/getSLA': mockSLAPolicies,
      };
      return { value: getterMap[getter] };
    });
    useI18n.mockReturnValue({ t: key => key });
    useAlert.mockReturnValue(vi.fn());
  });

  it('initializes computed properties correctly', () => {
    const { agents, campaigns, contacts, inboxes, labels, teams, slaPolicies } =
      useAutomation();

    expect(agents.value).toEqual(mockAgents);
    expect(campaigns.value).toEqual(mockCampaigns);
    expect(contacts.value).toEqual(mockContacts);
    expect(inboxes.value).toEqual(mockInboxes);
    expect(labels.value).toEqual(mockLabels);
    expect(teams.value).toEqual(mockTeams);
    expect(slaPolicies.value).toEqual(mockSLAPolicies);
  });

  it('appends new condition and action correctly', () => {
    const { appendNewCondition, appendNewAction } = useAutomation();
    const mockAutomation = {
      event_name: 'message_created',
      conditions: [],
      actions: [],
    };

    automationHelper.getDefaultConditions.mockReturnValue([{}]);
    automationHelper.getDefaultActions.mockReturnValue([{}]);

    appendNewCondition(mockAutomation);
    appendNewAction(mockAutomation);

    expect(automationHelper.getDefaultConditions).toHaveBeenCalledWith(
      'message_created'
    );
    expect(automationHelper.getDefaultActions).toHaveBeenCalled();
    expect(mockAutomation.conditions).toHaveLength(1);
    expect(mockAutomation.actions).toHaveLength(1);
  });

  it('removes filter and action correctly', () => {
    const { removeFilter, removeAction } = useAutomation();
    const mockAutomation = {
      conditions: [{ id: 1 }, { id: 2 }],
      actions: [{ id: 1 }, { id: 2 }],
    };

    removeFilter(mockAutomation, 0);
    removeAction(mockAutomation, 0);

    expect(mockAutomation.conditions).toHaveLength(1);
    expect(mockAutomation.actions).toHaveLength(1);
    expect(mockAutomation.conditions[0].id).toBe(2);
    expect(mockAutomation.actions[0].id).toBe(2);
  });

  it('resets filter and action correctly', () => {
    const { resetFilter, resetAction } = useAutomation();
    const mockAutomation = {
      event_name: 'message_created',
      conditions: [
        {
          attribute_key: 'status',
          filter_operator: 'equal_to',
          values: 'open',
        },
      ],
      actions: [{ action_name: 'assign_agent', action_params: [1] }],
    };
    const mockAutomationTypes = {
      message_created: {
        conditions: [
          { key: 'status', filterOperators: [{ value: 'not_equal_to' }] },
        ],
      },
    };

    resetFilter(
      mockAutomation,
      mockAutomationTypes,
      0,
      mockAutomation.conditions[0]
    );
    resetAction(mockAutomation, 0);

    expect(mockAutomation.conditions[0].filter_operator).toBe('not_equal_to');
    expect(mockAutomation.conditions[0].values).toBe('');
    expect(mockAutomation.actions[0].action_params).toEqual([]);
  });

  it('formats automation correctly', () => {
    const { formatAutomation } = useAutomation();
    const mockAutomation = {
      conditions: [{ attribute_key: 'status', values: ['open'] }],
      actions: [{ action_name: 'assign_agent', action_params: [1] }],
    };
    const mockAutomationTypes = {};
    const mockAutomationActionTypes = [
      { key: 'assign_agent', inputType: 'search_select' },
    ];

    automationHelper.getConditionOptions.mockReturnValue([
      { id: 'open', name: 'open' },
    ]);
    automationHelper.getActionOptions.mockReturnValue([
      { id: 1, name: 'Agent 1' },
    ]);

    const result = formatAutomation(
      mockAutomation,
      mockAttributes,
      mockAutomationTypes,
      mockAutomationActionTypes
    );

    expect(result.conditions[0].values).toEqual([{ id: 'open', name: 'open' }]);
    expect(result.actions[0].action_params).toEqual([
      { id: 1, name: 'Agent 1' },
    ]);
  });

  it('manifests custom attributes correctly', () => {
    const mockGetters = {
      'attributes/getAttributes': { value: mockAttributes },
      'attributes/getAttributesByModel': {
        value: model => {
          return model === 'conversation_attribute'
            ? [{ id: 1, name: 'Conversation Attribute' }]
            : [{ id: 2, name: 'Contact Attribute' }];
        },
      },
    };
    useStoreGetters.mockReturnValue(mockGetters);

    const { manifestCustomAttributes } = useAutomation();
    const mockAutomationTypes = {
      message_created: { conditions: [] },
      conversation_created: { conditions: [] },
      conversation_updated: { conditions: [] },
      conversation_opened: { conditions: [] },
    };

    automationHelper.generateCustomAttributeTypes.mockReturnValue([]);
    automationHelper.generateCustomAttributes.mockReturnValue([]);

    manifestCustomAttributes(mockAutomationTypes);

    expect(automationHelper.generateCustomAttributeTypes).toHaveBeenCalledTimes(
      2
    );
    expect(automationHelper.generateCustomAttributes).toHaveBeenCalledTimes(1);
    Object.values(mockAutomationTypes).forEach(type => {
      expect(type.conditions).toHaveLength(0);
    });
  });
});
