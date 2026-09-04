import {
  calculateScrollTop,
  getRelevantMessageElements,
} from '../scrollTopCalculationHelper';

describe('#getRelevantMessageElements', () => {
  const buildContainer = html => {
    const container = document.createElement('div');
    container.innerHTML = html;
    return container;
  };

  const messagesMarkup = `
    <div id="message1" class="message-bubble-container"></div>
    <div id="message2" class="message-bubble-container"></div>
    <div id="message3" class="message-bubble-container"></div>
  `;

  it('returns the unread message elements when there are unread messages', () => {
    const container = buildContainer(messagesMarkup);

    const result = getRelevantMessageElements({
      container,
      unreadMessages: [{ id: 2 }, { id: 3 }],
      unreadMessageCount: 2,
    });

    expect(result.map(element => element.id)).toEqual(['message2', 'message3']);
  });

  it('returns the label suggestions when there are no unread messages', () => {
    const container = buildContainer(
      `${messagesMarkup}<div class="label-suggestion"></div>`
    );

    const result = getRelevantMessageElements({
      container,
      unreadMessages: [],
      unreadMessageCount: 0,
    });

    expect(result).toHaveLength(1);
    expect(result[0].className).toEqual('label-suggestion');
  });

  it('returns the last message when there are no unread messages or label suggestions', () => {
    const container = buildContainer(messagesMarkup);

    const result = getRelevantMessageElements({
      container,
      unreadMessages: [],
      unreadMessageCount: 0,
    });

    expect(result.map(element => element.id)).toEqual(['message3']);
  });

  it('falls back to the last message when the unread messages are not rendered', () => {
    const container = buildContainer(messagesMarkup);

    const result = getRelevantMessageElements({
      container,
      unreadMessages: [{ id: 99 }],
      unreadMessageCount: 1,
    });

    expect(result.map(element => element.id)).toEqual(['message3']);
  });

  it('returns an empty list when the container is not available', () => {
    expect(getRelevantMessageElements({ container: null })).toEqual([]);
  });
});

describe('#calculateScrollTop', () => {
  it('returns calculated value of the scrollTop property', () => {
    class DOMElement {
      constructor(scrollHeight) {
        this.scrollHeight = scrollHeight;
      }
    }
    let count = 3;
    let relevantMessages = [];
    while (count > 0) {
      relevantMessages.push(new DOMElement(100));
      count -= 1;
    }
    expect(calculateScrollTop(1000, 300, relevantMessages)).toEqual(550);
  });
});
