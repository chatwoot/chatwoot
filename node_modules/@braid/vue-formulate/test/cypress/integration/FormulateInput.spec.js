describe('FormulateInput', () => {
  it('Can change validation message language by calling setLocale', () => {
    cy.formulate('text', {
      validation: 'required',
      errorBehavior: 'live',
      name: 'name',
      label: 'Your name'
    }).find('input')

    cy.window()
      .then(window => window.getVueInstance().$formulate.setLocale('de'))
      .then(() => cy.get('.formulate-input-errors').find('li').should('contain', 'Name ist ein Pflichtfeld.'))
  })
})
