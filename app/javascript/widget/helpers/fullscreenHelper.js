const buildURL = ({ origin, searchParams }) => {
  const resultURL = new URL('/widget', origin);
  searchParams.forEach(item => {
    resultURL.searchParams.append(item.key, item.value);
  });

  return resultURL.toString();
};

export const openFullScreenWindow = (
  origin,
  websiteToken,
  locale,
  referral,
  conversationCookie
) => {
  try {
    const windowUrl = buildURL({
      origin,
      searchParams: [
        { key: 'cw_conversation', value: conversationCookie },
        { key: 'website_token', value: websiteToken },
        { key: 'locale', value: locale },
        { key: 'referral', value: referral },
      ],
    });
    const newWindow = window.open(windowUrl, '_self');
    newWindow.focus();
  } catch (err) {
    // eslint-disable-next-line no-console
    console.log(err);
  }
};
