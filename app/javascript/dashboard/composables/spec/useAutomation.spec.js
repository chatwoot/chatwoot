import { useAutomation } from '../useAutomation';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import * as automationHelper from 'dashboard/helper/automationHelper';
import { CUSTOM_ATTRIBUTE_EVENTS } from 'dashboard/constants/automation';
import {
  customAttributes,
  agents,
  teams,
  labels,
  booleanFilterOptions,
  statusFilterOptions,
  messageTypeOptions,
  priorityOptions,
  campaigns,
  contacts,
  inboxes,
  languages,
  countries,
  slaPolicies,
} from 'dashboard/helper/specs/fixtures/automationFixtures.js';

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
        'agents/getVerifiedAgents': agents,
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
          return messageTypeOptions;
        case 'private_note':
          return booleanFilterOptions;
        case 'priority':
          return priorityOptions;
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
          return options.addNoneToListFn
            ? options.addNoneToListFn(options.agents)
            : options.agents;
        case 'send_email_to_team':
          return teams;
        case 'send_message':
          return [];
        case 'add_sla':
          return slaPolicies;
        case 'change_priority':
          return priorityOptions;
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
      statusFilterOptions: computedStatusFilterOptions,
    } = useAutomation();

    expect(computedAgents.value).toEqual(agents);
    expect(computedCampaigns.value).toEqual(campaigns);
    expect(computedContacts.value).toEqual(contacts);
    expect(computedInboxes.value).toEqual(inboxes);
    expect(computedLabels.value).toEqual(labels);
    expect(computedTeams.value).toEqual(teams);
    expect(computedSlaPolicies.value).toEqual(slaPolicies);
    expect(
      computedStatusFilterOptions.value.filter(option => option.id === 'all')
    ).toHaveLength(1);
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

  it('resets scheduled message action with default delay_minutes', () => {
    const { resetAction, automation } = useAutomation();
    automation.value = {
      event_name: 'message_created',
      conditions: [],
      actions: [
        {
          action_name: 'create_scheduled_message',
          action_params: [{ content: 'test', delay_minutes: 60 }],
        },
      ],
    };

    resetAction(0);

    // Should reset with default delay of 24 hours (1440 minutes)
    expect(automation.value.actions[0].action_params).toEqual([
      { delay_minutes: 1440 },
    ]);
  });

  // Every trigger is seeded and every trigger is asserted over, both driven by the object itself
  // rather than by a list typed here, so a trigger added tomorrow is covered instead of being the
  // thing that breaks this. Which triggers receive the attributes is read from the same constant the
  // pass reads. #667
  it('appends the account custom attributes to the triggers that offer them, and to no others', () => {
    const { manifestCustomAttributes, automationTypes } = useAutomation();

    const standard = { key: 'message_type', name: 'Message Type' };
    const stale = {
      key: 'stale_attribute',
      name: 'Stale',
      customAttributeType: 'conversation_attribute',
    };
    Object.keys(automationTypes).forEach(key => {
      automationTypes[key] = { conditions: [standard, stale] };
    });

    const manifested = [
      {
        key: 'conversation_custom_attribute',
        name: 'Conversation Custom Attributes',
      },
      {
        key: 'fresh_attribute',
        name: 'Fresh',
        customAttributeType: 'conversation_attribute',
      },
    ];
    automationHelper.generateCustomAttributeTypes.mockReturnValue([]);
    automationHelper.generateCustomAttributes.mockReturnValue(manifested);

    manifestCustomAttributes();

    expect(automationHelper.generateCustomAttributeTypes).toHaveBeenCalledTimes(
      2
    );
    expect(automationHelper.generateCustomAttributes).toHaveBeenCalledTimes(1);

    Object.keys(automationTypes).forEach(key => {
      // The attributes replace whatever custom-attribute conditions were there and leave the
      // standard ones alone; a trigger outside the list keeps everything it had.
      const expected = CUSTOM_ATTRIBUTE_EVENTS.includes(key)
        ? [standard, ...manifested]
        : [standard, stale];

      expect(automationTypes[key].conditions, key).toEqual(expected);
    });

    // Named, and deliberately not read off `CUSTOM_ATTRIBUTE_EVENTS`: the loop above proves the pass
    // follows the list, and would keep agreeing with it if the edit trigger were dropped from it.
    // That an edit offers the same custom attributes as a creation is the decision #648 made, so it
    // is asserted here on its own terms. #667
    expect(automationTypes.message_created.conditions).toEqual([
      standard,
      ...manifested,
    ]);
    expect(automationTypes.message_edited.conditions).toEqual([
      standard,
      ...manifested,
    ]);
  });

  // The edit trigger is defined as the creation trigger's conditions and actions, and that is a
  // product decision rather than an accident of how the constant is built. It used to be literally
  // the same object, and that identity was the only thing carrying the account's custom attributes
  // across, so a test that replaced `automationTypes.message_created` detached the two and took the
  // suite red with it. #667
  it('offers the edit trigger the same conditions as the creation trigger, without sharing an object', () => {
    const { automationTypes } = useAutomation();

    expect(automationTypes.message_edited).toEqual(
      automationTypes.message_created
    );
    expect(automationTypes.message_edited).not.toBe(
      automationTypes.message_created
    );
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
      messageTypeOptions
    );
    expect(getConditionDropdownValues('private_note')).toEqual(
      booleanFilterOptions
    );
    expect(getConditionDropdownValues('priority')).toEqual(priorityOptions);
  });

  it('gets action dropdown values correctly', () => {
    const { getActionDropdownValues } = useAutomation();

    expect(getActionDropdownValues('add_label')).toEqual(labels);
    expect(getActionDropdownValues('assign_team')).toEqual(teams);
    expect(getActionDropdownValues('assign_agent')).toEqual([
      { id: 'nil', name: 'AUTOMATION.NONE_OPTION' },
      { id: 'last_responding_agent', name: 'AUTOMATION.LAST_RESPONDING_AGENT' },
      ...agents,
    ]);
    expect(getActionDropdownValues('send_email_to_team')).toEqual(teams);
    expect(getActionDropdownValues('send_message')).toEqual([]);
    expect(getActionDropdownValues('add_sla')).toEqual(slaPolicies);
    expect(getActionDropdownValues('change_priority')).toEqual(priorityOptions);
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
