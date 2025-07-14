import type { Context } from '../context.js'

export const story = (ctx: Context, id: string) => {
  const moduleId = id.replace('\0', '')
  const storyFile = ctx.storyFiles.find(f => f.moduleId === moduleId && f.virtual)
  if (storyFile) {
    return storyFile.moduleCode
  }
}
