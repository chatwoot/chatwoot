describe('AdminDashboardAuthentication', function () {
  before(() => {
    cy.app('clean');
    cy.appScenario('default');
  });

  it('authenticates an admin ', function () {
    cy.visit('/');

    cy.get("[data-testid='email_input']")
      .clear()
      .type('john@acme.inc');
    cy.get("[data-testid='password_input']")
      .clear()
      .type('Password1!');

    cy.get("[data-testid='submit_button']").click();
  });

});
