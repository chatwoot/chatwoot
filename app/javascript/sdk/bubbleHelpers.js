import { addClass, toggleClass, wootOn } from './DOMHelpers';
import { IFrameHelper } from './IFrameHelper';
import { BUBBLE_DESIGN } from './constants';

export const bubbleImg =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAF5mlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS41LjAiPgogPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICAgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlLmNvbS9leGlmLzEuMC8iCiAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iCiAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIKICAgIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIKICAgIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIgogICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgZXhpZjpDb2xvclNwYWNlPSIxIgogICBleGlmOlBpeGVsWERpbWVuc2lvbj0iNDgiCiAgIGV4aWY6UGl4ZWxZRGltZW5zaW9uPSI0OCIKICAgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIKICAgcGhvdG9zaG9wOklDQ1Byb2ZpbGU9InNSR0IgSUVDNjE5NjYtMi4xIgogICB0aWZmOkltYWdlTGVuZ3RoPSI0OCIKICAgdGlmZjpJbWFnZVdpZHRoPSI0OCIKICAgdGlmZjpSZXNvbHV0aW9uVW5pdD0iMiIKICAgdGlmZjpYUmVzb2x1dGlvbj0iMzAwLjAiCiAgIHRp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';

export const body = document.getElementsByTagName('body')[0];
export const widgetHolder = document.createElement('div');

export const bubbleHolder = document.createElement('div');
export const chatBubble = document.createElement('div');
export const closeBubble = document.createElement('div');
export const notificationBubble = document.createElement('span');

export const getBubbleView = type =>
  BUBBLE_DESIGN.includes(type) ? type : BUBBLE_DESIGN[0];
export const isExpandedView = type => getBubbleView(type) === BUBBLE_DESIGN[1];

export const setBubbleText = bubbleText => {
  if (isExpandedView(window.$chatwoot.type)) {
    const textNode = document.getElementById('woot-widget--expanded__text');
    textNode.innerHTML = bubbleText;
  }
};

export const createBubbleIcon = ({ className, src, target }) => {
  let bubbleClassName = `${className} woot-elements--${window.$chatwoot.position}`;
  const bubbleIcon = document.createElement('img');
  bubbleIcon.src = src;
  bubbleIcon.alt = 'bubble-icon';
  target.appendChild(bubbleIcon);

  if (isExpandedView(window.$chatwoot.type)) {
    const textNode = document.createElement('div');
    textNode.id = 'woot-widget--expanded__text';
    textNode.innerHTML = '';
    target.appendChild(textNode);
    bubbleClassName += ' woot-widget--expanded';
  }

  target.className = bubbleClassName;
  return target;
};

export const createBubbleHolder = () => {
  addClass(bubbleHolder, 'woot--bubble-holder');
  body.appendChild(bubbleHolder);
};

export const createNotificationBubble = () => {
  addClass(notificationBubble, 'woot--notification');
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
  }
};

export const onClickChatBubble = () => {
  wootOn(bubbleHolder, 'click', onBubbleClick);
};
