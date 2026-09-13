export function traceForMessage(session, message) {
  if (!session || !message) return [];
  if (message.turn_id) {
    return session.trace.filter(event => event.turn_id === message.turn_id);
  }
  // An old single-turn trace can be attributed safely. Multi-turn legacy
  // traces have no boundaries, so never assign the combined history to one reply.
  const legacyRequests = session.messages.filter(
    item => item.role === 'user' && !item.turn_id
  );
  return legacyRequests.length === 1
    ? session.trace.filter(event => !event.turn_id)
    : [];
}
