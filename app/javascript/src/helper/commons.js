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
