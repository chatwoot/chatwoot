import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import BaseHeatmap from '../BaseHeatmap.vue';
import { bindDateLocale } from 'shared/helpers/localizedDate';

vi.mock('@chatwoot/viz', () => ({
  HeatmapChart: {
    name: 'HeatmapChart',
    props: ['data', 'rowLabelWidth'],
    template: '<div />',
  },
}));

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en: { DAYS_OF_WEEK: { SUNDAY: 'Sunday', WEDNESDAY: 'Wednesday' } },
    pt_BR: { DAYS_OF_WEEK: { SUNDAY: 'Domingo', WEDNESDAY: 'Quarta-feira' } },
  },
});

describe('BaseHeatmap', () => {
  it('names the days in the language applied after it mounted', async () => {
    const sunday = new Date(2026, 10, 8, 10).getTime() / 1000;
    const wrapper = mount(BaseHeatmap, {
      props: {
        heatmapData: [{ timestamp: sunday, value: 1 }],
        ariaLabel: 'heatmap',
        formatValue: value => value,
      },
      global: { plugins: [i18n] },
    });
    const dayLabel = () =>
      wrapper.findComponent({ name: 'HeatmapChart' }).props('data').rows[0]
        .label;
    expect(dayLabel()).toBe('Sunday');

    i18n.global.locale.value = 'pt_BR';
    await nextTick();
    expect(dayLabel()).toBe('Domingo');
  });

  it('widens the label column to fit the longer labels of the language', async () => {
    i18n.global.locale.value = 'en';
    bindDateLocale(i18n);
    const wednesday = new Date(2026, 10, 11, 10).getTime() / 1000;
    const wrapper = mount(BaseHeatmap, {
      props: {
        heatmapData: [{ timestamp: wednesday, value: 1 }],
        ariaLabel: 'heatmap',
        formatValue: value => value,
      },
      global: { plugins: [i18n] },
    });
    const width = () =>
      wrapper.findComponent({ name: 'HeatmapChart' }).props('rowLabelWidth');
    const englishWidth = width();

    i18n.global.locale.value = 'pt_BR';
    await nextTick();
    expect(width()).toBeGreaterThan(englishWidth);
  });
});
