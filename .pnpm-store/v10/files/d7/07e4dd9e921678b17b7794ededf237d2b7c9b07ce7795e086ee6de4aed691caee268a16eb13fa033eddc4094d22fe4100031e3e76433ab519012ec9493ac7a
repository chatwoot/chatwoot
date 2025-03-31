#= require ./renderer

class Turbolinks.SnapshotRenderer extends Turbolinks.Renderer
  constructor: (@currentSnapshot, @newSnapshot, @isPreview) ->
    @currentHeadDetails = @currentSnapshot.headDetails
    @newHeadDetails = @newSnapshot.headDetails
    @currentBody = @currentSnapshot.bodyElement
    @newBody = @newSnapshot.bodyElement

  render: (callback) ->
    if @shouldRender()
      @mergeHead()
      @renderView =>
        @replaceBody()
        @focusFirstAutofocusableElement() unless @isPreview
        callback()
    else
      @invalidateView()

  mergeHead: ->
    @copyNewHeadStylesheetElements()
    @copyNewHeadScriptElements()
    @removeCurrentHeadProvisionalElements()
    @copyNewHeadProvisionalElements()

  replaceBody: ->
    placeholders = @relocateCurrentBodyPermanentElements()
    @activateNewBodyScriptElements()
    @assignNewBody()
    @replacePlaceholderElementsWithClonedPermanentElements(placeholders)

  shouldRender: ->
    @newSnapshot.isVisitable() and @trackedElementsAreIdentical()

  trackedElementsAreIdentical: ->
    @currentHeadDetails.getTrackedElementSignature() is @newHeadDetails.getTrackedElementSignature()

  copyNewHeadStylesheetElements: ->
    for element in @getNewHeadStylesheetElements()
      document.head.appendChild(element)

  copyNewHeadScriptElements: ->
    for element in @getNewHeadScriptElements()
      document.head.appendChild(@createScriptElement(element))

  removeCurrentHeadProvisionalElements: ->
    for element in @getCurrentHeadProvisionalElements()
      document.head.removeChild(element)

  copyNewHeadProvisionalElements: ->
    for element in @getNewHeadProvisionalElements()
      document.head.appendChild(element)

  relocateCurrentBodyPermanentElements: ->
    for permanentElement in @getCurrentBodyPermanentElements()
      placeholder = createPlaceholderForPermanentElement(permanentElement)
      newElement = @newSnapshot.getPermanentElementById(permanentElement.id)
      replaceElementWithElement(permanentElement, placeholder.element)
      replaceElementWithElement(newElement, permanentElement)
      placeholder

  replacePlaceholderElementsWithClonedPermanentElements: (placeholders) ->
    for { element, permanentElement } in placeholders
      clonedElement = permanentElement.cloneNode(true)
      replaceElementWithElement(element, clonedElement)

  activateNewBodyScriptElements: ->
    for inertScriptElement in @getNewBodyScriptElements()
      activatedScriptElement = @createScriptElement(inertScriptElement)
      replaceElementWithElement(inertScriptElement, activatedScriptElement)

  assignNewBody: ->
    document.body = @newBody

  focusFirstAutofocusableElement: ->
    @newSnapshot.findFirstAutofocusableElement()?.focus()

  getNewHeadStylesheetElements: ->
    @newHeadDetails.getStylesheetElementsNotInDetails(@currentHeadDetails)

  getNewHeadScriptElements: ->
    @newHeadDetails.getScriptElementsNotInDetails(@currentHeadDetails)

  getCurrentHeadProvisionalElements: ->
    @currentHeadDetails.getProvisionalElements()

  getNewHeadProvisionalElements: ->
    @newHeadDetails.getProvisionalElements()

  getCurrentBodyPermanentElements: ->
    @currentSnapshot.getPermanentElementsPresentInSnapshot(@newSnapshot)

  getNewBodyScriptElements: ->
    @newBody.querySelectorAll("script")

createPlaceholderForPermanentElement = (permanentElement) ->
  element = document.createElement("meta")
  element.setAttribute("name", "turbolinks-permanent-placeholder")
  element.setAttribute("content", permanentElement.id)
  { element, permanentElement }

replaceElementWithElement = (fromElement, toElement) ->
  if parentElement = fromElement.parentNode
    parentElement.replaceChild(toElement, fromElement)
