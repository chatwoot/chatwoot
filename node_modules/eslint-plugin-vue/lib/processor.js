/**
 * @author Toru Nagashima <https://github.com/mysticatea>
 */
'use strict'

module.exports = {
  preprocess (code) {
    return [code]
  },

  postprocess (messages) {
    const state = {
      block: {
        disableAll: false,
        disableRules: new Set()
      },
      line: {
        disableAll: false,
        disableRules: new Set()
      }
    }

    // Filter messages which are in disabled area.
    return messages[0].filter(message => {
      if (message.ruleId === 'vue/comment-directive') {
        const rules = message.message.split(' ')
        const type = rules.shift()
        const group = rules.shift()
        switch (type) {
          case '--':
            state[group].disableAll = true
            break
          case '++':
            state[group].disableAll = false
            break
          case '-':
            for (const rule of rules) {
              state[group].disableRules.add(rule)
            }
            break
          case '+':
            for (const rule of rules) {
              state[group].disableRules.delete(rule)
            }
            break
          case 'clear':
            state.block.disableAll = false
            state.block.disableRules.clear()
            state.line.disableAll = false
            state.line.disableRules.clear()
            break
        }
        return false
      } else {
        return !(
          state.block.disableAll ||
          state.line.disableAll ||
          state.block.disableRules.has(message.ruleId) ||
          state.line.disableRules.has(message.ruleId)
        )
      }
    })
  },

  supportsAutofix: true
}
