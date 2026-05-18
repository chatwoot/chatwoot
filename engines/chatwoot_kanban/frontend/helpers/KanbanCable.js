// Subscribes to the per-board ActionCable channel so we get card/column
// changes from other users in real time. Built on Chatwoot's existing
// cable consumer.
import { createConsumer } from '@rails/actioncable';

let consumer = null;
function getConsumer() {
  if (consumer) return consumer;
  const userKey = window.authCookie?.user_id ? `&user_id=${window.authCookie.user_id}` : '';
  consumer = createConsumer(`${window.chatwootConfig?.cableUrl || '/cable'}?${userKey}`);
  return consumer;
}

export function subscribeToBoard(boardId, onMessage) {
  const sub = getConsumer().subscriptions.create(
    { channel: 'ChatwootKanban::BoardChannel', board_id: boardId },
    {
      connected()    { /* noop */ },
      disconnected() { /* noop */ },
      received(data) { try { onMessage(data); } catch (_e) { /* swallow */ } },
    }
  );
  return () => sub.unsubscribe();
}
