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
import RichCards from './RichCards.vue';
import { useMessageContext } from '../provider.js';
import { emitter } from 'shared/helpers/mitt';

// Mock window.globalConfig
Object.defineProperty(window, 'globalConfig', {
  value: {
    SOCIALWISE_RICH_DASHBOARD: true,
  },
  writable: true,
});

describe('RichCards.vue', () => {
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

  it('renders rich cards when feature flag is enabled and items exist', () => {
    mockContextWithItems([
      {
        title: 'Test Card',
        description: 'Test Description',
        media_url: 'https://example.com/image.jpg',
        actions: [
          {
            type: 'link',
            text: 'View More',
            uri: 'https://example.com',
          },
        ],
      },
    ]);

    const wrapper = mount(RichCards);

    expect(wrapper.find('.rich-cards-container').exists()).toBe(true);
    expect(wrapper.find('.card-title').text()).toBe('Test Card');
    expect(wrapper.find('.card-description').text()).toBe('Test Description');
    expect(wrapper.find('img').attributes('src')).toBe(
      'https://example.com/image.jpg'
    );
  });

  it('does not render when feature flag is disabled', () => {
    window.globalConfig.SOCIALWISE_RICH_DASHBOARD = false;
    mockContextWithItems([{ title: 'Test Card' }]);

    const wrapper = mount(RichCards);

    expect(wrapper.find('.rich-cards-container').exists()).toBe(false);
  });

  it('does not render when no items exist', () => {
    mockContextWithItems([]);

    const wrapper = mount(RichCards);

    expect(wrapper.find('.rich-cards-container').exists()).toBe(false);
  });

  it('handles postback button clicks correctly', async () => {
    mockContextWithItems([
      {
        title: 'Test Card',
        actions: [
          {
            type: 'postback',
            text: 'Click Me',
            payload: 'TEST_PAYLOAD',
          },
        ],
      },
    ]);

    const wrapper = mount(RichCards);
    const postbackButton = wrapper.find('.card-button--postback');

    await postbackButton.trigger('click');

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.RICH_POSTBACK, {
      messageId: 123,
      payload: 'TEST_PAYLOAD',
      text: 'Click Me',
      timestamp: expect.any(String),
    });
  });

  it('renders link buttons with correct attributes', () => {
    mockContextWithItems([
      {
        title: 'Test Card',
        actions: [
          {
            type: 'link',
            text: 'External Link',
            uri: 'https://example.com',
          },
        ],
      },
    ]);

    const wrapper = mount(RichCards);
    const linkButton = wrapper.find('.card-button--link');

    expect(linkButton.attributes('href')).toBe('https://example.com');
    expect(linkButton.attributes('target')).toBe('_blank');
    expect(linkButton.attributes('rel')).toBe('noopener noreferrer');
    expect(linkButton.text()).toContain('External Link');
  });

  it('handles image loading errors', async () => {
    mockContextWithItems([
      {
        title: 'Test Card',
        media_url: 'https://invalid-image.jpg',
      },
    ]);

    const wrapper = mount(RichCards);
    const image = wrapper.find('img');

    await image.trigger('error');

    expect(image.element.style.display).toBe('none');
  });

  it('escapes HTML in alt attributes', () => {
    mockContextWithItems([
      {
        title: '<script>alert("xss")</script>Test Title',
        media_url: 'https://example.com/image.jpg',
      },
    ]);

    const wrapper = mount(RichCards);
    const image = wrapper.find('img');

    expect(image.attributes('alt')).toBe(
      '&lt;script&gt;alert("xss")&lt;/script&gt;Test Title'
    );
  });

  it('renders multiple cards correctly', () => {
    mockContextWithItems([
      { title: 'Card 1', description: 'Description 1' },
      { title: 'Card 2', description: 'Description 2' },
      { title: 'Card 3', description: 'Description 3' },
    ]);

    const wrapper = mount(RichCards);
    const cards = wrapper.findAll('.rich-card');

    expect(cards).toHaveLength(3);
    expect(cards[0].find('.card-title').text()).toBe('Card 1');
    expect(cards[1].find('.card-title').text()).toBe('Card 2');
    expect(cards[2].find('.card-title').text()).toBe('Card 3');
  });

  it('handles cards without images', () => {
    mockContextWithItems([
      {
        title: 'Text Only Card',
        description: 'No image here',
        actions: [],
      },
    ]);

    const wrapper = mount(RichCards);

    expect(wrapper.find('.card-image').exists()).toBe(false);
    expect(wrapper.find('.card-title').text()).toBe('Text Only Card');
    expect(wrapper.find('.card-description').text()).toBe('No image here');
  });

  it('handles cards without actions', () => {
    mockContextWithItems([
      {
        title: 'No Actions Card',
        description: 'This card has no buttons',
      },
    ]);

    const wrapper = mount(RichCards);

    expect(wrapper.find('.card-actions').exists()).toBe(false);
    expect(wrapper.find('.card-title').text()).toBe('No Actions Card');
  });
});
