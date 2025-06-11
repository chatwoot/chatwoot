import { addClasses, removeClasses, toggleClass } from './DOMHelpers';
import { IFrameHelper } from './IFrameHelper';
import { isExpandedView } from './settingsHelper';
import {
  CHATWOOT_CLOSED,
  CHATWOOT_OPENED,
} from '../widget/constants/sdkEvents';
import { dispatchWindowEvent } from 'shared/helpers/CustomEventHelper';

// export const bubbleSVGStandard = 'M45,0A45,45,0,1,0,90,45,45,45,0,0,0,45,0Z';
// export const bubbleSVGStandard = 'M41,0A41,41,0,1,0,82,41,41,41,0,0,0,41,0Z';

export const bubbleSVGNoHole =
  'M208.85,104.42A104.43,104.43,0,0,0,101.9,0C46.51,1.34,1.34,46.51,0,101.9a104.42,104.42,0,0,0,104.39,107h.27A26.25,26.25,0,0,1,109,209c2.49.31,28.1,3.47,62.78,7.8,1.51.27,2.83.46,3.92.6a3,3,0,0,0,2.25-.25,2.26,2.26,0,0,0,.76-1.42q-1-15.57-1.93-31.16h0a13.07,13.07,0,0,1,1-5,9.6,9.6,0,0,1,1.77-2.58A104.14,104.14,0,0,0,208.85,104.42Z';

export const bubbleSVGStandard =
  'M208.85,104.42A104.43,104.43,0,0,0,101.9,0C46.51,1.34,1.34,46.51,0,101.9a104.42,104.42,0,0,0,104.39,107h.27A26.25,26.25,0,0,1,109,209c2.49.31,28.1,3.47,62.78,7.8,1.51.27,2.83.46,3.92.6a3,3,0,0,0,2.25-.25,2.26,2.26,0,0,0,.76-1.42q-1-15.57-1.93-31.16h0a13.07,13.07,0,0,1,1-5,9.6,9.6,0,0,1,1.77-2.58A104.14,104.14,0,0,0,208.85,104.42Zm-172,3.48a67.66,67.66,0,1,1,64,64.08A67.67,67.67,0,0,1,36.85,107.9Z';
// 'M66,0A66,66,0,1,0,132,66 A66,66,0,1,0,66,0Z';

export const bubbleSVGExpanded =
  'M 27.29 105.93 A 76.66 76.66 0 1 1 180.61 105.93 A 76.66 76.66 0 1 1 27.29 105.93 Z';
// 'M 0 120 A 120 120 0 1 1 240 120 A 120 120 0 1 1 0 120 Z';
// 'M197.48,196.66c1-.9,1.9-1.82,2.84-2.75A113.59,113.59,0,1,0,39.68,33.27a113.59,113.59,0,0,0,0,160.64,112.71,112.71,0,0,0,66.67,32.46l83.85,12.69c18.8,3.22,18-1.45,13.16-19.9ZM79.3,127.27A13.68,13.68,0,1,1,93,113.59,13.68,13.68,0,0,1,79.3,127.27Zm40.7,0a13.68,13.68,0,1,1,13.68-13.68A13.68,13.68,0,0,1,120,127.27Zm40.7,0a13.68,13.68,0,1,1,13.68-13.68A13.69,13.69,0,0,1,160.7,127.27Z';
export const body = document.getElementsByTagName('body')[0];
export const widgetHolder = document.createElement('div');

export const bubbleHolder = document.createElement('div');
export let bubblePath = null;
export const chatBubble = document.createElement('button');
export const closeBubble = document.createElement('button');
export const notificationBubble = document.createElement('span');

export const setBubbleText = bubbleText => {
  if (isExpandedView(window.$chatwoot.type)) {
    const textNode = document.getElementById('woot-widget--expanded__text');
    textNode.innerText = bubbleText;
  }
};

