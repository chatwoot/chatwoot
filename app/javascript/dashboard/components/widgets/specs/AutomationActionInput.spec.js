import { mount } from '@vue/test-utils';
import AutomationActionInput from '../AutomationActionInput.vue';

const EditorStub = {
  name: 'EditorStub',
  props: ['enableAutomationVariables'],
  template: '<div />',
};

const mountInput = (props = {}) =>
  mount(AutomationActionInput, {
    props: {
      modelValue: { action_name: 'add_private_note', action_params: ['Oi'] },
      actionTypes: [
        {
          key: 'add_private_note',
          label: 'Add a private note',
          inputType: 'textarea',
        },
      ],
      ...props,
    },
    global: {
      stubs: {
        WootMessageEditor: EditorStub,
        SingleSelect: true,
        MultiSelect: true,
      },
    },
  });

const offersAutomationVariables = wrapper =>
  wrapper.findComponent(EditorStub).props('enableAutomationVariables');

describe('AutomationActionInput', () => {
  // Only a rule run takes the snapshot `conversation.before` reads; in a macro it renders empty.
  it('offers the rule-only variables in an automation rule', () => {
    expect(offersAutomationVariables(mountInput())).toBe(true);
  });

  it('does not offer them in a macro', () => {
    expect(offersAutomationVariables(mountInput({ isMacro: true }))).toBe(
      false
    );
  });
});
