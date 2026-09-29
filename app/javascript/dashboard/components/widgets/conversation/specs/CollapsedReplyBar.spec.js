import { mount } from '@vue/test-utils';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import CollapsedReplyBar from '../CollapsedReplyBar.vue';

const GO_TO_LATEST =
  'button[label="CONVERSATION.CONTACT_HISTORY.GO_TO_LATEST"]';

const mountComponent = (props = {}) =>
  mount(CollapsedReplyBar, {
    props: { replyLabel: 'Reply', ...props },
    global: { stubs: { Icon: true } },
  });

const findButton = (wrapper, text) =>
  wrapper.findAll('button').find(button => button.text().includes(text));

describe('CollapsedReplyBar', () => {
  it('renders the reply and private note actions', () => {
    const wrapper = mountComponent({
      replyLabel: 'Reply to this older conversation',
    });

    expect(wrapper.text()).toContain('Reply to this older conversation');
    expect(wrapper.text()).toContain('CONVERSATION.REPLYBOX.PRIVATE_NOTE');
  });

  it('opens the editor in reply mode', async () => {
    const wrapper = mountComponent();

    await findButton(wrapper, 'Reply').trigger('click');

    expect(wrapper.emitted('open')).toEqual([[REPLY_EDITOR_MODES.REPLY]]);
  });

  it('opens the editor in private note mode', async () => {
    const wrapper = mountComponent();

    await findButton(wrapper, 'CONVERSATION.REPLYBOX.PRIVATE_NOTE').trigger(
      'click'
    );

    expect(wrapper.emitted('open')).toEqual([[REPLY_EDITOR_MODES.NOTE]]);
  });

  it('shows the alt key on non mac platforms', () => {
    vi.spyOn(navigator, 'platform', 'get').mockReturnValue('Win32');
    const wrapper = mountComponent();

    expect(wrapper.findAll('kbd').map(kbd => kbd.text())).toEqual([
      'ALT L',
      'ALT P',
    ]);
  });

  it('shows the option key on mac', () => {
    vi.spyOn(navigator, 'platform', 'get').mockReturnValue('MacIntel');
    const wrapper = mountComponent();

    expect(wrapper.findAll('kbd').map(kbd => kbd.text())).toEqual([
      '⌥ L',
      '⌥ P',
    ]);
  });

  it('hides the link to the latest conversation by default', () => {
    const wrapper = mountComponent();

    expect(wrapper.find(GO_TO_LATEST).exists()).toBe(false);
  });

  it('goes to the latest conversation', async () => {
    const wrapper = mountComponent({ hasLatest: true });

    await wrapper.find(GO_TO_LATEST).trigger('click');

    expect(wrapper.emitted('goToLatest')).toHaveLength(1);
    expect(wrapper.emitted('open')).toBeUndefined();
  });
});
