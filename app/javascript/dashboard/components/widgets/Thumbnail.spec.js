import { mount } from '@vue/test-utils';
import Avatar from './Avatar.vue';
import Thumbnail from './Thumbnail.vue';

describe(`when there are NO errors loading the thumbnail`, () => {
  it(`should render the agent thumbnail`, () => {
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
    expect(wrapper.find('#image').exists()).toBe(true);
    expect(wrapper.contains(Avatar)).toBe(false);
  });
});

describe(`when there ARE errors loading the thumbnail`, () => {
  it(`should render the agent avatar`, () => {
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
    expect(wrapper.contains('#image')).toBe(false);
    expect(wrapper.contains(Avatar)).toBe(true);
  });
});

describe(`when Avatar shows`, () => {
  it(`initials shold correspond to username`, () => {
    const wrapper = mount(Avatar, {
      propsData: {
        username: 'Angie Rojas',
      },
    });
    expect(wrapper.find('span').text()).toBe('AR');
  });
});
