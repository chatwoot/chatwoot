const eventTypes = require("./index");

test("can be used to create DOM events", () => {
  const eventInterface = eventTypes["click"].eventInterface;
  new window[eventInterface]("click");
});
