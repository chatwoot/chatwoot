import { defineStore } from 'pinia'
import { watch } from 'vue'
import { useStorage } from '@vueuse/core'
import { useStoryStore } from './story'

export const useFolderStore = defineStore('folder', () => {
  const openedFolders = useStorage<Map<string, boolean>>(
    '_histoire-tree-state',
    new Map(),
  )

  function getStringPath(path: Array<string>) {
    return path.join('␜')
  }

  function toggleFolder(path: Array<string>, defaultToggleValue = true) {
    const stringPath = getStringPath(path)

    const currentValue = openedFolders.value.get(stringPath)

    if (currentValue == null) {
      setFolderOpen(stringPath, defaultToggleValue)
    }
    else if (currentValue) {
      setFolderOpen(stringPath, false)
    }
    else {
      setFolderOpen(stringPath, true)
    }
  }

  function setFolderOpen(path: Array<string> | string, value: boolean) {
    const stringPath = typeof path === 'string' ? path : getStringPath(path)
    openedFolders.value.set(stringPath, value)
  }

  function isFolderOpened(path: Array<string>, defaultValue = false) {
    const value = openedFolders.value.get(getStringPath(path))
    if (value == null) {
      return defaultValue
    }
    return value
  }

  function openFileFolders(path: Array<string>) {
    for (let pathLength = 1; pathLength < path.length; pathLength++) {
      setFolderOpen(path.slice(0, pathLength), true)
    }
  }

  const storyStore = useStoryStore()

  watch(() => storyStore.currentStory, (story) => {
    if (story) {
      openFileFolders(story.file.path)
    }
  })

  return {
    isFolderOpened,
    toggleFolder,
  }
})
