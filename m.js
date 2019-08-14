var system = require('system')
var page = require('webpage').create()

var email = ''
var pass = ''
var conversation = system.args[1]
var text = 'Hi! I am Manoj, co-founder of Chatwoot. Thank you for trying us out! \n Have a look around and please feel free to message me here in case of any queries :)'

var steps = [
  function() {
    console.log('Opening messenger.com')
    page.open('https://www.messenger.com/')
  },
  function() {
    console.log('Logging in')
    page.evaluate(function(email, pass) {
      document.querySelector('input[name=email]').value = email
      document.querySelector('input[name=pass]').value = pass
      document.querySelector('#loginbutton').click()
    }, email, pass)
  },
  function() {
    console.log(page.evaluate(function() {
      return document.querySelector('div[role="banner"] a[href="/new"]')
        ? "Logged in" : "Could not log in"
    }))
  },
  function() {
    page.open('https://www.messenger.com/t/' + conversation)
  },
  function() {
    console.log('Talking to', page.evaluate(function() {
      return document.querySelector('div[role="main"] h2').innerText
    }))
  },
  function() {
    text.split('\n').forEach(function(line) {
      page.sendEvent('keypress', line)
      page.sendEvent('keypress', page.event.key.Enter, null, null, 0x02000000 /* shift */)
    })
    page.sendEvent('keypress', page.event.key.Enter)
  },
  function() {
    page.evaluate(function() {
      console.log('Done')
    })
  },
  function() {
    setTimeout(function() { phantom.exit() }, 2000)
  }
]

var stepindex = 0
var loading = false
setInterval(executeRequestsStepByStep, 50)

function executeRequestsStepByStep() {
  if (loading == false && steps[stepindex]) {
    steps[stepindex]()
    stepindex++
  }
}

page.onLoadStarted = function() { loading = true }
page.onLoadFinished = function() { loading = false }
page.onConsoleMessage = function(msg) { console.log(msg) }
