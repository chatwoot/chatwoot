import { reactive } from 'vue'
import type { PreviewSettings } from '../types'
import { histoireConfig } from './config'

export const receivedSettings = reactive<PreviewSettings>({} as PreviewSettings)

export function applyPreviewSettings(settings: PreviewSettings) {
  Object.assign(receivedSettings, settings)

  // Text direction
  document.documentElement.setAttribute('dir', settings.textDirection)

  // Contrast color
  const contrastColor = getContrastColor(settings)
  document.documentElement.style.setProperty('--histoire-contrast-color', contrastColor)
  if (histoireConfig.autoApplyContrastColor) {
    document.documentElement.style.color = contrastColor
  }
}

export function getContrastColor(setting: PreviewSettings) {
  return histoireConfig.backgroundPresets.find(preset => preset.color === setting.backgroundColor)?.contrastColor ?? 'unset'
}
