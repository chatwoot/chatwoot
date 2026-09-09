import { format, parseISO, isValid as isValidDate } from 'date-fns';
import DOMPurify from 'dompurify';

const NON_CONTENT_TAGS = new Set(['STYLE', 'SCRIPT', 'HEAD', 'TITLE']);
const BLOCK_TAGS = new Set([
  'ADDRESS',
  'ARTICLE',
  'ASIDE',
  'BLOCKQUOTE',
  'DD',
  'DIV',
  'DL',
  'DT',
  'FIELDSET',
  'FIGCAPTION',
  'FIGURE',
  'FOOTER',
  'H1',
  'H2',
  'H3',
  'H4',
  'H5',
  'H6',
  'HEADER',
  'HR',
  'LI',
  'MAIN',
  'NAV',
  'OL',
  'P',
  'PRE',
  'SECTION',
  'TABLE',
  'TR',
  'UL',
]);
const TABLE_CELL_TAGS = new Set(['TD', 'TH']);

const textFromNode = node => {
  if (node.nodeType === Node.TEXT_NODE) {
    return node.textContent;
  }
  if (
    node.nodeType !== Node.ELEMENT_NODE ||
    NON_CONTENT_TAGS.has(node.nodeName)
  ) {
    return '';
  }
  if (node.nodeName === 'BR') {
    return '\n';
  }

  const childText = [...node.childNodes].map(textFromNode).join('');
  if (BLOCK_TAGS.has(node.nodeName)) {
    return `${childText}\n`;
  }
  if (TABLE_CELL_TAGS.has(node.nodeName)) {
    return `${childText} `;
  }
  return childText;
};

/**
 * Extracts plain text from HTML content, keeping line breaks at block
 * boundaries so adjacent blocks don't run together in the quoted text.
 * @param {string} html - HTML content to convert
 * @returns {string} Plain text content
 */
export const extractPlainTextFromHtml = html => {
  if (!html) {
    return '';
  }
  if (typeof document === 'undefined') {
    return html.replace(/<[^>]*>/g, ' ');
  }
  const tempDiv = document.createElement('div');
  tempDiv.innerHTML = DOMPurify.sanitize(html);
  return textFromNode(tempDiv)
    .replace(/\n{3,}/g, '\n\n')
    .trim();
};

/**
 * Extracts sender name from email message
 * @param {Object} lastEmail - Last email message object
 * @param {Object} contact - Contact object
 * @returns {string} Sender name
 */
export const getEmailSenderName = (lastEmail, contact) => {
  const senderName = lastEmail?.sender?.name;
  if (senderName && senderName.trim()) {
    return senderName.trim();
  }

  const contactName = contact?.name;
  return contactName && contactName.trim() ? contactName.trim() : '';
};

/**
 * Extracts sender email from email message
 * @param {Object} lastEmail - Last email message object
 * @param {Object} contact - Contact object
 * @returns {string} Sender email address
 */
export const getEmailSenderEmail = (lastEmail, contact) => {
  const senderEmail = lastEmail?.sender?.email;
  if (senderEmail && senderEmail.trim()) {
    return senderEmail.trim();
  }

  const contentAttributes =
    lastEmail?.contentAttributes || lastEmail?.content_attributes || {};
  const emailMeta = contentAttributes.email || {};

  if (Array.isArray(emailMeta.from) && emailMeta.from.length > 0) {
    const fromAddress = emailMeta.from[0];
    if (fromAddress && fromAddress.trim()) {
      return fromAddress.trim();
    }
  }

  const contactEmail = contact?.email;
  return contactEmail && contactEmail.trim() ? contactEmail.trim() : '';
};

/**
 * Extracts date from email message
 * @param {Object} lastEmail - Last email message object
 * @returns {Date|null} Email date
 */
