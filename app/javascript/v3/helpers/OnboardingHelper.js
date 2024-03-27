export const companySizeOptions = [
  { value: '1-10', label: '1-10' },
  { value: '11-50', label: '11-50' },
  { value: '51-250', label: '51-250' },
  { value: '251-1000', label: '251-1000' },
  { value: '1001+', label: 'Over 1000' },
];

export const industryOptions = [
  { value: 'Information Technology', label: 'Information technology' },
  { value: 'Finance', label: 'Finance' },
  { value: 'Health & Medicine', label: 'Health & Medicine' },
  { value: 'Education', label: 'Education' },
  { value: 'E Commerce', label: 'E Commerce' },
  { value: 'Other', label: 'Other' },
];

export const findMatchingOption = (value, options, defaultValue) => {
  if (!value) return defaultValue;

  const match = options.find(
    option => option.value === value || option === value
  );
  return match ? match.value || match : defaultValue;
};

export const findIndustryOptions = searchCandidate => {
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
    Finance: [
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
    'E Commerce': [],
  };

  if (Object.keys(industryMap).includes(searchCandidate)) {
    return searchCandidate;
  }

  const industry = Object.entries(industryMap).find(([, value]) =>
    value.includes(searchCandidate)
  );

  return industry ? industry[0] : 'Other';
};
