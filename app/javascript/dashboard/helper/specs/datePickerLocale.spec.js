import { nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { bindDateLocale } from 'shared/helpers/localizedDate';
import DateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
import { datePickerLang } from '../datePickerLocale';

const locale = ref('pt_BR');
bindDateLocale({ global: { locale } });

describe('date picker locale', () => {
  it('names months and weekdays in the language, Sunday first', () => {
    const lang = datePickerLang('pt-BR');
    expect(lang.formatLocale.months[0]).toBe('janeiro');
    expect(lang.formatLocale.weekdays[0]).toBe('domingo');
    expect(lang.monthBeforeYear).toBe(true);
  });

  it('follows a language switch on a mounted picker', async () => {
    locale.value = 'pt_BR';
    const wrapper = mount(DateRangePicker);
    // The picker library renders functional components, so read what is bound.
    const months = () => wrapper.vm.pickerLang.formatLocale.months[0];
    expect(months()).toBe('janeiro');

    locale.value = 'en';
    await nextTick();
    expect(months()).toBe('January');
  });
});
