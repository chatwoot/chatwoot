/**
 * Function that parses a string boolean value and returns the corresponding boolean value
 * @param {string | number} candidate - The string boolean value to be parsed
 * @return {boolean} - The parsed boolean value
 */
export declare function parseBoolean(candidate: string | number): boolean;
/**
 * Sanitizes text for safe HTML rendering by escaping potentially dangerous characters
 * while preserving valid HTML tags.
 *
 * This function performs the following transformations:
 * - Converts newline characters (\n) to HTML line breaks (<br>)
 * - Escapes stray '<' characters that are not part of valid HTML tags (e.g., "x < 5" → "x &lt; 5")
 * - Escapes stray '>' characters that are not part of valid HTML tags (e.g., "x > 5" → "x &gt; 5")
 * - Preserves valid HTML tags and their attributes (e.g., <div>, <span class="test">, </p>)
 *
 * LIMITATIONS: This regex-based approach has known limitations:
 * - Cannot properly handle '>' characters inside HTML attributes (e.g., <div title="x > 5"> may not work correctly)
 * - Complex nested quotes or edge cases may not be handled perfectly
 * - For more complex HTML sanitization needs, consider using a proper HTML parser
 *
 * @param {string | null | undefined} text - The text to sanitize. Can be null or undefined.
 * @returns {string} The sanitized text safe for HTML rendering, or the original value if null/undefined.
 *
 * @example
 * sanitizeTextForRender('Hello\nWorld') // 'Hello<br>World'
 * sanitizeTextForRender('if x < 5') // 'if x &lt; 5'
 * sanitizeTextForRender('<div>Hello</div>') // '<div>Hello</div>'
 * sanitizeTextForRender('Price < $100 <strong>Sale!</strong>') // 'Price &lt; $100 <strong>Sale!</strong>'
 */
export declare function sanitizeTextForRender(text: string | null | undefined): string;
