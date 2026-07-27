import { useI18n } from 'vue-i18n';

export const formatBusinessRuleError = (message, t) => {
  if (!message || typeof message !== 'string') return null;

  const text = message.replace(/^Status\s+/i, '').trim();
  const missingAttr = text.match(/missing_attribute:(\S+)/);
  if (missingAttr) {
    return t('BUSINESS_RULES.STATUS_ERRORS.missing_attribute', {
      key: missingAttr[1],
    });
  }
  const missingReason = text.match(/missing_reason_attribute:(\S+)/);
  if (missingReason) {
    return t('BUSINESS_RULES.STATUS_ERRORS.missing_reason_attribute', {
      key: missingReason[1],
    });
  }
  if (text.includes('missing_private_note')) {
    return t('BUSINESS_RULES.STATUS_ERRORS.missing_private_note');
  }
  const forbidden = text.match(/forbidden_label:(\S+)/);
  if (forbidden) {
    return t('BUSINESS_RULES.STATUS_ERRORS.forbidden_label', {
      label: forbidden[1],
    });
  }
  if (text.includes('missing_assignee')) {
    return t('BUSINESS_RULES.STATUS_ERRORS.missing_assignee');
  }
  if (
    /missing_attribute|missing_reason|forbidden_label|missing_assignee|missing_private_note/.test(
      text
    )
  ) {
    return t('BUSINESS_RULES.STATUS_ERRORS.generic');
  }
  return text;
};

export function useFormatBusinessRuleError() {
  const { t } = useI18n();
  return message => formatBusinessRuleError(message, t);
}
