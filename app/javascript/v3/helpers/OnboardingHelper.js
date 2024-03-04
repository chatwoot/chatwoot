export const findMatchingOption = (value, options, defaultValue) => {
  if (!value) return defaultValue;

  const match = options.find(
    option => option.value === value || option === value
  );
  return match ? match.value || match : defaultValue;
};

export const findCompanySizeMatch = (options, size) => {
  if (!size || Number.isNaN(size)) return undefined;
  return (
    options.find(option => {
      // Options are like "1-10", "11-50", "5001-10000", "10001+", .split('-')[1]?.split('+')[0] is used to get the upper limit
      // If the upper limit is not present, it means the option is "10001+". The second .split('+')[0] is used to remove the '+' from the upper limit
      // We will parse this upper limit to a number and compare it with the size

      const upperLimitOption = option.value.split('-')[1]?.split('+')[0];
      const upperLimit = upperLimitOption ? Number(upperLimitOption) : Infinity;

      if (Number.isNaN(upperLimit)) return false;
      return size < upperLimit;
    })?.value || options[0].value
  );
};
