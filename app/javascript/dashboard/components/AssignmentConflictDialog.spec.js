import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { createI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import AssignmentConflictDialog from './AssignmentConflictDialog.vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en: {
      CONVERSATION: {
        ASSIGNMENT_CONFLICT: {
          TITLE: 'Conversation already assigned',
          DESCRIPTION: '{agentName} is already handling this conversation.',
          DESCRIPTION_UNKNOWN_AGENT: 'Another agent is handling it.',
          CONFIRM: 'Got it',
          OUTSIDE_WORKING_HOURS: {
            TITLE: 'Inbox outside business hours',
            DESCRIPTION: 'Only during business hours.',
          },
        },
      },
    },
  },
});

const DialogStub = {
  template: '<div><slot /><slot name="footer" /></div>',
  methods: { open: vi.fn(), close: vi.fn() },
};

const mountDialog = () =>
  mount(AssignmentConflictDialog, {
    global: {
      plugins: [i18n],
      stubs: { Dialog: DialogStub, NextButton: true },
    },
  });

describe('AssignmentConflictDialog', () => {
  it('explains a refusal caused by the inbox being closed', async () => {
    const wrapper = mountDialog();

    emitter.emit(BUS_EVENTS.ASSIGNMENT_CONFLICT, {
      agentName: '',
      reason: 'outside_working_hours',
    });
    await nextTick();

    expect(wrapper.text()).toContain('Inbox outside business hours');
    expect(wrapper.text()).toContain('Only during business hours.');
    expect(wrapper.text()).not.toContain('Conversation already assigned');
    wrapper.unmount();
  });

  // A takeover refusal after a closed-inbox one must not keep the old reason.
  it('names the owner on a takeover refusal', async () => {
    const wrapper = mountDialog();

    emitter.emit(BUS_EVENTS.ASSIGNMENT_CONFLICT, {
      reason: 'outside_working_hours',
    });
    emitter.emit(BUS_EVENTS.ASSIGNMENT_CONFLICT, { agentName: 'Ana' });
    await nextTick();

    expect(wrapper.text()).toContain('Conversation already assigned');
    expect(wrapper.text()).toContain('Ana is already handling');
    wrapper.unmount();
  });
});
