/**
 * Tries to gets the unencoded version of an encoded component of a
 * Uniform Resource Identifier (URI). If input string is malformed,
 * returns it back as-is.
 *
 * Note: All occurences of the `+` character become ` ` (spaces).
 **/
export function gracefulDecodeURIComponent(
  encodedURIComponent: string
): string {
  try {
    return decodeURIComponent(encodedURIComponent.replace(/\+/g, ' '))
  } catch {
    return encodedURIComponent
  }
}
