export const getAccountFromRoute = () => {
  const isInsideAccountScopedURLs = window.location.pathname.includes(
    '/app/accounts'
  );

  if (isInsideAccountScopedURLs) {
    return window.location.pathname.split('/')[3];
  }

  return '';
};
