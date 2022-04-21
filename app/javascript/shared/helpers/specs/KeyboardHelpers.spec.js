import {
  isEnter,
  isEscape,
  hasPressedShift,
  hasPressedCommand,
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
});
