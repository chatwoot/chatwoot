if (typeof Element.prototype.matches !== 'function') {
  Element.prototype.matches = Element.prototype.msMatchesSelector || Element.prototype.mozMatchesSelector || Element.prototype.webkitMatchesSelector || function matches(selector) {
    var element = this
    var elements = (element.document || element.ownerDocument).querySelectorAll(selector)
    var index = 0

    while (elements[index] && elements[index] !== element) {
      ++index
    }

    return Boolean(elements[index])
  }
}

if (typeof Element.prototype.closest !== 'function') {
  Element.prototype.closest = function closest(selector) {
    var element = this

    while (element && element.nodeType === 1) {
      if (element.matches(selector)) {
        return element
      }

      element = element.parentNode
    }

    return null
  }
}

if (typeof Object.assign !== 'function') {
  (function() {
    Object.assign = function(target) {
      'use strict'
      // We must check against these specific cases.
      if (target === undefined || target === null) {
        throw new TypeError('Cannot convert undefined or null to object')
      }

      var output = Object(target)
      for (var index = 1; index < arguments.length; index++) {
        var source = arguments[index]
        if (source !== undefined && source !== null) {
          for (var nextKey in source) {
            if (source.hasOwnProperty(nextKey)) {
              output[nextKey] = source[nextKey]
            }
          }
        }
      }
      return output
    }
  })()
}

function EventSource() {
  var self = this

  self.eventListeners = {}
}

EventSource.prototype.on = function(name, callback) {
  var self = this

  var listeners = self.eventListeners[name]
  if (!listeners)
    listeners = self.eventListeners[name] = []
  listeners.push(callback)
}

EventSource.prototype.dispatch = function(name, data) {
  var self = this

  var listeners = self.eventListeners[name] || []
  listeners.forEach(function(c) {
    requestAnimationFrame(function() { c(data) })
  })
}

function CanvasView(canvas) {
  var self = this

  self.canvas = canvas
}

CanvasView.prototype.setDimensions = function(width, height) {
  var self = this

  if (self.resizeRequestID)
    cancelAnimationFrame(self.resizeRequestID)

  self.resizeRequestID = requestAnimationFrame(self.setDimensionsNow.bind(self, width, height))
}

CanvasView.prototype.setDimensionsNow = function(width, height) {
  var self = this

  if (width === self.width && height === self.height)
    return

  self.width = width
  self.height = height

  self.canvas.style.width = width
  self.canvas.style.height = height

  var ratio = window.devicePixelRatio || 1
  self.canvas.width = width * ratio
  self.canvas.height = height * ratio

  var ctx = self.canvas.getContext('2d')
  ctx.setTransform(1, 0, 0, 1, 0, 0)
  ctx.scale(ratio, ratio)

  self.repaintNow()
}

CanvasView.prototype.paint = function() {
}

CanvasView.prototype.scheduleRepaint = function() {
  var self = this

  if (self.repaintRequestID)
    return

  self.repaintRequestID = requestAnimationFrame(function() {
    self.repaintRequestID = null
    self.repaintNow()
  })
}

CanvasView.prototype.repaintNow = function() {
  var self = this

  self.canvas.getContext('2d').clearRect(0, 0, self.width, self.height)
  self.paint()

  if (self.repaintRequestID) {
    cancelAnimationFrame(self.repaintRequestID)
    self.repaintRequestID = null
  }
}

function Flamechart(canvas, data, dataRange, info) {
  var self = this

  CanvasView.call(self, canvas)
  EventSource.call(self)

  self.canvas = canvas
  self.data = data
  self.dataRange = dataRange
  self.info = info

  self.viewport = {
    x: dataRange.minX,
    y: dataRange.minY,
    width: dataRange.maxX - dataRange.minX,
    height: dataRange.maxY - dataRange.minY,
  }
}

Flamechart.prototype = Object.create(CanvasView.prototype)
Flamechart.prototype.constructor = Flamechart
Object.assign(Flamechart.prototype, EventSource.prototype)

Flamechart.prototype.xScale = function(x) {
  var self = this
  return self.widthScale(x - self.viewport.x)
}

Flamechart.prototype.yScale = function(y) {
  var self = this
  return self.heightScale(y - self.viewport.y)
}

