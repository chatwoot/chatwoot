describe('Create agent', () => {
  it('open contact page', () => {
    cy.wait(5000);
    cy.get(
      'ul.menu.vertical > li:nth-child(2) > a.sub-menu-title.side-menu'
    ).click();
    // cy.get('ul.menu.vertical > li > a.sub-menu-title.side-menu')
    //   .should('have.attr', 'href')
    //   .and('include', 'contacts')
    //   .then(href => {
    //     console.log(href);
    //     cy.visit(href);
    //   });
  });
  it('open add contact model', () => {
    cy.get("[data='create-new-contact']").click();
  });
});
