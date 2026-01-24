import { addClasses, removeClasses, toggleClass } from './DOMHelpers';
import { IFrameHelper } from './IFrameHelper';
import { isExpandedView } from './settingsHelper';
import {
  CHATWOOT_CLOSED,
  CHATWOOT_OPENED,
} from '../widget/constants/sdkEvents';
import { dispatchWindowEvent } from 'shared/helpers/CustomEventHelper';

export const bubbleSVG =
  'M240.808 240.808H122.123C56.6994 240.808 3.45695 187.562 3.45695 122.122C3.45695 56.7031 56.6994 3.45697 122.124 3.45697C187.566 3.45697 240.808 56.7031 240.808 122.122V240.808Z';

export const body = document.getElementsByTagName('body')[0];
export const widgetHolder = document.createElement('div');

export const bubbleHolder = document.createElement('div');
export const chatBubble = document.createElement('button');
export const closeBubble = document.createElement('button');
export const notificationBubble = document.createElement('span');
export const greetingPreview = document.createElement('div');
export const greetingInputBox = document.createElement('div');

export const setBubbleText = bubbleText => {
  if (isExpandedView(window.$chatwoot.type)) {
    const textNode = document.getElementById('woot-widget--expanded__text');
    textNode.innerText = bubbleText;
  }
};

export const createBubbleIcon = ({ className, path, target, widgetColor }) => {
  let bubbleClassName = `${className} woot-elements--${window.$chatwoot.position}`;

  const avatarUrl = window.chatwootSettings?.avatarUrl;
  let avatarImg = null;
  if (avatarUrl) {
    avatarImg = document.createElement('img');
    avatarImg.src = avatarUrl;
    avatarImg.alt = 'Chat';
    avatarImg.style.width = '100%';
    avatarImg.style.height = '100%';
    avatarImg.style.objectFit = 'cover';
    avatarImg.style.borderRadius = '50%';
    avatarImg.style.position = 'absolute';
    avatarImg.style.top = '0';
    avatarImg.style.left = '0';
    target.appendChild(avatarImg);

    target.style.background = 'transparent';
    target.style.backgroundColor = 'transparent';
    target.classList.add('woot-has-avatar');
  } else {
    const bubbleIcon = document.createElementNS(
      'http://www.w3.org/2000/svg',
      'svg'
    );
    bubbleIcon.setAttributeNS(null, 'id', 'woot-widget-bubble-icon');
    bubbleIcon.setAttributeNS(null, 'height', '24');
    bubbleIcon.setAttributeNS(null, 'viewBox', '0 0 240 240');
    bubbleIcon.setAttributeNS(null, 'fill', 'none');
    bubbleIcon.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

    const bubblePath = document.createElementNS(
      'http://www.w3.org/2000/svg',
      'path'
    );
    bubblePath.setAttributeNS(null, 'd', path);
    bubblePath.setAttributeNS(null, 'fill', '#FFFFFF');

    bubbleIcon.appendChild(bubblePath);
    target.appendChild(bubbleIcon);
  }

  // Handle expanded view for both avatar and SVG cases
  if (isExpandedView(window.$chatwoot.type)) {
    if (avatarImg) {
      avatarImg.style.width = '';
      avatarImg.style.objectFit = '';
      avatarImg.style.position = '';
      avatarImg.style.top = '';
      avatarImg.style.height = '65%';
      avatarImg.style.margin = '1rem';
      avatarImg.style.left = '';
    }
    const textNode = document.createElement('div');
    textNode.id = 'woot-widget--expanded__text';
    textNode.innerText = window.$chatwoot.launcherTitle || '';
    target.style.background = widgetColor;
    target.style.backgroundColor = widgetColor;
    target.appendChild(textNode);
    bubbleClassName += ' woot-widget--expanded';
  }

  target.className = bubbleClassName;
  target.title = 'Open chat window';
  return target;
};

export const createBubbleHolder = hideMessageBubble => {
  if (hideMessageBubble) {
    addClasses(bubbleHolder, 'woot-hidden');
  }
  addClasses(bubbleHolder, 'woot--bubble-holder');
  bubbleHolder.id = 'cw-bubble-holder';
  bubbleHolder.dataset.turboPermanent = true;
  body.appendChild(bubbleHolder);
};

