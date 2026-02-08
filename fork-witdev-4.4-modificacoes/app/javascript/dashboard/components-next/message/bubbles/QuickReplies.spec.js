import { mount } from '@vue/test-utils';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { BUS_EVENTS } from 'shared/constants/busEvents';

// Mock modules with factory functions
vi.mock('../provider.js', () => ({
  useMessageContext: vi.fn(() => ({
    contentAttributes: { value: { items: [] } },
    id: { value: 123 },
    variant: { value: 'user' },
    orientation: { value: 'left' },
    inReplyTo: { value: null },
    shouldGroupWithNext: { value: false },
  })),
}));

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

// Import the component after mocks
import QuickReplies from './QuickReplies.vue';
import { useMessageContext } from '../provider.js';
import { emitter } from 'shared/helpers/mitt';

// Mock window.globalConfig
Object.defineProperty(window, 'globalConfig', {
  value: {
    SOCIALWISE_RICH_DASHBOARD: true,
  },
  writable: true,
});

describe('QuickReplies.vue', () => {
  const mockContextWithItems = items => {
    useMessageContext.mockReturnValue({
      contentAttributes: { value: { items } },
      id: { value: 123 },
      variant: { value: 'user' },
      orientation: { value: 'left' },
      inReplyTo: { value: null },
      shouldGroupWithNext: { value: false },
    });
  };

  beforeEach(() => {
    vi.clearAllMocks();
    window.globalConfig = {
      SOCIALWISE_RICH_DASHBOARD: true,
    };
  });

  it('renders quick replies when feature flag is enabled and items exist', () => {
    mockContextWithItems([
      {
        title: 'Option 1',
        value: 'option_1',
        payload: 'OPTION_1_PAYLOAD',
      },
      {
        title: 'Option 2',
        value: 'option_2',
        payload: 'OPTION_2_PAYLOAD',
      },
    ]);

    const wrapper = mount(QuickReplies);

    expect(wrapper.find('.quick-replies-wrapper').exists()).toBe(true);
    expect(wrapper.findAll('.quick-reply-option')).toHaveLength(2);
    expect(wrapper.find('.quick-reply-title').text()).toBe('Option 1');
  });

  it('does not render when feature flag is disabled', () => {
    window.globalConfig.SOCIALWISE_RICH_DASHBOARD = false;
    mockContextWithItems([{ title: 'Option 1', value: 'option_1' }]);

    const wrapper = mount(QuickReplies);

    expect(wrapper.find('.quick-replies-wrapper').exists()).toBe(false);
  });

  it('does not render when no items exist', () => {
    mockContextWithItems([]);

    const wrapper = mount(QuickReplies);

    expect(wrapper.find('.quick-replies-wrapper').exists()).toBe(false);
  });

  it('handles quick reply clicks correctly', async () => {
    mockContextWithItems([
      {
        title: 'Test Option',
        value: 'test_value',
        payload: 'TEST_PAYLOAD',
      },
    ]);

    const wrapper = mount(QuickReplies);
    const quickReplyButton = wrapper.find('.quick-reply-option');

    await quickReplyButton.trigger('click');

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.RICH_POSTBACK, {
      messageId: 123,
      payload: 'TEST_PAYLOAD',
      text: 'Test Option',
      type: 'quick_reply',
      timestamp: expect.any(String),
    });
  });

  it('uses value as payload when payload is not provided', async () => {
    mockContextWithItems([
      {
        title: 'Test Option',
        value: 'test_value',
      },
    ]);

    const wrapper = mount(QuickReplies);
    const quickReplyButton = wrapper.find('.quick-reply-option');

    await quickReplyButton.trigger('click');

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.RICH_POSTBACK, {
      messageId: 123,
      payload: 'test_value',
      text: 'Test Option',
      type: 'quick_reply',
      timestamp: expect.any(String),
    });
  });

  it('renders options with title and value correctly', () => {
    mockContextWithItems([
      {
        title: 'Display Title',
        value: 'internal_value',
      },
    ]);

    const wrapper = mount(QuickReplies);

    expect(wrapper.find('.quick-reply-title').text()).toBe('Display Title');
    expect(wrapper.find('.quick-reply-value').text()).toBe('internal_value');
  });

  it('does not show value when it matches title', () => {
    mockContextWithItems([
      {
        title: 'Same Value',
        value: 'Same Value',
      },
    ]);

    const wrapper = mount(QuickReplies);

    expect(wrapper.find('.quick-reply-title').text()).toBe('Same Value');
    expect(wrapper.find('.quick-reply-value').exists()).toBe(false);
  });

  it('renders multiple quick reply options correctly', () => {
    mockContextWithItems([
      { title: 'Option 1', value: 'opt1' },
      { title: 'Option 2', value: 'opt2' },
      { title: 'Option 3', value: 'opt3' },
    ]);

    const wrapper = mount(QuickReplies);
    const options = wrapper.findAll('.quick-reply-option');

    expect(options).toHaveLength(3);
    expect(options[0].find('.quick-reply-title').text()).toBe('Option 1');
    expect(options[1].find('.quick-reply-title').text()).toBe('Option 2');
    expect(options[2].find('.quick-reply-title').text()).toBe('Option 3');
  });

  it('has proper accessibility attributes', () => {
    mockContextWithItems([
      {
        title: 'Accessible Option',
        value: 'accessible',
      },
    ]);

    const wrapper = mount(QuickReplies);
    const button = wrapper.find('.quick-reply-option');

    expect(button.attributes('role')).toBe('button');
    expect(button.attributes('aria-label')).toBe(
      'Quick reply option: Accessible Option'
    );
  });

  it('handles options without value', () => {
    mockContextWithItems([
      {
        title: 'Title Only Option',
      },
    ]);

    const wrapper = mount(QuickReplies);

    expect(wrapper.find('.quick-reply-title').text()).toBe('Title Only Option');
    expect(wrapper.find('.quick-reply-value').exists()).toBe(false);
  });
});
