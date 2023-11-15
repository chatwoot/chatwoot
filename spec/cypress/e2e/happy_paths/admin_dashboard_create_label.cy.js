describe('AdminCreateLabel', () => {
  before(() => {
    cy.visit('/');

    cy.get("[data-testid='email_input']").clear();
    cy.get("[data-testid='email_input']").type('john@acme.inc');
    cy.get("[data-testid='password_input']").clear();
    cy.get("[data-testid='password_input']").type('Password1!');

    cy.get("[data-testid='submit_button']").click();
  });

  it('open add label modal and create a label', () => {
    cy.get("[data-testid='sidebar-new-label-button']").click();

    cy.get("[data-testid='label-title'] > input").clear();
    cy.get("[data-testid='label-title'] > input").type(
      `show_stopper_${new Date().getTime()}`
    );

    cy.get("[data-testid='label-description'] > input").clear();
    cy.get("[data-testid='label-description'] > input").type(
      'denote it with show show stopper cases'
    );

    cy.get("[data-testid='label-submit']").click();
  });
});
