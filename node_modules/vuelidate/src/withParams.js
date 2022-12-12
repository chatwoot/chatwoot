/* istanbul ignore next */
const withParams =
  process.env.BUILD === 'web'
    ? require('./withParamsBrowser').withParams
    : require('./params').withParams

export default withParams
