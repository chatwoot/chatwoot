import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import Avatar from '../Avatar.vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en: {
      THUMBNAIL: {
        AUTHOR: {
          NOT_AVAILABLE: 'Author not available',
        },
      },
    },
  },
});

describe('Avatar', () => {
  const createWrapper = (props = {}) => {
    return mount(Avatar, {
      props: {
        name: 'John Doe',
        ...props,
      },
      global: {
        plugins: [i18n],
        stubs: {
          Icon: true,
          ChannelIcon: true,
        },
      },
    });
  };

  describe('initials generation', () => {
    it('generates initials from two-word name', () => {
      const wrapper = createWrapper({ name: 'John Doe' });
      expect(wrapper.text()).toContain('JD');
    });

    it('generates single initial from single-word name', () => {
      const wrapper = createWrapper({ name: 'John' });
      expect(wrapper.text()).toContain('J');
    });

    it('generates initials from three-word name using first two words', () => {
      const wrapper = createWrapper({ name: 'John Doe Smith' });
      expect(wrapper.text()).toContain('JD');
    });

    describe('phone number handling', () => {
      it('uses last 2 digits for phone numbers with spaces', () => {
        // Issue #2641: "+44 7123456789" was incorrectly showing "+7"
        const wrapper = createWrapper({ name: '+44 7123456789' });
        expect(wrapper.text()).toContain('89');
      });

      it('uses last 2 digits for phone numbers without spaces', () => {
        const wrapper = createWrapper({ name: '+14155551234' });
        expect(wrapper.text()).toContain('34');
      });

      it('uses last 2 digits for phone numbers with dashes', () => {
        const wrapper = createWrapper({ name: '+1-415-555-1234' });
        expect(wrapper.text()).toContain('34');
      });

      it('uses last 2 digits for phone numbers with mixed formatting', () => {
        const wrapper = createWrapper({ name: '+44 (0) 7700-900123' });
        expect(wrapper.text()).toContain('23');
      });

      it('does not treat names starting with + but containing letters as phone numbers', () => {
        const wrapper = createWrapper({ name: '+John Doe' });
        // Should use normal initials, not phone number logic
        expect(wrapper.text()).toContain('+J');
      });
    });
  });
});
