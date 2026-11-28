import { mount } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import MessageContextMenu from '../MessageContextMenu.vue';

withFullI18n();

const deleteModalStub = {
  props: ['onConfirm'],
  template:
    '<div><slot /><button class="confirm-delete" @click="onConfirm" /></div>',
};

const mountMenu = (enabledOptions, props = {}) =>
  mount(MessageContextMenu, {
    props: {
      message: { id: 1, content: 'Hello', conversation_id: 2 },
      isOpen: true,
      enabledOptions,
      contextMenuPosition: { x: 10, y: 20 },
      hideButton: true,
      ...props,
    },
    global: {
      mocks: {
        $store: {
          dispatch: vi.fn(() => Promise.resolve()),
          getters: {
            'accounts/getAccount': () => ({}),
            getCurrentAccountId: 1,
            getUISettings: {},
          },
        },
      },
      stubs: {
        ContextMenu: { template: '<div><slot /></div>' },
        AddCannedModal: true,
        ReportCaptainMessageDialog: true,
        NextButton: true,
        FluentIcon: true,
        'woot-delete-modal': deleteModalStub,
      },
    },
  });

const menuItem = (wrapper, label) =>
  wrapper.findAll('.menu').find(item => item.text() === label);

describe('MessageContextMenu', () => {
  it('offers forward email first and emits it on click', async () => {
    const wrapper = mountMenu({ forwardEmail: true, copy: true });
    const labels = wrapper.findAll('.menu').map(item => item.text());

    expect(labels.slice(0, 2)).toEqual(['Forward email', 'Copy']);

    await menuItem(wrapper, 'Forward email').trigger('click');

    expect(wrapper.emitted('forwardEmail')).toHaveLength(1);
    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('hides forward email when it is not enabled', () => {
    const wrapper = mountMenu({ copy: true });

    expect(menuItem(wrapper, 'Forward email')).toBeUndefined();
    expect(menuItem(wrapper, 'Copy')).toBeDefined();
  });

  it('deletes the message for the customer when the agent opts in', async () => {
    const wrapper = mountMenu({ delete: true }, { canDeleteForCustomer: true });

    await menuItem(wrapper, 'Delete').trigger('click');
    await wrapper.find('input[type="checkbox"]').setValue(true);
    await wrapper.find('.confirm-delete').trigger('click');

    expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('deleteMessage', {
      conversationId: 2,
      messageId: 1,
      deleteOnChannel: true,
    });
  });

  it('deletes the message only in Chatwoot by default', async () => {
    const wrapper = mountMenu({ delete: true }, { canDeleteForCustomer: true });

    await menuItem(wrapper, 'Delete').trigger('click');
    await wrapper.find('.confirm-delete').trigger('click');

    expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('deleteMessage', {
      conversationId: 2,
      messageId: 1,
      deleteOnChannel: false,
    });
  });

  it('does not offer deleting for the customer when the channel cannot', async () => {
    const wrapper = mountMenu({ delete: true });

    await menuItem(wrapper, 'Delete').trigger('click');

    expect(wrapper.find('.confirm-delete').exists()).toBe(true);
    expect(wrapper.find('input[type="checkbox"]').exists()).toBe(false);
  });
});
