import { mount } from '@vue/test-utils';
import EmailTranscriptModal from './EmailTranscriptModal.vue';

const mountModal = currentChat =>
  mount(EmailTranscriptModal, {
    props: {
      show: true,
      currentChat,
    },
    global: {
      mocks: {
        $t: key => key,
        $store: { dispatch: () => Promise.resolve() },
      },
      stubs: {
        'woot-modal': { template: '<div><slot /></div>' },
        'woot-modal-header': true,
        NextButton: true,
      },
    },
  });

describe('EmailTranscriptModal', () => {
  it('does not offer the assigned-agent option when the assignee has no email', () => {
    const wrapper = mountModal({
      id: 1,
      meta: { assignee: { id: 5 } },
    });

    expect(wrapper.find('#assignee').exists()).toBe(false);
  });

  it('offers the assigned-agent option when the assignee has an email', () => {
    const wrapper = mountModal({
      id: 1,
      meta: { assignee: { id: 5, email: 'agent@example.com' } },
    });

    expect(wrapper.find('#assignee').exists()).toBe(true);
  });
});
