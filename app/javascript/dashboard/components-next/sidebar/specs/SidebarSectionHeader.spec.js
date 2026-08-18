import { mount } from '@vue/test-utils';
import SidebarSectionHeader from '../SidebarSectionHeader.vue';

const mountHeader = props =>
  mount(SidebarSectionHeader, { props: { label: 'Work', ...props } });

describe('SidebarSectionHeader', () => {
  it('renders the label when the sidebar is expanded', () => {
    const wrapper = mountHeader();

    expect(wrapper.text()).toBe('Work');
    expect(wrapper.find('[role="separator"]').exists()).toBe(false);
  });

  it('drops the wording for a plain rule when collapsed to the icon rail', () => {
    const wrapper = mountHeader({ collapsed: true });

    expect(wrapper.text()).toBe('');
    expect(wrapper.find('[role="separator"]').exists()).toBe(true);
  });
});
