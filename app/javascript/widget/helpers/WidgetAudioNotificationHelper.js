import { IFrameHelper } from 'widget/helpers/utils';

export const playNewMessageNotificationInWidget = () => {
  IFrameHelper.sendMessage({ event: 'playAudio' });
};
