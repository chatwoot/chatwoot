import chokidar from 'chokidar'
import { globby } from 'globby'
import { paramCase } from 'change-case'
import { resolve, basename } from 'pathe'
import micromatch from 'micromatch'
import type { ServerStoryFile } from '@histoire/shared'
import { Context } from './context.js'

type StoryChangeHandler = (file?: ServerStoryFile) => unknown
const storyChangeHandlers: StoryChangeHandler[] = []

/**
 * Called when a new story is added or modified. Collecting should be done.
 * @param handler
 */
export function onStoryChange (handler: StoryChangeHandler) {
  storyChangeHandlers.push(handler)
}

export function notifyStoryChange (file?: ServerStoryFile) {
  for (const handler of storyChangeHandlers) {
    handler(file)
  }
}

type StoryListChangeHandler = () => unknown
const storyListChangeHandlers: StoryListChangeHandler[] = []

/**
 * Called when the story list has changed (ex: removed a story). No collecting should be needed.
 * @param handler
 */
export function onStoryListChange (handler: StoryListChangeHandler) {
  storyListChangeHandlers.push(handler)
}

export function notifyStoryListChange () {
  for (const handler of storyListChangeHandlers) {
    handler()
  }
}

let context: Context

export async function watchStories (newContext: Context) {
  context = newContext
  const watcher = chokidar.watch(context.config.storyMatch, {
    cwd: context.root,
    ignored: context.config.storyIgnored,
  })

  watcher
    .on('add', (file) => {
      const storyFile = addStory(file)
      setTimeout(() => notifyStoryChange(storyFile), 100) // Delay in case file renaming fired Add event before Unlink event
    })
    .on('unlink', (file) => {
      removeStory(file)
      notifyStoryListChange()
    })

  return watcher
}

function getAbsoluteFilePath (relativeFilePath: string) {
  return resolve(context.root, relativeFilePath)
}

export function addStory (relativeFilePath: string, virtualModuleCode?: string) {
  const absoluteFilePath = getAbsoluteFilePath(relativeFilePath)

  for (const file of context.storyFiles) {
    if (file.path === absoluteFilePath) {
      return file
    }
  }

  const fileId = paramCase(relativeFilePath.toLowerCase())
  let fileName = basename(relativeFilePath)
  if (fileName.includes('.')) {
    fileName = fileName.substring(0, fileName.indexOf('.'))
  }

  let supportPluginId: string

  for (const p of context.config.supportMatch) {
    if (micromatch.isMatch(absoluteFilePath, p.patterns, {
      dot: true,
    })) {
      supportPluginId = p.pluginIds[0]
      break
    }
  }

  if (!supportPluginId) {
    throw new Error(`No support plugin found for file ${absoluteFilePath}`)
  }

  const file: ServerStoryFile = {
    id: fileId, // The file id will be changed by the story id after it is collected
    path: absoluteFilePath,
    relativePath: relativeFilePath,
    fileName,
    moduleId: virtualModuleCode ? `virtual:story:${absoluteFilePath}` : absoluteFilePath,
    supportPluginId,
    virtual: !!virtualModuleCode,
    moduleCode: virtualModuleCode,
  }
  context.storyFiles.push(file)
  return file
}

export function removeStory (relativeFilePath: string) {
  const absoluteFilePath = getAbsoluteFilePath(relativeFilePath)
  const index = context.storyFiles.findIndex((file) => file.path === absoluteFilePath)
  if (index !== -1) context.storyFiles.splice(index, 1)
}

export async function findAllStories (newContext: Context) {
  context = newContext

  const files = await globby(context.config.storyMatch, {
    cwd: context.root,
    ignore: context.config.storyIgnored,
  })
  context.storyFiles.length = 0
  for (const file of files) {
    addStory(file)
  }
}
