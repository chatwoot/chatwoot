import type { ServerRunPayload, ServerStory, ServerVariant } from '@histoire/shared'
import type { StoryOptions, VariantOptions } from './types'

export async function run ({ file, storyData }: ServerRunPayload) {
  const { default: Comp } = await import(/* @vite-ignore */ file.moduleId)

  const options = Comp as StoryOptions

  let rawVariants: VariantOptions[] = []

  if (options.onMount) {
    // Implicit variant
    rawVariants = [{
      id: '_default',
      title: 'default',
    }]
  } else {
    rawVariants = options.variants
  }

  const story: ServerStory = {
    id: options.id ?? file.id,
    title: options.title ?? file.fileName,
    group: options.group,
    layout: options.layout ?? { type: 'single', iframe: true },
    icon: options.icon,
    iconColor: options.iconColor,
    docsOnly: options.docsOnly ?? false,
    variants: null,
  }

  const variants: ServerVariant[] = rawVariants.map((v, index) => ({
    id: v.id ?? `${story.id}-${index}`,
    title: v.title ?? 'untitled',
    icon: v.icon ?? options.icon,
    iconColor: v.iconColor ?? options.iconColor,
  }))

  story.variants = variants

  storyData.push(story)
}
