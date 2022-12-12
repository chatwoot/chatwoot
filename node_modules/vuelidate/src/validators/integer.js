import { regex } from './common'
// ^[0-9]*$ - for empty string and positive integer
// ^-[0-9]+$ - only for negative integer (minus sign without at least 1 digit is not a number)
export default regex('integer', /(^[0-9]*$)|(^-[0-9]+$)/)
