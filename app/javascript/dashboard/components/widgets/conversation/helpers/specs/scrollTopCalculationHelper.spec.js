import { calculateScrollTop } from '../scrollTopCalculationHelper';

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
