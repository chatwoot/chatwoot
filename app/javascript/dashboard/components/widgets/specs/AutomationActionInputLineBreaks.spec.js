import { mount } from '@vue/test-utils';
import AutomationActionInput from '../AutomationActionInput.vue';

const EditorStub = {
  name: 'EditorStub',
  props: { overrideLineBreaks: Boolean },
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

const breaksLines = wrapper =>
  wrapper.findComponent(EditorStub).props('overrideLineBreaks');

// The editor turns Enter into "send" for agents who chose Enter to send; an action's text has
// nothing to send, so Enter has to break the line there.
describe('AutomationActionInput line breaks', () => {
  it('lets Enter break a line in an automation rule action', () => {
    expect(breaksLines(mountInput())).toBe(true);
  });

  it('lets Enter break a line in a macro action', () => {
    expect(breaksLines(mountInput({ isMacro: true }))).toBe(true);
  });
});
