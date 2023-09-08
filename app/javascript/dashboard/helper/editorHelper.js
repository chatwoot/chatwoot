/**
 * The delimiter used to separate the signature from the rest of the body.
 * @type {string}
 */
export const SIGNATURE_DELIMITER = '--';

/**
 * Adds the signature delimiter to the beginning of the signature.
 *
 * @param {string} signature - The signature to add the delimiter to.
 * @returns {string} - The signature with the delimiter added.
 */
function signatureWithDelimiter(signature) {
  return `${SIGNATURE_DELIMITER}\n\n${signature}`;
}

/**
 * Check if there's an unedited signature at the end of the body
 * If there is, return the index of the signature, If there isn't, return -1
 *
 * @param {string} body - The body to search for the signature.
 * @param {string} signature - The signature to search for.
 * @returns {number} - The index of the last occurrence of the signature in the body, or -1 if not found.
 */
export function findSignatureInBody(body, signature) {
  const trimmedBody = body.trimEnd();
  const trimmedSignature = signature.trim();

  // check if body ends with signature
  if (trimmedBody.endsWith(trimmedSignature)) {
    return body.lastIndexOf(signature);
  }

  return -1;
}

/**
 * Appends the signature to the body, separated by the signature delimiter.
 *
 * @param {string} body - The body to append the signature to.
 * @param {string} signature - The signature to append.
 * @returns {string} - The body with the signature appended.
 */
export function appendSignature(body, signature) {
  // if signature is already present, return body
  if (findSignatureInBody(body, signature) > -1) {
    return body;
  }

  return `${body.trimEnd()}\n\n${signatureWithDelimiter(signature)}`;
}

/**
 * Removes the signature from the body, along with the signature delimiter.
 *
 * @param {string} body - The body to remove the signature from.
 * @param {string} signature - The signature to remove.
 * @returns {string} - The body with the signature removed.
 */
export function removeSignature(body, signature) {
  // this will find the index of the signature if it exists
  // Regardless of extra spaces or new lines after the signature, the index will be the same if present
  const signatureIndex = findSignatureInBody(body, signature);

  // no need to trim the ends here, because it will simply be removed in the next method
  let newBody = body;

  // if signature is present, remove it and trim it
  // trimming will ensure any spaces or new lines before the signature are removed
  // This means we will have the delimiter at the end
  if (signatureIndex > -1) {
    newBody = newBody.substring(0, signatureIndex).trimEnd();
  }

  // let's find the delimiter and remove it
  const delimiterIndex = newBody.lastIndexOf(SIGNATURE_DELIMITER);
  if (
    delimiterIndex !== -1 &&
    delimiterIndex === newBody.length - SIGNATURE_DELIMITER.length // this will ensure the delimiter is at the end
  ) {
    // if the delimiter is at the end, remove it
    newBody = newBody.substring(0, delimiterIndex);
  }

  // return the value
  return newBody;
}

/**
 * Replaces the old signature with the new signature.
 * If the old signature is not present, it will append the new signature.
 *
 * @param {string} body - The body to replace the signature in.
 * @param {string} oldSignature - The signature to replace.
 * @param {string} newSignature - The signature to replace the old signature with.
 * @returns {string} - The body with the old signature replaced with the new signature.
 *
 */
export function replaceSignature(body, oldSignature, newSignature) {
  const withoutSignature = removeSignature(body, oldSignature);
  return appendSignature(withoutSignature, newSignature);
}
