import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import WhatsappLegacyProviderBanner from '../WhatsappLegacyProviderBanner.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const mountBanner = props => mount(WhatsappLegacyProviderBanner, { props });

describe('WhatsappLegacyProviderBanner', () => {
  it('recommends the native provider when the account can pick it', () => {
    const wrapper = mountBanner({ nativeAvailable: true });

    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.NOTICE_WITH_NATIVE'
    );
  });

  it('says only that the provider is legacy when the native one is not on offer', () => {
    const wrapper = mountBanner({ nativeAvailable: false, canConvert: true });

    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.NOTICE'
    );
    expect(wrapper.text()).not.toContain('NOTICE_WITH_NATIVE');
    expect(wrapper.find('button').exists()).toBe(false);
  });

  it('offers to set up the native provider on the setup screen', () => {
    const wrapper = mountBanner({ nativeAvailable: true });
    const button = wrapper.find('button');

    expect(button.text()).toBe(
      'INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.USE_NATIVE'
    );
    button.trigger('click');
    expect(wrapper.emitted('useNative')).toHaveLength(1);
    expect(wrapper.emitted('convert')).toBeUndefined();
  });

  it('offers the conversion where there is an inbox to convert', () => {
    const wrapper = mountBanner({ nativeAvailable: true, canConvert: true });
    const button = wrapper.find('button');
    expect(button.text()).toBe(
      'INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.CONVERT_TO_NATIVE'
    );

    button.trigger('click');
    expect(wrapper.emitted('convert')).toHaveLength(1);
    expect(wrapper.emitted('useNative')).toBeUndefined();
  });
});
