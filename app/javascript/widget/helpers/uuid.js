/* eslint-disable no-bitwise */
/* eslint-disable no-mixed-operators  */
const getUuid = () =>
  'xxxxxxxx4xxx'.replace(/[xy]/g, c => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });

export default getUuid;