export const createGreetingPreview = (config = {}) => {
  const { avatarUrl, agentName, dealerName, greetingMessage } = config;

  // Clear existing preview if any
  if (greetingPreview.parentNode) {
    greetingPreview.innerHTML = '';
    greetingPreview.removeEventListener('click', () => {});
  }

  // Set up the container
  greetingPreview.className = `woot-greeting-preview woot-elements--${window.$chatwoot.position} woot--hide`;
  greetingPreview.id = 'cw-greeting-preview';
  greetingPreview.dataset.turboPermanent = true;

  // Create preview structure
  const previewBox = document.createElement('div');
  previewBox.className = 'woot-greeting-preview-box';

  const header = document.createElement('div');
  header.className = 'woot-greeting-preview-header';

  const avatarNameContainer = document.createElement('div');
  avatarNameContainer.className = 'woot-greeting-preview-avatar-name';

  // Always show avatar if URL is provided, or show a default placeholder
  if (avatarUrl) {
    const img = document.createElement('img');
    img.src = avatarUrl;
    img.alt = agentName || '';
    img.className = 'woot-greeting-preview-avatar';
    avatarNameContainer.appendChild(img);
  } else if (agentName) {
    // Show a default avatar circle with initials if no avatar URL but we have a name
    const defaultAvatar = document.createElement('div');
    defaultAvatar.className =
      'woot-greeting-preview-avatar woot-greeting-preview-avatar-default';
    const initials = agentName
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .substring(0, 2);
    defaultAvatar.textContent = initials;
    avatarNameContainer.appendChild(defaultAvatar);
  }

  const nameContainer = document.createElement('div');
  nameContainer.className = 'woot-greeting-preview-name-container';

  if (agentName) {
    const nameEl = document.createElement('div');
    nameEl.className = 'woot-greeting-preview-name';
    nameEl.textContent = agentName;
    nameContainer.appendChild(nameEl);
  }

  if (dealerName && dealerName !== agentName) {
    const dealerEl = document.createElement('div');
    dealerEl.className = 'woot-greeting-preview-dealer';
    dealerEl.textContent = dealerName;
    nameContainer.appendChild(dealerEl);
  }

  if (nameContainer.children.length > 0) {
    avatarNameContainer.appendChild(nameContainer);
  }

  const closeBtn = document.createElement('button');
  closeBtn.className = 'woot-greeting-preview-close';
  closeBtn.setAttribute('aria-label', 'Close');
  closeBtn.innerHTML = `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <line x1="18" y1="6" x2="6" y2="18"></line>
      <line x1="6" y1="6" x2="18" y2="18"></line>
    </svg>
  `;

  header.appendChild(avatarNameContainer);
  header.appendChild(closeBtn);

  const messageEl = document.createElement('div');
  messageEl.className = 'woot-greeting-preview-message';
  messageEl.textContent =
    greetingMessage || 'Hi there! 👋 How can I help? Send me a message!';

  previewBox.appendChild(header);
  previewBox.appendChild(messageEl);
  greetingPreview.appendChild(previewBox);

  body.appendChild(greetingPreview);
};