export const getEmailDate = lastEmail => {
  const contentAttributes =
    lastEmail?.contentAttributes || lastEmail?.content_attributes || {};
  const emailMeta = contentAttributes.email || {};

  if (emailMeta.date) {
    const parsedDate = parseISO(emailMeta.date);
    if (isValidDate(parsedDate)) {
      return parsedDate;
    }
  }

  const createdAt = lastEmail?.created_at;
  if (createdAt) {
    const timestamp = Number(createdAt);
    if (!Number.isNaN(timestamp)) {
      const milliseconds = timestamp > 1e12 ? timestamp : timestamp * 1000;
      const derivedDate = new Date(milliseconds);
      if (!Number.isNaN(derivedDate.getTime())) {
        return derivedDate;
      }
    }
  }

  return null;
};

/**
 * Formats date for quoted email header
 * @param {Date} date - Date to format
 * @returns {string} Formatted date string
 */
export const formatQuotedEmailDate = date => {
  try {
    return format(date, "EEE, MMM d, yyyy 'at' p");
  } catch (error) {
    const fallbackDate = new Date(date);
    if (!Number.isNaN(fallbackDate.getTime())) {
      return format(fallbackDate, "EEE, MMM d, yyyy 'at' p");
    }
  }

  return '';
};

/**
 * Extracts inbox email address from last email message
 * @param {Object} lastEmail - Last email message object
 * @param {Object} inbox - Inbox object
 * @returns {string} Inbox email address
 */
export const getInboxEmail = (lastEmail, inbox) => {
  const contentAttributes =
    lastEmail?.contentAttributes || lastEmail?.content_attributes || {};
  const emailMeta = contentAttributes.email || {};

  if (Array.isArray(emailMeta.to) && emailMeta.to.length > 0) {
    const toAddress = emailMeta.to[0];
    if (toAddress && toAddress.trim()) {
      return toAddress.trim();
    }
  }

  const inboxEmail = inbox?.email;
  return inboxEmail && inboxEmail.trim() ? inboxEmail.trim() : '';
};

/**
 * Builds quoted email header from contact (for incoming messages)
 * @param {Object} lastEmail - Last email message object
 * @param {Object} contact - Contact object
 * @returns {string} Formatted header string
 */
export const buildQuotedEmailHeaderFromContact = (lastEmail, contact) => {
  if (!lastEmail) {
    return '';
  }

  const quotedDate = getEmailDate(lastEmail);
  const senderEmail = getEmailSenderEmail(lastEmail, contact);

  if (!quotedDate || !senderEmail) {
    return '';
  }

  const formattedDate = formatQuotedEmailDate(quotedDate);
  if (!formattedDate) {
    return '';
  }

  const senderName = getEmailSenderName(lastEmail, contact);
  const hasName = !!senderName;
  const contactLabel = hasName
    ? `${senderName} <${senderEmail}>`
    : `<${senderEmail}>`;

  return `On ${formattedDate} ${contactLabel} wrote:`;
};

/**
 * Builds quoted email header from inbox (for outgoing messages)
 * @param {Object} lastEmail - Last email message object
 * @param {Object} inbox - Inbox object
 * @returns {string} Formatted header string
 */
export const buildQuotedEmailHeaderFromInbox = (lastEmail, inbox) => {
  if (!lastEmail) {
    return '';
  }

  const quotedDate = getEmailDate(lastEmail);
  const inboxEmail = getInboxEmail(lastEmail, inbox);

  if (!quotedDate || !inboxEmail) {
    return '';
  }

  const formattedDate = formatQuotedEmailDate(quotedDate);
  if (!formattedDate) {
    return '';
  }

  const inboxName = inbox?.name;
  const hasName = !!inboxName;
  const inboxLabel = hasName
    ? `${inboxName} <${inboxEmail}>`
    : `<${inboxEmail}>`;

  return `On ${formattedDate} ${inboxLabel} wrote:`;
};

/**
 * Builds quoted email header based on message type
 * @param {Object} lastEmail - Last email message object
 * @param {Object} contact - Contact object
 * @param {Object} inbox - Inbox object
 * @returns {string} Formatted header string
 */
export const buildQuotedEmailHeader = (lastEmail, contact, inbox) => {
  if (!lastEmail) {
    return '';
  }

  // MESSAGE_TYPE.OUTGOING = 1, MESSAGE_TYPE.INCOMING = 0
  const isOutgoing = lastEmail.message_type === 1;

  if (isOutgoing) {
    return buildQuotedEmailHeaderFromInbox(lastEmail, inbox);
  }

  return buildQuotedEmailHeaderFromContact(lastEmail, contact);
};