Flamechart.prototype.widthScale = function(width) {
  var self = this
  return width * self.width / self.viewport.width
}

Flamechart.prototype.heightScale = function(height) {
  var self = this
  return height * self.height / self.viewport.height
}

Flamechart.prototype.frameRect = function(f) {
  return {
    x: f.x,
    y: f.y,
    width: f.width,
    height: 1,
  }
}

Flamechart.prototype.dataToCanvas = function(r) {
  var self = this

  return {
    x: self.xScale(r.x),
    y: self.yScale(r.y),
    width: self.widthScale(r.width),
    height: self.heightScale(r.height),
  }
}

Flamechart.prototype.setViewport = function(viewport) {
  var self = this

  if (self.viewport.x === viewport.x &&
      self.viewport.y === viewport.y &&
      self.viewport.width === viewport.width &&
      self.viewport.height === viewport.height)
    return

  self.viewport = viewport

  self.scheduleRepaint()

  self.dispatch('viewportchanged', { current: viewport })
}

Flamechart.prototype.paint = function(opacity, frames, gemName) {
  var self = this

  var ctx = self.canvas.getContext('2d')

  ctx.strokeStyle = 'rgba(0, 0, 0, 0.2)'

  if (self.showLabels) {
    ctx.textBaseline = 'middle'
    ctx.font = '11px ' + getComputedStyle(this.canvas).fontFamily
    // W tends to be one of the widest characters (and if the font is truly
    // fixed-width then any character will do).
    var characterWidth = ctx.measureText('WWWW').width / 4
  }

  if (typeof opacity === 'undefined')
    opacity = 1

  frames = frames || self.data

  var blocksByColor = {}

  frames.forEach(function(f) {
    if (gemName && f.gemName !== gemName)
      return

    var r = self.dataToCanvas(self.frameRect(f))

    if (r.x >= self.width ||
        r.y >= self.height ||
        (r.x + r.width) <= 0 ||
        (r.y + r.height) <= 0) {
      return
    }

    var i = self.info[f.frame_id]
    var color = colorString(i.color, opacity)
    var colorBlocks = blocksByColor[color]
    if (!colorBlocks)
      colorBlocks = blocksByColor[color] = []
    colorBlocks.push({ rect: r, text: f.frame })
  })

  var textBlocks = []

  Object.keys(blocksByColor).forEach(function(color) {
    ctx.fillStyle = color

    blocksByColor[color].forEach(function(block) {
      if (opacity < 1)
        ctx.clearRect(block.rect.x, block.rect.y, block.rect.width, block.rect.height)

      ctx.fillRect(block.rect.x, block.rect.y, block.rect.width, block.rect.height)

      if (block.rect.width > 4 && block.rect.height > 4)
        ctx.strokeRect(block.rect.x, block.rect.y, block.rect.width, block.rect.height)

      if (!self.showLabels || block.rect.width / characterWidth < 4)
        return

      textBlocks.push(block)
    })
  })

  ctx.fillStyle = '#000'
  textBlocks.forEach(function(block) {
    var text = block.text
    var textRect = Object.assign({}, block.rect)
    textRect.x += 1
    textRect.width -= 2
    if (textRect.width < text.length * characterWidth * 0.75)
      text = centerTruncate(block.text, Math.floor(textRect.width / characterWidth))
    ctx.fillText(text, textRect.x, textRect.y + textRect.height / 2, textRect.width)
  })
}

Flamechart.prototype.frameAtPoint = function(x, y) {
  var self = this

  return self.data.find(function(d) {
    var r = self.dataToCanvas(self.frameRect(d))

    return r.x <= x
      && r.x + r.width >= x
      && r.y <= y
      && r.y + r.height >= y
  })
}

function MainFlamechart(canvas, data, dataRange, info) {
  var self = this

  Flamechart.call(self, canvas, data, dataRange, info)

  self.showLabels = true

  self.canvas.addEventListener('mousedown', self.onMouseDown.bind(self))
  self.canvas.addEventListener('mousemove', self.onMouseMove.bind(self))
  self.canvas.addEventListener('mouseout', self.onMouseOut.bind(self))
  self.canvas.addEventListener('wheel', self.onWheel.bind(self))
}

MainFlamechart.prototype = Object.create(Flamechart.prototype)

