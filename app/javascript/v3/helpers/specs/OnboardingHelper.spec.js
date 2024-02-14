import { findMatchingOption, findCompanySizeMatch } from '../OnboardingHelper';

describe('findMatchingOption', () => {
  const options = [{ value: 'option1' }, { value: 'option2' }];

  it('should return the matching option', () => {
    expect(findMatchingOption('option1', options, 'default')).toBe('option1');
  });

  it('should return the default value when no match is found', () => {
    expect(findMatchingOption('nonExistingOption', options, 'default')).toBe(
      'default'
    );
  });
});

describe('findCompanySizeMatch', () => {
  const mockCompanySizeOptions = [
    { value: '1-10' },
    { value: '11-50' },
    { value: '51-500' },
    { value: '501-1000' },
    { value: '1001+' },
  ];

  it('should return the correct company size range', () => {
    const size = 25;
    expect(findCompanySizeMatch(size, mockCompanySizeOptions)).toBe('11-50');
  });

  it('should return the first company size range when no match is found', () => {
    const size = 1500;
    expect(findCompanySizeMatch(size, mockCompanySizeOptions)).toBe('1-10');
  });
});
