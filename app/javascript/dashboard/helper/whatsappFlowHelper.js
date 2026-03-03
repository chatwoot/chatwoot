/**
 * WhatsApp Flows helper — constants, component definitions, and JSON generation.
 *
 * Meta Flows JSON spec v6.0:
 * Each flow has screens, each screen has a SingleColumnLayout with children.
 * Children are form components (TextInput, Dropdown, etc.) and display components (TextHeading, etc.).
 * The last child should be a Footer component with on-click-action (navigate/complete).
 */

export const FLOW_VERSION = '6.0';

// ── Component types available in the palette ─────────────────────────
export const FLOW_COMPONENT_TYPES = {
  // Display components
  TEXT_HEADING: 'TextHeading',
  TEXT_SUBHEADING: 'TextSubheading',
  TEXT_BODY: 'TextBody',
  TEXT_CAPTION: 'TextCaption',
  IMAGE: 'Image',
  EMBEDDED_LINK: 'EmbeddedLink',

  // Input components
  TEXT_INPUT: 'TextInput',
  TEXT_AREA: 'TextArea',
  DROPDOWN: 'Dropdown',
  RADIO_BUTTONS_GROUP: 'RadioButtonsGroup',
  CHECKBOX_GROUP: 'CheckboxGroup',
  DATE_PICKER: 'DatePicker',
  OPT_IN: 'OptIn',

  // Action
  FOOTER: 'Footer',
};

// ── Palette category groupings ───────────────────────────────────────
export const COMPONENT_CATEGORIES = [
  {
    key: 'display',
    label: 'WHATSAPP_FLOWS.PALETTE.DISPLAY',
    components: [
      FLOW_COMPONENT_TYPES.TEXT_HEADING,
      FLOW_COMPONENT_TYPES.TEXT_SUBHEADING,
      FLOW_COMPONENT_TYPES.TEXT_BODY,
      FLOW_COMPONENT_TYPES.TEXT_CAPTION,
      FLOW_COMPONENT_TYPES.IMAGE,
      FLOW_COMPONENT_TYPES.EMBEDDED_LINK,
    ],
  },
  {
    key: 'input',
    label: 'WHATSAPP_FLOWS.PALETTE.INPUT',
    components: [
      FLOW_COMPONENT_TYPES.TEXT_INPUT,
      FLOW_COMPONENT_TYPES.TEXT_AREA,
      FLOW_COMPONENT_TYPES.DROPDOWN,
      FLOW_COMPONENT_TYPES.RADIO_BUTTONS_GROUP,
      FLOW_COMPONENT_TYPES.CHECKBOX_GROUP,
      FLOW_COMPONENT_TYPES.DATE_PICKER,
      FLOW_COMPONENT_TYPES.OPT_IN,
    ],
  },
  {
    key: 'action',
    label: 'WHATSAPP_FLOWS.PALETTE.ACTION',
    components: [FLOW_COMPONENT_TYPES.FOOTER],
  },
];

// ── Icons for each component type ────────────────────────────────────
export const COMPONENT_ICONS = {
  [FLOW_COMPONENT_TYPES.TEXT_HEADING]: 'i-lucide-heading-1',
  [FLOW_COMPONENT_TYPES.TEXT_SUBHEADING]: 'i-lucide-heading-2',
  [FLOW_COMPONENT_TYPES.TEXT_BODY]: 'i-lucide-type',
  [FLOW_COMPONENT_TYPES.TEXT_CAPTION]: 'i-lucide-text',
  [FLOW_COMPONENT_TYPES.IMAGE]: 'i-lucide-image',
  [FLOW_COMPONENT_TYPES.EMBEDDED_LINK]: 'i-lucide-link',
  [FLOW_COMPONENT_TYPES.TEXT_INPUT]: 'i-lucide-text-cursor-input',
  [FLOW_COMPONENT_TYPES.TEXT_AREA]: 'i-lucide-align-left',
  [FLOW_COMPONENT_TYPES.DROPDOWN]: 'i-lucide-chevrons-up-down',
  [FLOW_COMPONENT_TYPES.RADIO_BUTTONS_GROUP]: 'i-lucide-circle-dot',
  [FLOW_COMPONENT_TYPES.CHECKBOX_GROUP]: 'i-lucide-check-square',
  [FLOW_COMPONENT_TYPES.DATE_PICKER]: 'i-lucide-calendar',
  [FLOW_COMPONENT_TYPES.OPT_IN]: 'i-lucide-toggle-left',
  [FLOW_COMPONENT_TYPES.FOOTER]: 'i-lucide-mouse-pointer-click',
};

