import { mount } from '@vue/test-utils';
import { describe, it, expect, vi } from 'vitest';
import Avatar from 'dashboard/components/base-next/avatar/Avatar.vue';

describe('Avatar.vue', () => {
  const defaultProps = {
    name: 'John Doe',
  };

  it('renders initials when no valid src is provided', () => {
    const wrapper = mount(Avatar, {
      props: { ...defaultProps, src: '' },
    });

    expect(wrapper.text()).toBe('JD'); // Should show initials
    expect(wrapper.find('img').exists()).toBe(false); // No image should be rendered
  });

  it('renders an image when src is provided', () => {
    const wrapper = mount(Avatar, {
      props: { ...defaultProps, src: 'https://via.placeholder.com/150' },
    });

    const img = wrapper.find('img');
    expect(img.exists()).toBe(true);
    expect(img.attributes('src')).toBe('https://via.placeholder.com/150');
    expect(img.attributes('alt')).toBe('John Doe');
  });

  it('shows initials if image fails to load', async () => {
    const wrapper = mount(Avatar, {
      props: { ...defaultProps, src: 'invalid-src' },
    });

    const img = wrapper.find('img');
    await img.trigger('error');

    expect(wrapper.text()).toBe('JD'); // Initials should be displayed on error
    expect(wrapper.find('img').exists()).toBe(false); // Image should not render
  });

  it('re-renders the image if src changes', async () => {
    const wrapper = mount(Avatar, {
      props: { ...defaultProps, src: 'https://via.placeholder.com/150' },
    });

    expect(wrapper.find('img').exists()).toBe(true);

    await wrapper.setProps({ src: 'https://via.placeholder.com/200' });
    expect(wrapper.find('img').attributes('src')).toBe(
      'https://via.placeholder.com/200'
    );
  });

  it('applies custom numeric size', () => {
    const wrapper = mount(Avatar, {
      props: { ...defaultProps, size: 40 },
    });

    const span = wrapper.find('span');
    expect(span.attributes('style')).toContain('width: 40px;');
    expect(span.attributes('style')).toContain('height: 40px;');
  });

  it('handles single name input correctly', () => {
    const wrapper = mount(Avatar, {
      props: { name: 'Alice' },
    });

    expect(wrapper.text()).toBe('A');
  });

  it('reacts to name changes', async () => {
    const wrapper = mount(Avatar, {
      props: { name: 'John Doe' },
    });

    expect(wrapper.text()).toBe('JD');

    await wrapper.setProps({ name: 'Jane Smith' });
    expect(wrapper.text()).toBe('JS');
  });
});
