import { vi } from 'vitest';
import {
  validatePhoneNumber,
  formatPhoneNumber,
  normalizePhoneNumber,
  isPhoneLikeInput,
  detectInputType,
  buildTagMenuItems,
  MODE,
  INPUT_TYPES,
  getValidationRules,
  validateAndFormatNewTag,
  createNewTagMenuItem,
  canAddTag,
  findMatchingMenuItem,
  resolveDropdownSelection,
} from '../tagInputHelper';
import { email } from '@vuelidate/validators';
import { getActiveCountryCode } from 'shared/components/PhoneInput/helper';

vi.mock('shared/components/PhoneInput/helper');

describe('tagInputHelper', () => {
  describe('validatePhoneNumber', () => {
    it('returns true for empty value', () => {
      expect(validatePhoneNumber('')).toBe(true);
    });

    it('validates correct phone number', () => {
      expect(validatePhoneNumber('+918283838283')).toBe(true);
    });

    it('validates correct phone number id + is present and number is not valid', () => {
      expect(validatePhoneNumber('+91828383834283')).toBe(false);
    });

    it('validates correct phone number if + is not present', () => {
      expect(validatePhoneNumber('91828383834283')).toBe(false);
    });

    it('invalidates incorrect phone number', () => {
      expect(validatePhoneNumber('invalid')).toBe(false);
    });

    it('handles null value', () => {
      expect(validatePhoneNumber(null)).toBe(true);
    });
  });

  describe('formatPhoneNumber', () => {
    it('formats valid phone number', () => {
      const result = formatPhoneNumber('+918283838283');
      expect(result.isValid).toBe(true);
      expect(result.formattedValue).toBe('+91 82838 38283');
    });

    it('handles invalid phone number', () => {
      const result = formatPhoneNumber('invalid');
      expect(result.isValid).toBe(false);
      expect(result.formattedValue).toBe('invalid');
    });

    it('handles error case', () => {
      const result = formatPhoneNumber(null);
      expect(result.isValid).toBe(false);
      expect(result.formattedValue).toBe(null);
    });
  });

  describe('isPhoneLikeInput', () => {
    it('accepts digits with common separators', () => {
      expect(isPhoneLikeInput('9017880795')).toBe(true);
      expect(isPhoneLikeInput('901-788-0795')).toBe(true);
      expect(isPhoneLikeInput('(901) 788-0795')).toBe(true);
      expect(isPhoneLikeInput('+1 901.788.0795')).toBe(true);
    });

    it('rejects input containing letters or @', () => {
      expect(isPhoneLikeInput('jane@example.com')).toBe(false);
      expect(isPhoneLikeInput('jane')).toBe(false);
      expect(isPhoneLikeInput('ext 123')).toBe(false);
    });

    it('rejects input without any digit', () => {
      expect(isPhoneLikeInput('+')).toBe(false);
      expect(isPhoneLikeInput('()-')).toBe(false);
      expect(isPhoneLikeInput('')).toBe(false);
      expect(isPhoneLikeInput(null)).toBe(false);
    });
  });

  describe('detectInputType', () => {
    it('returns tel for phone-like input', () => {
      expect(detectInputType('901-788-0795')).toBe(INPUT_TYPES.TEL);
      expect(detectInputType('+19017880795')).toBe(INPUT_TYPES.TEL);
    });

    it('returns email for everything else', () => {
      expect(detectInputType('jane@example.com')).toBe(INPUT_TYPES.EMAIL);
      expect(detectInputType('jane')).toBe(INPUT_TYPES.EMAIL);
      expect(detectInputType('')).toBe(INPUT_TYPES.EMAIL);
    });
  });

  describe('default country inference', () => {
    beforeEach(() => {
      getActiveCountryCode.mockReturnValue('CA');
    });

    it('validates national numbers against the inferred country', () => {
      expect(validatePhoneNumber('9017880795')).toBe(true);
      expect(validatePhoneNumber('901-788-0795')).toBe(true);
      expect(validatePhoneNumber('123')).toBe(false);
    });

    it('formats national numbers with the inferred country prefix', () => {
      const result = formatPhoneNumber('901-788-0795');
      expect(result.isValid).toBe(true);
      expect(result.formattedValue).toBe('+1 901 788 0795');
    });

    it('explicit + prefix wins over the inferred country', () => {
      const result = formatPhoneNumber('+918283838283');
      expect(result.isValid).toBe(true);
      expect(result.formattedValue).toBe('+91 82838 38283');
    });
  });

  describe('normalizePhoneNumber', () => {
    it('normalizes explicit international numbers without a default country', () => {
      expect(normalizePhoneNumber('+1 901-788-0795')).toBe('+19017880795');
    });

    it('normalizes national numbers using the inferred country', () => {
      getActiveCountryCode.mockReturnValue('CA');
      expect(normalizePhoneNumber('(901) 788-0795')).toBe('+19017880795');
      expect(normalizePhoneNumber('19017880795')).toBe('+19017880795');
    });

    it('returns null for invalid input', () => {
      expect(normalizePhoneNumber('123')).toBe(null);
      expect(normalizePhoneNumber('invalid')).toBe(null);
      expect(normalizePhoneNumber('')).toBe(null);
      expect(normalizePhoneNumber(null)).toBe(null);
    });
  });

  describe('getValidationRules', () => {
    it('returns email validation for email type', () => {
      const rules = getValidationRules(INPUT_TYPES.EMAIL);
      expect(rules.newTag).toHaveProperty('email');
      expect(rules.newTag).not.toHaveProperty('isValidPhone');
      expect(rules.newTag.email).toBe(email);
    });

    it('returns phone validation for tel type', () => {
      const rules = getValidationRules(INPUT_TYPES.TEL);
      expect(rules.newTag).toHaveProperty('isValidPhone');
      expect(rules.newTag).not.toHaveProperty('email');
      expect(rules.newTag.isValidPhone).toBe(validatePhoneNumber);
    });

    it('returns empty rules for text type', () => {
      const rules = getValidationRules(INPUT_TYPES.TEXT);
      expect(Object.keys(rules.newTag)).toHaveLength(0);
    });
  });

  describe('validateAndFormatNewTag', () => {
    it('validates and formats email tag', () => {
      const result = validateAndFormatNewTag(
        'test@example.com',
        INPUT_TYPES.EMAIL,
        false
      );
      expect(result).toEqual({
        isValid: true,
        formattedValue: 'test@example.com',
      });
    });

    it('validates and formats phone tag', () => {
      const result = validateAndFormatNewTag(
        '+918283838283',
        INPUT_TYPES.TEL,
        false
      );
      expect(result.isValid).toBe(true);
      expect(result.formattedValue).toBe('+91 82838 38283');
    });

    it('handles invalid email', () => {
      const result = validateAndFormatNewTag(
        'test@example.com',
        INPUT_TYPES.EMAIL,
        true
      );
      expect(result.isValid).toBe(false);
      expect(result.formattedValue).toBe('test@example.com');
    });

    it('handles text type', () => {
      const result = validateAndFormatNewTag(
        'sample text',
        INPUT_TYPES.TEXT,
        false
      );
      expect(result.isValid).toBe(true);
      expect(result.formattedValue).toBe('sample text');
    });
  });

  describe('createNewTagMenuItem', () => {
    it('creates email menu item', () => {
      const result = createNewTagMenuItem(
        'test@example.com',
        'test@example.com',
        INPUT_TYPES.EMAIL
      );
      expect(result).toEqual({
        label: 'test@example.com',
        value: 'test@example.com',
        email: 'test@example.com',
        thumbnail: { name: 'test@example.com', src: '' },
        action: 'create',
      });
    });

    it('creates phone menu item', () => {
      const result = createNewTagMenuItem(
        '+91 82838 38283',
        '+918283838283',
        INPUT_TYPES.TEL
      );
      expect(result).toEqual({
        label: '+91 82838 38283',
        value: '+918283838283',
        phoneNumber: '+918283838283',
        thumbnail: { name: '+91 82838 38283', src: '' },
        action: 'create',
      });
    });

    it('creates text menu item', () => {
      const result = createNewTagMenuItem(
        'sample text',
        'sample text',
        INPUT_TYPES.TEXT
      );
      expect(result).toEqual({
        label: 'sample text',
        value: 'sample text',
        thumbnail: { name: 'sample text', src: '' },
        action: 'create',
      });
    });
  });

  describe('buildTagMenuItems', () => {
    const baseParams = {
      mode: MODE.MULTIPLE,
      tags: [],
      menuItems: [],
      newTag: '',
      isLoading: false,
      type: INPUT_TYPES.TEXT,
      isNewTagInValidType: false,
    };

    it('returns empty array in single mode with existing tag', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        mode: MODE.SINGLE,
        tags: ['existing'],
      });
      expect(result).toEqual([]);
    });

    it('filters out existing tags', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        menuItems: [
          { label: 'item1', value: '1' },
          { label: 'item2', value: '2' },
        ],
        tags: ['item1'],
      });
      expect(result).toHaveLength(1);
      expect(result[0].label).toBe('item2');
    });

    it('creates new email item when valid', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        type: INPUT_TYPES.EMAIL,
        newTag: 'test@example.com',
        menuItems: [],
      });
      expect(result[0]).toMatchObject({
        label: 'test@example.com',
        email: 'test@example.com',
        action: 'create',
      });
    });

    it('creates new phone item when valid', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        type: INPUT_TYPES.TEL,
        newTag: '+918283838283',
        menuItems: [],
      });
      expect(result[0]).toMatchObject({
        value: '+918283838283',
        label: '+91 82838 38283',
        action: 'create',
      });
    });

    it('returns empty array when loading', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        isLoading: true,
        newTag: 'test',
      });
      expect(result).toEqual([]);
    });

    it('returns empty array for invalid tag', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        type: INPUT_TYPES.EMAIL,
        newTag: 'invalid-email',
        isNewTagInValidType: true,
      });
      expect(result).toEqual([]);
    });

    it('returns available menu items when no new tag', () => {
      const menuItems = [
        { label: 'item1', value: '1' },
        { label: 'item2', value: '2' },
      ];
      const result = buildTagMenuItems({
        ...baseParams,
        menuItems,
      });
      expect(result).toEqual(menuItems);
    });

    it('does not create suggestion when allowCreate is false', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        type: INPUT_TYPES.EMAIL,
        newTag: 'test@example.com',
        allowCreate: false,
      });
      expect(result).toEqual([]);
    });

    it('still returns available menu items when allowCreate is false', () => {
      const menuItems = [
        { label: 'Agent 1', value: '1' },
        { label: 'Agent 2', value: '2' },
      ];
      const result = buildTagMenuItems({
        ...baseParams,
        menuItems,
        newTag: 'Agent',
        allowCreate: false,
      });
      expect(result).toEqual(menuItems);
    });

    it('creates new item when allowCreate is true (default)', () => {
      const result = buildTagMenuItems({
        ...baseParams,
        type: INPUT_TYPES.EMAIL,
        newTag: 'test@example.com',
        allowCreate: true,
      });
      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        label: 'test@example.com',
        action: 'create',
      });
    });

    it('skips label dedup when skipLabelDedup is true', () => {
      const menuItems = [
        { label: 'HDMA', value: 1 },
        { label: 'HDMA', value: 2 },
      ];
      const result = buildTagMenuItems({
        ...baseParams,
        tags: ['HDMA'],
        menuItems,
        skipLabelDedup: true,
      });
      expect(result).toEqual(menuItems);
    });

    it('filters by label when skipLabelDedup is false (default)', () => {
      const menuItems = [
        { label: 'HDMA', value: 1 },
        { label: 'HDMA', value: 2 },
      ];
      const result = buildTagMenuItems({
        ...baseParams,
        tags: ['HDMA'],
        menuItems,
      });
      expect(result).toEqual([]);
    });
  });

  describe('canAddTag', () => {
    it('prevents adding tags in single mode when tag exists', () => {
      expect(canAddTag(MODE.SINGLE, 1)).toBe(false);
      expect(canAddTag(MODE.SINGLE, 0)).toBe(true);
    });

    it('allows adding tags in multiple mode', () => {
      expect(canAddTag(MODE.MULTIPLE, 1)).toBe(true);
      expect(canAddTag(MODE.MULTIPLE, 0)).toBe(true);
    });
  });

  describe('findMatchingMenuItem', () => {
    const menuItems = [
      { email: 'test1@example.com', label: 'Test 1' },
      { email: 'test2@example.com', label: 'Test 2' },
    ];

    it('finds matching menu item by email', () => {
      const result = findMatchingMenuItem(menuItems, 'test1@example.com');
      expect(result).toEqual(menuItems[0]);
    });

    it('returns undefined when no match found', () => {
      const result = findMatchingMenuItem(menuItems, 'nonexistent@example.com');
      expect(result).toBeUndefined();
    });

    it('handles empty menu items', () => {
      const result = findMatchingMenuItem([], 'test@example.com');
      expect(result).toBeUndefined();
    });

    describe('with tel type', () => {
      const phoneMenuItems = [
        { phoneNumber: '+19017880795', label: 'Jane', email: null },
        { phoneNumber: '+918283838283', label: 'Ravi', email: null },
      ];

      it('matches by exact E.164 value', () => {
        const result = findMatchingMenuItem(
          phoneMenuItems,
          '+19017880795',
          INPUT_TYPES.TEL
        );
        expect(result).toEqual(phoneMenuItems[0]);
      });

      it('matches formatted input against stored E.164', () => {
        getActiveCountryCode.mockReturnValue('CA');
        const result = findMatchingMenuItem(
          phoneMenuItems,
          '901-788-0795',
          INPUT_TYPES.TEL
        );
        expect(result).toEqual(phoneMenuItems[0]);
      });

      it('returns undefined when the number is not in the list', () => {
        const result = findMatchingMenuItem(
          phoneMenuItems,
          '+15550001111',
          INPUT_TYPES.TEL
        );
        expect(result).toBeUndefined();
      });

      it('returns undefined for unparseable input', () => {
        const result = findMatchingMenuItem(
          phoneMenuItems,
          '123',
          INPUT_TYPES.TEL
        );
        expect(result).toBeUndefined();
      });

      it('ignores items without a phoneNumber', () => {
        const result = findMatchingMenuItem(
          [{ email: 'a@b.com', label: 'A' }],
          '+19017880795',
          INPUT_TYPES.TEL
        );
        expect(result).toBeUndefined();
      });
    });
  });

  describe('resolveDropdownSelection', () => {
    const emailContact = {
      email: 'jane@example.com',
      phoneNumber: null,
      label: 'Jane',
    };
    const phoneContact = {
      email: null,
      phoneNumber: '+19017880795',
      label: 'Jane',
    };

    it('selects by email for email input type', () => {
      expect(resolveDropdownSelection(INPUT_TYPES.EMAIL, emailContact)).toEqual(
        {
          isEmail: true,
          tagValue: 'jane@example.com',
          shouldValidate: true,
        }
      );
    });

    it('selects by phone number for tel input type', () => {
      expect(resolveDropdownSelection(INPUT_TYPES.TEL, phoneContact)).toEqual({
        isEmail: false,
        tagValue: '+19017880795',
        shouldValidate: true,
      });
    });

    it('selects an email-only item as email in tel mode without validation', () => {
      expect(resolveDropdownSelection(INPUT_TYPES.TEL, emailContact)).toEqual({
        isEmail: true,
        tagValue: 'jane@example.com',
        shouldValidate: false,
      });
    });

    it('prefers the phone number when an item has both in tel mode', () => {
      const contactWithBoth = {
        email: 'jane@example.com',
        phoneNumber: '+19017880795',
        label: 'Jane',
      };
      expect(
        resolveDropdownSelection(INPUT_TYPES.TEL, contactWithBoth)
      ).toEqual({
        isEmail: false,
        tagValue: '+19017880795',
        shouldValidate: true,
      });
    });

    it('falls back to the item value without validation for text input type', () => {
      expect(resolveDropdownSelection(INPUT_TYPES.TEXT, phoneContact)).toEqual({
        isEmail: false,
        tagValue: '+19017880795',
        shouldValidate: false,
      });
    });
  });
});
