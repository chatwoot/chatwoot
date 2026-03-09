import { useLocale } from './useLocale';

/**
 * Composable for number formatting with i18n locale support
 * Provides methods to format numbers in compact and full display formats
 */
export function useNumberFormatter() {
  const { resolvedLocale } = useLocale();

  /**
   * Formats numbers for display with clean, minimal formatting
   * - Up to 1,000: show exact number (e.g., 999)
   * - 1,000 to 999,999: show as "Xk" for exact thousands or "Xk+" for remainder (e.g., 1000 → "1k", 1500 → "1k+")
   * - 1,000,000+: show in millions with 1 decimal place (e.g., 1,234,000 → "1.2M")
   *
   * Uses browser-native Intl.NumberFormat with proper i18n locale support
   *
   * @param {number} num - The number to format
   * @returns {string} Formatted number string
   */
  const formatCompactNumber = num => {
    if (typeof num !== 'number' || Number.isNaN(num)) {
      return '0';
    }

    // For numbers between -1000 and 1000 (exclusive), show exact number with locale formatting
    if (Math.abs(num) < 1000) {
      return new Intl.NumberFormat(resolvedLocale.value).format(num);
    }

    // For numbers with absolute value above 1,000,000, show in millions with 1 decimal place
    if (Math.abs(num) >= 1000000) {
      const millions = num / 1000000;
      return new Intl.NumberFormat(resolvedLocale.value, {
        notation: 'compact',
        compactDisplay: 'short',
        maximumFractionDigits: 1,
        minimumFractionDigits: millions % 1 === 0 ? 0 : 1,
      }).format(num);
    }

    // For numbers with absolute value between 1,000 and 1,000,000, show as "Xk" or "Xk+" using floor value
    // For negative numbers, we want to floor towards zero (truncate), not towards negative infinity
    const thousands = num >= 0 ? Math.floor(num / 1000) : Math.ceil(num / 1000);
    const remainder = Math.abs(num) % 1000;
    const suffix = remainder === 0 ? 'k' : 'k+';
    return `${new Intl.NumberFormat(resolvedLocale.value).format(thousands)}${suffix}`;
  };

  /**
   * Format a number for full display with locale-specific formatting
   * @param {number} num - The number to format
   * @returns {string} Formatted number string with full precision and locale formatting (e.g., 1,234,567)
   */
  const formatFullNumber = num => {
    if (typeof num !== 'number' || Number.isNaN(num)) {
      return '0';
    }

    return new Intl.NumberFormat(resolvedLocale.value).format(num);
  };

  return {
    formatCompactNumber,
    formatFullNumber,
  };
}
