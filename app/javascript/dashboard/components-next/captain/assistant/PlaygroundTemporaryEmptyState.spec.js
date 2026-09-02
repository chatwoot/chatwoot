import { shallowMount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import PlaygroundTemporaryEmptyState from './PlaygroundTemporaryEmptyState.vue';

describe('PlaygroundTemporaryEmptyState', () => {
  it('renders the empty message and emits the add action', () => {
    const wrapper = shallowMount(PlaygroundTemporaryEmptyState, {
      props: {
        message: 'There are no temporary scenarios yet.',
        actionLabel: 'Add temporary scenario',
      },
    });
    const button = wrapper.findComponent(Button);

    expect(wrapper.text()).toContain('There are no temporary scenarios yet.');
    expect(button.props('label')).toBe('Add temporary scenario');

    button.vm.$emit('click');

    expect(wrapper.emitted('add')).toEqual([[]]);
  });
});
