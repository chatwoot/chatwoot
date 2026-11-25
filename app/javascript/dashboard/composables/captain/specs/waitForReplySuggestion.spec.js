import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  waitForReplySuggestion,
  REPLY_SUGGESTION_TIMEOUT_ERROR,
  REPLY_SUGGESTION_DISCONNECTED_ERROR,
} from '../waitForReplySuggestion';

const emitResult = data =>
  emitter.emit(BUS_EVENTS.CAPTAIN_REPLY_SUGGESTION_READY, data);

describe('waitForReplySuggestion', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('resolves with the result for this request and conversation', async () => {
    const promise = waitForReplySuggestion({
      requestId: 'req-2',
      conversationId: 7,
    });

    emitResult({ request_id: 'req-2', conversation_id: 7, message: 'Hi' });

    await expect(promise).resolves.toMatchObject({ message: 'Hi' });
  });

  it('ignores a late result from an older request or another conversation', async () => {
    const onDone = vi.fn();
    waitForReplySuggestion({ requestId: 'req-2', conversationId: 7 }).then(
      onDone
    );

    emitResult({ request_id: 'req-1', conversation_id: 7, message: 'Old' });
    emitResult({ request_id: 'req-2', conversation_id: 8, message: 'Other' });
    await Promise.resolve();

    expect(onDone).not.toHaveBeenCalled();
  });

  it('gives up after the timeout', async () => {
    const promise = waitForReplySuggestion({
      requestId: 'req-2',
      conversationId: 7,
      timeoutMs: 1000,
    });

    vi.advanceTimersByTime(1000);

    await expect(promise).rejects.toMatchObject({
      name: REPLY_SUGGESTION_TIMEOUT_ERROR,
    });
  });

  it('stops waiting when the request is cancelled', async () => {
    const controller = new AbortController();
    const promise = waitForReplySuggestion({
      requestId: 'req-2',
      conversationId: 7,
      signal: controller.signal,
    });

    controller.abort();
    emitResult({ request_id: 'req-2', conversation_id: 7, message: 'Late' });

    await expect(promise).rejects.toMatchObject({ name: 'AbortError' });
  });

  it('stops waiting when the live connection drops', async () => {
    const promise = waitForReplySuggestion({
      requestId: 'req-2',
      conversationId: 7,
    });

    emitter.emit(BUS_EVENTS.WEBSOCKET_DISCONNECT);

    await expect(promise).rejects.toMatchObject({
      name: REPLY_SUGGESTION_DISCONNECTED_ERROR,
    });
  });
});