MainFlamechart.prototype.setDimensionsNow = function(width, height) {
  var self = this

  var viewport = Object.assign({}, self.viewport)
  viewport.height = height / 16
  self.setViewport(viewport)

  CanvasView.prototype.setDimensionsNow.call(self, width, height)
}

MainFlamechart.prototype.onMouseDown = function(e) {
  var self = this

  if (e.button !== 0)
    return

  captureMouse({
    mouseup: self.onMouseUp.bind(self),
    mousemove: self.onMouseMove.bind(self),
  })

  var clientRect = self.canvas.getBoundingClientRect()
  var currentX = e.clientX - clientRect.left
  var currentY = e.clientY - clientRect.top

  self.dragging = true
  self.dragInfo = {
    mouse: { x: currentX, y: currentY },
    viewport: { x: self.viewport.x, y: self.viewport.y },
  }

  e.preventDefault()
}

MainFlamechart.prototype.onMouseUp = function(e) {
  var self = this

  if (!self.dragging)
    return

  releaseCapture()

  self.dragging = false
  e.preventDefault()
}

MainFlamechart.prototype.onMouseMove = function(e) {
  var self = this

  var clientRect = self.canvas.getBoundingClientRect()
  var currentX = e.clientX - clientRect.left
  var currentY = e.clientY - clientRect.top

  if (self.dragging) {
    var viewport = Object.assign({}, self.viewport)
    viewport.x = self.dragInfo.viewport.x - (currentX - self.dragInfo.mouse.x) * viewport.width / self.width
    viewport.y = self.dragInfo.viewport.y - (currentY - self.dragInfo.mouse.y) * viewport.height / self.height
    viewport.x = Math.min(self.dataRange.maxX - viewport.width, Math.max(self.dataRange.minX, viewport.x))
    viewport.y = Math.min(self.dataRange.maxY - viewport.height, Math.max(self.dataRange.minY, viewport.y))
    self.setViewport(viewport)
    return
  }

  var frame = self.frameAtPoint(currentX, currentY)
  self.setHoveredFrame(frame)
}

MainFlamechart.prototype.onMouseOut = function() {
  var self = this

  if (self.dragging)
    return

  self.setHoveredFrame(null)
}

MainFlamechart.prototype.onWheel = function(e) {
  var self = this

  var deltaX = e.deltaX
  var deltaY = e.deltaY

  if (e.deltaMode == WheelEvent.prototype.DOM_DELTA_LINE) {
    deltaX *= 11
    deltaY *= 11
  }

  if (e.shiftKey) {
    if ('webkitDirectionInvertedFromDevice' in e) {
      if (e.webkitDirectionInvertedFromDevice)
        deltaY *= -1
    } else if (/Mac OS X/.test(navigator.userAgent)) {
      // Assume that most Mac users have "Scroll direction: Natural" enabled.
      deltaY *= -1
    }

    var mouseWheelZoomSpeed = 1 / 120
    self.handleZoomGesture(Math.pow(1.2, -(deltaY || deltaX) * mouseWheelZoomSpeed), e.offsetX)
    e.preventDefault()
    return
  }

  var viewport = Object.assign({}, self.viewport)
  viewport.x += deltaX * viewport.width / (self.dataRange.maxX - self.dataRange.minX)
  viewport.x = Math.min(self.dataRange.maxX - viewport.width, Math.max(self.dataRange.minX, viewport.x))
  viewport.y += (deltaY / 8) * viewport.height / (self.dataRange.maxY - self.dataRange.minY)
  viewport.y = Math.min(self.dataRange.maxY - viewport.height, Math.max(self.dataRange.minY, viewport.y))
  self.setViewport(viewport)
  e.preventDefault()
}

MainFlamechart.prototype.handleZoomGesture = function(zoom, originX) {
  var self = this

  var viewport = Object.assign({}, self.viewport)
  var ratioX = originX / self.width

  var newWidth = Math.min(viewport.width / zoom, self.dataRange.maxX - self.dataRange.minX)
  viewport.x = Math.max(self.dataRange.minX, viewport.x + (viewport.width - newWidth) * ratioX)
  viewport.width = Math.min(newWidth, self.dataRange.maxX - viewport.x)

  self.setViewport(viewport)
}

