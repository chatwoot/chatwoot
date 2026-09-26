import { mount } from '@vue/test-utils';
import CustomToolCard from './CustomToolCard.vue';

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

describe('CustomToolCard', () => {
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
