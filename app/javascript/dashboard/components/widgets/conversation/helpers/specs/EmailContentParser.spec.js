import { stripStyleCharacters } from '../EmailContentParser';

describe('#stripStyleCharacters', () => {
  it('remove style characters', () => {
    expect(
      stripStyleCharacters(
        `<html><body><style type="text/css"> \n<!-- \nimg \n	{max-width:100%} \ndiv \n	{width:100%!important; \n	height:100%; \n	line-height:1.6em} \ndiv \n	{background-color:#f6f6f6} \n--> \n</style>\n<div itemscope="" itemtype="http://schema.org/EmailMessage" style="font-family:'Helvetica Neue',Helvetica,Arial,sans-serif; box-sizing:border-box; font-size:14px; width:100%!important; height:100%; line-height:1.6em; background-color:#f6f6f6; margin:0; background-color:#f6f6f6">Test Content</div>\n</body></html>`
      )
    ).toEqual(
      '\n<div itemscope="" itemtype="http://schema.org/EmailMessage">Test Content</div>\n'
    );
  });
});
