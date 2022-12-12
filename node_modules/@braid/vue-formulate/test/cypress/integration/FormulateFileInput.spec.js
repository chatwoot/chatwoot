import FileUpload from '../../../src/FileUpload'

describe('FormulateFileInput', () => {

  it('Can have one file displayed, removed, and re-added', () => {
    cy.formulate('file').find('input')
      .attachFile('1x1.png', { force: true })

    cy.get('@wrapper')
      .find('ul.formulate-files li')
      .should('have.length', 1)

    cy.get('@wrapper')
      .find('.formulate-file .formulate-file-name')
      .should('contain.text', '1x1.png')

    cy.modeledValue().should('have.nested.property', 'constructor.name', 'FileUpload')
    cy.submittedValue()
      .should('have.lengthOf', 1)
      .should('have.nested.property', '[0].name', '1x1.png')

    cy.get('@wrapper')
      .find('.formulate-file-remove')
      .click()

    cy.submittedValue()
      .should('have.lengthOf', 0)

    cy.get('@wrapper').find('input')
      .attachFile('1x1.png', { force: true })

    cy.submittedValue()
      .should('have.lengthOf', 1)
  })

  it('Can have multiple files displayed and removed', () => {
    cy.formulate('file', { multiple: true })
      .find('input')
      .attachFile('1x1.png', { force: true })
      .attachFile('2x2.png', { force: true })

    cy.submittedValue()
      .should('have.length', 2)

    cy.get('@wrapper')
      .find('.formulate-file-remove')
      .first()
      .click()

    cy.submittedValue()
      .should('have.lengthOf', 1)
      .should('have.nested.property', '[0].name')
  })

  it('It can remove invalid mime types', () => {
    cy.formulate('file', {
      validation: 'mime:application/pdf'
    })
      .find('input')
      .attachFile('1x1.png', { force: true })

    cy.get('@wrapper')
      .find('.formulate-file-remove')
      .first()
      .click()

    cy.submittedValue()
      .should('have.lengthOf', 0)
  })

  it('It can hydrate a file input, and submit its value', () => {
    cy.formulate('file', {
      multiple: true,
      value: [
        {
          url: '/uploads/example.pdf'
        },
        {
          url: '/uploads/example2.pdf',
          name: 'super-example.pdf'
        }
      ]
    })

    cy.get('@wrapper')
      .find('.formulate-file-name')
      .first()
      .should('have.text', 'example.pdf')

    cy.window().then(window => window.submitForm())

    cy.get('.formulate-file-progress')
      .should('not.exist')

      cy.submittedValue()
      .should('eql', [
        {
          url: '/uploads/example.pdf'
        },
        {
          url: '/uploads/example2.pdf',
          name: 'super-example.pdf'
        }
      ])
  })

  it('Emits file-upload-progress and file-upload-complete events', () => {
    const listeners = {
      uploadProgress: () => {},
      uploadComplete: () => {},
    }
    cy.spy(listeners, 'uploadProgress')
    cy.spy(listeners, 'uploadComplete')
    cy.formulate('file', {
      multiple: true,
      validation: 'mime:image/png,application/pdf',
      uploadBehavior: 'delayed',
      listeners: {
        'file-upload-progress':  listeners.uploadProgress,
        'file-upload-complete': listeners.uploadComplete,
        'file-upload-error': listeners.uploadError
      }
    })
      .find('input')
      .attachFile('1x1.png', { force: true })
      .attachFile('sample.pdf', { force: true })

      cy.submittedValue()
        .then(() => {
          expect(listeners.uploadProgress).to.be.called
          expect(listeners.uploadComplete).to.have.callCount(2)
        })
  })

  it('Emits file-upload-error event', () => {
    const listeners = {
      uploadError: () => {},
    }
    cy.spy(listeners, 'uploadError')
    cy.formulate('file', {
      multiple: true,
      validation: 'mime:application/pdf',
      uploader: (file, progress, error) => { error('Unable to upload file') },
      listeners: {
        'file-upload-error':  listeners.uploadError,
      }
    })
      .find('input')
      .attachFile('sample.pdf', { force: true })
      .wait(100) // simulate $nextTick()
      .then(() => expect(listeners.uploadError).to.be.called)
  })

  it('Can add additional files to the input', () => {
    cy.formulate('file', {
      multiple: true,
      addLabel: '+ Add another file',
    })

    cy.get('.formulate-file-add')
    .should('not.exist')

    cy.get('@wrapper')
      .find('input')
      .attachFile('sample.pdf', { force: true })

    cy.get('@wrapper')
      .find('.formulate-file-add')
      .shouldHaveTrimmedText('+ Add another file')

    cy.get('@wrapper')
      .find('.formulate-file-add-input')
      .attachFile('1x1.png', { force: true })

    cy.get('@wrapper')
      .find('.formulate-files li')
      .should('have.lengthOf', 2)

    cy.submittedValue()
    .should('eql', [
      {
        url: 'http://via.placeholder.com/350x150.png',
        name: 'sample.pdf'
      },
      {
        url: 'http://via.placeholder.com/350x150.png',
        name: '1x1.png'
      }
    ])
  })

  it('Can use the name property for hydrated name value', () => {
    cy.formulate('file', {
      value: [
        {
          url: '/uploads/private-filename.pdf',
          name: 'public-filename.pdf'
        }
      ]
    })
    cy.get('@wrapper')
      .find('.formulate-file-name')
      .first()
      .shouldHaveTrimmedText('public-filename.pdf')
  })
})
