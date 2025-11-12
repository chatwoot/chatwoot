/**
 * Function that parses a string boolean value and returns the corresponding boolean value
 * @param {string | number} candidate - The string boolean value to be parsed
 * @return {boolean} - The parsed boolean value
 */
export function parseBoolean(candidate: string | number) {
  try {
    // lowercase the string, so TRUE becomes true
    const candidateString = String(candidate).toLowerCase();

    // wrap in boolean to ensure that the return value
    // is a boolean even if values like 0 or 1 are passed
    return Boolean(JSON.parse(candidateString));
  } catch (error) {
    return false;
  }
}

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
export function sanitizeTextForRender(text: string | null | undefined) {
  if (!text) return '';

  return (
    text
      .replace(/\n/g, '<br>')

      // Escape < that doesn't start a valid HTML tag
      // Regex breakdown:
      // <          - matches '<'
      // (?!        - negative lookahead (not followed by)
      //   \/?      - optional forward slash for closing tags
      //   \w+      - one or more word characters (tag name)
      //   (?:      - non-capturing group for attributes
      //     \s+    - whitespace before attributes
      //     [^>]*  - any characters except '>' (attribute content)
      //   )?       - attributes are optional
      //   \/?>     - optional self-closing slash, then '>'
      // )          - end lookahead
      .replace(/<(?!\/?\w+(?:\s+[^>]*)?\/?>)/g, '&lt;')

      // Escape > that isn't part of an HTML tag
      // Regex breakdown:
      // (?<!       - negative lookbehind (not preceded by)
      //   <        - opening '<'
      //   \/?      - optional forward slash for closing tags
      //   \w+      - one or more word characters (tag name)
      //   (?:      - non-capturing group for attributes
      //     \s+    - whitespace before attributes
      //     [^>]*  - any characters except '>' (attribute content)
      //   )?       - attributes are optional
      //   \/?      - optional self-closing slash before >
      // )          - end lookbehind
      // >          - matches '>'
      .replace(/(?<!<\/?\w+(?:\s+[^>]*)?\/?)>/g, '&gt;')
  );
}
