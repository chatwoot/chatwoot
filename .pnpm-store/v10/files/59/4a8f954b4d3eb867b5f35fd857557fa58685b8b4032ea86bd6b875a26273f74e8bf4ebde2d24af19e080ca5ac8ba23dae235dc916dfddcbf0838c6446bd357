import type { Awaitable } from '../type-utils.js'

export interface PromptBase<TValue> {
  field: string
  label: string
  required?: boolean
  defaultValue?: TValue | ((answers: Record<string, any>) => TValue)
}

export interface TextPrompt extends PromptBase<string> {
  type: 'text'
}

export type SelectPromptOption = string | { value: string, label: string }

export interface SelectPrompt extends PromptBase<string> {
  type: 'select'
  options: SelectPromptOption[] | ((search: string, answers: Record<string, any>) => Awaitable<SelectPromptOption[]>)
}

// eslint-disable-next-line unused-imports/no-unused-vars
export type Prompt<TValue = any> = TextPrompt
  | SelectPrompt
