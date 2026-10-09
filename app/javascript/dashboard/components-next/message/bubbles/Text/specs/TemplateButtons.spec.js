import { mount } from '@vue/test-utils';
import TemplateButtons from '../TemplateButtons.vue';

const mountTemplateButtons = props =>
  mount(TemplateButtons, {
    props: { buttons: [], ...props },
    global: {
      stubs: { Icon: true },
    },
  });

describe('TemplateButtons', () => {
  it('renders nothing when there are no buttons', () => {
    const wrapper = mountTemplateButtons({ buttons: [] });
    expect(wrapper.find('div').exists()).toBe(false);
  });

  it('renders a chip per button with its text', () => {
    const wrapper = mountTemplateButtons({
      buttons: [
        { type: 'FLOW', text: 'Book demo' },
        { type: 'URL', text: 'Visit site', url: 'https://example.com' },
        { type: 'QUICK_REPLY', text: 'Yes' },
      ],
    });
    const chips = wrapper.findAll('span.truncate');
    expect(chips).toHaveLength(3);
    expect(chips[0].text()).toBe('Book demo');
    expect(chips[1].text()).toBe('Visit site');
    expect(chips[2].text()).toBe('Yes');
  });

  it('uses the URL as the chip title for URL buttons', () => {
    const wrapper = mountTemplateButtons({
      buttons: [{ type: 'URL', text: 'Visit', url: 'https://example.com' }],
    });
    expect(wrapper.find('[title="https://example.com"]').exists()).toBe(true);
  });

  it('falls back to the button text as title for non-URL buttons', () => {
    const wrapper = mountTemplateButtons({
      buttons: [{ type: 'FLOW', text: 'Book demo' }],
    });
    expect(wrapper.find('[title="Book demo"]').exists()).toBe(true);
  });
});
