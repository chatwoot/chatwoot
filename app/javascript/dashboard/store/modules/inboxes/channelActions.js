export const buildInboxData = inboxParams => {
  const formData = new FormData();
  const { channel = {}, ...inboxProperties } = inboxParams;
  Object.keys(inboxProperties).forEach(key => {
    formData.append(key, inboxProperties[key]);
  });
  const { selectedFeatureFlags, ...channelParams } = channel;
  // selectedFeatureFlags needs to be empty when creating a website channel
  if (selectedFeatureFlags) {
    if (selectedFeatureFlags.length) {
      selectedFeatureFlags.forEach(featureFlag => {
        formData.append(`channel[selected_feature_flags][]`, featureFlag);
      });
    } else {
      formData.append('channel[selected_feature_flags][]', '');
    }
  }
  Object.keys(channelParams).forEach(key => {
    formData.append(`channel[${key}]`, channel[key]);
  });
  return formData;
};

export const channelActions = {};
