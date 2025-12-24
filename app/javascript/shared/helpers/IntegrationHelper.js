const DYTE_MEETING_LINK = 'https://demo.realtime.cloudflare.com/v2/meeting';

export const buildDyteURL = dyteAuthToken => {
  return `${DYTE_MEETING_LINK}?authToken=${dyteAuthToken}&showSetupScreen=true&disableVideoBackground=true`;
};
