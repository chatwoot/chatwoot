import { mount } from '@vue/test-utils';
import { describe, it, expect } from 'vitest';
import WhatsAppUnofficialBanner from '@/shared/components/WhatsAppUnofficialBanner.vue';

describe('WhatsAppUnofficialBanner', () => {
  const createWrapper = (props = {}) => {
    return mount(WhatsAppUnofficialBanner, {
      props: {
        channel: null,
        faqUrl: 'https://weavecode.co.uk/faq/whatsapp-official-api',
        ...props,
      },
    });
  };

  describe('banner visibility', () => {
    it('should not show banner when no channel provided', () => {
      const wrapper = createWrapper();
      expect(wrapper.find('.bg-red-600').exists()).toBe(false);
    });

    it('should not show banner for official WhatsApp Cloud channels', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
          phone_number: '+447700900123'
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(false);
    });

    it('should show banner for unofficial/default WhatsApp channels', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          channel_type: 'Channel::Whatsapp', 
          provider: 'default',
          phone_number: '+447700900123'
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(true);
    });

    it('should show banner for any non-whatsapp_cloud provider', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          channel_type: 'Channel::Whatsapp',
          provider: '360dialog',
          phone_number: '+447700900123'
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(true);
    });

    it('should not show banner for non-WhatsApp channels', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          channel_type: 'Channel::WebWidget',
          provider: 'widget'
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(false);
    });
  });

  describe('banner content', () => {
    const unofficialChannel = {
      id: 1,
      channel_type: 'Channel::Whatsapp',
      provider: 'default',
      phone_number: '+447700900123'
    };

    it('displays correct warning title', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      expect(wrapper.text()).toContain('PERMANENT RISK: Unofficial WhatsApp Connection');
    });

    it('displays risk warning message', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      expect(wrapper.text()).toContain('permanent risk of service disruption');
      expect(wrapper.text()).toContain('WhatsApp business number could be suspended without notice');
    });

    it('displays migration recommendation', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      expect(wrapper.text()).toContain('migrating to the official WhatsApp Business Cloud API');
    });

    it('shows non-dismissible warning text', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      expect(wrapper.text()).toContain('This warning cannot be dismissed until official API is connected');
    });
  });

  describe('banner interaction', () => {
    const unofficialChannel = {
      id: 1,
      channel_type: 'Channel::Whatsapp',
      provider: 'default', 
      phone_number: '+447700900123'
    };

    it('renders FAQ link with correct URL', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      const link = wrapper.find('a[href="https://weavecode.co.uk/faq/whatsapp-official-api"]');
      expect(link.exists()).toBe(true);
      expect(link.text()).toContain('Migration Guide & FAQ');
    });

    it('opens FAQ link in new tab', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      const link = wrapper.find('a[href="https://weavecode.co.uk/faq/whatsapp-official-api"]');
      expect(link.attributes('target')).toBe('_blank');
      expect(link.attributes('rel')).toBe('noopener noreferrer');
    });

    it('accepts custom FAQ URL', () => {
      const customUrl = 'https://example.com/custom-faq';
      const wrapper = createWrapper({
        channel: unofficialChannel,
        faqUrl: customUrl
      });
      const link = wrapper.find(`a[href="${customUrl}"]`);
      expect(link.exists()).toBe(true);
    });

    it('has no close or dismiss button', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      expect(wrapper.find('button').exists()).toBe(false);
      expect(wrapper.find('.close').exists()).toBe(false);
      expect(wrapper.find('[data-dismiss]').exists()).toBe(false);
    });
  });

  describe('banner styling', () => {
    const unofficialChannel = {
      id: 1,
      channel_type: 'Channel::Whatsapp',
      provider: 'default',
      phone_number: '+447700900123'
    };

    it('has sticky positioning and high z-index', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      const banner = wrapper.find('.bg-red-600');
      expect(banner.classes()).toContain('sticky');
      expect(banner.classes()).toContain('top-0');
      expect(banner.classes()).toContain('z-50');
    });

    it('has red warning colour scheme', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      const banner = wrapper.find('div');
      expect(banner.classes()).toContain('bg-red-600');
      expect(banner.classes()).toContain('border-red-800');
    });

    it('has pulsing warning icon', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      const icon = wrapper.find('.ri-alert-fill');
      expect(icon.exists()).toBe(true);
      expect(icon.classes()).toContain('animate-pulse');
    });

    it('has prominent shadow styling', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      const banner = wrapper.find('.bg-red-600');
      expect(banner.classes()).toContain('shadow-lg');
    });
  });

  describe('accessibility', () => {
    const unofficialChannel = {
      id: 1,
      channel_type: 'Channel::Whatsapp',
      provider: 'default',
      phone_number: '+447700900123'
    };

    it('uses semantic HTML structure', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      expect(wrapper.find('h3').exists()).toBe(true);
      expect(wrapper.find('p').exists()).toBe(true);
    });

    it('has descriptive link text', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      const link = wrapper.find('a');
      expect(link.text()).not_to.match(/^(click here|read more|link)$/i);
      expect(link.text()).toContain('Migration Guide & FAQ');
    });

    it('uses appropriate contrast colours', () => {
      const wrapper = createWrapper({ channel: unofficialChannel });
      // Red background with white text should provide good contrast
      expect(wrapper.find('.text-white').exists()).toBe(true);
      expect(wrapper.find('.bg-red-600').exists()).toBe(true);
    });
  });

  describe('edge cases', () => {
    it('handles null channel gracefully', () => {
      expect(() => createWrapper({ channel: null })).not.toThrow();
    });

    it('handles undefined channel gracefully', () => {
      expect(() => createWrapper({ channel: undefined })).not.toThrow();
    });

    it('handles channel without provider property', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          channel_type: 'Channel::Whatsapp'
          // provider missing
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(true); // Should show warning for missing provider
    });

    it('handles channel without channel_type property', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          provider: 'default'
          // channel_type missing
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(false);
    });

    it('is case sensitive for provider matching', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          channel_type: 'Channel::Whatsapp',
          provider: 'WHATSAPP_CLOUD' // Wrong case
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(true); // Should show warning
    });

    it('is case sensitive for channel_type matching', () => {
      const wrapper = createWrapper({
        channel: {
          id: 1,
          channel_type: 'channel::whatsapp', // Wrong case
          provider: 'default'
        }
      });
      expect(wrapper.find('.bg-red-600').exists()).toBe(false); // Should not show banner
    });
  });
});