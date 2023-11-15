const DYTE_MEETING_LINK = 'https://app.dyte.in/meeting/stage/';

export const buildDyteURL = (roomName, dyteAuthToken) => {
  return `${DYTE_MEETING_LINK}${roomName}?authToken=${dyteAuthToken}&showSetupScreen=true&disableVideoBackground=true`;
};
