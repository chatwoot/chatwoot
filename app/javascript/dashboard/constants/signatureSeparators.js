// The message signature separators. InboxSignature::SEPARATORS mirrors the
// values, so a new option is one entry here and one value there.
import { lineBreakBetween } from 'dashboard/helper/markdownLineJoin';

export const SIGNATURE_SEPARATORS = [
  {
    value: 'blank',
    labelKey:
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.OPTIONS.BLANK',
    delimiter: () => '\n\n',
    editorLine: null,
  },
  {
    value: '--',
    labelKey:
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.OPTIONS.HORIZONTAL_LINE',
    delimiter: () => '\n\n--\n\n',
    editorLine: '--',
  },
  {
    value: 'none',
    labelKey:
      'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.SIGNATURE_SEPARATOR.OPTIONS.NONE',
    delimiter: lineBreakBetween,
    editorLine: null,
  },
];

export const DEFAULT_SIGNATURE_SEPARATOR = SIGNATURE_SEPARATORS[0].value;

export const findSignatureSeparator = value =>
  SIGNATURE_SEPARATORS.find(separator => separator.value === value) ||
  SIGNATURE_SEPARATORS[0];
