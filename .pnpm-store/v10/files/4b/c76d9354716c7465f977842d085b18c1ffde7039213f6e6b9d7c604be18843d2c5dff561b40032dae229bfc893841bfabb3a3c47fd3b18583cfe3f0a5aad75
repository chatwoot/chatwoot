export const pWhile = async <T>(
  condition: (value: T | undefined) => boolean,
  action: () => T | PromiseLike<T>
): Promise<void> => {
  const loop = async (actionResult: T | undefined): Promise<void> => {
    if (condition(actionResult)) {
      return loop(await action())
    }
  }

  return loop(undefined)
}
