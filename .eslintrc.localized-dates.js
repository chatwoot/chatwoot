// Dates and times shown to a person read in the app language (the dashboard
// UI language, the widget locale), through shared/helpers/localizedDate.js.
// These rules stop a display format from bypassing it: date-fns formatters
// write English only, and Intl or toLocale* without the app locale follow the
// browser language instead. Machine formats (API parameters, file names) use
// `formatFixed` from the same module, which says so at the call site.
//
// ESLint keeps one `no-restricted-syntax` list per config and a later one
// replaces an earlier one, so the date selectors live in
// .eslintrc.localized-dates.syntax.js and .eslintrc.js spreads them into its
// own list instead of this file setting the rule.
const HELPER = 'shared/helpers/localizedDate';
const IMPORT_MESSAGE = `Dates shown to people go through ${HELPER} (formatLocalized, formatRelative, formatElapsed); machine formats use formatFixed.`;
const DATE_FNS_FORMATTERS = [
  'format',
  'formatDistance',
  'formatDistanceStrict',
  'formatDistanceToNow',
  'formatDistanceToNowStrict',
  'formatRelative',
  'intlFormat',
  'intlFormatDistance',
];

module.exports = {
  rules: {
    'no-restricted-imports': [
      'error',
      {
        paths: [
          {
            name: 'date-fns',
            importNames: DATE_FNS_FORMATTERS,
            message: IMPORT_MESSAGE,
          },
          { name: 'date-fns/locale', message: IMPORT_MESSAGE },
          {
            name: '@chatwoot/utils',
            importNames: ['formatTime'],
            message: `Durations shown to people go through formatDuration from ${HELPER}; formatTime writes English units.`,
          },
          ...DATE_FNS_FORMATTERS.map(name => ({
            name: `date-fns/${name}`,
            message: IMPORT_MESSAGE,
          })),
        ],
      },
    ],
  },
  overrides: [
    {
      files: [
        `app/javascript/${HELPER}.js`,
        '**/*.spec.{j,t}s?(x)',
        '**/*.story.vue',
      ],
      rules: { 'no-restricted-imports': 'off' },
    },
  ],
};
