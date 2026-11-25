// A conversion to a provider paired by QR asks the inbox settings to open the pairing.
// The request lives in memory, not in the URL or the history entry: a reload or a Back
// must not bring it back, and the settings page is cached by full path, so it has to be
// read by whichever instance is shown, fresh or reactivated.
let pendingInboxId = null;

export const requestPairing = inboxId => {
  pendingInboxId = inboxId;
};

export const consumePairingRequest = inboxId => {
  if (pendingInboxId !== inboxId) return false;
  pendingInboxId = null;
  return true;
};
