import { defineStore } from 'pinia'
import { useStorage } from '@vueuse/core'
import type { PreviewSettings } from '../types'

export const usePreviewSettingsStore = defineStore('preview-settings', () => {
  const currentSettings = useStorage<PreviewSettings>('_histoire-sandbox-settings-v3', {
    responsiveWidth: 720,
    responsiveHeight: null,
    rotate: false,
    backgroundColor: 'transparent',
    checkerboard: false,
    textDirection: 'ltr',
  })

  return {
    currentSettings,
  }
})
