import methodsMixin from '../../../dashboard/mixins/automations/methodsMixin';
import validationsMixin from '../../../dashboard/mixins/automations/validationsMixin';
import {
  automation,
  customAttributes,
  agents,
  booleanFilterOptions,
  teams,
  labels,
  statusFilterOptions,
  campaigns,
  contacts,
  inboxes,
  languages,
  countries,
  slaPolicies,
  MESSAGE_CONDITION_VALUES,
  automationToSubmit,
  savedAutomation,
} from './automationFixtures';
import {
  AUTOMATIONS,
  AUTOMATION_ACTION_TYPES,
} from '../../../dashboard/routes/dashboard/settings/automation/constants.js';

import { createWrapper, createLocalVue } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
const localVue = createLocalVue();
localVue.use(Vuex);

// Vuelidate required to test submit method
import Vuelidate from 'vuelidate';
Vue.use(Vuelidate);

const createComponent = (
  mixins,
  data,
  // eslint-disable-next-line default-param-last
  computed = {},
  // eslint-disable-next-line default-param-last
  methods = {},
  validations
) => {
  const Component = {
    render() {},
    mixins,
    data,
    computed,
    methods,
    validations,
  };
  const Constructor = Vue.extend(Component);
  const vm = new Constructor().$mount();
  return createWrapper(vm);
};

const generateComputedProperties = () => {
  return {
    statusFilterOptions() {
      return statusFilterOptions;
    },
    agents() {
      return agents;
    },
    customAttributes() {
      return customAttributes;
    },
    labels() {
      return labels;
    },
    teams() {
      return teams;
    },
    booleanFilterOptions() {
      return booleanFilterOptions;
    },
    campaigns() {
      return campaigns;
    },
    contacts() {
      return contacts;
    },
    inboxes() {
      return inboxes;
    },
    languages() {
      return languages;
    },
    countries() {
      return countries;
    },
    slaPolicies() {
      return slaPolicies;
    },
    MESSAGE_CONDITION_VALUES() {
      return MESSAGE_CONDITION_VALUES;
    },
  };
};

