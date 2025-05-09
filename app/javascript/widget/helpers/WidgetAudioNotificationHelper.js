import { IFrameHelper } from 'widget/helpers/utils';

export const playNewMessageNotificationInWidget = () => {
  IFrameHelper.sendMessage({ event: 'playAudio' });
};

export const playNewCallNotificationInWidget = () => {
  IFrameHelper.sendMessage({ event: 'playRingtone' });
};

export const stopCallNotificationInWidget = () => {
  IFrameHelper.sendMessage({ event: 'stopRingtone' });
};

