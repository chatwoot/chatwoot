// Credits: borrowed code from fcomb/redux-logger

import { deepCopy } from '../util'

export default function createLogger ({
  collapsed = true,
  transformer = state => state,
  mutationTransformer = mut => mut
} = {}) {
  return store => {
    let prevState = deepCopy(store.state)

    store.subscribe((mutation, state) => {
      if (typeof console === 'undefined') {
        return
      }
      const nextState = deepCopy(state)
      const time = new Date()
      const formattedTime = ` @ ${pad(time.getHours(), 2)}:${pad(time.getMinutes(), 2)}:${pad(time.getSeconds(), 2)}.${pad(time.getMilliseconds(), 3)}`
      const formattedMutation = mutationTransformer(mutation)
      const message = `mutation ${mutation.type}${formattedTime}`
      const startMessage = collapsed
        ? console.groupCollapsed
        : console.group

      // render
      try {
        startMessage.call(console, message)
      } catch (e) {
        console.log(message)
      }

      console.log('%c prev state', 'color: #9E9E9E; font-weight: bold', transformer(prevState))
      console.log('%c mutation', 'color: #03A9F4; font-weight: bold', formattedMutation)
      console.log('%c next state', 'color: #4CAF50; font-weight: bold', transformer(nextState))

      try {
        console.groupEnd()
      } catch (e) {
        console.log('—— log end ——')
      }

      prevState = nextState
    })
  }
}

function repeat (str, times) {
  return (new Array(times + 1)).join(str)
}

function pad (num, maxLength) {
  return repeat('0', maxLength - num.toString().length) + num
}
