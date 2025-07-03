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

export const createBubbleIcon = ({ className, path, target }) => {
  let bubbleClassName = `${className} woot-elements--${window.$chatwoot.position}`;
  const iconDiv = document.createElement(
    'div'
  );



  const bubbleIcon= '<svg width="28" height="28" viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg"> <mask id="mask0_8187_46927" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="28" height="28"> <rect width="28" height="28" fill="#D9D9D9"/> </mask> <g mask="url(#mask0_8187_46927)"> <path d="M8.16536 20.9997C7.83481 20.9997 7.55773 20.8879 7.33411 20.6643C7.1105 20.4406 6.9987 20.1636 6.9987 19.833V17.4997H22.1654V6.99967H24.4987C24.8293 6.99967 25.1063 7.11148 25.3299 7.33509C25.5536 7.5587 25.6654 7.83579 25.6654 8.16634V25.6663L20.9987 20.9997H8.16536ZM2.33203 19.833V3.49967C2.33203 3.16912 2.44384 2.89204 2.66745 2.66842C2.89106 2.44481 3.16814 2.33301 3.4987 2.33301H18.6654C18.9959 2.33301 19.273 2.44481 19.4966 2.66842C19.7202 2.89204 19.832 3.16912 19.832 3.49967V13.9997C19.832 14.3302 19.7202 14.6073 19.4966 14.8309C19.273 15.0545 18.9959 15.1663 18.6654 15.1663H6.9987L2.33203 19.833ZM17.4987 12.833V4.66634H4.66536V12.833H17.4987Z" fill="#FFFFFF"/> </g> </svg>';
  iconDiv.innerHTML=bubbleIcon;
  target.appendChild(iconDiv);

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
