import {
  extractPlainTextFromHtml,
  getEmailSenderName,
  getEmailSenderEmail,
  getEmailDate,
  formatQuotedEmailDate,
  getInboxEmail,
  buildQuotedEmailHeader,
  buildQuotedEmailHeaderFromContact,
  buildQuotedEmailHeaderFromInbox,
  formatQuotedTextAsBlockquote,
  extractQuotedEmailText,
  truncatePreviewText,
  appendQuotedTextToMessage,
} from '../quotedEmailHelper';

describe('quotedEmailHelper', () => {
  describe('extractPlainTextFromHtml', () => {
    it('returns empty string for null or undefined', () => {
      expect(extractPlainTextFromHtml(null)).toBe('');
      expect(extractPlainTextFromHtml(undefined)).toBe('');
    });

    it('strips HTML tags and returns plain text', () => {
      const html = '<p>Hello <strong>world</strong></p>';
      const result = extractPlainTextFromHtml(html);
      expect(result).toBe('Hello world');
    });

    it('handles complex HTML structure', () => {
      const html = '<div><p>Line 1</p><p>Line 2</p></div>';
      const result = extractPlainTextFromHtml(html);
      expect(result).toContain('Line 1');
      expect(result).toContain('Line 2');
    });

    it('sanitizes onerror handlers from img tags', () => {
      const html = '<p>Hello</p><img src="x" onerror="alert(1)">';
      const result = extractPlainTextFromHtml(html);
      expect(result).toBe('Hello');
    });

    it('sanitizes script tags', () => {
      const html = '<p>Safe</p><script>alert(1)</script><p>Content</p>';
      const result = extractPlainTextFromHtml(html);
      expect(result).toContain('Safe');
      expect(result).toContain('Content');
      expect(result).not.toContain('alert');
    });

    it('sanitizes onclick handlers', () => {
      const html = '<p onclick="alert(1)">Click me</p>';
      const result = extractPlainTextFromHtml(html);
      expect(result).toBe('Click me');
    });
  });

  describe('getEmailSenderName', () => {
    it('returns sender name from lastEmail', () => {
      const lastEmail = { sender: { name: 'John Doe' } };
      const result = getEmailSenderName(lastEmail, {});
      expect(result).toBe('John Doe');
    });

    it('returns contact name if sender name not available', () => {
      const lastEmail = { sender: {} };
      const contact = { name: 'Jane Smith' };
      const result = getEmailSenderName(lastEmail, contact);
      expect(result).toBe('Jane Smith');
    });

    it('returns empty string if neither available', () => {
      const result = getEmailSenderName({}, {});
      expect(result).toBe('');
    });

    it('trims whitespace from names', () => {
      const lastEmail = { sender: { name: '  John Doe  ' } };
      const result = getEmailSenderName(lastEmail, {});
      expect(result).toBe('John Doe');
    });
  });

  describe('getEmailSenderEmail', () => {
    it('returns sender email from lastEmail', () => {
      const lastEmail = { sender: { email: 'john@example.com' } };
      const result = getEmailSenderEmail(lastEmail, {});
      expect(result).toBe('john@example.com');
    });

    it('returns email from contentAttributes if sender email not available', () => {
      const lastEmail = {
        contentAttributes: {
          email: { from: ['jane@example.com'] },
        },
      };
      const result = getEmailSenderEmail(lastEmail, {});
      expect(result).toBe('jane@example.com');
    });

    it('returns contact email as fallback', () => {
      const lastEmail = {};
      const contact = { email: 'contact@example.com' };
      const result = getEmailSenderEmail(lastEmail, contact);
      expect(result).toBe('contact@example.com');
    });

    it('trims whitespace from emails', () => {
      const lastEmail = { sender: { email: '  john@example.com  ' } };
      const result = getEmailSenderEmail(lastEmail, {});
      expect(result).toBe('john@example.com');
    });
  });

  describe('getEmailDate', () => {
    it('returns parsed date from email metadata', () => {
      const lastEmail = {
        contentAttributes: {
          email: { date: '2024-01-15T10:30:00Z' },
        },
      };
      const result = getEmailDate(lastEmail);
      expect(result).toBeInstanceOf(Date);
    });

    it('returns date from created_at timestamp', () => {
      const lastEmail = { created_at: 1705318200 };
      const result = getEmailDate(lastEmail);
      expect(result).toBeInstanceOf(Date);
    });

    it('handles millisecond timestamps', () => {
      const lastEmail = { created_at: 1705318200000 };
      const result = getEmailDate(lastEmail);
      expect(result).toBeInstanceOf(Date);
    });

    it('returns null if no valid date found', () => {
      const result = getEmailDate({});
      expect(result).toBeNull();
    });
  });

  describe('formatQuotedEmailDate', () => {
    it('formats date correctly', () => {
      const date = new Date('2024-01-15T10:30:00Z');
      const result = formatQuotedEmailDate(date);
      expect(result).toMatch(/Mon, Jan 15, 2024 at/);
    });

    it('returns empty string for invalid date', () => {
      const result = formatQuotedEmailDate('invalid');
      expect(result).toBe('');
    });
  });

  describe('getInboxEmail', () => {
    it('returns email from contentAttributes.email.to', () => {
      const lastEmail = {
        contentAttributes: {
          email: { to: ['inbox@example.com'] },
        },
      };
      const result = getInboxEmail(lastEmail, {});
      expect(result).toBe('inbox@example.com');
    });

    it('returns inbox email as fallback', () => {
      const lastEmail = {};
      const inbox = { email: 'support@example.com' };
      const result = getInboxEmail(lastEmail, inbox);
      expect(result).toBe('support@example.com');
    });

    it('returns empty string if no email found', () => {
      expect(getInboxEmail({}, {})).toBe('');
    });

    it('trims whitespace from emails', () => {
      const lastEmail = {
        contentAttributes: {
          email: { to: ['  inbox@example.com  '] },
        },
      };
      const result = getInboxEmail(lastEmail, {});
      expect(result).toBe('inbox@example.com');
    });
  });

  describe('buildQuotedEmailHeaderFromContact', () => {
    it('builds complete header with name and email', () => {
      const lastEmail = {
        sender: { name: 'John Doe', email: 'john@example.com' },
        contentAttributes: {
          email: { date: '2024-01-15T10:30:00Z' },
        },
      };
      const result = buildQuotedEmailHeaderFromContact(lastEmail, {});
      expect(result).toContain('John Doe');
      expect(result).toContain('john@example.com');
      expect(result).toContain('wrote:');
    });

    it('builds header without name if not available', () => {
      const lastEmail = {
        sender: { email: 'john@example.com' },
        contentAttributes: {
          email: { date: '2024-01-15T10:30:00Z' },
        },
      };
      const result = buildQuotedEmailHeaderFromContact(lastEmail, {});
      expect(result).toContain('<john@example.com>');
      expect(result).not.toContain('undefined');
    });

    it('returns empty string if missing required data', () => {
      expect(buildQuotedEmailHeaderFromContact(null, {})).toBe('');
      expect(buildQuotedEmailHeaderFromContact({}, {})).toBe('');
    });
  });

  describe('buildQuotedEmailHeaderFromInbox', () => {
    it('builds complete header with inbox name and email', () => {
      const lastEmail = {
        contentAttributes: {
          email: {
            date: '2024-01-15T10:30:00Z',
            to: ['support@example.com'],
          },
        },
      };
      const inbox = { name: 'Support Team', email: 'support@example.com' };
      const result = buildQuotedEmailHeaderFromInbox(lastEmail, inbox);
      expect(result).toContain('Support Team');
      expect(result).toContain('support@example.com');
      expect(result).toContain('wrote:');
    });

    it('builds header without name if not available', () => {
      const lastEmail = {
        contentAttributes: {
          email: {
            date: '2024-01-15T10:30:00Z',
            to: ['inbox@example.com'],
          },
        },
      };
      const inbox = { email: 'inbox@example.com' };
      const result = buildQuotedEmailHeaderFromInbox(lastEmail, inbox);
      expect(result).toContain('<inbox@example.com>');
      expect(result).not.toContain('undefined');
    });

    it('returns empty string if missing required data', () => {
      expect(buildQuotedEmailHeaderFromInbox(null, {})).toBe('');
      expect(buildQuotedEmailHeaderFromInbox({}, {})).toBe('');
    });
  });

  describe('buildQuotedEmailHeader', () => {
    it('uses inbox email for outgoing messages (message_type: 1)', () => {
      const lastEmail = {
        message_type: 1,
        contentAttributes: {
          email: {
            date: '2024-01-15T10:30:00Z',
            to: ['support@example.com'],
          },
        },
      };
      const inbox = { name: 'Support', email: 'support@example.com' };
      const contact = { name: 'John Doe', email: 'john@example.com' };
      const result = buildQuotedEmailHeader(lastEmail, contact, inbox);
      expect(result).toContain('Support');
      expect(result).toContain('support@example.com');
      expect(result).not.toContain('John Doe');
    });

    it('uses contact email for incoming messages (message_type: 0)', () => {
      const lastEmail = {
        message_type: 0,
        sender: { name: 'Jane Smith', email: 'jane@example.com' },
        contentAttributes: {
          email: { date: '2024-01-15T10:30:00Z' },
        },
      };
      const inbox = { name: 'Support', email: 'support@example.com' };
      const contact = { name: 'Jane Smith', email: 'jane@example.com' };
      const result = buildQuotedEmailHeader(lastEmail, contact, inbox);
      expect(result).toContain('Jane Smith');
      expect(result).toContain('jane@example.com');
      expect(result).not.toContain('Support');
    });

    it('returns empty string if missing required data', () => {
      expect(buildQuotedEmailHeader(null, {}, {})).toBe('');
      expect(buildQuotedEmailHeader({}, {}, {})).toBe('');
    });
  });

  describe('formatQuotedTextAsBlockquote', () => {
    it('formats single line text', () => {
      const result = formatQuotedTextAsBlockquote('Hello world');
      expect(result).toBe('> Hello world');
    });

    it('formats multi-line text', () => {
      const text = 'Line 1\nLine 2\nLine 3';
      const result = formatQuotedTextAsBlockquote(text);
      expect(result).toBe('> Line 1\n> Line 2\n> Line 3');
    });

    it('includes header if provided', () => {
      const result = formatQuotedTextAsBlockquote('Hello', 'Header text');
      expect(result).toContain('> Header text');
      expect(result).toContain('>\n> Hello');
    });

    it('handles empty lines correctly', () => {
      const text = 'Line 1\n\nLine 3';
      const result = formatQuotedTextAsBlockquote(text);
      expect(result).toBe('> Line 1\n>\n> Line 3');
    });

    it('returns empty string for empty input', () => {
      expect(formatQuotedTextAsBlockquote('')).toBe('');
      expect(formatQuotedTextAsBlockquote('', '')).toBe('');
    });

    it('handles Windows line endings', () => {
      const text = 'Line 1\r\nLine 2';
      const result = formatQuotedTextAsBlockquote(text);
      expect(result).toBe('> Line 1\n> Line 2');
    });
  });

  describe('extractQuotedEmailText', () => {
    it('extracts text from textContent.reply', () => {
      const lastEmail = {
        contentAttributes: {
          email: { textContent: { reply: 'Reply text' } },
        },
      };
      const result = extractQuotedEmailText(lastEmail);
      expect(result).toBe('Reply text');
    });

    it('falls back to textContent.full', () => {
      const lastEmail = {
        contentAttributes: {
          email: { textContent: { full: 'Full text' } },
        },
      };
      const result = extractQuotedEmailText(lastEmail);
      expect(result).toBe('Full text');
    });

    it('extracts from htmlContent and converts to plain text', () => {
      const lastEmail = {
        contentAttributes: {
          email: { htmlContent: { reply: '<p>HTML reply</p>' } },
        },
      };
      const result = extractQuotedEmailText(lastEmail);
      expect(result).toBe('HTML reply');
    });

    it('uses fallback content if structured content not available', () => {
      const lastEmail = { content: 'Fallback content' };
      const result = extractQuotedEmailText(lastEmail);
      expect(result).toBe('Fallback content');
    });

    it('returns empty string for null or missing email', () => {
      expect(extractQuotedEmailText(null)).toBe('');
      expect(extractQuotedEmailText({})).toBe('');
    });
  });

  describe('truncatePreviewText', () => {
    it('returns full text if under max length', () => {
      const text = 'Short text';
      const result = truncatePreviewText(text, 80);
      expect(result).toBe('Short text');
    });

    it('truncates text exceeding max length', () => {
      const text = 'A'.repeat(100);
      const result = truncatePreviewText(text, 80);
      expect(result).toHaveLength(80);
      expect(result).toContain('...');
    });

    it('collapses multiple spaces', () => {
      const text = 'Text   with    spaces';
      const result = truncatePreviewText(text);
      expect(result).toBe('Text with spaces');
    });

    it('trims whitespace', () => {
      const text = '  Text with spaces  ';
      const result = truncatePreviewText(text);
      expect(result).toBe('Text with spaces');
    });

    it('returns empty string for empty input', () => {
      expect(truncatePreviewText('')).toBe('');
      expect(truncatePreviewText('   ')).toBe('');
    });

    it('uses default max length of 80', () => {
      const text = 'A'.repeat(100);
      const result = truncatePreviewText(text);
      expect(result).toHaveLength(80);
    });
  });

  describe('appendQuotedTextToMessage', () => {
    it('appends quoted text to message', () => {
      const message = 'My reply';
      const quotedText = 'Original message';
      const header = 'On date sender wrote:';
      const result = appendQuotedTextToMessage(message, quotedText, header);

      expect(result).toContain('My reply');
      expect(result).toContain('> On date sender wrote:');
      expect(result).toContain('> Original message');
    });

    it('returns only quoted text if message is empty', () => {
      const result = appendQuotedTextToMessage('', 'Quoted', 'Header');
      expect(result).toContain('> Header');
      expect(result).toContain('> Quoted');
      expect(result).not.toContain('\n\n\n');
    });

    it('returns message if no quoted text', () => {
      const result = appendQuotedTextToMessage('Message', '', '');
      expect(result).toBe('Message');
    });

    it('handles proper spacing with double newline', () => {
      const result = appendQuotedTextToMessage('Message', 'Quoted', 'Header');
      expect(result).toContain('Message\n\n>');
    });

    it('does not add extra newlines if message already ends with newlines', () => {
      const result = appendQuotedTextToMessage(
        'Message\n\n',
        'Quoted',
        'Header'
      );
      expect(result).not.toContain('\n\n\n');
    });

    it('adds single newline if message ends with one newline', () => {
      const result = appendQuotedTextToMessage('Message\n', 'Quoted', 'Header');
      expect(result).toContain('Message\n\n>');
    });
  });
});
