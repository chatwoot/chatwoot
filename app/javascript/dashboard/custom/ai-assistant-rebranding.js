// AI Assistant Rebranding
// This script applies custom rebranding from "Captain" to "AI Assistant" and "Assistant" to "Topic"
// without modifying enterprise-licensed files

// Wait for DOM to be ready
document.addEventListener('DOMContentLoaded', function() {
  // Initial transformation
  transformUI();
  
  // Set up a MutationObserver to watch for DOM changes
  const observer = new MutationObserver(function() {
    transformUI();
  });
  
  // Start observing the document with the configured parameters
  observer.observe(document.body, { 
    childList: true, 
    subtree: true,
    characterData: true
  });
});

// Function to replace text in DOM nodes
function transformUI() {
  // Replace Captain with AI Assistant and Assistant with Topic in text nodes
  walkTextNodes(document.body, function(node) {
    const text = node.nodeValue;
    if (text && text.includes('Captain')) {
      node.nodeValue = text.replace(/Captain/g, 'AI Assistant');
    }
    if (text && text.includes('Assistant')) {
      // Only replace standalone "Assistant" to avoid replacing in "AI Assistant"
      node.nodeValue = node.nodeValue.replace(/\bAssistant\b(?!\s+AI)/g, 'Topic');
    }
  });
  
  // Replace in attributes
  const elements = document.querySelectorAll('[title], [placeholder], [aria-label], [alt]');
  elements.forEach(el => {
    ['title', 'placeholder', 'aria-label', 'alt'].forEach(attr => {
      if (el.hasAttribute(attr)) {
        const value = el.getAttribute(attr);
        if (value && value.includes('Captain')) {
          el.setAttribute(attr, value.replace(/Captain/g, 'AI Assistant'));
        }
        if (value && value.includes('Assistant')) {
          el.setAttribute(attr, value.replace(/\bAssistant\b(?!\s+AI)/g, 'Topic'));
        }
      }
    });
  });
  
  // Replace in button text and labels
  const buttons = document.querySelectorAll('button, .button, .btn, label');
  buttons.forEach(button => {
    if (button.innerText && button.innerText.includes('Captain')) {
      button.innerText = button.innerText.replace(/Captain/g, 'AI Assistant');
    }
    if (button.innerText && button.innerText.includes('Assistant')) {
      button.innerText = button.innerText.replace(/\bAssistant\b(?!\s+AI)/g, 'Topic');
    }
  });
  
  // Modify URLs in the page without changing the actual navigation
  const links = document.querySelectorAll('a[href*="captain"]');
  links.forEach(link => {
    // We don't modify the href as that would break navigation, but we can change how it's displayed
    if (link.innerText && link.innerText.includes('Captain')) {
      link.innerText = link.innerText.replace(/Captain/g, 'AI Assistant');
    }
    if (link.innerText && link.innerText.includes('Assistant')) {
      link.innerText = link.innerText.replace(/\bAssistant\b(?!\s+AI)/g, 'Topic');
    }
  });
}

// Helper function to walk through all text nodes in the DOM
function walkTextNodes(node, func) {
  if (node.nodeType === 3) { // Text node
    func(node);
  } else if (node.childNodes && node.childNodes.length) {
    for (let i = 0; i < node.childNodes.length; i++) {
      walkTextNodes(node.childNodes[i], func);
    }
  }
} 