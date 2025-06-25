describe('AdminCreateLabel', () => {
  before(() => {
    cy.wait(3000);
  });

  it('open add label modal', () => {
    cy.get(
      'ul.menu.vertical > li:last-child > a.sub-menu-title.side-menu > span.child-icon.ion-android-add-circle'
    ).click();
  });
  it('create a label', () => {
    cy.get("[data-testid='label-title'] > input")
      .clear()
      .type(`show_stopper_${new Date().getTime()}`);
    cy.get("[data-testid='label-description'] > input")
      .clear()
      .type('denote it with show show stopper cases');

    cy.get("[data-testid='label-submit']").click();
  });
});
