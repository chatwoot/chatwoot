import {
  stripTrailingSlash,
  formatCampaigns,
  filterCampaigns,
} from '../campaignHelper';
import campaigns from './camapginFixtures';
describe('#Campagin Helper', () => {
  describe('stripTrailingSlash', () => {
    it('should return striped trailing slash if url with trailing slash is passed', () => {
      expect(
        stripTrailingSlash({ URL: 'https://www.chatwoot.com/pricing/' })
      ).toBe('https://www.chatwoot.com/pricing');
    });
  });

  describe('formatCampaigns', () => {
    it('should return formated campaigns if camapgins are passed', () => {
      expect(formatCampaigns({ campagins: campaigns })).toStrictEqual([
        {
          id: 1,
          timeOnPage: 3,
          url: 'https://www.chatwoot.com/pricing',
        },
        {
          id: 2,
          timeOnPage: 6,
          url: 'https://www.chatwoot.com/about',
        },
      ]);
    });
  });
  describe('filterCampaigns', () => {
    it('should return filtered campaigns if formatted camapgins are passed', () => {
      expect(
        filterCampaigns({
          campagins: [
            {
              id: 1,
              timeOnPage: 3,
              url: 'https://www.chatwoot.com/pricing',
            },
            {
              id: 2,
              timeOnPage: 6,
              url: 'https://www.chatwoot.com/about',
            },
          ],
          currentURL: 'https://www.chatwoot.com/about/',
        })
      ).toStrictEqual([
        {
          id: 2,
          timeOnPage: 6,
          url: 'https://www.chatwoot.com/about',
        },
      ]);
    });
  });
});
