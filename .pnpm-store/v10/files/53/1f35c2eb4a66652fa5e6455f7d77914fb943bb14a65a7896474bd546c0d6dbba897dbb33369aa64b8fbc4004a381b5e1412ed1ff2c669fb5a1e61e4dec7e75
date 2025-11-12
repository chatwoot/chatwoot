import { createWriteStream, unlinkSync } from 'node:fs'
import path from 'node:path'
import { describe, test, expect, vi, beforeEach, afterEach } from 'vitest'
import { createMarkdownFilesWatcher } from '../markdown.js'
import { watchStories } from '../stories.js'
import { Context, createContext } from '../context.js'

describe('markdown', async () => {
  vi.spyOn(process, 'cwd').mockReturnValue(path.resolve(__dirname, './markdown'))

  let ctx: Context
  let storyWatcher: Awaited<ReturnType<typeof watchStories>>

  beforeEach(async () => {
    ctx = await createContext({
      mode: 'dev',
    })

    // create watch stories to set context root etc.
    storyWatcher = await watchStories(ctx)
  })

  afterEach(() => {
    storyWatcher.close()
  })

  test('should not throw error or depend on - resolve order for linking', async () => {
    // FileWatcher should pickup the test markdown files (test1 and test2)
    // test1 links to test2 (issue previously as test1 resolved first)
    // test 2 links to test1
    const { stop } = await createMarkdownFilesWatcher(ctx)
    expect(ctx.markdownFiles.length).toEqual(2)
    stop()
  })

  test('should render html from md', async () => {
    const { stop } = await createMarkdownFilesWatcher(ctx)
    expect(ctx.markdownFiles[0].html).toContain('<p>')
    stop()
  })

  test('should throw error on missing [md] story file.', async () => {
    const testFile3 = '/markdown/test3.story.md'
    const writer = createWriteStream(__dirname.concat(testFile3))
    // link to missing file.
    writer.write(
      '<!-- File should link to test1 file. -->\n' +
      '# Test3\n\n' +
      'Link to test 4\n' +
      '[TEST](./test4.story.md)\n')
    writer.end()
    await new Promise(resolve => writer.on('finish', resolve))

    // create markdownWatcher and check for error
    await expect(async () => createMarkdownFilesWatcher(ctx)).rejects.toThrowError()
    // delete test file, so failures are removed as well.
    unlinkSync(__dirname.concat(testFile3))
  })
})
