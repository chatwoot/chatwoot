// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
import 'cypress-file-upload'
import FileUpload from '../../../src/FileUpload'

//
// -- This is a parent command --
Cypress.Commands.add('formulate', (type, props = {}) => {
  cy.visit('http://localhost:7872')

  cy.window().then(window => {
    window.showTest({
      ...{
        component: 'FormulateInput',
        props: {
          type: type,
          outerClass: ['input-under-test'],
          name: props.name || 'inputUnderTest',
          ...props
        },
      },
      ...(Object.prototype.hasOwnProperty.call(props, 'value') ? { value: props.value } : {})
    })
  })

  cy.get('.input-under-test')
    .as('wrapper')
})


Cypress.Commands.add('modeledValue', () => {
  cy.window().then(window => {
    return window.getInputValue()
  })
})

Cypress.Commands.add('submittedValue', (name = 'inputUnderTest') => {
  cy.window().then(window => {
    // wait before executing, this allows us to prevent race conditions where
    // formSubmitted.finally() has not yet been called but we're already
    // re-running a submission test
    cy.wait(500)
    return window.getSubmittedValue()
      .then(value => cy.wrap(value[name]))
  })
})

// -- This is a child command --

Cypress.Commands.add('shouldHaveTrimmedText', { prevSubject: true }, (subject, equalTo) => {
  if (isNaN(equalTo)) {
      expect(subject.text().trim()).to.eq(equalTo);
  } else {
      expect(parseInt(subject.text())).to.eq(equalTo);
  }
  return subject;
})

// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })
