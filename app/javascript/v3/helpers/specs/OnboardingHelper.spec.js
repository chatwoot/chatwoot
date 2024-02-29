import { findMatchingOption } from '../OnboardingHelper';

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
