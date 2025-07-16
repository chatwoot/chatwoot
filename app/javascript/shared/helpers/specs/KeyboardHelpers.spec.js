import {
  isEnter,
  isEscape,
  hasPressedShift,
  hasPressedCommand,
  buildHotKeys,
  isActiveElementTypeable,
} from '../KeyboardHelpers';

describe('#KeyboardHelpers', () => {
  describe('#isEnter', () => {
    it('return correct values', () => {
      expect(isEnter({ keyCode: 13 })).toEqual(true);
    });
  });

  describe('#isEscape', () => {
    it('return correct values', () => {
      expect(isEscape({ keyCode: 27 })).toEqual(true);
    });
  });

  describe('#hasPressedShift', () => {
    it('return correct values', () => {
      expect(hasPressedShift({ shiftKey: true })).toEqual(true);
    });
  });

  describe('#hasPressedCommand', () => {
    it('return correct values', () => {
      expect(hasPressedCommand({ metaKey: true })).toEqual(true);
    });
  });

  describe('#buildHotKeys', () => {
    it('returns hot keys', () => {
      expect(buildHotKeys({ altKey: true, key: 'alt' })).toEqual('alt');
      expect(buildHotKeys({ ctrlKey: true, key: 'a' })).toEqual('ctrl+a');
      expect(buildHotKeys({ metaKey: true, key: 'b' })).toEqual('meta+b');
    });
  });
});

describe('isActiveElementTypeable', () => {
  it('should return true if the active element is an input element', () => {
    const event = { target: document.createElement('input') };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(true);
  });

  it('should return true if the active element is a textarea element', () => {
    const event = { target: document.createElement('textarea') };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(true);
  });

  it('should return true if the active element is a contentEditable element', () => {
    const element = document.createElement('div');
    element.contentEditable = 'true';
    const event = { target: element };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(true);
  });

  it('should return false if the active element is not typeable', () => {
    const event = { target: document.createElement('div') };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(false);
  });

  it('should return false if the active element is null', () => {
    const event = { target: null };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(false);
  });
});
