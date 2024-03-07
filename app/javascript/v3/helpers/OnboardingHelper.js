export const findMatchingOption = (value, options, defaultValue) => {
  if (!value) return defaultValue;

  const match = options.find(
    option => option.value === value || option === value
  );
  return match ? match.value || match : defaultValue;
};