// ── User-friendly labels ─────────────────────────────────────────────
export const COMPONENT_LABELS = {
  [FLOW_COMPONENT_TYPES.TEXT_HEADING]: 'Heading',
  [FLOW_COMPONENT_TYPES.TEXT_SUBHEADING]: 'Subheading',
  [FLOW_COMPONENT_TYPES.TEXT_BODY]: 'Body Text',
  [FLOW_COMPONENT_TYPES.TEXT_CAPTION]: 'Caption',
  [FLOW_COMPONENT_TYPES.IMAGE]: 'Image',
  [FLOW_COMPONENT_TYPES.EMBEDDED_LINK]: 'Link',
  [FLOW_COMPONENT_TYPES.TEXT_INPUT]: 'Text Input',
  [FLOW_COMPONENT_TYPES.TEXT_AREA]: 'Text Area',
  [FLOW_COMPONENT_TYPES.DROPDOWN]: 'Dropdown',
  [FLOW_COMPONENT_TYPES.RADIO_BUTTONS_GROUP]: 'Radio Buttons',
  [FLOW_COMPONENT_TYPES.CHECKBOX_GROUP]: 'Checkbox Group',
  [FLOW_COMPONENT_TYPES.DATE_PICKER]: 'Date Picker',
  [FLOW_COMPONENT_TYPES.OPT_IN]: 'Opt-In',
  [FLOW_COMPONENT_TYPES.FOOTER]: 'Submit Button',
};

// ── Flow actions ─────────────────────────────────────────────────────
export const FLOW_ACTIONS = {
  NAVIGATE: 'navigate',
  COMPLETE: 'complete',
  DATA_EXCHANGE: 'data_exchange',
};

// ── Default property values for new components ───────────────────────
export function createDefaultComponent(type) {
  const id = `${type}_${Date.now()}`;
  const base = { type, _id: id };

  switch (type) {
    case FLOW_COMPONENT_TYPES.TEXT_HEADING:
      return { ...base, text: 'Heading' };
    case FLOW_COMPONENT_TYPES.TEXT_SUBHEADING:
      return { ...base, text: 'Subheading' };
    case FLOW_COMPONENT_TYPES.TEXT_BODY:
      return { ...base, text: 'Body text goes here' };
    case FLOW_COMPONENT_TYPES.TEXT_CAPTION:
      return { ...base, text: 'Caption text' };
    case FLOW_COMPONENT_TYPES.IMAGE:
      return { ...base, src: '', height: 200, 'scale-type': 'contain' };
    case FLOW_COMPONENT_TYPES.EMBEDDED_LINK:
      return {
        ...base,
        text: 'Learn more',
        'on-click-action': {
          name: 'navigate',
          next: { type: 'screen', name: '' },
          payload: {},
        },
      };
    case FLOW_COMPONENT_TYPES.TEXT_INPUT:
      return {
        ...base,
        label: 'Text Input',
        name: `text_input_${Date.now()}`,
        required: false,
        'input-type': 'text',
        'helper-text': '',
      };
    case FLOW_COMPONENT_TYPES.TEXT_AREA:
      return {
        ...base,
        label: 'Text Area',
        name: `text_area_${Date.now()}`,
        required: false,
        'helper-text': '',
      };
    case FLOW_COMPONENT_TYPES.DROPDOWN:
      return {
        ...base,
        label: 'Select an option',
        name: `dropdown_${Date.now()}`,
        required: false,
        'data-source': [
          { id: '1', title: 'Option 1' },
          { id: '2', title: 'Option 2' },
        ],
      };
    case FLOW_COMPONENT_TYPES.RADIO_BUTTONS_GROUP:
      return {
        ...base,
        label: 'Choose one',
        name: `radio_${Date.now()}`,
        required: false,
        'data-source': [
          { id: '1', title: 'Option 1' },
          { id: '2', title: 'Option 2' },
        ],
      };
    case FLOW_COMPONENT_TYPES.CHECKBOX_GROUP:
      return {
        ...base,
        label: 'Select all that apply',
        name: `checkbox_${Date.now()}`,
        required: false,
        'data-source': [
          { id: '1', title: 'Option 1' },
          { id: '2', title: 'Option 2' },
        ],
      };
    case FLOW_COMPONENT_TYPES.DATE_PICKER:
      return {
        ...base,
        label: 'Select a date',
        name: `date_${Date.now()}`,
        required: false,
        'helper-text': '',
      };
    case FLOW_COMPONENT_TYPES.OPT_IN:
      return {
        ...base,
        label: 'I agree to the terms',
        name: `opt_in_${Date.now()}`,
        required: false,
      };
    case FLOW_COMPONENT_TYPES.FOOTER:
      return {
        ...base,
        label: 'Continue',
        'on-click-action': {
          name: FLOW_ACTIONS.COMPLETE,
          payload: {},
        },
      };
    default:
      return base;
  }
}

