import { addClass, toggleClass, wootOn } from './DOMHelpers';
import { IFrameHelper } from './IFrameHelper';
import { BUBBLE_DESIGN } from './constants';

export const bubbleImg =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAABfmlDQ1BJQ0MgUHJvZmlsZQAAKJF9kE1LAlEUhl8/wijDRQUtWgxlrVRsIqlNoBImuBAzyGozXkcNdBxmJiratAjaCgVRm74W9Qtq0yJoHQRBEUS7/kBRm5DpXMfQCjqXy3nuuee83PsCdp+kqiVnECgrhpaKRYS5zLzgeoETvejBBMYkpqvhZDIBiu/8Mz7uYeP5zs+1/t7/G505WWeArZ14kqmaQTxNPLhiqJy5Xo9GjyLe4FyweIdz1uKzek86FSW+JBZYUcoRPxH7WFErA3au78229BRauFxaZo338J+4ZWV2hvIA7X7oSCGGCATEMYUoQhghX0K0/BARoBMMedXgw9GKuqYtFYqGECYnZCGusIBPEIMi9XBff/vVrFUOgfF3wFFt1rK7wMUW0PfYrHkPAM8mcH6tSppULzlo2/N54PUU6MoA3bdAx4KeHxWtH7kjQNuzab4NAa5toFY1zc8j06wd0zB5dKVYHjW0cPIApNeBxA2wtw8Mk7Zn8QuRLWdi0XUdBgAAAJhlWElmTU0AKgAAAAgABgESAAMAAAABAAEAAAEaAAUAAAABAAAAVgEbAAUAAAABAAAAXgEoAAMAAAABAAIAAAEyAAIAAAAUAAAAZodpAAQAAAABAAAAegAAAAAAAAEsAAAAAQAAASwAAAABMjAyMTowMjoxOCAxNjoyMzoyMAAAAqACAAQAAAABAAAAMKADAAQAAAABAAAAMAAAAABflCuuAAAACXBIWXMAAC4jAAAuIwF4pT92AAAHH2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNi4wLjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6dGlmZj0iaHR0cDovL25zLmFkb2JlLmNvbS90aWZmLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICAgICAgICAgICB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIKICAgICAgICAgICAgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIKICAgICAgICAgICAgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIj4KICAgICAgICAgPGV4aWY6Q29sb3JTcGFjZT4xPC9leGlmOkNvbG9yU3BhY2U+CiAgICAgICAgIDxleGlmOlBpeGVsWERpbWVuc2lvbj4yMDQ4PC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPGV4aWY6UGl4ZWxZRGltZW5zaW9uPjIwNDg8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICAgICA8dGlmZjpJbWFnZVdpZHRoPjIwNDg8L3RpZmY6SW1hZ2VXaWR0aD4KICAgICAgICAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9uVW5pdD4KICAgICAgICAgPHRpZmY6SW1hZ2VMZW5ndGg+MjA0ODwvdGlmZjpJbWFnZUxlbmd0aD4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPGRjOnRpdGxlPgogICAgICAgICAgICA8cmRmOkFsdD4KICAgICAgICAgICAgICAgPHJkZjpsaSB4bWw6bGFuZz0ieC1kZWZhdWx0Ij5Mb2dvPC9yZGY6bGk+CiAgICAgICAgICAgIDwvcmRmOkFsdD4KICAgICAgICAgPC9kYzp0aXRsZT4KICAgICAgICAgPHhtcDpNb2RpZnlEYXRlPjIwMjEtMDItMThUMTY6MjM6MjArMDE6MDA8L3htcDpNb2RpZnlE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';

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
