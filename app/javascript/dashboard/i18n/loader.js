export async function setLocale(i18n, locale) {
  const { default: messages } = await import(`./locale/${locale}/index.js`);

  i18n.setLocaleMessage(locale, messages);
  i18n.locale.value = locale;
}
