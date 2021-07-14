import { shallowMount } from '@vue/test-utils';
import messageMixin from '../messageMixin';
import messages from './messageFixture';

describe('messageMixin', () => {
  let Component = {
    render() {},
    title: 'TestComponent',
    mixins: [messageMixin],
  };

  it('deleted messages', async () => {
    const wrapper = shallowMount(Component, {
      data() {
        return {
          message: messages.deletedMessage,
        };
      },
    });
    expect(wrapper.vm.messageContentAttributes).toEqual({
      deleted: true,
    });
    expect(wrapper.vm.hasAttachments).toBe(false);
  });
  it('non-deleted messages', async () => {
    const wrapper = shallowMount(Component, {
      data() {
        return {
          message: messages.nonDeletedMessage,
        };
      },
    });
    expect(wrapper.vm.deletedMessage).toBe(undefined);
    expect(wrapper.vm.messageContentAttributes).toEqual({});
    expect(wrapper.vm.hasAttachments).toBe(true);
  });
});
