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

export const setBubbleText = bubbleText => {
  if (isExpandedView(window.$chatwoot.type)) {
    const textNode = document.getElementById('woot-widget--expanded__text');
    textNode.innerText = bubbleText;
  }
};

// Mooly.vn: Danh sách text để hiển thị liên tục
let MOOLY_TYPING_TEXTS = [
  'Xin chào! Tôi có thể giúp gì cho bạn?',
  'Hỗ trợ 24/7 - Luôn sẵn sàng!',
  'Chat ngay để được tư vấn miễn phí',
  'Mooly.vn - Giải pháp AI thông minh',
  'Bạn cần hỗ trợ gì không?',
  'Nhấn để bắt đầu trò chuyện',
  'AI Assistant đang chờ bạn...',
  'Tư vấn nhanh - Phản hồi tức thì'
];

// Function để load typing texts từ config
export const loadTypingTextsFromConfig = () => {
  if (window.chatwootWebChannel && window.chatwootWebChannel.typing_texts) {
    const configTexts = window.chatwootWebChannel.typing_texts;
    if (Array.isArray(configTexts) && configTexts.length > 0) {
      MOOLY_TYPING_TEXTS = configTexts;
    }
  }
};

// Function để cập nhật danh sách text từ bên ngoài
export const setMoolyTypingTexts = (newTexts) => {
  if (Array.isArray(newTexts) && newTexts.length > 0) {
    MOOLY_TYPING_TEXTS = newTexts;
    currentTextIndex = 0;
    currentCharIndex = 0;
    isTypingForward = true;
  }
};

let currentTextIndex = 0;
let typingInterval = null;
let currentCharIndex = 0;
let isTypingForward = true;

// Function để tạo hiệu ứng typing
export const startMoolyTypingAnimation = () => {
  if (!isExpandedView(window.$chatwoot.type)) return;

  const textNode = document.getElementById('woot-widget--expanded__text');
  if (!textNode) return;

  // Clear existing interval
  if (typingInterval) {
    clearInterval(typingInterval);
  }

  const typeText = () => {
    const currentText = MOOLY_TYPING_TEXTS[currentTextIndex];

    if (isTypingForward) {
      // Typing forward
      if (currentCharIndex <= currentText.length) {
        textNode.innerText = currentText.substring(0, currentCharIndex);
        currentCharIndex++;
      } else {
        // Pause at end of text
        setTimeout(() => {
          isTypingForward = false;
        }, 2000);
      }
    } else {
      // Typing backward (erasing)
      if (currentCharIndex > 0) {
        currentCharIndex--;
        textNode.innerText = currentText.substring(0, currentCharIndex);
      } else {
        // Move to next text
        currentTextIndex = (currentTextIndex + 1) % MOOLY_TYPING_TEXTS.length;
        isTypingForward = true;
        // Pause before starting new text
        setTimeout(() => {
          currentCharIndex = 0;
        }, 500);
      }
    }
  };

  // Start typing animation
  typingInterval = setInterval(typeText, isTypingForward ? 100 : 50);
};

// Function để dừng typing animation
export const stopMoolyTypingAnimation = () => {
  if (typingInterval) {
    clearInterval(typingInterval);
    typingInterval = null;
  }
};

// Function để toggle animation on/off
export const toggleMoolyAnimation = (enable = true) => {
  const bubble = document.querySelector('.woot-widget-bubble');
  if (!bubble) return;

  if (enable) {
    bubble.style.animation = 'mooly-pulse 2s infinite, mooly-glow 3s ease-in-out infinite alternate';
    startMoolyTypingAnimation();
  } else {
    bubble.style.animation = 'none';
    stopMoolyTypingAnimation();
  }
};

// Function để thay đổi màu bubble với animation
export const setMoolyBubbleColor = (color) => {
  const bubble = document.querySelector('.woot-widget-bubble');
  if (bubble) {
    bubble.style.background = color;
  }
};

// Function để kích hoạt rainbow animation
export const enableMoolyRainbow = (enable = true) => {
  const bubble = document.querySelector('.woot-widget-bubble');
  if (!bubble) return;

  if (enable) {
    bubble.style.animation = 'mooly-rainbow 5s infinite, mooly-pulse 2s infinite, mooly-glow 3s ease-in-out infinite alternate';
  } else {
    bubble.style.animation = 'mooly-pulse 2s infinite, mooly-glow 3s ease-in-out infinite alternate';
  }
};

export const createBubbleIcon = ({ className, path, target }) => {
  let bubbleClassName = `${className} woot-elements--${window.$chatwoot.position}`;
  const bubbleIcon = document.createElementNS(
    'http://www.w3.org/2000/svg',
    'svg'
  );
  bubbleIcon.setAttributeNS(null, 'id', 'woot-widget-bubble-icon');
  bubbleIcon.setAttributeNS(null, 'width', '24');
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

  if (isExpandedView(window.$chatwoot.type)) {
    const textNode = document.createElement('div');
    textNode.id = 'woot-widget--expanded__text';
    textNode.innerText = '';
    textNode.style.animation = 'mooly-typing 1.5s ease-in-out infinite';
    target.appendChild(textNode);
    bubbleClassName += ' woot-widget--expanded';

    // Load typing texts from config and start animation
    setTimeout(() => {
      loadTypingTextsFromConfig();
      startMoolyTypingAnimation();
    }, 1000);
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

  // Mooly.vn: Dừng typing animation khi mở chat
  if (newIsOpen) {
    stopMoolyTypingAnimation();
  } else {
    // Khởi động lại typing animation khi đóng chat
    setTimeout(() => {
      startMoolyTypingAnimation();
    }, 500);
  }

  toggleClass(chatBubble, 'woot--hide');
  toggleClass(closeBubble, 'woot--hide');
  toggleClass(widgetHolder, 'woot--hide');

  handleBubbleToggle(newIsOpen);
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

// Mooly.vn: Expose functions to global scope for external access
if (typeof window !== 'undefined') {
  window.MoolyWidget = {
    setTypingTexts: setMoolyTypingTexts,
    startTyping: startMoolyTypingAnimation,
    stopTyping: stopMoolyTypingAnimation,
    toggleAnimation: toggleMoolyAnimation,
    setBubbleColor: setMoolyBubbleColor,
    enableRainbow: enableMoolyRainbow,
    loadConfigTexts: loadTypingTextsFromConfig
  };
}
