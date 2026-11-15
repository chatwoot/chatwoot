// `no-restricted-syntax` selectors for dates shown to a person: toLocale* and
// Intl formatters must get the app locale, not the browser's (no locale,
// `undefined`, `navigator.language`) and not vue-i18n's raw `locale.value`
// (`pt_BR`, which Intl rejects). Spread into the rule in .eslintrc.js; see
// .eslintrc.localized-dates.js for the rest of the date rules.
const LOCALE_MESSAGE =
  "Pass the app locale (currentDateLocale() from shared/helpers/localizedDate), not the browser's.";

// Every date shown goes through dateTimeFormat, which keeps it in the
// Gregorian calendar the rest of the app uses.
const CALENDAR_MESSAGE =
  'Use dateTimeFormat from shared/helpers/localizedDate: it keeps every date the app shows in the Gregorian calendar.';

const BROWSER_LOCALE_ARGUMENT = [
  '[arguments.length=0]',
  "[arguments.0.type='Identifier'][arguments.0.name='undefined']",
  "[arguments.0.object.name='navigator'][arguments.0.property.name='language']",
  "[arguments.0.object.name='locale'][arguments.0.property.name='value']",
];

module.exports = BROWSER_LOCALE_ARGUMENT.flatMap(argument => [
  {
    selector: `CallExpression[callee.property.name=/^toLocale(Date|Time)String$/]${argument}`,
    message: LOCALE_MESSAGE,
  },
  {
    selector: `NewExpression[callee.object.name='Intl'][callee.property.name=/^(DateTimeFormat|RelativeTimeFormat)$/]${argument}`,
    message: LOCALE_MESSAGE,
  },
]).concat(
  {
    selector:
      "NewExpression[callee.object.name='Intl'][callee.property.name='DateTimeFormat']",
    message: CALENDAR_MESSAGE,
  },
  {
    selector:
      'CallExpression[callee.property.name=/^toLocale(Date|Time)String$/]',
    message: CALENDAR_MESSAGE,
  },
  {
    // A date with options; a number takes Intl.NumberFormat instead.
    selector:
      "CallExpression[callee.property.name='toLocaleString'][arguments.length>1]",
    message: CALENDAR_MESSAGE,
  }
);
