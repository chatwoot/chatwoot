import { buildPopoutURL } from './urlParamsHelper';

export const popoutChatWindow = (
  origin,
  websiteToken,
  locale,
  conversationCookie
) => {
  try {
    const windowUrl = buildPopoutURL({
      origin,
      websiteToken,
      locale,
      conversationCookie,
    });
    const popoutWindow = window.open(
      windowUrl,
      `webwidget_session_${websiteToken}`,
      'resizable=off,width=400,height=600'
    );
    popoutWindow.focus();
  } catch (err) {
    // eslint-disable-next-line no-console
    console.log(err);
  }
};
