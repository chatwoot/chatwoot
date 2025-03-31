class Turbolinks.Location
  @wrap: (value) ->
    if value instanceof this
      value
    else
      new this value

  constructor: (url = "") ->
    linkWithAnchor = document.createElement("a")
    linkWithAnchor.href = url.toString()

    @absoluteURL = linkWithAnchor.href

    anchorLength = linkWithAnchor.hash.length
    if anchorLength < 2
      @requestURL = @absoluteURL
    else
      @requestURL = @absoluteURL.slice(0, -anchorLength)
      @anchor = linkWithAnchor.hash.slice(1)

  getOrigin: ->
    @absoluteURL.split("/", 3).join("/")

  getPath: ->
    @requestURL.match(/\/\/[^/]*(\/[^?;]*)/)?[1] ? "/"

  getPathComponents: ->
    @getPath().split("/").slice(1)

  getLastPathComponent: ->
    @getPathComponents().slice(-1)[0]

  getExtension: ->
    @getLastPathComponent().match(/\.[^.]*$/)?[0] ? ""

  isHTML: ->
    @getExtension().match(/^(?:|\.(?:htm|html|xhtml))$/)

  isPrefixedBy: (location) ->
    prefixURL = getPrefixURL(location)
    @isEqualTo(location) or stringStartsWith(@absoluteURL, prefixURL)

  isEqualTo: (location) ->
    @absoluteURL is location?.absoluteURL

  toCacheKey: ->
    @requestURL

  toJSON: ->
    @absoluteURL

  toString: ->
    @absoluteURL

  valueOf: ->
    @absoluteURL

  # Private

  getPrefixURL = (location) ->
    addTrailingSlash(location.getOrigin() + location.getPath())

  addTrailingSlash = (url) ->
    if stringEndsWith(url, "/") then url else url + "/"

  stringStartsWith = (string, prefix) ->
    string.slice(0, prefix.length) is prefix

  stringEndsWith = (string, suffix) ->
    string.slice(-suffix.length) is suffix
