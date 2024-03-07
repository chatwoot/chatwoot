export const findMatchingOption = (value, options, defaultValue) => {
  if (!value) return defaultValue;

  const match = options.find(
    option => option.value === value || option === value
  );
  return match ? match.value || match : defaultValue;
};

export const findIndustryOptions = subIndustry => {
  const industryMap = {
    'Information Technology': [
      'Semiconductors & Semiconductor Equipment',
      'Internet Software & Services',
      'IT Services',
      'Software',
      'Communications Equipment',
      'Electronic Equipment, Instruments & Components',
      'Technology Hardware, Storage & Peripherals',
    ],
    Financials: [
      'Banks',
      'Diversified Financial Services',
      'Capital Markets',
      'Insurance',
    ],
    'Health & Medicine': [
      'Health Care Equipment & Supplies',
      'Health Care Providers & Services',
      'Biotechnology',
      'Life Sciences Tools & Services',
      'Pharmaceuticals',
    ],
    Education: ['Education Services'],
  };

  const industry = Object.entries(industryMap).find(([, value]) =>
    value.includes(subIndustry)
  );

  return industry ? industry[0] : 'Other';
};
