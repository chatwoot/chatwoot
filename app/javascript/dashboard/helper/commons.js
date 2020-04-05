/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
export default () => {
  if (!Array.prototype.last) {
    Object.assign(Array.prototype, {
      last() {
        return this[this.length - 1];
      },
    });
  }
};

export const accountIdFromUrl = () => {
  const isInsideAccountScopedURLs = window.location.pathname.includes(
    '/app/accounts'
  );
  const accountId = isInsideAccountScopedURLs
    ? window.location.pathname.split('/')[3]
    : '';
  return accountId;
};
