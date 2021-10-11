export const stripTrailingSlash = ({ URL }) => {
  return URL.replace(/\/$/, '');
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
  return campaigns.filter(item =>
    item.triggerOnlyDuringBusinessHours
      ? isInBusinessHours
      : stripTrailingSlash({ URL: item.url }) ===
        stripTrailingSlash({ URL: currentURL })
  );
};
