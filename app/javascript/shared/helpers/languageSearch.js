const nameOptions = { type: 'language', fallback: 'none' };
const englishNames = Intl.DisplayNames
  ? new Intl.DisplayNames(['en'], nameOptions)
  : null;
const aliasesByCode = new Map();

const languageAliases = code => {
  if (!code) return [];
  if (aliasesByCode.has(code)) return aliasesByCode.get(code);

  // Provider codes may use underscores. Normalize for lookup only.
  const tag = code.replaceAll('_', '-');
  const aliases = [code, tag];
  try {
    if (englishNames) {
      aliases.push(
        englishNames.of(tag),
        new Intl.DisplayNames([tag], nameOptions).of(tag)
      );
    }
  } catch (error) {
    // Keep provider-specific codes searchable when they aren't BCP 47 tags.
    if (!(error instanceof RangeError)) throw error;
  }
  const uniqueAliases = [...new Set(aliases.filter(Boolean))];
  aliasesByCode.set(code, uniqueAliases);
  return uniqueAliases;
};

export const languageOption = (label, value) => ({
  label,
  value,
  searchAliases: languageAliases(value),
});

export const matchesOptionSearch = (option, query) =>
  option.label.toLowerCase().includes(query) ||
  (option.searchAliases ?? []).some(alias =>
    alias.toLowerCase().includes(query)
  );
