class Turbolinks.HeadDetails
  @fromHeadElement: (headElement) ->
    new this headElement?.childNodes ? []

  constructor: (childNodes) ->
    @elements = {}
    for node in childNodes when node.nodeType is Node.ELEMENT_NODE
      key = node.outerHTML
      data = @elements[key] ?=
        type: elementType(node)
        tracked: elementIsTracked(node)
        elements: []
      data.elements.push(node)

  hasElementWithKey: (key) ->
    key of @elements

  getTrackedElementSignature: ->
    (key for key, {tracked} of @elements when tracked).join("")

  getScriptElementsNotInDetails: (headDetails) ->
    @getElementsMatchingTypeNotInDetails("script", headDetails)

  getStylesheetElementsNotInDetails: (headDetails) ->
    @getElementsMatchingTypeNotInDetails("stylesheet", headDetails)

  getElementsMatchingTypeNotInDetails: (matchedType, headDetails) ->
    elements[0] for key, {type, elements} of @elements when type is matchedType and not headDetails.hasElementWithKey(key)

  getProvisionalElements: ->
    provisionalElements = []
    for key, {type, tracked, elements} of @elements
      if not type? and not tracked
        provisionalElements.push(elements...)
      else if elements.length > 1
        provisionalElements.push(elements[1...]...)
    provisionalElements

  getMetaValue: (name) ->
    @findMetaElementByName(name)?.getAttribute("content")

  findMetaElementByName: (name) ->
    element = undefined
    for key, {elements} of @elements
      if elementIsMetaElementWithName(elements[0], name)
        element = elements[0]
    element

  elementType = (element) ->
    if elementIsScript(element)
      "script"
    else if elementIsStylesheet(element)
      "stylesheet"

  elementIsTracked = (element) ->
    element.getAttribute("data-turbolinks-track") is "reload"

  elementIsScript = (element) ->
    tagName = element.tagName.toLowerCase()
    tagName is "script"

  elementIsStylesheet = (element) ->
    tagName = element.tagName.toLowerCase()
    tagName is "style" or (tagName is "link" and element.getAttribute("rel") is "stylesheet")

  elementIsMetaElementWithName = (element, name) ->
    tagName = element.tagName.toLowerCase()
    tagName is "meta" and element.getAttribute("name") is name
