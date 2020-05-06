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

export const getTypingUsersText = (users = []) => {
  const count = users.length;
  if (count === 1) {
    const [user] = users;
    return `${user.name} is typing`;
  }

  if (count === 2) {
    const [first, second] = users;
    return `${first.name} and ${second.name} are typing`;
  }

  const [user] = users;
  const rest = users.length - 1;
  return `${user.name} and ${rest} others are typing`;
};
