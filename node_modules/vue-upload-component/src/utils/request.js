/**
 * Creates a XHR request
 *
 * @param {Object} options
 */
export const createRequest = (options) => {
  const xhr = new XMLHttpRequest()
  xhr.open(options.method || 'GET', options.url)
  xhr.responseType = 'json'
  if (options.headers) {
    Object.keys(options.headers).forEach(key => {
      xhr.setRequestHeader(key, options.headers[key])
    })
  }

  return xhr
}

/**
 * Sends a XHR request with certain body
 *
 * @param {XMLHttpRequest} xhr
 * @param {Object} body
 */
export const sendRequest = (xhr, body) => {
  return new Promise((resolve, reject) => {
    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        var response
        try {
          response = JSON.parse(xhr.response)
        } catch (err) {
          response = xhr.response
        }
        resolve(response)
      } else {
        reject(xhr.response)
      }
    }
    xhr.onerror = () => reject(xhr.response)
    xhr.send(JSON.stringify(body))
  })
}

/**
 * Sends a XHR request with certain form data
 *
 * @param {XMLHttpRequest} xhr
 * @param {Object} data
 */
export const sendFormRequest = (xhr, data) => {
  const body = new FormData()
  for (var name in data) {
    body.append(name, data[name])
  }

  return new Promise((resolve, reject) => {
    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        var response
        try {
          response = JSON.parse(xhr.response)
        } catch (err) {
          response = xhr.response
        }
        resolve(response)
      } else {
        reject(xhr.response)
      }
    }
    xhr.onerror = () => reject(xhr.response)
    xhr.send(body)
  })
}

/**
 * Creates and sends XHR request
 *
 * @param {Object} options
 *
 * @returns Promise
 */
export default function (options) {
  const xhr = createRequest(options)

  return sendRequest(xhr, options.body)
}
