import { mount } from '@vue/test-utils';
import CustomToolCard from './CustomToolCard.vue';

const mocks = vi.hoisted(() => ({ isAdmin: { value: true } }));

vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: mocks.isAdmin }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key, locale: { value: 'en' } }),
}));

const mountCard = (props = {}) =>
  mount(CustomToolCard, {
    props: {
      id: 1,
      title: 'Get Order',
      createdAt: 1_700_000_000,
      updatedAt: 1_700_000_000,
      ...props,
    },
    global: {
      stubs: {
        CardLayout: { template: '<div><slot /></div>' },
        Policy: { template: '<div><slot /></div>' },
        Switch: true,
      },
      directives: { 'on-clickaway': {} },
    },
  });

const menuActions = wrapper => wrapper.vm.menuItems.map(item => item.action);

const installedSource = {
  repository: 'chatwoot/support-tools',
  path: 'shopify',
};

const clickTitle = async wrapper => {
  await wrapper.get('[data-test="tool-title"]').trigger('click');
  return wrapper.emitted('action').at(-1)[0].action;
};

describe('CustomToolCard', () => {
  beforeEach(() => {
    mocks.isAdmin.value = true;
  });

  it('opens a tool the admin created for editing from its title', async () => {
    expect(await clickTitle(mountCard())).toBe('edit');
  });

  it('opens installed tools and any tool for agents read-only from the title', async () => {
    expect(
      await clickTitle(mountCard({ sourceMetadata: installedSource }))
    ).toBe('view');

    mocks.isAdmin.value = false;
    expect(await clickTitle(mountCard())).toBe('view');
  });

  it('lets admins edit and delete tools they created', () => {
    expect(menuActions(mountCard())).toEqual(['edit', 'delete']);
  });

  it('keeps tools installed from a manifest read-only', () => {
    const wrapper = mountCard({
      sourceMetadata: { repository: 'chatwoot/support-tools', path: 'shopify' },
    });

    expect(menuActions(wrapper)).toEqual(['view', 'delete']);
  });
});
