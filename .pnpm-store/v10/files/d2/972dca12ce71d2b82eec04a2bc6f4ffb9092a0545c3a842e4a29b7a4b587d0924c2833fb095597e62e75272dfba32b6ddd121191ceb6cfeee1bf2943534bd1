class Turbolinks.Renderer
  @render: (delegate, callback, args...) ->
    renderer = new this args...
    renderer.delegate = delegate
    renderer.render(callback)
    renderer

  renderView: (callback) ->
    @delegate.viewWillRender(@newBody)
    callback()
    @delegate.viewRendered(@newBody)

  invalidateView: ->
    @delegate.viewInvalidated()

  createScriptElement: (element) ->
    if element.getAttribute("data-turbolinks-eval") is "false"
      element
    else
      createdScriptElement = document.createElement("script")
      createdScriptElement.textContent = element.textContent
      createdScriptElement.async = false
      copyElementAttributes(createdScriptElement, element)
      createdScriptElement

  copyElementAttributes = (destinationElement, sourceElement) ->
    for {name, value} in sourceElement.attributes
      destinationElement.setAttribute(name, value)
