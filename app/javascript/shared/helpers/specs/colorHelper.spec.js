import { isWidgetColorLighter } from 'shared/helpers/colorHelper';

describe('#isWidgetColorLighter', () => {
  it('returns true if color is lighter', () => {
    expect(isWidgetColorLighter('#ffffff')).toEqual(true);
  });
  it('returns false if color is darker', () => {
    expect(isWidgetColorLighter('#000000')).toEqual(false);
  });
});
