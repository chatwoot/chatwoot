import { shallowMount } from '@vue/test-utils';
import AddReminder from '../AddReminder.vue';

let wrapper;

describe('AddReminder', () => {
  beforeEach(() => {
    wrapper = shallowMount(AddReminder, {
      mocks: {
        $t: x => x,
        $store: { getters: {}, state: {} },
      },
      stubs: { WootButton: { template: '<button />' } },
    });
  });

  it('tests resetValue', () => {
    const resetValue = vi.spyOn(wrapper.vm, 'resetValue');
    wrapper.vm.content = 'test';
    wrapper.vm.date = '08/11/2022';
    wrapper.vm.resetValue();
    expect(wrapper.vm.content).toEqual('');
    expect(wrapper.vm.date).toEqual('');
    expect(resetValue).toHaveBeenCalled();
  });

  it('tests optionSelected', () => {
    const optionSelected = vi.spyOn(wrapper.vm, 'optionSelected');
    wrapper.vm.label = '';
    wrapper.vm.optionSelected({ target: { value: 'test' } });
    expect(wrapper.vm.label).toEqual('test');
    expect(optionSelected).toHaveBeenCalled();
  });

  it('tests onAdd', () => {
    const onAdd = vi.spyOn(wrapper.vm, 'onAdd');
    wrapper.vm.label = 'label';
    wrapper.vm.content = 'content';
    wrapper.vm.date = '08/11/2022';
    wrapper.vm.onAdd();
    expect(onAdd).toHaveBeenCalled();
    expect(wrapper.emitted().add[0]).toEqual([
      { content: 'content', date: '08/11/2022', label: 'label' },
    ]);
  });
});