/**
 * Formats text as markdown blockquote
 * @param {string} text - Text to format
 * @param {string} header - Optional header to prepend
 * @returns {string} Formatted blockquote
 */
export const formatQuotedTextAsBlockquote = (text, header = '') => {
  const normalizedLines = text
    ? String(text).replace(/\r\n/g, '\n').split('\n')
    : [];

  if (!header && !normalizedLines.length) {
    return '';
  }

  const quotedLines = [];

  if (header) {
    quotedLines.push(`> ${header}`);
    quotedLines.push('>');
  }

  normalizedLines.forEach(line => {
    const trimmedLine = line.trimEnd();
    quotedLines.push(trimmedLine ? `> ${trimmedLine}` : '>');
  });

  return quotedLines.join('\n');
};

/**
 * Extracts quoted email text from last email message.
 * Prefers the full content over the trimmed reply so the quoted thread
 * carries the entire history, matching regular email client behavior.
 * @param {Object} lastEmail - Last email message object
 * @returns {string} Quoted email text
 */
export const extractQuotedEmailText = lastEmail => {
  if (!lastEmail) {
    return '';
  }

  const contentAttributes =
    lastEmail.contentAttributes || lastEmail.content_attributes || {};
  const emailContent = contentAttributes.email || {};
  const textContent = emailContent.textContent || emailContent.text_content;

  if (textContent?.full) {
    return textContent.full;
  }
  if (textContent?.reply) {
    return textContent.reply;
  }

  const htmlContent = emailContent.htmlContent || emailContent.html_content;
  if (htmlContent?.full) {
    return extractPlainTextFromHtml(htmlContent.full);
  }
  if (htmlContent?.reply) {
    return extractPlainTextFromHtml(htmlContent.reply);
  }

  const fallbackContent =
    lastEmail.content || lastEmail.processed_message_content || '';

  return fallbackContent;
};

// Keep in sync with the content length validation on Message (app/models/message.rb).
const MAX_MESSAGE_CONTENT_LENGTH = 150000;

// Outgoing content is rendered through Liquid on the server
// (app/models/concerns/liquidable.rb); emit quoted {{ and {% tokens as
// literals so customer-supplied expressions are never evaluated.
const escapeLiquidTokens = text => text.replace(/\{[{%]/g, "{{ '$&' }}");

const fitQuotedBlockWithinLimit = (quotedBlock, available) => {
  if (quotedBlock.length <= available) {
    return quotedBlock;
  }

  // Keep whole lines from the top — the oldest history sits at the bottom.
  const kept = [];
  let length = 0;
  quotedBlock.split('\n').every(line => {
    const nextLength = length + line.length + (kept.length ? 1 : 0);
    if (nextLength > available) {
      return false;
    }
    kept.push(line);
    length = nextLength;
    return true;
  });
  return kept.join('\n');
};

/**
 * Appends quoted text to message, truncating the quote so the combined
 * content stays within the server-side message length limit.
 * @param {string} message - Original message
 * @param {string} quotedText - Text to quote
 * @param {string} header - Quote header
 * @returns {string} Message with quoted text appended
 */
export const appendQuotedTextToMessage = (message, quotedText, header) => {
  const baseMessage = message ? String(message) : '';
  let quotedBlock = formatQuotedTextAsBlockquote(quotedText, header);

  if (!quotedBlock) {
    return baseMessage;
  }
  quotedBlock = escapeLiquidTokens(quotedBlock);

  let separator = '\n\n';
  if (!baseMessage || baseMessage.endsWith('\n\n')) {
    separator = '';
  } else if (baseMessage.endsWith('\n')) {
    separator = '\n';
  }

  quotedBlock = fitQuotedBlockWithinLimit(
    quotedBlock,
    MAX_MESSAGE_CONTENT_LENGTH - baseMessage.length - separator.length
  );
  if (!quotedBlock) {
    return baseMessage;
  }

  return `${baseMessage}${separator}${quotedBlock}`;
};
