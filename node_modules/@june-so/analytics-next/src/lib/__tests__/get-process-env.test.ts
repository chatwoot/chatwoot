import { getProcessEnv } from '../get-process-env'

it('it matches the contents of process.env', () => {
  expect(getProcessEnv()).toBe(process.env)
})
