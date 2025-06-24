// Global fix for Shopify integration search input
// This prevents the search from triggering after typing just one character

class ShopifySearchFix {
  constructor() {
    this.debounceTimers = new Map();
    this.minSearchLength = 3;
    this.debounceDelay = 800;
    this.observer = null;
    this.init();
  }

  init() {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () =>
        this.setupSearchFix()
      );
    } else {
      this.setupSearchFix();
    }
  }

  setupSearchFix() {
    this.fixExistingInputs();
    // Only observe DOM changes if document.body exists
    if (document.body) {
      this.observeDOMChanges();
    } else {
      // Wait for body to be available
      const checkBody = () => {
        if (document.body) {
          this.observeDOMChanges();
        } else {
          setTimeout(checkBody, 100);
        }
      };
      checkBody();
    }
  }

  fixExistingInputs() {
    // Target Ant Design search inputs specifically
    const searchInputs = document.querySelectorAll(
      '.ant-input[placeholder*="Search"], .ant-input-affix-wrapper input[placeholder*="Search"]'
    );

    searchInputs.forEach(input => {
      this.applySearchFix(input);
    });
  }

  applySearchFix(input) {
    // Skip if already fixed
    if (input.dataset.shopifySearchFixed === 'true') {
      return;
    }

    // Mark as fixed
    input.dataset.shopifySearchFixed = 'true';

    // Store original event handlers
    const originalInputHandler = input.originalInputHandler || input.oninput;

    // Clear any existing timers for this input
    if (this.debounceTimers.has(input)) {
      clearTimeout(this.debounceTimers.get(input));
    }

    // Create new debounced input handler
    const debouncedHandler = event => {
      const value = event.target.value;

      // Clear existing timer
      if (this.debounceTimers.has(input)) {
        clearTimeout(this.debounceTimers.get(input));
      }

      // Only trigger search if we have enough characters
      if (value.length >= this.minSearchLength) {
        const timer = setTimeout(() => {
          // Call original handler if it exists
          if (originalInputHandler) {
            originalInputHandler.call(input, event);
          }

          // Dispatch custom event for other listeners
          const customEvent = new CustomEvent('shopifySearch', {
            detail: { query: value, input: input },
            bubbles: true,
          });
          input.dispatchEvent(customEvent);
        }, this.debounceDelay);

        this.debounceTimers.set(input, timer);
      } else if (value.length === 0) {
        // Clear results when input is empty - use shorter delay for clearing
        const clearTimer = setTimeout(() => {
          if (originalInputHandler) {
            originalInputHandler.call(input, event);
          }
        }, 300); // Shorter delay for clearing

        this.debounceTimers.set(input, clearTimer);
      }
    };

    // Replace the input handler
    input.removeEventListener('input', originalInputHandler);
    input.addEventListener('input', debouncedHandler);
    input.originalInputHandler = originalInputHandler;
    input.debouncedHandler = debouncedHandler;
  }

  observeDOMChanges() {
    // Check if MutationObserver is supported and document.body exists
    if (!window.MutationObserver || !document.body) {
      return;
    }

    try {
      // Use MutationObserver to handle dynamically added search inputs
      this.observer = new MutationObserver(mutations => {
        mutations.forEach(mutation => {
          mutation.addedNodes.forEach(node => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              // Check if the added node is a search input
              if (
                node.matches &&
                node.matches(
                  '.ant-input[placeholder*="Search"], .ant-input-affix-wrapper input[placeholder*="Search"]'
                )
              ) {
                this.applySearchFix(node);
              }

              // Check for search inputs within the added node
              const searchInputs =
                node.querySelectorAll &&
                node.querySelectorAll(
                  '.ant-input[placeholder*="Search"], .ant-input-affix-wrapper input[placeholder*="Search"]'
                );
              if (searchInputs) {
                searchInputs.forEach(input => this.applySearchFix(input));
              }
            }
          });
        });
      });

      this.observer.observe(document.body, {
        childList: true,
        subtree: true,
      });
    } catch (error) {
      // Silently handle observer errors
    }
  }

  // Method to manually apply fix to a specific input
  fixInput(input) {
    this.applySearchFix(input);
  }

  // Method to change settings
  updateSettings(minLength = 3, delay = 800) {
    this.minSearchLength = minLength;
    this.debounceDelay = delay;
  }

  // Method to cleanup
  destroy() {
    if (this.observer) {
      this.observer.disconnect();
      this.observer = null;
    }

    // Clear all timers
    this.debounceTimers.forEach(timer => clearTimeout(timer));
    this.debounceTimers.clear();
  }
}

// Initialize the fix
const shopifySearchFix = new ShopifySearchFix();

// Export for use in other modules
export default shopifySearchFix;