MainFlamechart.prototype.setHoveredFrame = function(frame) {
  var self = this

  if (frame === self.hoveredFrame)
    return

  var previous = self.hoveredFrame
  self.hoveredFrame = frame

  self.dispatch('hoveredframechanged', { previous: previous, current: self.hoveredFrame })
}

function OverviewFlamechart(container, viewportOverlay, data, dataRange, info) {
  var self = this

  Flamechart.call(self, container.querySelector('.overview'), data, dataRange, info)

  self.container = container

  self.showLabels = false

  self.viewportOverlay = viewportOverlay

  self.canvas.addEventListener('mousedown', self.onMouseDown.bind(self))
  self.viewportOverlay.addEventListener('mousedown', self.onOverlayMouseDown.bind(self))
}

OverviewFlamechart.prototype = Object.create(Flamechart.prototype)

OverviewFlamechart.prototype.setViewportOverlayRect = function(r) {
  var self = this

  self.viewportOverlayRect = r

  r = self.dataToCanvas(r)
  r.width = Math.max(2, r.width)
  r.height = Math.max(2, r.height)

  if ('transform' in self.viewportOverlay.style) {
    self.viewportOverlay.style.transform = 'translate(' + r.x + 'px, ' + r.y + 'px) scale(' + r.width + ', ' + r.height + ')'
  } else {
    self.viewportOverlay.style.left = r.x
    self.viewportOverlay.style.top = r.y
    self.viewportOverlay.style.width = r.width
    self.viewportOverlay.style.height = r.height
  }
}

OverviewFlamechart.prototype.onMouseDown = function(e) {
  var self = this

  captureMouse({
    mouseup: self.onMouseUp.bind(self),
    mousemove: self.onMouseMove.bind(self),
  })

  self.dragging = true
  self.dragStartX = e.clientX - self.canvas.getBoundingClientRect().left

  self.handleDragGesture(e)

  e.preventDefault()
}

OverviewFlamechart.prototype.onMouseUp = function(e) {
  var self = this

  if (!self.dragging)
    return

  releaseCapture()

  self.dragging = false

  self.handleDragGesture(e)

  e.preventDefault()
}

OverviewFlamechart.prototype.onMouseMove = function(e) {
  var self = this

  if (!self.dragging)
    return

  self.handleDragGesture(e)

  e.preventDefault()
}

OverviewFlamechart.prototype.handleDragGesture = function(e) {
  var self = this

  var clientRect = self.canvas.getBoundingClientRect()
  var currentX = e.clientX - clientRect.left
  var currentY = e.clientY - clientRect.top

  if (self.dragCurrentX === currentX)
    return

  self.dragCurrentX = currentX

  var minX = Math.min(self.dragStartX, self.dragCurrentX)
  var maxX = Math.max(self.dragStartX, self.dragCurrentX)

  var rect = Object.assign({}, self.viewportOverlayRect)
  rect.x = minX / self.width * self.viewport.width + self.viewport.x
  rect.width = Math.max(self.viewport.width / 1000, (maxX - minX) / self.width * self.viewport.width)

  rect.y = Math.max(self.viewport.y, Math.min(self.viewport.height - self.viewport.y, currentY / self.height * self.viewport.height + self.viewport.y - rect.height / 2))

  self.setViewportOverlayRect(rect)
  self.dispatch('overlaychanged', { current: self.viewportOverlayRect })
}

OverviewFlamechart.prototype.onOverlayMouseDown = function(e) {
  var self = this

  captureMouse({
    mouseup: self.onOverlayMouseUp.bind(self),
    mousemove: self.onOverlayMouseMove.bind(self),
  })

  self.overlayDragging = true
  self.overlayDragInfo = {
    mouse: { x: e.clientX, y: e.clientY },
    rect: Object.assign({}, self.viewportOverlayRect),
  }
  self.viewportOverlay.classList.add('moving')

  self.handleOverlayDragGesture(e)

  e.preventDefault()
}

OverviewFlamechart.prototype.onOverlayMouseUp = function(e) {
  var self = this

  if (!self.overlayDragging)
    return

  releaseCapture()

  self.overlayDragging = false
  self.viewportOverlay.classList.remove('moving')

  self.handleOverlayDragGesture(e)

  e.preventDefault()
}

OverviewFlamechart.prototype.onOverlayMouseMove = function(e) {
  var self = this

  if (!self.overlayDragging)
    return

  self.handleOverlayDragGesture(e)

  e.preventDefault()
}

