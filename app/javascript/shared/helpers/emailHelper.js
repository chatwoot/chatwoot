export const splitEmailAddresses = value =>
  value
    .split(/[,;]+/)
    .flatMap(part =>
      part.replace(/[\s\u0085]*@[\s\u0085]*/g, '@').split(/[\s\u0085]+/)
    )
    .filter(Boolean);
