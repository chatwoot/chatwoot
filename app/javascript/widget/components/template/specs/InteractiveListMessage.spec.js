import { mount } from '@vue/test-utils';
import InteractiveListMessage from '../InteractiveListMessage.vue';
import { IFrameHelper } from 'widget/helpers/utils';

vi.mock('widget/helpers/utils', () => ({
  IFrameHelper: {
    isIFrame: vi.fn(() => true),
    sendMessage: vi.fn(),
  },
}));

describe('InteractiveListMessage', () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  it('sends a postback event with the row id when a row is clicked', async () => {
    const wrapper = mount(InteractiveListMessage, {
      props: {
        messageContentAttributes: {
          body_text: 'Pick an item',
          action: { button_text: 'View options' },
          sections: [
            {
              title: 'Section 1',
              rows: [{ id: 'row_1', title: 'Row A', description: 'desc' }],
            },
          ],
        },
      },
    });

    await wrapper.find('button').trigger('click');

    expect(IFrameHelper.sendMessage).toHaveBeenCalledWith({
      event: 'postback',
      data: { payload: 'row_1' },
    });
  });
});
