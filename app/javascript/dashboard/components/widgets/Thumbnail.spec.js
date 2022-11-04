import { mount } from '@vue/test-utils';
import Avatar from './Avatar.vue';
import Thumbnail from './Thumbnail.vue';

describe('Thumbnail.vue', () => {
  it('should render the agent thumbnail if valid image is passed', () => {
    const wrapper = mount(Thumbnail, {
      propsData: {
        src: 'https://some_valid_url.com',
      },
      data() {
        return {
          imgError: false,
        };
      },
    });
    expect(wrapper.find('.user-thumbnail').exists()).toBe(true);
    const avatarComponent = wrapper.findComponent(Avatar);
    expect(avatarComponent.exists()).toBe(false);
  });

  it('should render the avatar component if invalid image is passed', () => {
    const wrapper = mount(Thumbnail, {
      propsData: {
        src: 'https://some_invalid_url.com',
      },
      data() {
        return {
          imgError: true,
        };
      },
    });
    expect(wrapper.find('.avatar-container').exists()).toBe(true);
    const avatarComponent = wrapper.findComponent(Avatar);
    expect(avatarComponent.exists()).toBe(true);
  });

  it('should the initial of the name if no image is passed', () => {
    const wrapper = mount(Avatar, {
      propsData: {
        username: 'Angie Rojas',
      },
    });
    expect(wrapper.find('div').text()).toBe('AR');
  });
});