OverviewFlamechart.prototype.handleOverlayDragGesture = function(e) {
  var self = this

  var deltaX = (e.clientX - self.overlayDragInfo.mouse.x) / self.width * self.viewport.width
  var deltaY = (e.clientY - self.overlayDragInfo.mouse.y) / self.height * self.viewport.height

  var rect = Object.assign({}, self.overlayDragInfo.rect)
  rect.x += deltaX
  rect.y += deltaY
  rect.x = Math.max(self.viewport.x, Math.min(self.viewport.x + self.viewport.width - rect.width, rect.x))
  rect.y = Math.max(self.viewport.y, Math.min(self.viewport.y + self.viewport.height - rect.height, rect.y))

  self.setViewportOverlayRect(rect)
  self.dispatch('overlaychanged', { current: self.viewportOverlayRect })
}

function FlamegraphView(data, info, sortedGems) {
  var self = this

  self.data = data
  self.info = info

  self.dataRange = self.computeDataRange()

  self.mainChart = new MainFlamechart(document.querySelector('.flamegraph'), data, self.dataRange, info)
  self.overview = new OverviewFlamechart(document.querySelector('.overview-container'), document.querySelector('.overview-viewport-overlay'), data, self.dataRange, info)
  self.infoElement = document.querySelector('.info')

  self.mainChart.on('hoveredframechanged', self.onHoveredFrameChanged.bind(self))
  self.mainChart.on('viewportchanged', self.onViewportChanged.bind(self))
  self.overview.on('overlaychanged', self.onOverlayChanged.bind(self))

  var legend = document.querySelector('.legend')
  self.renderLegend(legend, sortedGems)

  legend.addEventListener('mousemove', self.onLegendMouseMove.bind(self))
  legend.addEventListener('mouseout', self.onLegendMouseOut.bind(self))

  window.addEventListener('resize', self.updateDimensions.bind(self))

  self.updateDimensions()
}

FlamegraphView.prototype.updateDimensions = function() {
  var self = this

  var margin = {top: 10, right: 10, bottom: 10, left: 10}
  var width = window.innerWidth - 200 - margin.left - margin.right
  var mainChartHeight = Math.ceil(window.innerHeight * 0.80) - margin.top - margin.bottom
  var overviewHeight = Math.floor(window.innerHeight * 0.20) - 60 - margin.top - margin.bottom

  self.mainChart.setDimensions(width + margin.left + margin.right, mainChartHeight + margin.top + margin.bottom)
  self.overview.setDimensions(width + margin.left + margin.right, overviewHeight + margin.top + margin.bottom)
  self.overview.setViewportOverlayRect(self.mainChart.viewport)
}

FlamegraphView.prototype.computeDataRange = function() {
  var self = this

  var range = { minX: Infinity, minY: Infinity, maxX: -Infinity, maxY: -Infinity }
  self.data.forEach(function(d) {
    range.minX = Math.min(range.minX, d.x)
    range.minY = Math.min(range.minY, d.y)
    range.maxX = Math.max(range.maxX, d.x + d.width)
    range.maxY = Math.max(range.maxY, d.y + 1)
  })

  return range
}

FlamegraphView.prototype.onHoveredFrameChanged = function(data) {
  var self = this

  self.updateInfo(data.current)

  if (data.previous)
    self.repaintFrames(1, self.info[data.previous.frame_id].frames)

  if (data.current)
    self.repaintFrames(0.5, self.info[data.current.frame_id].frames)
}

FlamegraphView.prototype.repaintFrames = function(opacity, frames) {
  var self = this

  self.mainChart.paint(opacity, frames)
  self.overview.paint(opacity, frames)
}

