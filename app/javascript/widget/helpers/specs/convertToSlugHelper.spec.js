import { convertToSlug } from '../convertToSlugHelper.js';
describe('#Attribute Helper', () => {
  describe('convertToSlug', () => {
    it('should convert to slug', () => {
      expect(convertToSlug('Test@%^&*(){}>.!@`~_ ing')).toBe('test__ing');
    });
  });
});
