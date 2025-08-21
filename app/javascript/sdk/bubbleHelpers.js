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
    textNode.innerText = '';
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
