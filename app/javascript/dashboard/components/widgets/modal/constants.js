export const KEYS = {
  ALT: 'Alt / ⌥',
  WIN: 'Win / ⌘',
  SHIFT: 'Shift',
  SLASH: '/',
  UP: 'Up',
  DOWN: 'Down',
};

export const SHORTCUT_KEYS = [
  {
    id: 1,
    label: 'OPEN_CONVERSATION',
    displayKeys: [KEYS.ALT, 'J', KEYS.SLASH, KEYS.ALT, 'K'],
    keySet: ['Alt+KeyJ', 'Alt+KeyK'],
  },
  {
    id: 2,
    label: 'RESOLVE_AND_NEXT',
    displayKeys: [KEYS.WIN, KEYS.ALT, 'E'],
    keySet: ['$mod+Alt+KeyE'],
  },
  {
    id: 3,
    label: 'NAVIGATE_DROPDOWN',
    displayKeys: [KEYS.UP, KEYS.DOWN],
    keySet: ['ArrowUp', 'ArrowDown'],
  },
  {
    id: 4,
    label: 'RESOLVE_CONVERSATION',
    displayKeys: [KEYS.ALT, 'E'],
    keySet: ['Alt+KeyE'],
  },
  {
    id: 5,
    label: 'GO_TO_CONVERSATION_DASHBOARD',
    displayKeys: [KEYS.ALT, 'C'],
    keySet: ['Alt+KeyC'],
  },
  {
    id: 6,
    label: 'ADD_ATTACHMENT',
    displayKeys: [KEYS.WIN, KEYS.ALT, 'A'],
    keySet: ['$mod+Alt+KeyA'],
  },
  {
    id: 7,
    label: 'GO_TO_CONTACTS_DASHBOARD',
    displayKeys: [KEYS.ALT, 'V'],
    keySet: ['Alt+KeyV'],
  },
  {
    id: 8,
    label: 'TOGGLE_SIDEBAR',
    displayKeys: [KEYS.ALT, 'O'],
    keySet: ['Alt+KeyO'],
  },
  {
    id: 9,
    label: 'GO_TO_REPORTS_SIDEBAR',
    displayKeys: [KEYS.ALT, 'R'],
    keySet: ['Alt+KeyR'],
  },
  {
    id: 10,
    label: 'MOVE_TO_NEXT_TAB',
    displayKeys: [KEYS.ALT, 'N'],
    keySet: ['Alt+KeyN'],
  },
  {
    id: 11,
    label: 'GO_TO_SETTINGS',
    displayKeys: [KEYS.ALT, 'S'],
    keySet: ['Alt+KeyS'],
  },
  {
    id: 12,
    label: 'SWITCH_TO_PRIVATE_NOTE',
    displayKeys: [KEYS.ALT, 'P'],
    keySet: ['Alt+KeyP'],
  },
  {
    id: 13,
    label: 'SWITCH_TO_REPLY',
    displayKeys: [KEYS.ALT, 'L'],
    keySet: ['Alt+KeyL'],
  },
  {
    id: 14,
    label: 'TOGGLE_SNOOZE_DROPDOWN',
    displayKeys: [KEYS.ALT, 'M'],
    keySet: ['Alt+KeyM'],
  },
];
