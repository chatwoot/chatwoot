import { shallowMount } from '@vue/test-utils';

const mockGlobalConfig = { value: { installationName: 'Chatwoot fazer.ai' } };

vi.mock('dashboard/composables/store.js', () => ({
  useMapGetter: () => mockGlobalConfig,
}));

// Read at module scope by the component, so it has to exist before the import below.
window.globalConfig = {
  BRAND_NAME: 'Chatwoot fazer.ai',
  LOGO_THUMBNAIL: '/brand-assets/logo_thumbnail.svg',
  WIDGET_BRAND_URL: 'https://www.chatwoot.com',
};

const Branding = (await import('../Branding.vue')).default;

// poweredBy stands in for the locale's own POWERED_BY. The default carries the Latin
// "Chatwoot" that replaceInstallationName depends on; a test can pass a transliterated one to
// stand for Persian or Tamil.
const mountBranding = (props = {}, poweredBy = 'Powered by Chatwoot') =>
  shallowMount(Branding, {
    props,
    global: {
      mocks: {
        $t: (key, params) => {
          if (key === 'POWERED_BY') return poweredBy;
          if (key === 'POWERED_BY_BRAND')
            return `Powered by ${params.brandName}`;
          return key;
        },
        $store: { getters: { 'appConfig/getReferrerHost': '' } },
      },
    },
  });

describe('Branding', () => {
  it('names the installation when no brand name is given', () => {
    const wrapper = mountBranding();

    expect(wrapper.text()).toContain('Powered by Chatwoot fazer.ai');
  });

  it('names the account when a brand name is given', () => {
    const wrapper = mountBranding({ brandName: 'Bistrô Exemplo' });

    expect(wrapper.text()).toContain('Powered by Bistrô Exemplo');
    expect(wrapper.find('img').attributes('alt')).toBe('Bistrô Exemplo');
  });

  // The only case the fork key is for: Persian and Tamil spell the vendor transliterated, so
  // there is no Latin "Chatwoot" to substitute.
  // Regression: an earlier fix sent every survey through the fork key, which exists in three
  // languages and falls back to English. A French survey then read "Powered by Chatwoot"
  // where it used to read "Propulsé par Chatwoot".
  it('keeps the sentence in the locale of the survey when substituting the brand', () => {
    const wrapper = mountBranding(
      { brandName: 'Bistrô Exemplo' },
      'Propulsé par Chatwoot'
    );

    expect(wrapper.text()).toContain('Propulsé par Bistrô Exemplo');
  });

  // brand_name only rejects `<>`, so `$` reaches here. As a replacement string those are
  // syntax: "ACME $$" would render "ACME $", and "$&" would put the vendor's name back.
  it('inserts a brand containing replacement syntax literally', () => {
    expect(mountBranding({ brandName: 'ACME $$' }).text()).toContain(
      'Powered by ACME $$'
    );
    expect(mountBranding({ brandName: '$&' }).text()).toContain(
      'Powered by $&'
    );
  });

  it('falls back to the interpolated key where there is no Latin name to substitute', () => {
    const wrapper = mountBranding(
      { brandName: 'Bistrô Exemplo' },
      'قدرت گرفته از چت ووت'
    );

    expect(wrapper.text()).toContain('Powered by Bistrô Exemplo');
    expect(wrapper.text()).not.toContain('چت ووت');
  });

  it('renders nothing when branding is disabled', () => {
    const wrapper = mountBranding({
      brandName: 'Bistrô Exemplo',
      disableBranding: true,
    });

    expect(wrapper.find('a').exists()).toBe(false);
  });
});
