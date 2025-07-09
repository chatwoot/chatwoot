import { isMac } from './env.js'
import { formatKey } from './keyboard.js'

export function makeTooltip(descriptionHtml: string, keyboardShortcut: (options: { isMac: boolean }) => string) {
  return {
    content: `<div>${descriptionHtml}</div><div class="htw-flex htw-items-center htw-gap-1 htw-mt-2 htw-text-sm">${genKeyboardShortcutHtml(keyboardShortcut({ isMac }))}</div>`,
    html: true,
  }
}

function genKeyboardShortcutHtml(shortcut: string) {
  return `<span class="htw-border htw-border-gray-600 htw-px-1 htw-rounded-sm htw-text-gray-400">${shortcut.split('+').map(k => formatKey(k.trim())).join(' ')}</span>`
}
