import { parseColor } from '../colors.js'
import type { Context } from '../context.js'

export const resolvedTheme = (ctx: Context) => {
  let css = '*, ::before, ::after {'
  // Colors
  for (const color in ctx.config.theme?.colors ?? {}) {
    for (const key in ctx.config.theme.colors[color]) {
      css += `--_histoire-color-${color}-${key}: ${parseColor(ctx.config.theme.colors[color][key]).color.join(' ')};`
    }
  }
  css += '}'
  return css
}
