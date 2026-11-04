const MAX_AGE_MS = 30 * 60 * 1000;
const keyFor = (accountId, token) => `contact-export:${accountId}:${token}`;

export const saveExportDraft = (accountId, selection) => {
  const token = crypto.randomUUID();
  sessionStorage.setItem(
    keyFor(accountId, token),
    JSON.stringify({ selection, createdAt: Date.now() })
  );
  return token;
};

export const consumeExportDraft = (accountId, token) => {
  const key = keyFor(accountId, token);
  const raw = sessionStorage.getItem(key);
  sessionStorage.removeItem(key);
  const draft = raw && JSON.parse(raw);
  if (!draft || Date.now() - draft.createdAt > MAX_AGE_MS) {
    throw new Error('Export selection expired');
  }
  return draft.selection;
};
