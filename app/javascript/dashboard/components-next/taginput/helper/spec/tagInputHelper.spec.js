import {
  validatePhoneNumber,
  formatPhoneNumber,
  buildTagMenuItems,
  MODE,
  INPUT_TYPES,
  getValidationRules,
  validateAndFormatNewTag,
  createNewTagMenuItem,
  canAddTag,
  findMatchingMenuItem,
} from '../tagInputHelper';
import { email } from '@vuelidate/validators';

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
  });
});
