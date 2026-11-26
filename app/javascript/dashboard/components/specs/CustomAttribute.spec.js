import { shallowMount } from '@vue/test-utils';
import CustomAttribute from '../CustomAttribute.vue';

const mountAttribute = props =>
  shallowMount(CustomAttribute, {
    props: { label: 'Label', attributeKey: 'key', showActions: true, ...props },
    global: {
      mocks: { $t: key => key },
      directives: { onClickaway: {}, tooltip: {} },
    },
  });

describe('CustomAttribute copy', () => {
  it('copies a date as it is displayed', () => {
    const value = '1967-05-07T22:00:00.000Z';
    const wrapper = mountAttribute({ attributeType: 'date', value });

    wrapper.vm.onCopy();

    expect(wrapper.emitted('copy')[0]).toEqual([
      new Date(value).toLocaleDateString(),
    ]);
  });

  it('copies a text value unchanged', () => {
    const wrapper = mountAttribute({
      attributeType: 'text',
      value: 'INV-2026-0417',
    });

    wrapper.vm.onCopy();

    expect(wrapper.emitted('copy')[0]).toEqual(['INV-2026-0417']);
  });
});