FlamegraphView.prototype.updateInfo = function(frame) {
  var self = this

  if (!frame) {
    self.infoElement.style.backgroundColor = ''
    self.infoElement.querySelector('.frame').textContent = ''
    self.infoElement.querySelector('.file').textContent = ''
    self.infoElement.querySelector('.samples').textContent = ''
    self.infoElement.querySelector('.exclusive').textContent = ''
    return
  }

  var i = self.info[frame.frame_id]
  var shortFile = frame.file.replace(/^.+\/(gems|app|lib|config|jobs)/, '$1')
  var sData = self.samplePercentRaw(i.samples.length, frame.topFrame ? frame.topFrame.exclusiveCount : 0)

  self.infoElement.style.backgroundColor = colorString(i.color, 1)
  self.infoElement.querySelector('.frame').textContent = frame.frame
  self.infoElement.querySelector('.file').textContent = shortFile
  self.infoElement.querySelector('.samples').textContent = sData[0] + ' samples (' + sData[1] + '%)'
  if (sData[3])
    self.infoElement.querySelector('.exclusive').textContent = sData[2] + ' exclusive (' + sData[3] + '%)'
  else
    self.infoElement.querySelector('.exclusive').textContent = ''
}

FlamegraphView.prototype.samplePercentRaw = function(samples, exclusive) {
  var self = this

  var ret = [samples, ((samples / self.dataRange.maxX) * 100).toFixed(2)]
  if (exclusive)
    ret = ret.concat([exclusive, ((exclusive / self.dataRange.maxX) * 100).toFixed(2)])
  return ret
}

FlamegraphView.prototype.onViewportChanged = function(data) {
  var self = this

  self.overview.setViewportOverlayRect(data.current)
}

FlamegraphView.prototype.onOverlayChanged = function(data) {
  var self = this

  self.mainChart.setViewport(data.current)
}

FlamegraphView.prototype.renderLegend = function(element, sortedGems) {
  var self = this

  var fragment = document.createDocumentFragment()

  sortedGems.forEach(function(gem) {
    var sData = self.samplePercentRaw(gem.samples.length)
    var node = document.createElement('div')
    node.className = 'legend-gem'
    node.setAttribute('data-gem-name', gem.name)
    node.style.backgroundColor = colorString(gem.color, 1)

    var span = document.createElement('span')
    span.style.float = 'right'
    span.textContent = sData[0] + 'x'
    span.appendChild(document.createElement('br'))
    span.appendChild(document.createTextNode(sData[1] + '%'))
    node.appendChild(span)

    var name = document.createElement('div')
    name.className = 'name'
    name.textContent = gem.name
    name.appendChild(document.createElement('br'))
    name.appendChild(document.createTextNode('\u00a0'))
    node.appendChild(name)

    fragment.appendChild(node)
  })

  element.appendChild(fragment)
}

FlamegraphView.prototype.onLegendMouseMove = function(e) {
  var self = this

  var gemElement = e.target.closest('.legend-gem')
  var gemName = gemElement.getAttribute('data-gem-name')

  if (self.hoveredGemName === gemName)
    return

  if (self.hoveredGemName) {
    self.mainChart.paint(1, null, self.hoveredGemName)
    self.overview.paint(1, null, self.hoveredGemName)
  }

  self.hoveredGemName = gemName

  self.mainChart.paint(0.5, null, self.hoveredGemName)
  self.overview.paint(0.5, null, self.hoveredGemName)
}

FlamegraphView.prototype.onLegendMouseOut = function() {
  var self = this

  if (!self.hoveredGemName)
    return

  self.mainChart.paint(1, null, self.hoveredGemName)
  self.overview.paint(1, null, self.hoveredGemName)
  self.hoveredGemName = null
}

var capturingListeners = null
function captureMouse(listeners) {
  if (capturingListeners)
    releaseCapture()

  for (var name in listeners)
    document.addEventListener(name, listeners[name], true)
  capturingListeners = listeners
}

function releaseCapture() {
  if (!capturingListeners)
    return

  for (var name in capturingListeners)
    document.removeEventListener(name, capturingListeners[name], true)
  capturingListeners = null
}

function guessGem(frame) {
  var split = frame.split('/gems/')
  if (split.length === 1) {
    split = frame.split('/app/')
    if (split.length === 1) {
      split = frame.split('/lib/')
    } else {
      return split[split.length - 1].split('/')[0]
    }

    split = split[Math.max(split.length - 2, 0)].split('/')
    return split[split.length - 1].split(':')[0]
  }
  else
  {
    return split[split.length - 1].split('/')[0].split('-', 2)[0]
  }
}

function color() {
  var r = parseInt(205 + Math.random() * 50)
  var g = parseInt(Math.random() * 230)
  var b = parseInt(Math.random() * 55)
  return [r, g, b]
}

