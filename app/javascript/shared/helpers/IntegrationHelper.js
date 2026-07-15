const DYTE_MEETING_LINK = 'https://examples.realtime.cloudflare.com/meeting/';

export const buildDyteURL = dyteAuthToken => {
  const params = new URLSearchParams({
    authToken: dyteAuthToken,
    showSetupScreen: true,
    disableVideoBackground: true,
  });

  return `${DYTE_MEETING_LINK}?${params.toString()}`;
};
