class Turbolinks.ProgressBar
  ANIMATION_DURATION = 300

  @defaultCSS: """
    .turbolinks-progress-bar {
      position: fixed;
      display: block;
      top: 0;
      left: 0;
      height: 3px;
      background: #0076ff;
      z-index: 9999;
      transition: width #{ANIMATION_DURATION}ms ease-out, opacity #{ANIMATION_DURATION / 2}ms #{ANIMATION_DURATION / 2}ms ease-in;
      transform: translate3d(0, 0, 0);
    }
  """

  constructor: ->
    @stylesheetElement = @createStylesheetElement()
    @progressElement = @createProgressElement()

  show: ->
    unless @visible
      @visible = true
      @installStylesheetElement()
      @installProgressElement()
      @startTrickling()

  hide: ->
    if @visible and not @hiding
      @hiding = true
      @fadeProgressElement =>
        @uninstallProgressElement()
        @stopTrickling()
        @visible = false
        @hiding = false

  setValue: (@value) ->
    @refresh()

  # Private

  installStylesheetElement: ->
    document.head.insertBefore(@stylesheetElement, document.head.firstChild)

  installProgressElement: ->
    @progressElement.style.width = 0
    @progressElement.style.opacity = 1
    document.documentElement.insertBefore(@progressElement, document.body)
    @refresh()

  fadeProgressElement: (callback) ->
    @progressElement.style.opacity = 0
    setTimeout(callback, ANIMATION_DURATION * 1.5)

  uninstallProgressElement: ->
    if @progressElement.parentNode
      document.documentElement.removeChild(@progressElement)

  startTrickling: ->
    @trickleInterval ?= setInterval(@trickle, ANIMATION_DURATION)

  stopTrickling: ->
    clearInterval(@trickleInterval)
    @trickleInterval = null

  trickle: =>
    @setValue(@value + Math.random() / 100)

  refresh: ->
    requestAnimationFrame =>
      @progressElement.style.width = "#{10 + (@value * 90)}%"

  createStylesheetElement: ->
    element = document.createElement("style")
    element.type = "text/css"
    element.textContent = @constructor.defaultCSS
    element

  createProgressElement: ->
    element = document.createElement("div")
    element.className = "turbolinks-progress-bar"
    element