// ── Screen helpers ───────────────────────────────────────────────────
let screenCounter = 0;

export function createDefaultScreen(isTerminal = false) {
  screenCounter += 1;
  const id = `SCREEN_${screenCounter}`;
  return {
    id,
    title: `Screen ${screenCounter}`,
    terminal: isTerminal,
    layout: {
      type: 'SingleColumnLayout',
      children: [
        createDefaultComponent(FLOW_COMPONENT_TYPES.TEXT_HEADING),
        createDefaultComponent(FLOW_COMPONENT_TYPES.FOOTER),
      ],
    },
  };
}

export function resetScreenCounter() {
  screenCounter = 0;
}

// ── Generate clean Flow JSON (strip internal _id fields) ─────────────
function cleanComponent(component) {
  // eslint-disable-next-line no-underscore-dangle
  const { _id, ...rest } = component;
  return rest;
}

function cleanScreen(screen) {
  return {
    id: screen.id,
    title: screen.title,
    terminal: screen.terminal || false,
    layout: {
      type: 'SingleColumnLayout',
      children: screen.layout.children.map(child => cleanComponent(child)),
    },
  };
}

export function buildFlowJSON(screens) {
  return {
    version: FLOW_VERSION,
    screens: screens.map(screen => cleanScreen(screen)),
  };
}

// ── Check if a component is an input type (collects data) ────────────
export function isInputComponent(type) {
  return [
    FLOW_COMPONENT_TYPES.TEXT_INPUT,
    FLOW_COMPONENT_TYPES.TEXT_AREA,
    FLOW_COMPONENT_TYPES.DROPDOWN,
    FLOW_COMPONENT_TYPES.RADIO_BUTTONS_GROUP,
    FLOW_COMPONENT_TYPES.CHECKBOX_GROUP,
    FLOW_COMPONENT_TYPES.DATE_PICKER,
    FLOW_COMPONENT_TYPES.OPT_IN,
  ].includes(type);
}

// ── Extract all variable names from screens ──────────────────────────
export function extractFlowVariables(screens) {
  const variables = [];
  screens.forEach(screen => {
    (screen.layout?.children || []).forEach(child => {
      if (isInputComponent(child.type) && child.name) {
        variables.push({
          screen: screen.id,
          name: child.name,
          type: child.type,
          label: child.label,
        });
      }
    });
  });
  return variables;
}
