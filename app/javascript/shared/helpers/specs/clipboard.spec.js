import { copyTextToClipboard } from '../clipboard';

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
