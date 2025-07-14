class Turbolinks.HttpRequest
  @NETWORK_FAILURE = 0
  @TIMEOUT_FAILURE = -1

  @timeout = 60

  constructor: (@delegate, location, referrer) ->
    @url = Turbolinks.Location.wrap(location).requestURL
    @referrer = Turbolinks.Location.wrap(referrer).absoluteURL
    @createXHR()

  send: ->
    if @xhr and not @sent
      @notifyApplicationBeforeRequestStart()
      @setProgress(0)
      @xhr.send()
      @sent = true
      @delegate.requestStarted?()

  cancel: ->
    if @xhr and @sent
      @xhr.abort()

  # XMLHttpRequest events

  requestProgressed: (event) =>
    if event.lengthComputable
      @setProgress(event.loaded / event.total)

  requestLoaded: =>
    @endRequest =>
      if 200 <= @xhr.status < 300
        @delegate.requestCompletedWithResponse(@xhr.responseText, @xhr.getResponseHeader("Turbolinks-Location"))
      else
        @failed = true
        @delegate.requestFailedWithStatusCode(@xhr.status, @xhr.responseText)

  requestFailed: =>
    @endRequest =>
      @failed = true
      @delegate.requestFailedWithStatusCode(@constructor.NETWORK_FAILURE)

  requestTimedOut: =>
    @endRequest =>
      @failed = true
      @delegate.requestFailedWithStatusCode(@constructor.TIMEOUT_FAILURE)

  requestCanceled: =>
    @endRequest()


  # Application events

  notifyApplicationBeforeRequestStart: ->
    Turbolinks.dispatch("turbolinks:request-start", data: { url: @url, xhr: @xhr })

  notifyApplicationAfterRequestEnd: ->
    Turbolinks.dispatch("turbolinks:request-end", data: { url: @url, xhr: @xhr })

  # Private

  createXHR: ->
    @xhr = new XMLHttpRequest
    @xhr.open("GET", @url, true)
    @xhr.timeout = @constructor.timeout * 1000
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml")
    @xhr.setRequestHeader("Turbolinks-Referrer", @referrer)
    @xhr.onprogress = @requestProgressed
    @xhr.onload = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.ontimeout = @requestTimedOut
    @xhr.onabort = @requestCanceled

  endRequest: (callback) ->
    if @xhr
      @notifyApplicationAfterRequestEnd()
      callback?.call(this)
      @destroy()

  setProgress: (progress) ->
    @progress = progress
    @delegate.requestProgressed?(@progress)

  destroy: ->
    @setProgress(1)
    @delegate.requestFinished?()
    @delegate = null
    @xhr = null
