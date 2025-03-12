import { useAutomation } from '../useAutomation';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import * as automationHelper from 'dashboard/helper/automationHelper';
import {
  customAttributes,
  agents,
  teams,
  labels,
  statusFilterOptions,
  campaigns,
  contacts,
  inboxes,
  languages,
  countries,
  slaPolicies,
} from 'dashboard/helper/specs/fixtures/automationFixtures.js';
import { MESSAGE_CONDITION_VALUES } from 'dashboard/constants/automation';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables');
vi.mock('vue-i18n');
vi.mock('dashboard/helper/automationHelper');

describe('useAutomation', () => {
  beforeEach(() => {
    useStoreGetters.mockReturnValue({
      'attributes/getAttributes': { value: customAttributes },
      'attributes/getAttributesByModel': {
        value: model => {
          return model === 'conversation_attribute'
            ? [{ id: 1, name: 'Conversation Attribute' }]
            : [{ id: 2, name: 'Contact Attribute' }];
        },
      },
    });
    useMapGetter.mockImplementation(getter => {
      const getterMap = {
        'agents/getAgents': agents,
        'campaigns/getAllCampaigns': campaigns,
        'contacts/getContacts': contacts,
        'inboxes/getInboxes': inboxes,
        'labels/getLabels': labels,
        'teams/getTeams': teams,
        'sla/getSLA': slaPolicies,
      };
      return { value: getterMap[getter] };
    });
    useI18n.mockReturnValue({ t: key => key });
    useAlert.mockReturnValue(vi.fn());

    // Mock getConditionOptions for different types
    automationHelper.getConditionOptions.mockImplementation(options => {
      const { type } = options;
      switch (type) {
        case 'status':
          return statusFilterOptions;
        case 'team_id':
          return teams;
        case 'assignee_id':
          return agents;
        case 'contact':
          return contacts;
        case 'inbox_id':
          return inboxes;
        case 'campaigns':
          return campaigns;
        case 'browser_language':
          return languages;
        case 'country_code':
          return countries;
        case 'message_type':
          return MESSAGE_CONDITION_VALUES;
        default:
          return [];
      }
    });

    // Mock getActionOptions for different types
    automationHelper.getActionOptions.mockImplementation(options => {
      const { type } = options;
      switch (type) {
        case 'add_label':
          return labels;
        case 'assign_team':
          return teams;
        case 'assign_agent':
          return agents;
        case 'send_email_to_team':
          return teams;
        case 'send_message':
          return [];
        case 'add_sla':
          return slaPolicies;
        default:
          return [];
      }
    });
  });

  it('initializes computed properties correctly', () => {
    const {
      agents: computedAgents,
      campaigns: computedCampaigns,
      contacts: computedContacts,
      inboxes: computedInboxes,
      labels: computedLabels,
      teams: computedTeams,
      slaPolicies: computedSlaPolicies,
    } = useAutomation();

    expect(computedAgents.value).toEqual(agents);
    expect(computedCampaigns.value).toEqual(campaigns);
    expect(computedContacts.value).toEqual(contacts);
    expect(computedInboxes.value).toEqual(inboxes);
    expect(computedLabels.value).toEqual(labels);
    expect(computedTeams.value).toEqual(teams);
    expect(computedSlaPolicies.value).toEqual(slaPolicies);
  });

  it('appends new condition and action correctly', () => {
    const { appendNewCondition, appendNewAction, automation } = useAutomation();
    automation.value = {
      event_name: 'message_created',
      conditions: [],
      actions: [],
    };

    automationHelper.getDefaultConditions.mockReturnValue([{}]);
    automationHelper.getDefaultActions.mockReturnValue([{}]);

    appendNewCondition();
    appendNewAction();

    expect(automationHelper.getDefaultConditions).toHaveBeenCalledWith(
      'message_created'
    );
    expect(automationHelper.getDefaultActions).toHaveBeenCalled();
    expect(automation.value.conditions).toHaveLength(1);
    expect(automation.value.actions).toHaveLength(1);
  });

  it('removes filter and action correctly', () => {
    const { removeFilter, removeAction, automation } = useAutomation();
    automation.value = {
      conditions: [{ id: 1 }, { id: 2 }],
      actions: [{ id: 1 }, { id: 2 }],
    };

    removeFilter(0);
    removeAction(0);

    expect(automation.value.conditions).toHaveLength(1);
    expect(automation.value.actions).toHaveLength(1);
    expect(automation.value.conditions[0].id).toBe(2);
    expect(automation.value.actions[0].id).toBe(2);
  });

  it('resets filter and action correctly', () => {
    const { resetFilter, resetAction, automation, automationTypes } =
      useAutomation();
    automation.value = {
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
    automationTypes.message_created = {
      conditions: [
        { key: 'status', filterOperators: [{ value: 'not_equal_to' }] },
      ],
    };

    resetFilter(0, automation.value.conditions[0]);
    resetAction(0);

    expect(automation.value.conditions[0].filter_operator).toBe('not_equal_to');
    expect(automation.value.conditions[0].values).toBe('');
    expect(automation.value.actions[0].action_params).toEqual([]);
  });

  it('manifests custom attributes correctly', () => {
    const { manifestCustomAttributes, automationTypes } = useAutomation();
    automationTypes.message_created = { conditions: [] };
    automationTypes.conversation_created = { conditions: [] };
    automationTypes.conversation_updated = { conditions: [] };
    automationTypes.conversation_opened = { conditions: [] };

    automationHelper.generateCustomAttributeTypes.mockReturnValue([]);
    automationHelper.generateCustomAttributes.mockReturnValue([]);

    manifestCustomAttributes();

    expect(automationHelper.generateCustomAttributeTypes).toHaveBeenCalledTimes(
      2
    );
    expect(automationHelper.generateCustomAttributes).toHaveBeenCalledTimes(1);
    Object.values(automationTypes).forEach(type => {
      expect(type.conditions).toHaveLength(0);
    });
  });

  it('gets condition dropdown values correctly', () => {
    const { getConditionDropdownValues } = useAutomation();

    expect(getConditionDropdownValues('status')).toEqual(statusFilterOptions);
    expect(getConditionDropdownValues('team_id')).toEqual(teams);
    expect(getConditionDropdownValues('assignee_id')).toEqual(agents);
    expect(getConditionDropdownValues('contact')).toEqual(contacts);
    expect(getConditionDropdownValues('inbox_id')).toEqual(inboxes);
    expect(getConditionDropdownValues('campaigns')).toEqual(campaigns);
    expect(getConditionDropdownValues('browser_language')).toEqual(languages);
    expect(getConditionDropdownValues('country_code')).toEqual(countries);
    expect(getConditionDropdownValues('message_type')).toEqual(
      MESSAGE_CONDITION_VALUES
    );
  });

  it('gets action dropdown values correctly', () => {
    const { getActionDropdownValues } = useAutomation();

    expect(getActionDropdownValues('add_label')).toEqual(labels);
    expect(getActionDropdownValues('assign_team')).toEqual(teams);
    expect(getActionDropdownValues('assign_agent')).toEqual(agents);
    expect(getActionDropdownValues('send_email_to_team')).toEqual(teams);
    expect(getActionDropdownValues('send_message')).toEqual([]);
    expect(getActionDropdownValues('add_sla')).toEqual(slaPolicies);
  });

  it('handles event change correctly', () => {
    const { onEventChange, automation } = useAutomation();
    automation.value = {
      event_name: 'message_created',
      conditions: [],
      actions: [],
    };

    automationHelper.getDefaultConditions.mockReturnValue([{}]);
    automationHelper.getDefaultActions.mockReturnValue([{}]);

    onEventChange();

    expect(automationHelper.getDefaultConditions).toHaveBeenCalledWith(
      'message_created'
    );
    expect(automationHelper.getDefaultActions).toHaveBeenCalled();
    expect(automation.value.conditions).toHaveLength(1);
    expect(automation.value.actions).toHaveLength(1);
  });
});
