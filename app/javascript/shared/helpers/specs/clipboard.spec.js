import { copyTextToClipboard, handleOtpPaste } from '../clipboard';

const mockWriteText = vi.fn();
Object.assign(navigator, {
  clipboard: {
    writeText: mockWriteText,
  },
});

describe('copyTextToClipboard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('with string input', () => {
    it('copies plain text string to clipboard', async () => {
      const text = 'Hello World';
      await copyTextToClipboard(text);

      expect(mockWriteText).toHaveBeenCalledWith('Hello World');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('copies empty string to clipboard', async () => {
      const text = '';
      await copyTextToClipboard(text);

      expect(mockWriteText).toHaveBeenCalledWith('');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });
  });

  describe('with number input', () => {
    it('converts number to string', async () => {
      await copyTextToClipboard(42);

      expect(mockWriteText).toHaveBeenCalledWith('42');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('converts zero to string', async () => {
      await copyTextToClipboard(0);

      expect(mockWriteText).toHaveBeenCalledWith('0');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });
  });

  describe('with boolean input', () => {
    it('converts true to string', async () => {
      await copyTextToClipboard(true);

      expect(mockWriteText).toHaveBeenCalledWith('true');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('converts false to string', async () => {
      await copyTextToClipboard(false);

      expect(mockWriteText).toHaveBeenCalledWith('false');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });
  });

  describe('with null/undefined input', () => {
    it('converts null to empty string', async () => {
      await copyTextToClipboard(null);

      expect(mockWriteText).toHaveBeenCalledWith('');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('converts undefined to empty string', async () => {
      await copyTextToClipboard(undefined);

      expect(mockWriteText).toHaveBeenCalledWith('');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });
  });

  describe('with object input', () => {
    it('stringifies simple object with proper formatting', async () => {
      const obj = { name: 'John', age: 30 };
      await copyTextToClipboard(obj);

      const expectedJson = JSON.stringify(obj, null, 2);
      expect(mockWriteText).toHaveBeenCalledWith(expectedJson);
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('stringifies nested object with proper formatting', async () => {
      const nestedObj = {
        severity: {
          user_id: 1181505,
          user_name: 'test',
          server_name: '[1253]test1253',
        },
      };
      await copyTextToClipboard(nestedObj);

      const expectedJson = JSON.stringify(nestedObj, null, 2);
      expect(mockWriteText).toHaveBeenCalledWith(expectedJson);
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('stringifies array with proper formatting', async () => {
      const arr = [1, 2, { name: 'test' }];
      await copyTextToClipboard(arr);

      const expectedJson = JSON.stringify(arr, null, 2);
      expect(mockWriteText).toHaveBeenCalledWith(expectedJson);
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('stringifies empty object', async () => {
      const obj = {};
      await copyTextToClipboard(obj);

      expect(mockWriteText).toHaveBeenCalledWith('{}');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('stringifies empty array', async () => {
      const arr = [];
      await copyTextToClipboard(arr);

      expect(mockWriteText).toHaveBeenCalledWith('[]');
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });
  });

  describe('error handling', () => {
    it('throws error when clipboard API fails', async () => {
      const error = new Error('Clipboard access denied');
      mockWriteText.mockRejectedValueOnce(error);

      await expect(copyTextToClipboard('test')).rejects.toThrow(
        'Unable to copy text to clipboard: Clipboard access denied'
      );
    });

    it('handles clipboard API not available', async () => {
      // Temporarily remove clipboard API
      const originalClipboard = navigator.clipboard;
      delete navigator.clipboard;

      await expect(copyTextToClipboard('test')).rejects.toThrow(
        'Unable to copy text to clipboard:'
      );

      // Restore clipboard API
      navigator.clipboard = originalClipboard;
    });
  });

  describe('edge cases', () => {
    it('handles Date objects', async () => {
      const date = new Date('2023-01-01T00:00:00.000Z');
      await copyTextToClipboard(date);

      const expectedJson = JSON.stringify(date, null, 2);
      expect(mockWriteText).toHaveBeenCalledWith(expectedJson);
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });

    it('handles functions by converting to string', async () => {
      const func = () => 'test';
      await copyTextToClipboard(func);

      expect(mockWriteText).toHaveBeenCalledWith(func.toString());
      expect(mockWriteText).toHaveBeenCalledTimes(1);
    });
  });
});

describe('handleOtpPaste', () => {
  // Helper function to create mock clipboard event
  const createMockPasteEvent = text => ({
    clipboardData: {
      getData: vi.fn().mockReturnValue(text),
    },
  });

  describe('valid OTP paste scenarios', () => {
    it('extracts 6-digit OTP from clean numeric string', () => {
      const event = createMockPasteEvent('123456');
      const result = handleOtpPaste(event);

      expect(result).toBe('123456');
      expect(event.clipboardData.getData).toHaveBeenCalledWith('text');
    });

    it('extracts 6-digit OTP from string with spaces', () => {
      const event = createMockPasteEvent('1 2 3 4 5 6');
      const result = handleOtpPaste(event);

      expect(result).toBe('123456');
    });

    it('extracts 6-digit OTP from string with dashes', () => {
      const event = createMockPasteEvent('123-456');
      const result = handleOtpPaste(event);

      expect(result).toBe('123456');
    });

    it('handles negative numbers by extracting digits only', () => {
      const event = createMockPasteEvent('-123456');
      const result = handleOtpPaste(event);

      expect(result).toBe('123456');
    });

    it('handles decimal numbers by extracting digits only', () => {
      const event = createMockPasteEvent('123.456');
      const result = handleOtpPaste(event);

      expect(result).toBe('123456');
    });

    it('extracts 6-digit OTP from mixed alphanumeric string', () => {
      const event = createMockPasteEvent('Your code is: 987654');
      const result = handleOtpPaste(event);

      expect(result).toBe('987654');
    });

    it('extracts first 6 digits when more than 6 digits present', () => {
      const event = createMockPasteEvent('12345678901234');
      const result = handleOtpPaste(event);

      expect(result).toBe('123456');
    });

    it('handles custom maxLength parameter', () => {
      const event = createMockPasteEvent('12345678');
      const result = handleOtpPaste(event, 8);

      expect(result).toBe('12345678');
    });

    it('extracts 4-digit OTP with custom maxLength', () => {
      const event = createMockPasteEvent('Your PIN: 9876');
      const result = handleOtpPaste(event, 4);

      expect(result).toBe('9876');
    });
  });

  describe('invalid OTP paste scenarios', () => {
    it('returns null for insufficient digits', () => {
      const event = createMockPasteEvent('12345');
      const result = handleOtpPaste(event);

      expect(result).toBeNull();
    });

    it('returns null for text with no digits', () => {
      const event = createMockPasteEvent('Hello World');
      const result = handleOtpPaste(event);

      expect(result).toBeNull();
    });

    it('returns null for empty string', () => {
      const event = createMockPasteEvent('');
      const result = handleOtpPaste(event);

      expect(result).toBeNull();
    });

    it('returns null when event is null', () => {
      const result = handleOtpPaste(null);

      expect(result).toBeNull();
    });

    it('returns null when event is undefined', () => {
      const result = handleOtpPaste(undefined);

      expect(result).toBeNull();
    });
  });
});
