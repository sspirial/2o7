const test = require("node:test");
const assert = require("node:assert/strict");
const { createState, chooseAction, resolveRumour } = require("./game-core.js");

test("createState returns a fresh playable state", () => {
  const state = createState();
  assert.equal(state.safe, 100);
  assert.equal(state.wall, 70);
  assert.equal(state.stamina, 100);
  assert.deepEqual(state.en, []);
});

test("chooseAction applies an action once and spends an action point", () => {
  const state = createState();
  state.ap = 2;
  assert.equal(chooseAction(state, "b"), true);
  assert.equal(state.wall, 100);
  assert.equal(state.ap, 1);
  assert.equal(chooseAction(state, "unknown"), false);
});

test("chooseAction rejects actions when no points remain", () => {
  const state = createState();
  assert.equal(chooseAction(state, "m"), false);
  assert.equal(state.safe, 100);
});

test("checking a false rumour spends one action without adding attackers", () => {
  const state = createState();
  state.ap = 1;
  const message = resolveRumour(state, { ok: false }, false);
  assert.match(message, /false/);
  assert.equal(state.ap, 0);
  assert.equal(state.xt, 0);
});

test("forwarding a false rumour adds four attackers", () => {
  const state = createState();
  const message = resolveRumour(state, { ok: false }, true);
  assert.match(message, /4 more attackers/);
  assert.equal(state.xt, 4);
});

test("a true rumour improves safety and cannot be resolved twice", () => {
  const state = createState();
  const message = resolveRumour(state, { ok: true }, true);
  assert.match(message, /\+8 safety/);
  assert.equal(state.safe, 100);
  assert.equal(resolveRumour(state, { ok: true }, true), null);
});
