export const stripTrailingSlash = ({ URL }) => {
  return URL.replace(/\/$/, '');
};

// Format all campaigns
export const formatCampaigns = ({ campaigns }) => {
  return campaigns.map(item => {
    return {
      id: item.id,
      timeOnPage: item?.trigger_rules?.time_on_page,
      url: item?.trigger_rules?.url,
    };
  });
};

// Find all campaigns that matches the current URL
export const filterCampaigns = ({ campaigns, currentURL }) => {
  return campaigns.filter(
    item =>
      stripTrailingSlash({ URL: item.url }) ===
      stripTrailingSlash({ URL: currentURL })
  );
};
