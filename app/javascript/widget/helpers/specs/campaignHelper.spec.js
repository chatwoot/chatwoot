import {
  stripTrailingSlash,
  formatCampaigns,
  filterCampaigns,
} from '../campaignHelper';
import campaigns from './campaignFixtures';

global.chatwootWebChannel = {
  workingHoursEnabled: false,
};
describe('#Campaigns Helper', () => {
  describe('stripTrailingSlash', () => {
    it('should return striped trailing slash if url with trailing slash is passed', () => {
      expect(
        stripTrailingSlash({ URL: 'https://www.chatwoot.com/pricing/' })
      ).toBe('https://www.chatwoot.com/pricing');
    });
  });

  describe('formatCampaigns', () => {
    it('should return formatted campaigns if campaigns are passed', () => {
      expect(formatCampaigns({ campaigns })).toStrictEqual([
        {
          id: 1,
          timeOnPage: 3,
          triggerOnlyDuringBusinessHours: false,
          url: 'https://www.chatwoot.com/pricing',
        },
        {
          id: 2,
          triggerOnlyDuringBusinessHours: false,
          timeOnPage: 6,
          url: 'https://www.chatwoot.com/about',
        },
      ]);
    });
  });
  describe('filterCampaigns', () => {
    it('should return filtered campaigns if formatted campaigns are passed', () => {
      expect(
        filterCampaigns({
          campaigns: [
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
