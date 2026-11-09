(function (root, factory) {
  const api = factory();
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else root.GameCore = api;
})(typeof self === "undefined" ? this : self, function () {
  const ACTIONS = {
    b: (state) => {
      state.wall = Math.min(100, state.wall + 30);
    },
    e: (state) => {
      state.el = 1;
    },
    m: (state) => {
      state.safe = Math.min(100, state.safe + 25);
    },
    f: (state) => {
      state.sp += 12;
    },
  };

  function createState() {
    return {
      st: "title",
      location: null,
      w: 0,
      safe: 100,
      wall: 70,
      stamina: 100,
      ammo: 6,
      sp: 24,
      rl: 0,
      fc: 0,
      cd: 0,
      q: 0,
      t: 0,
      en: [],
      fx: [],
      dis: 0,
      el: 0,
      ap: 0,
      fl: 0,
      xt: 0,
      ev: 0,
      at: 14,
      rd: 0,
    };
  }

  function chooseAction(state, key) {
    if (state.ap < 1 || !ACTIONS[key]) return false;
    state.ap--;
    ACTIONS[key](state);
    return true;
  }

  function resolveRumour(state, rumour, forward) {
    if (state.rd || (!forward && state.ap < 1)) return null;
    state.rd = 1;
    if (!forward) state.ap--;
    if (rumour.ok) {
      state.safe = Math.min(100, state.safe + 8);
      return forward
        ? "You forwarded it. It was true, and people calmed down. (+8 safety)"
        : "Mzee Jabali confirms it is true. (+8 safety)";
    }
    if (forward) {
      state.xt = 4;
      return "You forwarded it. It was false, and the panic spreads: 4 more attackers will come tonight.";
    }
    return "Mzee Jabali says it is false and sends a correction to the group.";
  }

  return { createState, chooseAction, resolveRumour };
});
