export const SENDER_LIST_TYPES = ['vip', 'blocked', 'allowed'];

export const parseSenderListValues = input =>
  (input || '')
    .split(/[\s,;]+/)
    .map(value => value.trim().toLowerCase())
    .filter(Boolean);
