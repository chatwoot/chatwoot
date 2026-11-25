import { defineComponent, h, ref } from 'vue';
import { createStore } from 'vuex';
import { mount } from '@vue/test-utils';
import { useRoute } from 'vue-router';
import { useAccountEnrichment } from '../../account-details/useAccountEnrichment';

vi.mock('vue-router');

const ENABLED_LANGUAGES = [
  { iso_639_1_code: 'en', name: 'English' },
  { iso_639_1_code: 'fr', name: 'French' },
];

// Mounts the composable against a real store and the real useAccount/useConfig
// (only useRoute and the underlying account getter / window config are faked),
// so a change to how those resolve their data is exercised here too. `presets`
// seeds form fields as if the user had already typed them.
const mountComposable = ({
  account = {},
  enabledLanguages = ENABLED_LANGUAGES,
  presets = {},
} = {}) => {
  window.chatwootConfig = { enabledLanguages };

  const store = createStore({
    modules: {
      accounts: {
        namespaced: true,
        getters: { getAccount: () => () => account },
      },
    },
  });

  const fields = {
    locale: ref(presets.locale || ''),
    website: ref(presets.website || ''),
    timezone: ref(presets.timezone || ''),
    companySize: ref(presets.companySize || ''),
    industry: ref(presets.industry || ''),
    referralSource: ref(presets.referralSource || ''),
  };

  let api;
  const Component = defineComponent({
    setup() {
      api = useAccountEnrichment(fields);
      return () => h('div');
    },
  });
  const wrapper = mount(Component, { global: { plugins: [store] } });
  return { ...api, fields, wrapper };
};

beforeEach(() => {
  useRoute.mockReturnValue({ params: { accountId: '1' } });
});

afterEach(() => {
  delete window.chatwootConfig;
});

describe('useAccountEnrichment', () => {
  describe('populateFormFields', () => {
    it('fills empty fields from the enriched attributes on mount', () => {
      const { fields } = mountComposable({
        account: {
          locale: 'en',
          custom_attributes: {
            website: 'https://acme.com',
            timezone: 'America/New_York',
            company_size: '11-50',
            industry: 'Technology',
            referral_source: 'google',
          },
        },
      });

      expect(fields.website.value).toBe('https://acme.com');
      expect(fields.timezone.value).toBe('America/New_York');
      expect(fields.companySize.value).toBe('11-50');
      expect(fields.industry.value).toBe('Technology');
      expect(fields.referralSource.value).toBe('google');
    });

    it('falls back to brand_info for website and industry', () => {
      const { fields } = mountComposable({
        account: {
          custom_attributes: {
            brand_info: {
              domain: 'acme.com',
              industries: [{ industry: 'Retail & E-commerce' }],
            },
          },
        },
      });

      expect(fields.website.value).toBe('acme.com');
      expect(fields.industry.value).toBe('Retail & E-commerce');
    });

    it('does not clobber fields the user already set', () => {
      const { fields } = mountComposable({
        presets: { website: 'mysite.com', industry: 'Finance' },
        account: {
          custom_attributes: {
            website: 'https://enriched.com',
            industry: 'Technology',
          },
        },
      });

      expect(fields.website.value).toBe('mysite.com');
      expect(fields.industry.value).toBe('Finance');
    });

    it('detects the locale from the browser, else the account locale', () => {
      // jsdom reports navigator.language as 'en-US' -> base 'en' is enabled.
      const { fields } = mountComposable({ account: { locale: 'de' } });
      expect(fields.locale.value).toBe('en');

      // No enabled language matches the browser -> fall back to account locale.
      const { fields: other } = mountComposable({
        account: { locale: 'de' },
        enabledLanguages: [{ iso_639_1_code: 'es', name: 'Spanish' }],
      });
      expect(other.locale.value).toBe('de');
    });
  });

  describe('isEnriching', () => {
    it('is true while the account is on the enrichment step', () => {
      const { isEnriching } = mountComposable({
        account: { custom_attributes: { onboarding_step: 'enrichment' } },
      });
      expect(isEnriching.value).toBe(true);
    });

    it('is false on any other step', () => {
      const { isEnriching } = mountComposable({
        account: { custom_attributes: { onboarding_step: 'account_details' } },
      });
      expect(isEnriching.value).toBe(false);
    });

    it('times out after 30s, flipping to false and populating', () => {
      vi.useFakeTimers();
      try {
        const { isEnriching, fields } = mountComposable({
          account: {
            custom_attributes: {
              onboarding_step: 'enrichment',
              company_size: '51-200',
            },
          },
        });
        expect(isEnriching.value).toBe(true);

        vi.advanceTimersByTime(30000);

        expect(isEnriching.value).toBe(false);
        expect(fields.companySize.value).toBe('51-200');
      } finally {
        vi.useRealTimers();
      }
    });
  });

  describe('getChangedFields', () => {
    it('lists only enrichable fields edited after auto-fill', () => {
      const { fields, getChangedFields } = mountComposable({
        account: {
          custom_attributes: {
            website: 'https://acme.com',
            company_size: '11-50',
            industry: 'Technology',
          },
        },
      });

      expect(getChangedFields()).toEqual([]);

      fields.industry.value = 'Finance';
      expect(getChangedFields()).toEqual(['industry']);
    });
  });
});
