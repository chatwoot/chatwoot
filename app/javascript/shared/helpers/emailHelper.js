export const splitEmailAddresses = value =>
  value
    .split(/[,;]+/)
    .flatMap(part => {
      if ((part.match(/@/g) || []).length > 1) {
        return part
          .replace(/[\s\u0085]*@[\s\u0085]*/g, '@')
          .split(/[\s\u0085]+/);
      }
      return part.replace(/[\s\u0085]+/g, '');
    })
    .filter(Boolean);
