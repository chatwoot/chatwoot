import { addClasses, removeClasses, toggleClass } from './DOMHelpers';
import { IFrameHelper } from './IFrameHelper';
import { isExpandedView } from './settingsHelper';

export const bubbleSVGStandard =
  'M33,0A33,33,0,1,0,66,33,33,33,0,0,0,33,0ZM20,37.38A4.38,4.38,0,1,1,24.34,33,4.38,4.38,0,0,1,20,37.38Zm13,0A4.38,4.38,0,1,1,37.38,33,4.38,4.38,0,0,1,33,37.38Zm13,0A4.38,4.38,0,1,1,50.42,33,4.38,4.38,0,0,1,46,37.38Z';

export const bubbleSVGExpanded =
  'M197.48,196.66c1-.9,1.9-1.82,2.84-2.75A113.59,113.59,0,1,0,39.68,33.27a113.59,113.59,0,0,0,0,160.64,112.71,112.71,0,0,0,66.67,32.46l83.85,12.69c18.8,3.22,18-1.45,13.16-19.9ZM79.3,127.27A13.68,13.68,0,1,1,93,113.59,13.68,13.68,0,0,1,79.3,127.27Zm40.7,0a13.68,13.68,0,1,1,13.68-13.68A13.68,13.68,0,0,1,120,127.27Zm40.7,0a13.68,13.68,0,1,1,13.68-13.68A13.69,13.69,0,0,1,160.7,127.27Z';

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
  body.appendChild(bubbleHolder);
};

export const createNotificationBubble = () => {
  addClasses(notificationBubble, 'woot--notification');
  return notificationBubble;
};

export const onBubbleClick = (props = {}) => {
  const { toggleValue } = props;
  const { isOpen } = window.$chatwoot;
  if (isOpen !== toggleValue) {
    const newIsOpen = toggleValue === undefined ? !isOpen : toggleValue;
    window.$chatwoot.isOpen = newIsOpen;

    toggleClass(chatBubble, 'woot--hide');
    toggleClass(closeBubble, 'woot--hide');
    toggleClass(widgetHolder, 'woot--hide');
    IFrameHelper.events.onBubbleToggle(newIsOpen);

    if (!newIsOpen) {
      chatBubble.focus();
    }
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
