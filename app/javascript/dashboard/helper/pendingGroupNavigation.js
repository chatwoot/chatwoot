// Simple module-level store for pending group creation navigation.
// When a group is created, the group JID is stored here. When the
// conversation.created websocket event arrives matching that JID,
// the ActionCable handler emits a NAVIGATE_TO_GROUP bus event.

let pendingJid = null;
let timeout = null;

const TIMEOUT_MS = 30_000; // 30 seconds to receive the GROUP_CREATE event

export const pendingGroupNavigation = {
  set(groupJid) {
    pendingJid = groupJid;
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      pendingJid = null;
    }, TIMEOUT_MS);
  },

  consume() {
    const jid = pendingJid;
    pendingJid = null;
    clearTimeout(timeout);
    return jid;
  },
};
