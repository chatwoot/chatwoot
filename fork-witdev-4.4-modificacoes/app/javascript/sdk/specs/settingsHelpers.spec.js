import {
  getBubbleView,
  getWidgetStyle,
  isExpandedView,
  isFlatWidgetStyle,
} from '../settingsHelper';

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

describe('#getWidgetStyle', () => {
  it('returns correct view', () => {
    expect(getWidgetStyle('')).toEqual('standard');
    expect(getWidgetStyle('standard')).toEqual('standard');
    expect(getWidgetStyle('flat')).toEqual('flat');
  });
});

describe('#isFlatWidgetStyle', () => {
  it('returns true if it is expanded view', () => {
    expect(isFlatWidgetStyle('')).toEqual(false);
    expect(isFlatWidgetStyle('standard')).toEqual(false);
    expect(isFlatWidgetStyle('flat')).toEqual(true);
  });
});