// http://stackoverflow.com/a/7419630
function rainbow(numOfSteps, step) {
    // This function generates vibrant, "evenly spaced" colours (i.e. no clustering). This is ideal for creating easily distiguishable vibrant markers in Google Maps and other apps.
    // Adam Cole, 2011-Sept-14
    // HSV to RBG adapted from: http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
  var r, g, b
  var h = step / numOfSteps
  var i = ~~(h * 6)
  var f = h * 6 - i
  var q = 1 - f
  switch (i % 6) {
    case 0: r = 1, g = f, b = 0; break
    case 1: r = q, g = 1, b = 0; break
    case 2: r = 0, g = 1, b = f; break
    case 3: r = 0, g = q, b = 1; break
    case 4: r = f, g = 0, b = 1; break
    case 5: r = 1, g = 0, b = q; break
  }
  return [Math.floor(r * 255), Math.floor(g * 255), Math.floor(b * 255)]
}

function colorString(color, opacity) {
  if (typeof opacity === 'undefined')
    opacity = 1
  return 'rgba(' + color.join(',') + ',' + opacity + ')'
}

// http://stackoverflow.com/questions/1960473/unique-values-in-an-array
function getUnique(orig) {
  var o = {}
  for (var i = 0; i < orig.length; i++) o[orig[i]] = 1
  return Object.keys(o)
}

function centerTruncate(text, maxLength) {
  var charactersToKeep = maxLength - 1
  if (charactersToKeep <= 0)
    return ''
  if (text.length <= charactersToKeep)
    return text

  var prefixLength = Math.ceil(charactersToKeep / 2)
  var suffixLength = charactersToKeep - prefixLength
  var prefix = text.substr(0, prefixLength)
  var suffix = suffixLength > 0 ? text.substr(-suffixLength) : ''

  return [prefix, '\u2026', suffix].join('')
}

function flamegraph(data) {
  var info = {}
  data.forEach(function(d) {
    var i = info[d.frame_id]
    if (!i)
      info[d.frame_id] = i = {frames: [], samples: [], color: color()}
    i.frames.push(d)
    for (var j = 0; j < d.width; j++) {
      i.samples.push(d.x + j)
    }
  })

  // Samples may overlap on the same line
  for (var r in info) {
    if (info[r].samples) {
      info[r].samples = getUnique(info[r].samples)
    }
  }

  // assign some colors, analyze samples per gem
  var gemStats = {}
  var topFrames = {}
  var lastFrame = {frame: 'd52e04d-df28-41ed-a215-b6ec840a8ea5', x: -1}

  data.forEach(function(d) {
    var gem = guessGem(d.file)
    var stat = gemStats[gem]
    d.gemName = gem

    if (!stat) {
      gemStats[gem] = stat = {name: gem, samples: [], frames: []}
    }

    stat.frames.push(d.frame_id)
    for (var j = 0; j < d.width; j++) {
      stat.samples.push(d.x + j)
    }
    // This assumes the traversal is in order
    if (lastFrame.x !== d.x) {
      var topFrame = topFrames[lastFrame.frame_id]
      if (!topFrame) {
        topFrames[lastFrame.frame_id] = topFrame = {exclusiveCount: 0}
      }
      topFrame.exclusiveCount += 1
      lastFrame.topFrame = topFrame
    }
    lastFrame = d
  })

  var topFrame = topFrames[lastFrame.frame_id]
  if (!topFrame) {
    topFrames[lastFrame.frame_id] = topFrame = {exclusiveCount: 0}
  }
  topFrame.exclusiveCount += 1
  lastFrame.topFrame = topFrame

  var totalGems = 0
  for (var k in gemStats) {
    totalGems++
    gemStats[k].samples = getUnique(gemStats[k].samples)
  }

  var gemsSorted = Object.keys(gemStats).map(function(k) { return gemStats[k] })
  gemsSorted.sort(function(a, b) { return b.samples.length - a.samples.length })

  var currentIndex = 0
  gemsSorted.forEach(function(stat) {
    stat.color = rainbow(totalGems, currentIndex)
    currentIndex += 1

    for (var x = 0; x < stat.frames.length; x++) {
      info[stat.frames[x]].color = stat.color
    }
  })

  new FlamegraphView(data, info, gemsSorted)
}
