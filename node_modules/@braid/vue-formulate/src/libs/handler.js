/**
 * The default backend error handler assumes a failed axios instance. You can
 * easily override this function with fetch. The expected output is defined
 * on the documentation site vueformulate.com.
 */
export default function (err) {
  if (typeof err === 'object' && err.response) {

  }
  return {}
}
