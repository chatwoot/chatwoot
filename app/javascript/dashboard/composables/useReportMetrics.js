import { useMapGetter } from 'dashboard/composables/store';
import { formatTime } from '@chatwoot/utils';

/**
 * A composable function for report metrics calculations and display.
 *
 * @param {string} [accountSummaryKey='getAccountSummary'] - The key for accessing account summary data.
 * @returns {Object} An object containing utility functions for report metrics.
 */
export function useReportMetrics(
  accountSummaryKey = 'getAccountSummary',
  summarFetchingKey = 'getAccountSummaryFetchingStatus'
) {
  const accountSummary = useMapGetter(accountSummaryKey);
  const fetchingStatus = useMapGetter(summarFetchingKey);

  /**
   * Calculates the trend percentage for a given metric.
   *
   * @param {string} key - The key of the metric to calculate trend for.
   * @returns {number} The calculated trend percentage, rounded to the nearest integer.
   */
  const calculateTrend = key => {
    if (!accountSummary.value.previous[key]) return 0;
    const diff = accountSummary.value[key] - accountSummary.value.previous[key];
    return Math.round((diff / accountSummary.value.previous[key]) * 100);
  };

  /**
   * Checks if a given metric key represents an average metric type.
   *
   * @param {string} key - The key of the metric to check.
   * @returns {boolean} True if the metric is an average type, false otherwise.
   */
  const isAverageMetricType = key => {
    return [
      'avg_first_response_time',
      'avg_resolution_time',
      'reply_time',
    ].includes(key);
  };

  /**
   * Formats and displays a metric value based on its type.
   *
   * @param {string} key - The key of the metric to display.
   * @returns {string} The formatted metric value as a string.
   */
  const displayMetric = key => {
    if (isAverageMetricType(key)) {
      return formatTime(accountSummary.value[key]);
    }
    return Number(accountSummary.value[key] || '').toLocaleString();
  };

  return {
    calculateTrend,
    isAverageMetricType,
    displayMetric,
    fetchingStatus,
  };
}
