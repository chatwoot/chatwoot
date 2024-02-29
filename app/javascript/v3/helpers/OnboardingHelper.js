export const findMatchingOption = (value, options, defaultValue) => {
  const match = options.find(
    option => option.value === value || option === value
  );
  return match ? match.value || match : defaultValue;
};
