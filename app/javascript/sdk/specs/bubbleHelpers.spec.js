import { getBubbleView, isExpandedView } from '../bubbleHelpers';

describe('#getBubbleView', () => {
  it('returns correct view', () => {
    expect(getBubbleView('')).toEqual('standard');
    expect(getBubbleView('standard')).toEqual('standard');
    expect(getBubbleView('expanded_bubble')).toEqual('expanded_bubble');
  });
});

describe('#isExpandedView', () => {
  it('returns true if it is expanded view', () => {
    expect(isExpandedView('')).toEqual(false);
    expect(isExpandedView('standard')).toEqual(false);
    expect(isExpandedView('expanded_bubble')).toEqual(true);
  });
});
