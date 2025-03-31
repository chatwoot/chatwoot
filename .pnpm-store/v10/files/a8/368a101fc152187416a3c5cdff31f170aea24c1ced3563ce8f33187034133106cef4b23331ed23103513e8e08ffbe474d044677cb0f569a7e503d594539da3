#= require ./http_request

class Turbolinks.Visit
  constructor: (@controller, location, @action) ->
    @identifier = Turbolinks.uuid()
    @location = Turbolinks.Location.wrap(location)
    @adapter = @controller.adapter
    @state = "initialized"
    @timingMetrics = {}

  start: ->
    if @state is "initialized"
      @recordTimingMetric("visitStart")
      @state = "started"
      @adapter.visitStarted(this)

  cancel: ->
    if @state is "started"
      @request?.cancel()
      @cancelRender()
      @state = "canceled"

  complete: ->
    if @state is "started"
      @recordTimingMetric("visitEnd")
      @state = "completed"
      @adapter.visitCompleted?(this)
      @controller.visitCompleted(this)

  fail: ->
    if @state is "started"
      @state = "failed"
      @adapter.visitFailed?(this)

  changeHistory: ->
    unless @historyChanged
      actionForHistory = if @location.isEqualTo(@referrer) then "replace" else @action
      method = getHistoryMethodForAction(actionForHistory)
      @controller[method](@location, @restorationIdentifier)
      @historyChanged = true

  issueRequest: ->
    if @shouldIssueRequest() and not @request?
      @progress = 0
      @request = new Turbolinks.HttpRequest this, @location, @referrer
      @request.send()

  getCachedSnapshot: ->
    if snapshot = @controller.getCachedSnapshotForLocation(@location)
      if not @location.anchor? or snapshot.hasAnchor(@location.anchor)
        if @action is "restore" or snapshot.isPreviewable()
          snapshot

  hasCachedSnapshot: ->
    @getCachedSnapshot()?

  loadCachedSnapshot: ->
    if snapshot = @getCachedSnapshot()
      isPreview = @shouldIssueRequest()
      @render ->
        @cacheSnapshot()
        @controller.render({snapshot, isPreview}, @performScroll)
        @adapter.visitRendered?(this)
        @complete() unless isPreview

  loadResponse: ->
    if @response?
      @render ->
        @cacheSnapshot()
        if @request.failed
          @controller.render(error: @response, @performScroll)
          @adapter.visitRendered?(this)
          @fail()
        else
          @controller.render(snapshot: @response, @performScroll)
          @adapter.visitRendered?(this)
          @complete()

  followRedirect: ->
    if @redirectedToLocation and not @followedRedirect
      @location = @redirectedToLocation
      @controller.replaceHistoryWithLocationAndRestorationIdentifier(@redirectedToLocation, @restorationIdentifier)
      @followedRedirect = true

  # HTTP Request delegate

  requestStarted: ->
    @recordTimingMetric("requestStart")
    @adapter.visitRequestStarted?(this)

  requestProgressed: (@progress) ->
    @adapter.visitRequestProgressed?(this)

  requestCompletedWithResponse: (@response, redirectedToLocation) ->
    @redirectedToLocation = Turbolinks.Location.wrap(redirectedToLocation) if redirectedToLocation?
    @adapter.visitRequestCompleted(this)

  requestFailedWithStatusCode: (statusCode, @response) ->
    @adapter.visitRequestFailedWithStatusCode(this, statusCode)

  requestFinished: ->
    @recordTimingMetric("requestEnd")
    @adapter.visitRequestFinished?(this)

  # Scrolling

  performScroll: =>
    unless @scrolled
      if @action is "restore"
        @scrollToRestoredPosition() or @scrollToTop()
      else
        @scrollToAnchor() or @scrollToTop()
      @scrolled = true

  scrollToRestoredPosition: ->
    position = @restorationData?.scrollPosition
    if position?
      @controller.scrollToPosition(position)
      true

  scrollToAnchor: ->
    if @location.anchor?
      @controller.scrollToAnchor(@location.anchor)
      true

  scrollToTop: ->
    @controller.scrollToPosition(x: 0, y: 0)

  # Instrumentation

  recordTimingMetric: (name) ->
    @timingMetrics[name] ?= new Date().getTime()

  getTimingMetrics: ->
    Turbolinks.copyObject(@timingMetrics)

  # Private

  getHistoryMethodForAction = (action) ->
    switch action
      when "replace" then "replaceHistoryWithLocationAndRestorationIdentifier"
      when "advance", "restore" then "pushHistoryWithLocationAndRestorationIdentifier"

  shouldIssueRequest: ->
    if @action is "restore"
      not @hasCachedSnapshot()
    else
      true

  cacheSnapshot: ->
    unless @snapshotCached
      @controller.cacheSnapshot()
      @snapshotCached = true

  render: (callback) ->
    @cancelRender()
    @frame = requestAnimationFrame =>
      @frame = null
      callback.call(this)

  cancelRender: ->
    cancelAnimationFrame(@frame) if @frame
