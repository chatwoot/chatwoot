import { useEventListener } from '@vueuse/core'
import type { Ref } from 'vue'
import { isRef } from 'vue'
import { isMac } from './env.js'

export type KeyboardShortcut = string[]

export type KeyboardHandler = (event: KeyboardEvent) => unknown

export interface KeyboardShortcutOptions {
  event?: 'keyup' | 'keydown' | 'keypress'
}

export function onKeyboardShortcut(shortcut: KeyboardShortcut | Ref<KeyboardShortcut>, handler: KeyboardHandler, options: KeyboardShortcutOptions = {}) {
  useEventListener(options.event ?? 'keydown', (event) => {
    if (isMatchingShortcut(isRef(shortcut) ? shortcut.value : shortcut)) {
      handler(event)
    }
  })
}

const modifiers: { [i: string]: { key: string, pressed: boolean } } = {
  ctrl: { key: 'Control', pressed: false },
  alt: { key: 'Alt', pressed: false },
  shift: { key: 'Shift', pressed: false },
  meta: { key: 'Meta', pressed: false },
}

const pressedKeys = new Set<string>()

window.addEventListener('keydown', (event) => {
  for (const i in modifiers) {
    const mod = modifiers[i]
    if (mod.key === event.key) {
      mod.pressed = true
      return
    }
  }
  pressedKeys.add(event.key.toLocaleLowerCase())
})

window.addEventListener('keyup', (event) => {
  requestAnimationFrame(() => {
    pressedKeys.clear()
    for (const i in modifiers) {
      const mod = modifiers[i]
      if (mod.key === event.key) {
        mod.pressed = false
        break
      }
    }
  })
})

window.addEventListener('blur', () => {
  pressedKeys.clear()
  for (const i in modifiers) {
    const mod = modifiers[i]
    mod.pressed = false
  }
})

function isMatchingShortcut(shortcut: KeyboardShortcut): boolean {
  for (const combination of shortcut) {
    if (isMatchingCombination(combination.toLowerCase())) {
      return true
    }
  }
  return false
}

function isMatchingCombination(combination: string): boolean {
  const splitted = combination.split('+').map(key => key.trim())
  const targetKey = splitted.pop()
  for (const mod in modifiers) {
    const containsMod = splitted.includes(mod)
    const isPressed = modifiers[mod].pressed
    if (containsMod !== isPressed) {
      return false
    }
  }
  return pressedKeys.has(targetKey)
}

export function formatKey(key: string) {
  key = key.toLowerCase()
  if (key === 'ctrl') {
    return isMac ? '^' : 'Ctrl'
  }
  if (key === 'alt') {
    return isMac ? '⎇' : 'Alt'
  }
  if (key === 'shift') {
    return '⇧'
  }
  if (key === 'meta') {
    return '⌘'
  }
  if (key === 'enter') {
    return '⏎'
  }
  return key.charAt(0).toUpperCase() + key.substring(1).toLowerCase()
}
