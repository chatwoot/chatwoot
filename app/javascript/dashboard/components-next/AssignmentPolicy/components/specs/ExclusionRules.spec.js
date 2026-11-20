import { defineComponent, nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import ExclusionRules from '../ExclusionRules.vue';
import DurationInput from 'dashboard/components-next/input/DurationInput.vue';

const mountExclusionRules = ({ initialHours = null } = {}) => {
  const TestHost = defineComponent({
    components: { ExclusionRules },
    setup() {
      const excludedLabels = ref([]);
      const excludeOlderThanHours = ref(initialHours);
      return { excludedLabels, excludeOlderThanHours };
    },
    template: `
      <ExclusionRules
        v-model:excluded-labels="excludedLabels"
        v-model:exclude-older-than-hours="excludeOlderThanHours"
      />
      <output data-testid="hours">{{ excludeOlderThanHours }}</output>
    `,
  });

  return mount(TestHost, {
    global: { stubs: { AddDataDropdown: true, LabelItem: true } },
  });
};

const durationInput = wrapper => wrapper.findComponent(DurationInput);

describe('ExclusionRules', () => {
  it('stores a duration entered in hours as hours', async () => {
    const wrapper = mountExclusionRules();

    expect(durationInput(wrapper).props('unit')).toBe('hours');

    await wrapper.find('input[type="number"]').setValue('20');

    expect(wrapper.find('[data-testid="hours"]').text()).toBe('20');
  });

  it('stores a duration entered in days as hours', async () => {
    const wrapper = mountExclusionRules();

    await durationInput(wrapper).vm.$emit('update:unit', 'days');
    await wrapper.find('input[type="number"]').setValue('2');

    expect(wrapper.find('[data-testid="hours"]').text()).toBe('48');
  });

  it('shows a saved value in its matching unit', async () => {
    const daysWrapper = mountExclusionRules({ initialHours: 48 });
    const hoursWrapper = mountExclusionRules({ initialHours: 20 });
    await nextTick();

    expect(durationInput(daysWrapper).props('unit')).toBe('days');
    expect(daysWrapper.find('input[type="number"]').element.value).toBe('2');

    expect(durationInput(hoursWrapper).props('unit')).toBe('hours');
    expect(hoursWrapper.find('input[type="number"]').element.value).toBe('20');
  });

  it('keeps a saved value above the maximum when the form opens and the field is left', async () => {
    // 28,800 is a legacy "20 days" that was saved as minutes into the hours field
    const wrapper = mountExclusionRules({ initialHours: 28800 });
    await nextTick();

    expect(durationInput(wrapper).props('unit')).toBe('days');
    expect(wrapper.find('input[type="number"]').element.value).toBe('1200');
    expect(wrapper.find('[data-testid="hours"]').text()).toBe('28800');

    await wrapper.find('input[type="number"]').trigger('blur');

    expect(wrapper.find('[data-testid="hours"]').text()).toBe('28800');
  });

  it('offers only hours and days, since the policy stores whole hours', () => {
    const units = mountExclusionRules()
      .findAll('option')
      .map(option => option.element.value);

    expect(units).toEqual(['hours', 'days']);
  });
});
