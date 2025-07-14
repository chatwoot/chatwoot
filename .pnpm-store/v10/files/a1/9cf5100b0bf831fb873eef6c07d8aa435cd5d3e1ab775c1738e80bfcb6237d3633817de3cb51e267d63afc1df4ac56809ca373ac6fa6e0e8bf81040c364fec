import { isThenable } from '../utils/is-thenable'

export type TaskGroup = {
  done: () => Promise<void>
  run: <Operation extends (...args: any[]) => any>(
    op: Operation
  ) => ReturnType<Operation>
}

export const createTaskGroup = (): TaskGroup => {
  let taskCompletionPromise: Promise<void>
  let resolvePromise: () => void
  let count = 0

  return {
    done: () => taskCompletionPromise,
    run: (op) => {
      const returnValue = op()

      if (isThenable(returnValue)) {
        if (++count === 1) {
          taskCompletionPromise = new Promise((res) => (resolvePromise = res))
        }

        returnValue.finally(() => --count === 0 && resolvePromise())
      }

      return returnValue
    },
  }
}
