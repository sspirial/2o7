// Smoke test: builds every location and plays a few simulated seconds of a
// night in a fake browser (jsdom) with a stubbed WebGL renderer.
// `three` is pinned to 0.128.0 on purpose: index.html loads r128 from cdnjs,
// so APIs added later (for example CapsuleGeometry, r142) must not be used.
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { JSDOM } = require("jsdom");

function boot() {
  const html = fs
    .readFileSync(path.join(__dirname, "index.html"), "utf8")
    .replace(/<script[\s\S]*?<\/script>/g, "")
    .replace(/<link[^>]*>/g, "");
  const dom = new JSDOM(html, {
    runScripts: "dangerously",
    pretendToBeVisual: true,
    url: "http://localhost/",
  });
  const w = dom.window;
  const errors = [];
  w.addEventListener("error", (e) => errors.push(e.message));
  w.HTMLCanvasElement.prototype.getContext = () => ({
    createRadialGradient: () => ({ addColorStop() {} }),
    fillRect() {},
  });
  w.requestAnimationFrame = () => 0;
  const run = (code) => {
    const s = w.document.createElement("script");
    s.textContent = code;
    w.document.body.appendChild(s);
  };
  run(fs.readFileSync(require.resolve("three/build/three.min.js"), "utf8"));
  run(`THREE.WebGLRenderer = class {
    constructor() { this.shadowMap = {}; }
    setPixelRatio() {} setSize() {}
    render(scene) { scene.updateMatrixWorld(true); }
  };`);
  run(fs.readFileSync(path.join(__dirname, "game-core.js"), "utf8"));
  run(fs.readFileSync(path.join(__dirname, "game.js"), "utf8"));
  return { w, errors, run };
}

const LOCATION_IDS = ["nairobi", "rift_valley", "western", "coast", "nyanza"];

for (const id of LOCATION_IDS) {
  test(`location ${id} builds with a small draw-call budget and plays`, () => {
    const { w, errors, run } = boot();
    run(`window.__r = (() => {
      reset();
      selectLocation(${JSON.stringify("__ID__")});
      let drawn = 0;
      sc.traverse((o) => {
        let v = o.visible;
        for (let p = o.parent; p && v; p = p.parent) v = p.visible;
        if (o.isMesh && v) drawn++;
      });
      pick("b", {});
      go();
      for (let f = 0, t = 1000; f < 900 && S.st == "fight"; f++, t += 33) {
        const e = S.en.find((x) => x.s != 2);
        if (e) {
          yaw = Math.atan2(-(e.g.position.x - cam.position.x), -(e.g.position.z - cam.position.z));
          if (f % 8 == 0) fire();
        }
        loop(t);
      }
      return { drawn, location: S.location };
    })();`.replace("__ID__", id));
    assert.deepEqual(errors, []);
    assert.equal(w.__r.location, id);
    assert.ok(w.__r.drawn < 40, `too many draw calls: ${w.__r.drawn}`);
  });
}

test("win text names the selected place, not a hard-coded estate", () => {
  const { w, run } = boot();
  run(`window.__p = (() => { reset(); selectLocation("coast"); return placeName(); })();`);
  assert.equal(w.__p, "Bahari Relief Hub");
});
