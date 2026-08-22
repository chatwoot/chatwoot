export const campaignAudienceCount = (stats = {}) =>
  Number(stats.audience_total || stats.audience || 0);

export const campaignDeliveredCount = (stats = {}) =>
  Number(stats.delivered || 0) + Number(stats.read || 0);

export const campaignDeliveryRate = (stats = {}) => {
  const audience = campaignAudienceCount(stats);
  if (!audience) return null;

  return Math.round((campaignDeliveredCount(stats) / audience) * 100);
};
