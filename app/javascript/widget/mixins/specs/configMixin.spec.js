import { createWrapper } from '@vue/test-utils';
import configMixin from '../configMixin';
import Vue from 'vue';

global.chatwootWebChannel = {
  avatarUrl: 'https://test.url',
  hasAConnectedAgentBot: 'AgentBot',
  enabledFeatures: ['emoji_picker', 'attachments'],
};

global.chatwootWidgetDefaults = {
  useInboxAvatarForBot: true,
};

describe('configMixin', () => {
  test('returns config', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [configMixin],
    };
    const Constructor = Vue.extend(Component);
    const vm = new Constructor().$mount();
    const wrapper = createWrapper(vm);
    expect(wrapper.vm.hasEmojiPickerEnabled).toBe(true);
    expect(wrapper.vm.hasAttachmentsEnabled).toBe(true);
    expect(wrapper.vm.hasAConnectedAgentBot).toBe(true);
    expect(wrapper.vm.useInboxAvatarForBot).toBe(true);
    expect(wrapper.vm.inboxAvatarUrl).toBe('https://test.url');
    expect(wrapper.vm.channelConfig).toEqual({
      avatarUrl: 'https://test.url',
      hasAConnectedAgentBot: 'AgentBot',
      enabledFeatures: ['emoji_picker', 'attachments'],
    });
  });
});
