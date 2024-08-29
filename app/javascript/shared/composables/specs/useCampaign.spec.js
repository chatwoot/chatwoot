import { describe, it, expect, vi } from 'vitest';
import { useCampaign } from '../useCampaign';
import { useRoute } from 'dashboard/composables/route';
import { CAMPAIGN_TYPES } from '../../constants/campaign';

// Mock the useRoute composable
vi.mock('dashboard/composables/route', () => ({
  useRoute: vi.fn(),
}));

describe('useCampaign', () => {
  it('returns the correct campaign type for ongoing campaigns', () => {
    useRoute.mockReturnValue({ name: 'ongoing_campaigns' });
    const { campaignType } = useCampaign();
    expect(campaignType.value).toBe(CAMPAIGN_TYPES.ONGOING);
  });

  it('returns the correct campaign type for one-off campaigns', () => {
    useRoute.mockReturnValue({ name: 'one_off' });
    const { campaignType } = useCampaign();
    expect(campaignType.value).toBe(CAMPAIGN_TYPES.ONE_OFF);
  });

  it('isOngoingType returns true for ongoing campaigns', () => {
    useRoute.mockReturnValue({ name: 'ongoing_campaigns' });
    const { isOngoingType } = useCampaign();
    expect(isOngoingType.value).toBe(true);
  });

  it('isOngoingType returns false for one-off campaigns', () => {
    useRoute.mockReturnValue({ name: 'one_off' });
    const { isOngoingType } = useCampaign();
    expect(isOngoingType.value).toBe(false);
  });

  it('isOneOffType returns true for one-off campaigns', () => {
    useRoute.mockReturnValue({ name: 'one_off' });
    const { isOneOffType } = useCampaign();
    expect(isOneOffType.value).toBe(true);
  });

  it('isOneOffType returns false for ongoing campaigns', () => {
    useRoute.mockReturnValue({ name: 'ongoing_campaigns' });
    const { isOneOffType } = useCampaign();
    expect(isOneOffType.value).toBe(false);
  });
});
