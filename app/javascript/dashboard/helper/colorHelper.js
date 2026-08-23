/**
 * Convert #RGB / #RRGGBB to rgba() string.
 * @param {string} hex
 * @param {number} alpha 0–1
 * @returns {string|null}
 */
export const hexToRgba = (hex, alpha = 1) => {
  if (!hex || typeof hex !== 'string') return null;

  let value = hex.trim().replace('#', '');
  if (value.length === 3) {
    value = value
      .split('')
      .map(c => c + c)
      .join('');
  }
  if (!/^[0-9a-fA-F]{6}$/.test(value)) return null;

  const r = parseInt(value.slice(0, 2), 16);
  const g = parseInt(value.slice(2, 4), 16);
  const b = parseInt(value.slice(4, 6), 16);

  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

/**
 * Soft tint styles matching campaign badge look (bg / border / solid text).
 * @param {string} hex
 * @returns {{ backgroundColor?: string, borderColor?: string, color?: string }}
 */
export const tintStylesFromHex = hex => {
  const bg = hexToRgba(hex, 0.1);
  const border = hexToRgba(hex, 0.3);
  if (!bg || !border) return {};

  return {
    backgroundColor: bg,
    borderColor: border,
    color: hex,
  };
};
