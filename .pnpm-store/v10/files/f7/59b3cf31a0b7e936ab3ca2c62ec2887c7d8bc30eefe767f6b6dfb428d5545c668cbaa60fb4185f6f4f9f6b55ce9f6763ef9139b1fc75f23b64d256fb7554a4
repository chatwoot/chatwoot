var Individual = require('individual')

var VERSION_KEY = '1';
var ERROR_CACHE_KEY = '__RUST_RESULT_ERROR_UUID@' + VERSION_KEY
var OK_CACHE_KEY = '__RUST_RESULT_OK_UUID@' + VERSION_KEY

var ERROR_UUID = Individual(ERROR_CACHE_KEY, fakeUUID('Error'))
var OK_UUID = Individual(OK_CACHE_KEY, fakeUUID('Ok'))

function Ok(v) {
  this.v = v

  this[OK_UUID] = true
}

function Err(err) {
  this.err = err

  this[ERROR_UUID] = true
}

function createOk(v) {
  if (isObject(v) && OK_UUID in v) {
    return v.v
  } else if (isObject(v) && ERROR_UUID in v) {
    return undefined
  } else {
    if (v === undefined) {
      throw Error('rust-result: Cannot box `undefined` in Result.Ok')
    }

    return new Ok(v)
  }
}

function createErr(err) {
  if (isObject(err) && ERROR_UUID in err) {
    return err.err
  } else if (isObject(err) && OK_UUID in err) {
    return undefined
  } else {
    if (!isError(err)) {
      throw Error('rust-result: Cannot box a non-error in Result.Err')
    }

    return new Err(err)
  }
}

function isOk(v) {
  return createOk(v) !== undefined
}

function isErr(err) {
  return createErr(err) !== undefined
}

module.exports = {
  isOk: isOk,
  Ok: createOk,
  isErr: isErr,
  Err: createErr
}

function fakeUUID(word) {
  return 'rust-result:' + word + ':' +
    Math.random().toString(32).slice(2) + ':' +
    Math.random().toString(32).slice(2) + ':' +
    Math.random().toString(32).slice(2) + ':' +
    Math.random().toString(32).slice(2) + ':'
}

function isObject(o) {
  return typeof o === 'object' && o !== null
}

function isError(e) {
  return isObject(e) &&
      (Object.prototype.toString.call(e) === '[object Error]' ||
        /* istanbul ignore next */ e instanceof Error)
}
