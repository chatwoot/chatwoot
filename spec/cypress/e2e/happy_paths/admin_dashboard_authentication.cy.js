describe('AdminDashboardAuthentication', () => {
  before(() => {
    cy.app('clean');
    cy.appScenario('default');
  });

  it('authenticates an admin ', () => {
    cy.visit('/');

    cy.get("[data-testid='email_input']").clear();
    cy.get("[data-testid='email_input']").type('john@acme.inc');
    cy.get("[data-testid='password_input']").clear();
    cy.get("[data-testid='password_input']").type('Password1!');

    cy.get("[data-testid='submit_button']").click();
  });
});
