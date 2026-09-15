import MessagesView from '../MessagesView.vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

// The jump is plain DOM work on the component instance, so the methods are exercised directly
// rather than mounting MessagesView, which pulls in the whole conversation store.
const { jumpToMessage } = MessagesView.methods;

const makeElement = () => {
  const el = document.createElement('div');
  el.scrollIntoView = vi.fn();
  document.body.appendChild(el);
  return el;
};

describe('jumpToMessage', () => {
  let vm;
  let target;

  beforeEach(() => {
    document.body.innerHTML = '';
    target = makeElement();
    target.id = 'message42';
    vm = {
      isProgrammaticScroll: false,
      fetchPreviousMessages: vi.fn().mockResolvedValue(),
      scrollToBottom: vi.fn(),
      makeMessagesRead: vi.fn(),
      $nextTick: cb => Promise.resolve().then(cb),
    };
  });

  // The old code called fetchPreviousMessages on every jump. With no argument its `scrollTop`
  // defaulted to 0, so the `< 100` guard always passed and a page of older messages was
  // prepended mid-animation, landing the view between two messages.
  it('does not load older messages when the target is already on screen', async () => {
    await jumpToMessage.call(vm, 42);

    expect(vm.fetchPreviousMessages).not.toHaveBeenCalled();
    expect(target.scrollIntoView).toHaveBeenCalledWith({ block: 'center' });
  });

  // The mirror of the bug: loading belongs here, where the quoted message is out of the loaded
  // page, and where the old code merely jumped to the bottom.
  it('loads older messages when the target is not on screen yet', async () => {
    target.id = 'message-other';
    vm.fetchPreviousMessages = vi.fn().mockImplementation(async () => {
      target.id = 'message42';
    });

    await jumpToMessage.call(vm, 42);

    expect(vm.fetchPreviousMessages).toHaveBeenCalled();
    expect(target.scrollIntoView).toHaveBeenCalled();
    expect(vm.scrollToBottom).not.toHaveBeenCalled();
  });

  // The target pulled in by the history load mounts during the nextTick, after the click's own
  // event has come and gone, so the highlight has to be announced once it is on screen.
  it('announces the highlight only once the target exists', async () => {
    const highlighted = [];
    const listener = payload => highlighted.push(payload);
    emitter.on(BUS_EVENTS.HIGHLIGHT_MESSAGE, listener);

    target.id = 'message-other';
    vm.fetchPreviousMessages = vi.fn().mockImplementation(async () => {
      expect(highlighted).toHaveLength(0);
      target.id = 'message42';
    });

    await jumpToMessage.call(vm, 42);
    emitter.off(BUS_EVENTS.HIGHLIGHT_MESSAGE, listener);

    expect(highlighted).toEqual([{ messageId: 42 }]);
  });

  it('announces no highlight when the message was never found', async () => {
    const highlighted = [];
    const listener = payload => highlighted.push(payload);
    emitter.on(BUS_EVENTS.HIGHLIGHT_MESSAGE, listener);

    target.id = 'message-other';
    await jumpToMessage.call(vm, 42);
    emitter.off(BUS_EVENTS.HIGHLIGHT_MESSAGE, listener);

    expect(highlighted).toHaveLength(0);
  });

  // Jumping to the newest message is the opposite of what was asked for; staying put is honest.
  it('leaves the agent where they are when the message is further back', async () => {
    target.id = 'message-other';

    await jumpToMessage.call(vm, 42);

    expect(vm.scrollToBottom).not.toHaveBeenCalled();
    expect(target.scrollIntoView).not.toHaveBeenCalled();
  });

  // SCROLL_TO_MESSAGE is also the "go to the bottom" signal, emitted with no payload on every
  // message sent or received. Reaching the not-found path there would fetch a page of history
  // on the busiest path in the conversation view.
  it('goes straight to the bottom when no message was asked for', async () => {
    await jumpToMessage.call(vm, '');

    expect(vm.fetchPreviousMessages).not.toHaveBeenCalled();
    expect(vm.scrollToBottom).toHaveBeenCalled();
  });
});
