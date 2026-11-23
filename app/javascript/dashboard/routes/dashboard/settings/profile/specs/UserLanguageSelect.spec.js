import { mount, flushPromises } from '@vue/test-utils';
import { ref } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import languagesSource from '../../../../../../../../config/initializers/languages.rb?raw';
import UserLanguageSelect from '../UserLanguageSelect.vue';

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ currentAccount: { value: { locale: 'en' } } }),
}));
vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: vi.fn(),
}));

const languages = Array.from(
  languagesSource.matchAll(
    /name: '([^']*)'.*?iso_639_1_code: '([^']+)', enabled: true/g
  ),
  ([, name, code]) => ({ name, iso_639_1_code: code })
);
const defaultLabel =
  'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.USE_ACCOUNT_DEFAULT';

const searchInput = wrapper => wrapper.get('input[type="search"]');
const labels = wrapper =>
  wrapper.findAll('[role="option"]').map(option => option.text());

const mountPicker = (locale = null) => {
  const uiSettings = ref({ locale });
  const updateUISettings = vi.fn(async settings => {
    uiSettings.value = settings;
  });
  useUISettings.mockReturnValue({ uiSettings, updateUISettings });

  const wrapper = mount(UserLanguageSelect, {
    attachTo: document.body,
    props: { label: 'Language' },
  });
  return { wrapper, updateUISettings };
};

beforeEach(() => {
  window.chatwootConfig = { enabledLanguages: languages };
});

afterEach(() => {
  document.body.innerHTML = '';
  delete window.chatwootConfig;
});

describe('UserLanguageSelect', () => {
  it('preserves supplied labels and order for the full catalogue', async () => {
    const { wrapper } = mountPicker();
    await wrapper.get('button').trigger('click');

    expect(languages.length).toBeGreaterThan(30);
    expect(
      wrapper
        .findAll('[role="option"] span.text-n-slate-12')
        .map(option => option.element.textContent)
    ).toEqual([defaultLabel, ...languages.map(language => language.name)]);
    expect(labels(wrapper)).toEqual([
      defaultLabel,
      ...languages.map(language => language.name.trim()),
    ]);
    wrapper.unmount();
  });

  it.each([
    ['日本語', '日本語 (ja)'],
    ['Japanese', '日本語 (ja)'],
    ['ja', '日本語 (ja)'],
    ['Português Brasileiro', 'Português Brasileiro (pt-BR)'],
    ['Brazilian Portuguese', 'Português Brasileiro (pt-BR)'],
    ['pt_BR', 'Português Brasileiro (pt-BR)'],
    ['pt-bR', 'Português Brasileiro (pt-BR)'],
    ['Chinese (Taiwan)', '中文 (台湾) (zh-TW)'],
    ['zh_CN', '中文 (zh-CN)'],
  ])('finds %s without changing the option label', async (query, label) => {
    const { wrapper } = mountPicker();
    await wrapper.get('button').trigger('click');
    await searchInput(wrapper).setValue(query);

    expect(labels(wrapper)).toContain(label);
    if (/português brasileiro|brazilian|pt.br/i.test(query)) {
      expect(labels(wrapper)).not.toContain('Português (pt)');
    }
    wrapper.unmount();
  });

  it.each(['Hrvatski', 'Croatian', 'hr'])(
    'finds a future Croatian option by %s without a change to the picker',
    async query => {
      window.chatwootConfig = {
        enabledLanguages: [
          ...languages,
          { name: 'Hrvatski (hr)', iso_639_1_code: 'hr' },
        ],
      };
      const { wrapper } = mountPicker();
      await wrapper.get('button').trigger('click');

      await searchInput(wrapper).setValue(query);
      expect(labels(wrapper)).toContain('Hrvatski (hr)');
      wrapper.unmount();
    }
  );

  it('saves the original locale value, does not clear it on repeat, and can reset to the account default', async () => {
    const { wrapper, updateUISettings } = mountPicker('en');
    const trigger = wrapper.get('button');
    await trigger.trigger('click');
    await searchInput(wrapper).setValue('pt-BR');
    await searchInput(wrapper).trigger('keydown', { key: 'ArrowDown' });
    expect(searchInput(wrapper).attributes('aria-activedescendant')).toBe(
      wrapper.get('[role="option"]').attributes('id')
    );
    await searchInput(wrapper).trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(updateUISettings).toHaveBeenLastCalledWith({ locale: 'pt_BR' });
    expect(trigger.text()).toContain('Português Brasileiro (pt-BR)');
    expect(document.activeElement).toBe(trigger.element);

    await trigger.trigger('click');
    await searchInput(wrapper).setValue('pt_BR');
    await wrapper.get('[role="option"]').trigger('click');
    expect(updateUISettings).toHaveBeenCalledTimes(1);

    await trigger.trigger('click');
    expect(searchInput(wrapper).element.value).toBe('');
    await wrapper.get('[role="option"]').trigger('click');
    await flushPromises();
    expect(updateUISettings).toHaveBeenLastCalledWith({ locale: null });
    expect(trigger.text()).toContain(defaultLabel);
    wrapper.unmount();
  });

  it('does not save on typing, empty results, or Escape', async () => {
    const { wrapper, updateUISettings } = mountPicker('en');
    const trigger = wrapper.get('button');
    await trigger.trigger('click');
    await searchInput(wrapper).setValue('not-a-real-locale');
    expect(labels(wrapper)).toEqual([]);

    await searchInput(wrapper).trigger('keydown', { key: 'Enter' });
    expect(trigger.attributes('aria-expanded')).toBe('true');
    await searchInput(wrapper).trigger('keydown', { key: 'Escape' });
    expect(trigger.attributes('aria-expanded')).toBe('false');
    expect(document.activeElement).toBe(trigger.element);
    expect(updateUISettings).not.toHaveBeenCalled();
    wrapper.unmount();
  });
});
