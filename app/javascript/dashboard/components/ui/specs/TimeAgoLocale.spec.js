import { nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { bindDateLocale } from 'shared/helpers/localizedDate';
import TimeAgo from '../TimeAgo.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ locale: { value: 'en' } }),
}));

const locale = ref('pt_BR');
bindDateLocale({ global: { locale } });

describe('TimeAgo', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(Date.UTC(2026, 4, 5, 12)));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('redoes its stored relative times when the language switches', async () => {
    const fiveMinutesAgo = Date.now() / 1000 - 5 * 60;
    const wrapper = mount(TimeAgo, {
      props: {
        isAutoRefreshEnabled: false,
        lastActivityTimestamp: fiveMinutesAgo,
        createdAtTimestamp: fiveMinutesAgo,
      },
      global: {
        mocks: { $t: key => key },
        directives: { tooltip: {} },
      },
    });
    expect(wrapper.text()).toMatch(/5\s?min/);

    locale.value = 'en';
    await nextTick();
    expect(wrapper.text()).toBe('5m • 5m');
  });
});
