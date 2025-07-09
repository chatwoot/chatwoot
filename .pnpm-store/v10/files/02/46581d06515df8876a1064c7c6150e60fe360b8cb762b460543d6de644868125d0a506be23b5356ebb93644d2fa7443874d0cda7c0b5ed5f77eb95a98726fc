#= require ./renderer

class Turbolinks.ErrorRenderer extends Turbolinks.Renderer
  constructor: (html) ->
    htmlElement = document.createElement("html")
    htmlElement.innerHTML = html
    @newHead = htmlElement.querySelector("head")
    @newBody = htmlElement.querySelector("body")

  render: (callback) ->
    @renderView =>
      @replaceHeadAndBody()
      @activateBodyScriptElements()
      callback()

  replaceHeadAndBody: ->
    {head, body} = document
    head.parentNode.replaceChild(@newHead, head)
    body.parentNode.replaceChild(@newBody, body)

  activateBodyScriptElements: ->
    for replaceableElement in @getScriptElements()
      element = @createScriptElement(replaceableElement)
      replaceableElement.parentNode.replaceChild(element, replaceableElement)

  getScriptElements: ->
    document.documentElement.querySelectorAll("script")
