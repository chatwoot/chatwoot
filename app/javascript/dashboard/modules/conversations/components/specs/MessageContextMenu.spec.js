import { mount } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import MessageContextMenu from '../MessageContextMenu.vue';

withFullI18n();

const mountMenu = enabledOptions =>
  mount(MessageContextMenu, {
    props: {
      message: { id: 1, content: 'Hello', conversation_id: 2 },
      isOpen: true,
      enabledOptions,
      contextMenuPosition: { x: 10, y: 20 },
      hideButton: true,
    },
    global: {
      mocks: {
        $store: {
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
});
