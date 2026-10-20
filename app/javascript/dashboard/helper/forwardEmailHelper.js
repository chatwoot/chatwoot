import { escapeHtml } from 'shared/helpers/HTMLSanitizer';

const mailtoLink = email =>
  `&lt;<a href="mailto:${escapeHtml(email)}">${escapeHtml(email)}</a>&gt;`;

const addressHtml = ({ name, email }) =>
  name ? `<b>${escapeHtml(name)}</b> ${mailtoLink(email)}` : mailtoLink(email);

export const textToHtml = text => escapeHtml(text).replace(/\n/g, '<br>');

export const buildForwardedEmailHtml = ({
  labels,
  sender,
  date,
  subject,
  recipients,
  bodyHtml,
}) => {
  const header = [
    labels.title,
    `${labels.from}: ${addressHtml(sender)}`,
    `${labels.date}: ${escapeHtml(date)}`,
    `${labels.subject}: ${escapeHtml(subject)}`,
    `${labels.to}: ${recipients.map(mailtoLink).join(', ')}`,
  ].join('<br>');

  return `<div class="chatwoot_forward_header">${header}</div><br>${bodyHtml}`;
};
