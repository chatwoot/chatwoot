/**
 * Parses various date formats into a JavaScript Date object
 *
 * This function handles different date input formats commonly found in conversation data:
 * - 10-digit timestamps (Unix seconds) - automatically converted to milliseconds
 * - 13-digit timestamps (Unix milliseconds) - used directly
 * - String representations of timestamps
 * - ISO date strings (e.g., "2025-06-01T12:30:00Z")
 * - Simple date strings (e.g., "2025-06-01") - time defaults to 00:00:00
 * - Date strings with space-separated time (e.g., "2025-06-01 12:30:00")
 *
 * Note: This function follows JavaScript Date constructor behavior for date parsing.
 * Some invalid dates like "2025-02-30" auto-correct to valid dates (becomes "2025-03-02"),
 * while malformed strings like "2025-13-01" or "2025-06-01T25:00:00" return null.
 *
 * @example
 * coerceToDate('2025-06-01') // Returns Date object set to 2025-06-01 00:00:00
 * coerceToDate('2025-06-01T12:30:00Z') // Returns Date object with specified time
 * coerceToDate(1748834578) // Returns Date object (10-digit timestamp in seconds)
 * coerceToDate(1748834578000) // Returns Date object (13-digit timestamp in milliseconds)
 * coerceToDate('1748834578') // Returns Date object (string timestamp converted)
 * coerceToDate(null) // Returns null
 * coerceToDate('invalid-date') // Returns null
 */
export const coerceToDate = (
  dateInput: string | number | null | undefined
): Date | null => {
  if (dateInput == null) return null;

  let timestamp = typeof dateInput === 'number' ? dateInput : null;

  // Handle string inputs that represent numeric timestamps
  if (
    timestamp === null &&
    typeof dateInput === 'string' &&
    /^\d+$/.test(dateInput)
  ) {
    timestamp = Number(dateInput);
  }

  // Process numeric timestamps
  if (timestamp !== null) {
    // Convert 10-digit timestamps (seconds) to milliseconds
    const timestampMs =
      timestamp.toString().length === 10 ? timestamp * 1000 : timestamp;
    return new Date(timestampMs);
  }

  // Process string date inputs
  if (typeof dateInput === 'string') {
    const dateObj = new Date(dateInput);

    // Return null for invalid dates
    if (Number.isNaN(dateObj.getTime())) return null;

    // If no time component is specified, set time to 00:00:00
    // this is because by default JS will set the time to midnight UTC for that date
    const hasTimeComponent =
      /T\d{2}:\d{2}(:\d{2})?/.test(dateInput) || /\d{2}:\d{2}/.test(dateInput);
    if (!hasTimeComponent) {
      dateObj.setHours(0, 0, 0, 0);
    }

    return dateObj;
  }

  return null;
};