export const createGreetingInputBox = (config = {}) => {
  const { widgetColor } = config;

  // Clear existing input box if any
  if (greetingInputBox.parentNode) {
    greetingInputBox.innerHTML = '';
    greetingInputBox.removeEventListener('click', () => {});
  }

  // Set up the container
  greetingInputBox.className = `woot-greeting-input-box woot-elements--${window.$chatwoot.position} woot--hide`;
  greetingInputBox.id = 'cw-greeting-input-box';
  greetingInputBox.dataset.turboPermanent = true;

  // Create input box structure
  const inputBoxContainer = document.createElement('div');
  inputBoxContainer.className = 'woot-greeting-input-box-container';

  const inputWrapper = document.createElement('div');
  inputWrapper.className = 'woot-greeting-input-wrapper';

  const input = document.createElement('input');
  input.type = 'text';
  input.className = 'woot-greeting-input';
  input.placeholder = 'Type your message...';
  input.setAttribute('aria-label', 'Type your message');

  const sendButton = document.createElement('button');
  sendButton.type = 'button';
  sendButton.className = 'woot-greeting-input-send';
  sendButton.setAttribute('aria-label', 'Send message');
  sendButton.style.minHeight = '32px';
  sendButton.style.minWidth = '32px';
  sendButton.style.display = 'flex';
  sendButton.style.alignItems = 'center';
  sendButton.style.justifyContent = 'center';
  sendButton.style.margin = '0';
  sendButton.style.padding = '0';
  sendButton.style.backgroundColor = 'transparent';
  sendButton.style.border = 'none';
  sendButton.style.cursor = 'pointer';
  sendButton.style.color = widgetColor || '#1f93ff';
  sendButton.innerHTML = `
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="transform: rotate(45deg);">
      <line x1="22" y1="2" x2="11" y2="13"></line>
      <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
    </svg>
  `;

  // Add "Text Us" button - shown by default
  const textUsButton = document.createElement('button');
  textUsButton.type = 'button';
  textUsButton.className = 'woot-greeting-input-text-us';
  textUsButton.setAttribute('aria-label', 'Text us');
  textUsButton.textContent = 'Or Text Us';
  textUsButton.style.backgroundColor = widgetColor || '#1f93ff';
  textUsButton.style.borderRadius = '8px';
  textUsButton.style.padding = '0 4px';
  textUsButton.style.color = 'white';
  textUsButton.style.fontSize = '13px';
  textUsButton.style.fontWeight = '500';
  textUsButton.style.cursor = 'pointer';
  textUsButton.style.border = 'none';
  textUsButton.style.height = '30px';
  textUsButton.style.flexShrink = '0';
  textUsButton.style.display = 'flex';
  textUsButton.style.alignItems = 'center';
  textUsButton.style.justifyContent = 'center';
  textUsButton.style.transition =
    'background-color 0.2s ease, opacity 0.2s ease';

  // Add input to wrapper
  inputWrapper.appendChild(input);
  // Add "Text Us" button to wrapper only if enabled
  if (config.hasSmsInbox) {
    inputWrapper.appendChild(textUsButton);
  }
  inputBoxContainer.appendChild(inputWrapper);

  // Add footer text with privacy policy and branding
  const footerText = document.createElement('div');
  footerText.className = 'woot-greeting-input-footer';
  footerText.innerHTML = `
    <p class="woot-greeting-footer-text">Chats may be monitored, stored, and/or shared as described in our <a href="https://getcruisecontrol.com/privacy-policy/" target="_blank" rel="noopener noreferrer" class="woot-greeting-footer-link">Privacy Policy</a>.
    Powered by <a href="https://getcruisecontrol.com" target="_blank" rel="noopener noreferrer" class="woot-greeting-footer-link">Cruise Control</a>. Use is subject to <a href="https://getcruisecontrol.com/sms-terms-and-conditions" target="_blank" rel="noopener noreferrer" class="woot-greeting-footer-link">Terms</a>.</p>
  `;

  inputBoxContainer.appendChild(footerText);
  greetingInputBox.appendChild(inputBoxContainer);

  body.appendChild(greetingInputBox);

  // Handle send message - defined inline to access input and other functions
  // eslint-disable-next-line no-use-before-define
  const handleSendMessage = () => {
    const messageText = input.value.trim();
    if (!messageText) return;

    // Clear input first
    input.value = '';

    // Open the widget - functions will be defined when this executes
    // eslint-disable-next-line no-use-before-define
    onBubbleClick({ toggleValue: true });
    // eslint-disable-next-line no-use-before-define
    hideGreetingPreview();
    // eslint-disable-next-line no-use-before-define
    hideGreetingInputBox();

    // Send message to widget iframe after a short delay to ensure widget is open
    setTimeout(() => {
      if (window.$chatwoot && window.$chatwoot.hasLoaded) {
        IFrameHelper.sendMessage('send-message', { content: messageText });
      }
    }, 300);
  };

  // Toggle between "Text Us" and send button based on input
  // Only one button should exist in DOM at a time
  const toggleButtons = () => {
    const hasText = input.value.trim().length > 0;
    if (hasText) {
      // Remove Text Us button, add send button
      if (textUsButton.parentNode) {
        textUsButton.remove();
      }
      if (!sendButton.parentNode) {
        inputWrapper.appendChild(sendButton);
      }
    } else {
      // Remove send button, add Text Us button
      if (sendButton.parentNode) {
        sendButton.remove();
      }
      // Add Text Us button only if enabled
      if (config.hasSmsInbox && !textUsButton.parentNode) {
        inputWrapper.appendChild(textUsButton);
      }
    }
  };

  // Listen to input changes
  input.addEventListener('input', toggleButtons);

  // Handle Enter key press
  input.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      if (input.value.trim()) {
        handleSendMessage();
      }
    }
  });

  // Handle send button click
  sendButton.addEventListener('click', () => {
    handleSendMessage();
  });

  // Handle "Text Us" button click
  textUsButton.addEventListener('click', () => {
    // Hide greeting preview and input box first
    // eslint-disable-next-line no-use-before-define
    hideGreetingPreview();
    // eslint-disable-next-line no-use-before-define
    hideGreetingInputBox();

    // Set a flag to indicate we're opening for SMS form
    window.$chatwoot.openingForSms = true;

    // Open the widget
    // eslint-disable-next-line no-use-before-define
    onBubbleClick({ toggleValue: true });

    // Send message to widget iframe to show SMS form
    // Use a retry mechanism to ensure message is sent once widget is ready
    const sendSmsFormMessage = () => {
      if (window.$chatwoot && window.$chatwoot.hasLoaded) {
        IFrameHelper.sendMessage('show-sms-form', {});
      } else {
        // If widget not loaded yet, wait a bit and try again
        setTimeout(sendSmsFormMessage, 50);
      }
    };

    // Start trying to send immediately
    sendSmsFormMessage();
  });

  // Focus input when clicked
  inputBoxContainer.addEventListener('click', () => {
    input.focus();
  });

  // Initialize button state
  toggleButtons();
};

