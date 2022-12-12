import global from 'global';
const {
  LOGLEVEL,
  console
} = global;
const levels = {
  trace: 1,
  debug: 2,
  info: 3,
  warn: 4,
  error: 5,
  silent: 10
};
const currentLogLevelString = LOGLEVEL;
const currentLogLevelNumber = levels[currentLogLevelString] || levels.info;
export const logger = {
  trace: (message, ...rest) => currentLogLevelNumber <= levels.trace && console.trace(message, ...rest),
  debug: (message, ...rest) => currentLogLevelNumber <= levels.debug && console.debug(message, ...rest),
  info: (message, ...rest) => currentLogLevelNumber <= levels.info && console.info(message, ...rest),
  warn: (message, ...rest) => currentLogLevelNumber <= levels.warn && console.warn(message, ...rest),
  error: (message, ...rest) => currentLogLevelNumber <= levels.error && console.error(message, ...rest),
  log: (message, ...rest) => currentLogLevelNumber < levels.silent && console.log(message, ...rest)
};
const logged = new Set();
export const once = type => (message, ...rest) => {
  if (logged.has(message)) return undefined;
  logged.add(message);
  return logger[type](message, ...rest);
};

once.clear = () => logged.clear();

once.trace = once('trace');
once.debug = once('debug');
once.info = once('info');
once.warn = once('warn');
once.error = once('error');
once.log = once('log');
export const pretty = type => (...args) => {
  const argArray = [];

  if (args.length) {
    const startTagRe = /<span\s+style=(['"])([^'"]*)\1\s*>/gi;
    const endTagRe = /<\/span>/gi;
    let reResultArray;
    argArray.push(args[0].replace(startTagRe, '%c').replace(endTagRe, '%c')); // eslint-disable-next-line no-cond-assign

    while (reResultArray = startTagRe.exec(args[0])) {
      argArray.push(reResultArray[2]);
      argArray.push('');
    } // pass through subsequent args since chrome dev tools does not (yet) support console.log styling of the following form: console.log('%cBlue!', 'color: blue;', '%cRed!', 'color: red;');
    // eslint-disable-next-line no-plusplus


    for (let j = 1; j < args.length; j++) {
      argArray.push(args[j]);
    }
  } // eslint-disable-next-line prefer-spread


  logger[type].apply(logger, argArray);
};
pretty.trace = pretty('trace');
pretty.debug = pretty('debug');
pretty.info = pretty('info');
pretty.warn = pretty('warn');
pretty.error = pretty('error');