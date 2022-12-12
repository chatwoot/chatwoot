import { TransformerConfig } from './transformers'

export interface Rule {
  scope: string
  target_type: string
  matchers: Matcher[]
  transformers: Transformer[][]
  destinationName?: string
}

export interface Matcher {
  type: string
  ir: string
}

export interface Transformer {
  type: string
  config?: TransformerConfig
}

export default class Store {
  private readonly rules = []

  constructor(rules?: Rule[]) {
    this.rules = rules || []
  }

  public getRulesByDestinationName(destinationName: string): Rule[] {
    const rules: Rule[] = []
    for (const rule of this.rules) {
      // Rules with no destinationName are global (workspace || workspace::source)
      if (rule.destinationName === destinationName || rule.destinationName === undefined) {
        rules.push(rule)
      }
    }

    return rules
  }
}
