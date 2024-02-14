export const findMatchingOption = (value, options, defaultValue) => {
  const match = options.find(
    option => option.value === value || option === value
  );
  return match ? match.value || match : defaultValue;
};

export const findCompanySizeMatch = (options, size) => {
  return (
    options.find(option => {
      const upperLimit = option.value.split('-')[1]?.split('+')[0];
      return size < (upperLimit ? Number(upperLimit) : Infinity);
    })?.value || this.companySizeOptions[0].value
  );
};
