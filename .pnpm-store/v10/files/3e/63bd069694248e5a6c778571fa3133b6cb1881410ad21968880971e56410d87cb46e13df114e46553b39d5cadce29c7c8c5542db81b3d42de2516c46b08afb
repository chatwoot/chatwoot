import type {
  PreInitMethodCall,
  PreInitMethodName,
  PreInitMethodParams,
} from '.'

export function transformSnippetCall([
  methodName,
  ...args
]: SnippetWindowBufferedMethodCall): PreInitMethodCall {
  return {
    method: methodName,
    resolve: () => {},
    reject: console.error,
    args,
    called: false,
  }
}

const normalizeSnippetBuffer = (buffer: SnippetBuffer): PreInitMethodCall[] => {
  return buffer.map(transformSnippetCall)
}

type SnippetWindowBufferedMethodCall<
  MethodName extends PreInitMethodName = PreInitMethodName
> = [MethodName, ...PreInitMethodParams<MethodName>]

/**
 * A list of the method calls before initialization for snippet users
 * For example, [["track", "foo", {bar: 123}], ["page"], ["on", "ready", function(){..}]
 */
type SnippetBuffer = SnippetWindowBufferedMethodCall[]

/**
 * Fetch the buffered method calls from the window object and normalize them.
 * This removes existing buffered calls from the window object.
 */
export const popSnippetWindowBuffer = (): PreInitMethodCall[] => {
  const wa = window.analytics
  if (!Array.isArray(wa)) return []
  const buffered = wa.splice(0, wa.length)
  return normalizeSnippetBuffer(buffered)
}
