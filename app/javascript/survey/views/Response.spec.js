import { config, flushPromises, mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import App from '../App.vue';
import { getSurveyDetails, updateSurvey } from '../api/survey';
import en from '../i18n/locale/en.json';
import hr from '../i18n/locale/hr.json';
import ptBR from '../i18n/locale/pt_BR.json';
import es from '../i18n/locale/es.json';
import ar from '../i18n/locale/ar.json';

vi.mock('../api/survey', () => ({
  getSurveyDetails: vi.fn(),
  updateSurvey: vi.fn(),
}));

const messages = { en, hr, pt_BR: ptBR, es, ar };
const locales = Object.keys(messages);
const originalPlugins = config.global.plugins;
const mountOptions = {
  global: {
    stubs: {
      Branding: true,
      Rating: true,
      Feedback: true,
      StarRating: true,
      Spinner: true,
      Banner: true,
    },
  },
};

describe('standalone survey localization', () => {
  let wrapper;

  beforeEach(() => {
    document.documentElement.dir = 'ltr';
    config.global.plugins = [
      createI18n({ legacy: false, locale: 'en', messages }),
      VueDOMPurifyHTML,
    ];
  });

  afterEach(() => {
    wrapper?.unmount();
    config.global.plugins = originalPlugins;
    document.documentElement.dir = 'ltr';
  });

  it.each(
    locales.flatMap(locale =>
      [null, '', undefined].map(content => [locale, content])
    )
  )(
    'uses the %s account language for a missing default prompt (%s)',
    async (locale, content) => {
      getSurveyDetails.mockResolvedValue({
        data: { locale, content, inbox_name: 'QA Inbox' },
      });
      wrapper = mount(App, mountOptions);
      await flushPromises();

      expect(wrapper.find('.prose').text().replace(/\s+/g, ' ').trim()).toBe(
        messages[locale].SURVEY.DESCRIPTION.replace('{inboxName}', 'QA Inbox')
          .replace(/\s+/g, ' ')
          .trim()
      );
      expect(wrapper.text()).toContain(messages[locale].SURVEY.RATING.LABEL);
    }
  );

  it.each(locales)(
    'preserves custom %s text and its literal placeholders',
    async locale => {
      getSurveyDetails.mockResolvedValue({
        data: {
          locale,
          content: 'Custom {inboxName}: **keep this text**.',
          inbox_name: 'QA Inbox',
        },
      });
      wrapper = mount(App, mountOptions);
      await flushPromises();

      expect(wrapper.text()).toContain('Custom {inboxName}: keep this text.');
      expect(wrapper.find('strong').text()).toBe('keep this text');
      expect(updateSurvey).not.toHaveBeenCalled();
    }
  );

  it.each([
    ['ar', 'rtl'],
    ['hr', 'ltr'],
    ['en', 'ltr'],
  ])(
    'sets the %s page direction to %s after loading the account locale',
    async (locale, direction) => {
      getSurveyDetails.mockResolvedValue({
        data: { locale, content: null, inbox_name: 'QA Inbox' },
      });
      wrapper = mount(App, mountOptions);
      await flushPromises();

      expect(wrapper.attributes('dir')).toBe(direction);
      expect(document.documentElement.dir).toBe(direction);
    }
  );
});
