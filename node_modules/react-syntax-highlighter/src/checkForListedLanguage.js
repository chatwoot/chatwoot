export default (astGenerator, language) => {
  const langs = astGenerator.listLanguages();
  return langs.indexOf(language) !== -1;
};
