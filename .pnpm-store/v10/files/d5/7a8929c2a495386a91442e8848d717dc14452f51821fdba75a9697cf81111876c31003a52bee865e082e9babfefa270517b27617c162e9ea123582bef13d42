import { markRaw, reactive } from 'vue'
import type { StoryFile, Variant } from '../types'

const copiedFromExistingVariant = [
  'state',
  'slots',
  'source',
  'responsiveDisabled',
  'autoPropsDisabled',
  'setupApp',
  'configReady',
  'previewReady',
]

export function mapFile(file: StoryFile, existingFile?: StoryFile): StoryFile {
  let result: StoryFile

  if (existingFile) {
    // Update
    result = existingFile
    for (const key in file) {
      if (key === 'story') {
        result.story = {
          ...result.story,
          ...file.story,
          file: markRaw(result),
          variants: file.story.variants.map(v => mapVariant(v, existingFile.story.variants.find(item => item.id === v.id))),
        }
      }
      else if (key !== 'component') {
        result[key] = file[key]
      }
    }
  }
  else {
    // Create
    result = {
      ...file,
      component: markRaw(file.component),
      story: {
        ...file.story,
        title: file.story.title,
        file: markRaw(file),
        variants: file.story.variants.map(v => mapVariant(v)),
        slots: () => ({}),
      },
    }
  }

  return result
}

export function mapVariant(variant: Variant, existingVariant?: Variant): Variant {
  let result: Variant

  if (existingVariant) {
    // Update
    result = existingVariant
    for (const key in variant) {
      if (!copiedFromExistingVariant.includes(key)) {
        result[key] = variant[key]
      }
    }
  }
  else {
    // Create
    result = {
      ...variant,
      state: reactive({
        _hPropState: {},
        _hPropDefs: {},
      }),
      setupApp: null,
      slots: () => ({}),
      previewReady: false,
    }
  }

  return result
}