describe('automationMethodsMixin', () => {
  it('getFileName returns the correct file name', () => {
    const data = () => {
      return {};
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(
      wrapper.vm.getFileName(automation.actions[0], automation.files)
    ).toEqual(automation.files[0].filename);
  });

  it('getAttributes returns all attributes', () => {
    const data = () => {
      return {
        automationTypes: AUTOMATIONS,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(wrapper.vm.getAttributes('conversation_created')).toEqual(
      AUTOMATIONS.conversation_created.conditions
    );
  });

  it('getAttributes returns all respective attributes', () => {
    const data = () => {
      return {
        allCustomAttributes: customAttributes,
        automationTypes: AUTOMATIONS,
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(wrapper.vm.getInputType('status')).toEqual('multi_select');
    expect(wrapper.vm.getInputType('my_list')).toEqual('search_select');
  });

  it('getOperators returns all respective operators', () => {
    const data = () => {
      return {
        allCustomAttributes: customAttributes,
        automationTypes: AUTOMATIONS,
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(wrapper.vm.getOperators('status')).toEqual(
      AUTOMATIONS.conversation_created.conditions[0].filterOperators
    );
  });

  it('getAutomationType returns the correct automationType', () => {
    const data = () => {
      return {
        automationTypes: AUTOMATIONS,
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(wrapper.vm.getAutomationType('status')).toEqual(
      AUTOMATIONS[automation.event_name].conditions[0]
    );
  });

  it('getConditionDropdownValues returns respective condition dropdown values', () => {
    const computed = generateComputedProperties();
    const data = () => {
      return {
        allCustomAttributes: customAttributes,
      };
    };
    const wrapper = createComponent([methodsMixin], data, computed);
    expect(wrapper.vm.getConditionDropdownValues('status')).toEqual(
      statusFilterOptions
    );
    expect(wrapper.vm.getConditionDropdownValues('team_id')).toEqual(teams);
    expect(wrapper.vm.getConditionDropdownValues('assignee_id')).toEqual(
      agents
    );
    expect(wrapper.vm.getConditionDropdownValues('contact')).toEqual(contacts);
    expect(wrapper.vm.getConditionDropdownValues('inbox_id')).toEqual(inboxes);
    expect(wrapper.vm.getConditionDropdownValues('campaigns')).toEqual(
      campaigns
    );
    expect(wrapper.vm.getConditionDropdownValues('browser_language')).toEqual(
      languages
    );
    expect(wrapper.vm.getConditionDropdownValues('country_code')).toEqual(
      countries
    );
    expect(wrapper.vm.getConditionDropdownValues('message_type')).toEqual(
      MESSAGE_CONDITION_VALUES
    );
  });

  it('appendNewCondition appends a new condition to the automation data property', () => {
    const condition = {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
      custom_attribute_type: '',
    };
    const data = () => {
      return {
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    wrapper.vm.appendNewCondition();
    expect(automation.conditions[automation.conditions.length - 1]).toEqual(
      condition
    );
  });

  it('appendNewAction appends a new condition to the automation data property', () => {
    const action = {
      action_name: 'assign_agent',
      action_params: [],
    };
    const data = () => {
      return {
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    wrapper.vm.appendNewAction();
    expect(automation.actions[automation.actions.length - 1]).toEqual(action);
  });

  it('removeFilter removes the given condition in the automation', () => {
    const data = () => {
      return {
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    wrapper.vm.removeFilter(0);
    expect(automation.conditions.length).toEqual(1);
  });

  it('removeAction removes the given action in the automation', () => {
    const data = () => {
      return {
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    wrapper.vm.removeAction(0);
    expect(automation.actions.length).toEqual(1);
  });

  it('resetFilter resets the current automation conditions', () => {
    const data = () => {
      return {
        automation: automationToSubmit,
        automationTypes: AUTOMATIONS,
      };
    };
    const conditionAfterReset = {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
      custom_attribute_type: '',
    };
    const wrapper = createComponent([methodsMixin], data);
    wrapper.vm.resetFilter(0, automationToSubmit.conditions[0]);
    expect(automation.conditions[0]).toEqual(conditionAfterReset);
  });

  it('showUserInput returns boolean value based on the operator type', () => {
    const data = () => {
      return {};
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(wrapper.vm.showUserInput('is_present')).toBeFalsy();
    expect(wrapper.vm.showUserInput('is_not_present')).toBeFalsy();
    expect(wrapper.vm.showUserInput('equal_to')).toBeTruthy();
    expect(wrapper.vm.showUserInput('not_equal_to')).toBeTruthy();
  });

  it('showActionInput returns boolean value based on the action type', () => {
    const data = () => {
      return {
        automationActionTypes: AUTOMATION_ACTION_TYPES,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(wrapper.vm.showActionInput('send_email_to_team')).toBeFalsy();
    expect(wrapper.vm.showActionInput('send_message')).toBeFalsy();
    expect(wrapper.vm.showActionInput('send_webhook_event')).toBeTruthy();
    expect(wrapper.vm.showActionInput('resolve_conversation')).toBeFalsy();
    expect(wrapper.vm.showActionInput('add_label')).toBeTruthy();
  });

  it('resetAction resets the action to default state', () => {
    const data = () => {
      return {
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    wrapper.vm.resetAction(0);
    expect(automation.actions[0].action_params).toEqual([]);
  });

  it('manifestConditions resets the action to default state', () => {
    const data = () => {
      return {
        automation: {},
        allCustomAttributes: customAttributes,
        automationTypes: AUTOMATIONS,
      };
    };
    const methods = {
      getConditionDropdownValues() {
        return statusFilterOptions;
      },
    };

    const manifestedConditions = [
      {
        values: [
          {
            id: 'open',
            name: 'Open',
          },
        ],
        attribute_key: 'status',
        filter_operator: 'equal_to',
        query_operator: 'and',
      },
    ];
    const wrapper = createComponent([methodsMixin], data, {}, methods);
    expect(wrapper.vm.manifestConditions(savedAutomation)).toEqual(
      manifestedConditions
    );
  });

  it('generateActionsArray return the manifested actions array', () => {
    const data = () => {
      return {
        automationActionTypes: AUTOMATION_ACTION_TYPES,
      };
    };
    const computed = {
      agents() {
        return agents;
      },
      labels() {
        return labels;
      },
      teams() {
        return teams;
      },
    };

    const methods = {
      getActionDropdownValues() {
        return [
          {
            id: 2,
            name: 'testlabel',
          },
          {
            id: 1,
            name: 'snoozes',
          },
        ];
      },
    };
    const testAction = {
      action_name: 'add_label',
      action_params: [2],
    };

    const expectedActionArray = [
      {
        id: 2,
        name: 'testlabel',
      },
    ];

    const wrapper = createComponent([methodsMixin], data, computed, methods);
    expect(wrapper.vm.generateActionsArray(testAction)).toEqual(
      expectedActionArray
    );
  });

  it('manifestActions manifest the received action and generate the correct array', () => {
    const data = () => {
      return {
        automation: {},
        allCustomAttributes: customAttributes,
        automationTypes: AUTOMATIONS,
      };
    };
    const methods = {
      generateActionsArray() {
        return [
          {
            id: 2,
            name: 'testlabel',
          },
        ];
      },
    };
    const expectedActions = [
      {
        action_name: 'add_label',
        action_params: [
          {
            id: 2,
            name: 'testlabel',
          },
        ],
      },
    ];
    const wrapper = createComponent([methodsMixin], data, {}, methods);
    expect(wrapper.vm.manifestActions(savedAutomation)).toEqual(
      expectedActions
    );
  });

  it('getActionDropdownValues returns Action dropdown Values', () => {
    const data = () => {
      return {};
    };
    const computed = {
      agents() {
        return agents;
      },
      labels() {
        return labels;
      },
      teams() {
        return teams;
      },
      slaPolicies() {
        return slaPolicies;
      },
    };
    const expectedActionDropdownValues = [
      { id: 'testlabel', name: 'testlabel' },
      { id: 'snoozes', name: 'snoozes' },
    ];
    const wrapper = createComponent([methodsMixin], data, computed);
    expect(wrapper.vm.getActionDropdownValues('add_label')).toEqual(
      expectedActionDropdownValues
    );
  });
});

describe('automationValidationsMixin', () => {
  it('automationValidationsMixin is present', () => {
    const data = () => {
      return {};
    };
    const wrapper = createComponent([validationsMixin], data, {}, {});
    expect(typeof wrapper.vm.$options.validations).toBe('object');
  });
});