export const createCloseBubbleIcon = ({ className, target, widgetColor }) => {
  let bubbleClassName = `${className} woot-elements--${window.$chatwoot.position}`;
  const bubbleIcon = document.createElementNS(
    'http://www.w3.org/2000/svg',
    'svg'
  );
  bubbleIcon.setAttributeNS(null, 'id', 'woot-widget-bubble-close-icon');
  bubbleIcon.setAttributeNS(null, 'width', '100%');
  bubbleIcon.setAttributeNS(null, 'height', '100%');
  bubbleIcon.setAttributeNS(null, 'viewBox', '0 0 208.85 217.51');
  bubbleIcon.setAttribute('preserveAspectRatio', 'xMidYMid meet');

  bubbleIcon.setAttributeNS(null, 'fill', 'none');
  bubbleIcon.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

  bubblePath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  bubblePath.setAttributeNS(null, 'd', bubbleSVGNoHole);
  bubblePath.setAttributeNS(null, 'fill', widgetColor);

  bubbleIcon.append(bubblePath);

  // Cross parameters
  const crossSize = 48; // Length of each line
  const centerX = 104.43;
  const centerY = 108.76;
  const half = crossSize / 2;

  // Create first line (top-left to bottom-right)
  const line1 = document.createElementNS('http://www.w3.org/2000/svg', 'line');
  line1.setAttribute('x1', centerX - half);
  line1.setAttribute('y1', centerY - half);
  line1.setAttribute('x2', centerX + half);
  line1.setAttribute('y2', centerY + half);

  // Create second line (top-right to bottom-left)
  const line2 = document.createElementNS('http://www.w3.org/2000/svg', 'line');
  line2.setAttribute('x1', centerX + half);
  line2.setAttribute('y1', centerY - half);
  line2.setAttribute('x2', centerX - half);
  line2.setAttribute('y2', centerY + half);

  // Style the lines
  [line1, line2].forEach(line => {
    line.setAttribute('stroke', '#fff'); // White cross; use widgetColor or another color if you prefer
    line.setAttribute('stroke-width', '6');
    line.setAttribute('stroke-linecap', 'round');
  });

  bubbleIcon.append(line1, line2);

  target.insertBefore(bubbleIcon, target.firstChild);

  target.className = bubbleClassName;
  target.title = 'Close chat window';
  return target;
};

export const createBubbleIcon = ({
  className,
  path,
  target,
  logoColors,
  widgetColor,
}) => {
  let bubbleClassName = `${className} woot-elements--${window.$chatwoot.position}`;
  const bubbleIcon = document.createElementNS(
    'http://www.w3.org/2000/svg',
    'svg'
  );
  bubbleIcon.setAttributeNS(null, 'id', 'woot-widget-bubble-icon');
  bubbleIcon.setAttributeNS(null, 'width', '100%');
  bubbleIcon.setAttributeNS(null, 'height', '100%');
  if (isExpandedView(window.$chatwoot.type)) {
    // bubbleIcon.setAttributeNS(null, 'viewBox', '0 0 240 240');
    bubbleIcon.setAttributeNS(null, 'viewBox', '27.29 29.27 153.32 153.32');
  } else {
    bubbleIcon.setAttributeNS(null, 'viewBox', '0 0 208.85 217.51');
    bubbleIcon.setAttribute('preserveAspectRatio', 'xMidYMid meet');
  }

  bubbleIcon.setAttributeNS(null, 'fill', 'none');
  bubbleIcon.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

  bubblePath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
  bubblePath.setAttributeNS(null, 'd', path);
  bubblePath.setAttributeNS(null, 'fill', widgetColor);

  bubbleIcon.appendChild(bubblePath);
  target.appendChild(bubbleIcon);

  if (isExpandedView(window.$chatwoot.type)) {
    const textNode = document.createElement('div');
    textNode.id = 'woot-widget--expanded__text';
    textNode.innerText = '';
    target.appendChild(textNode);
    bubbleClassName += ' woot-widget--expanded';
  }

  const xStart = 70.18;
  const xSep = 33.77;
  const rad = 11.97;
  const yOff = 105.93;

  const c1 = document.createElementNS('http://www.w3.org/2000/svg', 'circle');

  c1.setAttribute('cx', xStart);
  c1.setAttribute('cy', yOff);
  c1.setAttribute('r', rad);
  c1.setAttribute('fill', logoColors.dot1);

  bubbleIcon.appendChild(c1);

  const c2 = document.createElementNS('http://www.w3.org/2000/svg', 'circle');

  c2.setAttribute('cx', `${xStart + xSep}`);
  c2.setAttribute('cy', yOff);
  c2.setAttribute('r', rad);
  c2.setAttribute('fill', logoColors.dot2);

  bubbleIcon.appendChild(c2);

  const c3 = document.createElementNS('http://www.w3.org/2000/svg', 'circle');

  c3.setAttribute('cx', `${xStart + 2 * xSep}`);
  c3.setAttribute('cy', yOff);
  c3.setAttribute('r', rad);
  c3.setAttribute('fill', logoColors.dot3);

  bubbleIcon.appendChild(c3);

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
