// One line per dashboard locale enabled in config/initializers/languages.rb.
// A locale enabled there but missing here renders in English until its line is added.
const localeFiles = import.meta.glob(
  [
    './locale/ar/*.json',
    './locale/bg/*.json',
    './locale/ca/*.json',
    './locale/cs/*.json',
    './locale/da/*.json',
    './locale/de/*.json',
    './locale/el/*.json',
    './locale/en/*.json',
    './locale/es/*.json',
    './locale/et/*.json',
    './locale/fa/*.json',
    './locale/fi/*.json',
    './locale/fr/*.json',
    './locale/he/*.json',
    './locale/hu/*.json',
    './locale/id/*.json',
    './locale/is/*.json',
    './locale/it/*.json',
    './locale/ja/*.json',
    './locale/ko/*.json',
    './locale/lt/*.json',
    './locale/lv/*.json',
    './locale/ml/*.json',
    './locale/nl/*.json',
    './locale/no/*.json',
    './locale/pl/*.json',
    './locale/pt/*.json',
    './locale/pt_BR/*.json',
    './locale/ro/*.json',
    './locale/ru/*.json',
    './locale/sk/*.json',
    './locale/sl/*.json',
    './locale/sr/*.json',
    './locale/sv/*.json',
    './locale/ta/*.json',
    './locale/th/*.json',
    './locale/tr/*.json',
    './locale/uk/*.json',
    './locale/uz/*.json',
    './locale/vi/*.json',
    './locale/zh_CN/*.json',
    './locale/zh_TW/*.json',
  ],
  { eager: true, import: 'default' }
);

const messages = {};

Object.entries(localeFiles).forEach(([path, translations]) => {
  const locale = path.split('/')[2];
  messages[locale] = { ...messages[locale], ...translations };
});

export default messages;
