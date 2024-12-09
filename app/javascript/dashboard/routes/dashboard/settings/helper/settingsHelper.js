export const getI18nKey = (prefix, event) => {
  const eventName = event.toUpperCase();
  return `${prefix}.${eventName}`;
};
