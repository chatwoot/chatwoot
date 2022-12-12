/**
 * A fake uploader used by default.
 *
 * @param {File} file
 * @param {function} progress
 * @param {function} error
 * @param {object} options
 */
export default function (file, progress, error, options) {
  return new Promise((resolve, reject) => {
    const totalTime = (options.fauxUploaderDuration || 1500) * (0.5 + Math.random())
    const start = performance.now()

    /**
     * Create a recursive timeout that advances the progress.
     */
    const advance = () => setTimeout(() => {
      const elapsed = performance.now() - start
      const currentProgress = Math.min(100, Math.round(elapsed / totalTime * 100))
      progress(currentProgress)

      if (currentProgress >= 100) {
        return resolve({
          url: 'http://via.placeholder.com/350x150.png',
          name: file.name
        })
      } else {
        advance()
      }
    }, 20)
    advance()
  })
}
