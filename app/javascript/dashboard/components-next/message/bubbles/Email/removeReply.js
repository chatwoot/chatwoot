// Quote detection strategies
const QUOTE_INDICATORS = [
  '.gmail_quote_container',
  '.gmail_quote',
  '.OutlookQuote',
  '.email-quote',
  '.quoted-text',
  '.quote',
  '[class*="quote"]',
  '[class*="Quote"]',
];

// Regex patterns for quote identification
const QUOTE_PATTERNS = [
  /On .* wrote:/i,
  /-----Original Message-----/i,
  /Sent: /i,
  /From: /i,
];

export class EmailQuoteExtractor {
  /**
   * Remove quotes from email HTML and return cleaned HTML
   * @param {string} htmlContent - Full HTML content of the email
   * @returns {string} HTML content with quotes removed
   */
  static extractQuotes(htmlContent) {
    // Create a temporary DOM element to parse HTML
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = htmlContent;

    // Remove elements matching class selectors
    QUOTE_INDICATORS.forEach(selector => {
      tempDiv.querySelectorAll(selector).forEach(el => {
        el.remove();
      });
    });

    // Remove text-based quotes
    const textNodeQuotes = this.findTextNodeQuotes(tempDiv);
    textNodeQuotes.forEach(el => {
      el.remove();
    });

    return tempDiv.innerHTML;
  }

  /**
   * Check if HTML content contains any quotes
   * @param {string} htmlContent - Full HTML content of the email
   * @returns {boolean} True if quotes are detected, false otherwise
   */
  static hasQuotes(htmlContent) {
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = htmlContent;

    // Check for class-based quotes
    // eslint-disable-next-line no-restricted-syntax
    for (const selector of QUOTE_INDICATORS) {
      if (tempDiv.querySelector(selector)) {
        return true;
      }
    }

    // Check for text-based quotes
    const textNodeQuotes = this.findTextNodeQuotes(tempDiv);
    return textNodeQuotes.length > 0;
  }

  /**
   * Find text nodes that match quote patterns
   * @param {Element} rootElement - Root element to search
   * @returns {Element[]} Array of parent block elements containing quote-like text
   */
  static findTextNodeQuotes(rootElement) {
    const quoteBlocks = [];
    const treeWalker = document.createTreeWalker(
      rootElement,
      NodeFilter.SHOW_TEXT,
      null,
      false
    );

    for (
      let currentNode = treeWalker.nextNode();
      currentNode !== null;
      currentNode = treeWalker.nextNode()
    ) {
      const isQuoteLike = QUOTE_PATTERNS.some(pattern =>
        pattern.test(currentNode.textContent)
      );

      if (isQuoteLike) {
        const parentBlock = this.findParentBlock(currentNode);
        if (parentBlock && !quoteBlocks.includes(parentBlock)) {
          quoteBlocks.push(parentBlock);
        }
      }
    }

    return quoteBlocks;
  }

  /**
   * Find the closest block-level parent element by recursively traversing up the DOM tree.
   * This method searches for common block-level elements like DIV, P, BLOCKQUOTE, and SECTION
   * that contain the text node. It's used to identify and remove entire block-level elements
   * that contain quote-like text, rather than just removing the text node itself. This ensures
   * proper structural removal of quoted content while maintaining HTML integrity.
   * @param {Node} node - Starting node to find parent
   * @returns {Element|null} Block-level parent element
   */
  static findParentBlock(node) {
    const blockElements = ['DIV', 'P', 'BLOCKQUOTE', 'SECTION'];
    let current = node.parentElement;

    while (current) {
      if (blockElements.includes(current.tagName)) {
        return current;
      }
      current = current.parentElement;
    }

    return null;
  }
}
