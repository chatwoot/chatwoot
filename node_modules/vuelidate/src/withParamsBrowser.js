// In browser, validators should be independent from Vuelidate.
// The only usecase those do need to be dependent is when you need $params.
// To make the dependency optional, try to grab Vuelidate from global object,
// fallback to stubbed WithParams on failure.

const root =
  typeof window !== 'undefined'
    ? window
    : typeof global !== 'undefined'
    ? global
    : {}

/* istanbul ignore next */
const fakeWithParams = (paramsOrClosure, maybeValidator) => {
  if (typeof paramsOrClosure === 'object' && maybeValidator !== undefined) {
    return maybeValidator
  }
  return paramsOrClosure(() => {})
}

export const withParams = root.vuelidate
  ? root.vuelidate.withParams
  : fakeWithParams
