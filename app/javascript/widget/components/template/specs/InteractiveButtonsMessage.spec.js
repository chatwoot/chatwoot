import { mount } from '@vue/test-utils';
import InteractiveButtonsMessage from '../InteractiveButtonsMessage.vue';
import { IFrameHelper } from 'widget/helpers/utils';

vi.mock('widget/helpers/utils', () => ({
  IFrameHelper: {
    isIFrame: vi.fn(() => true),
    sendMessage: vi.fn(),
  },
}));

describe('InteractiveButtonsMessage', () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  it('sends a postback event when a reply button is clicked', async () => {
    const wrapper = mount(InteractiveButtonsMessage, {
      props: {
        messageContentAttributes: {
          body_text: 'Choose an option',
          buttons: [{ id: 'btn_1', text: 'Option A' }],
        },
      },
    });

    await wrapper.find('button').trigger('click');

    expect(IFrameHelper.sendMessage).toHaveBeenCalledWith({
      event: 'postback',
      data: { payload: 'btn_1' },
    });
  });

  it('renders a URL button as a link without sending a postback', async () => {
    const wrapper = mount(InteractiveButtonsMessage, {
      props: {
        messageContentAttributes: {
          body_text: 'Choose an option',
          buttons: [
            {
              id: 'btn_1',
              text: 'Visit',
              type: 'url',
              uri: 'https://example.com',
            },
          ],
        },
      },
    });

    const link = wrapper.find('a');
    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe('https://example.com');

    await link.trigger('click');
    expect(IFrameHelper.sendMessage).not.toHaveBeenCalled();
  });
});