export const showGreetingInputBox = () => {
  removeClasses(greetingInputBox, 'woot--hide');
};

export const hideGreetingInputBox = () => {
  addClasses(greetingInputBox, 'woot--hide');
};

export const showGreetingPreview = () => {
  removeClasses(greetingPreview, 'woot--hide');
  window.$chatwoot.greetingPreviewShown = true;
};

export const hideGreetingPreview = () => {
  addClasses(greetingPreview, 'woot--hide');
};

const handleBubbleToggle = newIsOpen => {
  IFrameHelper.events.onBubbleToggle(newIsOpen);

  if (newIsOpen) {
    dispatchWindowEvent({ eventName: CHATWOOT_OPENED });
  } else {
    dispatchWindowEvent({ eventName: CHATWOOT_CLOSED });
    chatBubble.focus();
  }
};

export const onBubbleClick = (props = {}) => {
  const { toggleValue } = props;
  const { isOpen } = window.$chatwoot;
  if (isOpen === toggleValue) return;

  const newIsOpen = toggleValue === undefined ? !isOpen : toggleValue;
  window.$chatwoot.isOpen = newIsOpen;

  toggleClass(chatBubble, 'woot--hide');
  toggleClass(closeBubble, 'woot--hide');
  toggleClass(widgetHolder, 'woot--hide');

  // Hide greeting preview and input box when widget opens
  if (newIsOpen) {
    hideGreetingPreview();
    hideGreetingInputBox();
  }

  handleBubbleToggle(newIsOpen);
};

// Attach event handlers to greeting preview
export const attachGreetingPreviewHandlers = () => {
  // Add click handler to open widget
  greetingPreview.addEventListener('click', e => {
    if (!e.target.closest('.woot-greeting-preview-close')) {
      onBubbleClick({ toggleValue: true });
      hideGreetingPreview();
    }
  });

  // Add close button handler
  const closeBtnEl = greetingPreview.querySelector(
    '.woot-greeting-preview-close'
  );
  if (closeBtnEl) {
    closeBtnEl.addEventListener('click', e => {
      e.stopPropagation();
      hideGreetingPreview();
    });
  }
};

export const onClickChatBubble = () => {
  bubbleHolder.addEventListener('click', onBubbleClick);
};

export const addUnreadClass = () => {
  const holderEl = document.querySelector('.woot-widget-holder');
  addClasses(holderEl, 'has-unread-view');
};

export const removeUnreadClass = () => {
  const holderEl = document.querySelector('.woot-widget-holder');
  removeClasses(holderEl, 'has-unread-view');
};

export const updateWidgetPosition = position => {
  if (!position) return;

  const elements = [
    bubbleHolder,
    chatBubble,
    closeBubble,
    widgetHolder,
    greetingPreview,
    greetingInputBox,
  ];

  elements.forEach(elm => {
    if (elm) {
      removeClasses(elm, 'woot-elements--left woot-elements--right');
      addClasses(elm, `woot-elements--${position}`);
    }
  });
};

export const updateWidgetType = type => {
  if (!chatBubble || !window.$chatwoot) return;

  const isExpanded = isExpandedView(type);
  const currentIsExpanded = isExpandedView(window.$chatwoot.type);

  window.$chatwoot.type = type;

  if (isExpanded !== currentIsExpanded) {
    const existingTextNode = chatBubble.querySelector(
      '#woot-widget--expanded__text'
    );

    if (isExpanded) {
      if (!existingTextNode) {
        const textNode = document.createElement('div');
        textNode.id = 'woot-widget--expanded__text';
        textNode.innerText = window.$chatwoot.launcherTitle || '';
        chatBubble.appendChild(textNode);
      }
      chatBubble.classList.add('woot-widget--expanded');
    } else {
      if (existingTextNode) {
        existingTextNode.remove();
      }
      chatBubble.classList.remove('woot-widget--expanded');
    }
  }
};
