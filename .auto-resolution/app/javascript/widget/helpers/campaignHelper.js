import { URLPattern } from 'urlpattern-polyfill';

export const isPatternMatchingWithURL = (urlPattern, url) => {
  let updatedUrlPattern = urlPattern;
  const locationObj = new URL(url);

  if (updatedUrlPattern.endsWith('/')) {
    updatedUrlPattern = updatedUrlPattern.slice(0, -1) + '*\\?*\\#*';
  }

  if (locationObj.pathname.endsWith('/')) {
    locationObj.pathname = locationObj.pathname.slice(0, -1);
  }

  const pattern = new URLPattern(updatedUrlPattern);
  return pattern.test(locationObj.toString());
};

// Format all campaigns
export const formatCampaigns = ({ campaigns }) => {
  return campaigns.map(item => {
    return {
      id: item.id,
      triggerOnlyDuringBusinessHours:
        item.trigger_only_during_business_hours || false,
      timeOnPage: item?.trigger_rules?.time_on_page,
      url: item?.trigger_rules?.url,
    };
  });
};

// Filter all campaigns based on current URL and business availability time
export const filterCampaigns = ({
  campaigns,
  currentURL,
  isInBusinessHours,
}) => {
  return campaigns.filter(campaign => {
    if (!isPatternMatchingWithURL(campaign.url, currentURL)) {
      return false;
    }
    if (campaign.triggerOnlyDuringBusinessHours) {
      return isInBusinessHours;
    }
    return true;
  });
};
