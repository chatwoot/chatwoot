import { mount, flushPromises } from '@vue/test-utils';
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
  beforeEach(() => {
    window.cw_keyboard_layout = 'QWERTY';
  });

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

  it('adds the shift key on a QWERTZ layout', async () => {
    window.cw_keyboard_layout = 'QWERTZ';
    vi.spyOn(navigator, 'platform', 'get').mockReturnValue('Win32');
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.findAll('kbd').map(kbd => kbd.text())).toEqual([
      '⇧ ALT L',
      '⇧ ALT P',
    ]);
  });

  it('offers only a private note when public replies are restricted', () => {
    const wrapper = mountComponent({ canReply: false });

    expect(wrapper.text()).not.toContain('Reply');
    expect(wrapper.text()).toContain('CONVERSATION.REPLYBOX.PRIVATE_NOTE');
  });

  it('keeps the latest conversation link when replies are restricted', () => {
    const wrapper = mountComponent({ canReply: false, hasLatest: true });

    expect(wrapper.findAll('kbd')).toHaveLength(1);
    expect(wrapper.find(GO_TO_LATEST).exists()).toBe(true);
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
