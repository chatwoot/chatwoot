import {
  hexToHSLAsArray,
  hexToHSL,
  getTextShadeOfHexColor,
  getBleachBgOfHexColor,
} from '../ColorHelper';

describe('#hexToHSLAsArray', () => {
  it('should return correct color conversion for 6 digit hex', () => {
    expect(hexToHSLAsArray('#ffffff')).toEqual([0, 0, 100]);
  });

  it('should return correct color conversion for 3 digit hex', () => {
    expect(hexToHSLAsArray('#fff')).toEqual([0, 0, 100]);
  });
});

describe('#hexToHSL', () => {
  it('should return correct color conversion for 6 digit hex to hsl string', () => {
    expect(hexToHSL('#ffffff')).toEqual('hsl(0,0%,100%)');
  });
});

describe('#getTextShadeOfHexColor', () => {
  it('should return correct color shade for 6 digit hex to hsl string', () => {
    expect(getTextShadeOfHexColor('#ffffff')).toEqual('hsl(0,0%,22%)');
  });
});

describe('#getBleachBgOfHexColor', () => {
  it('should return correct color shade for 6 digit hex to hsl string', () => {
    expect(getBleachBgOfHexColor('#ffffff')).toEqual('hsl(0,0%,96%)');
  });
});
