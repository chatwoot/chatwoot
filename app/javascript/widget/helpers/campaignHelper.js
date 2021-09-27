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

// Find all campaigns that matches the current URL and check the working hour
export const filterCampaigns = ({ campaigns, currentURL }) => {
  const { workingHoursEnabled } = window.chatwootWebChannel;
  return campaigns.filter(item =>
    item.triggerOnlyDuringBusinessHours
      ? workingHoursEnabled
      : true &&
        stripTrailingSlash({ URL: item.url }) ===
          stripTrailingSlash({ URL: currentURL })
  );
};
