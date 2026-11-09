const $ = (i) => document.getElementById(i),
  T = THREE,
  touch = "ontouchstart" in window,
  rnd = Math.random;
const required = [
  "c",
  "ov",
  "cap",
  "msg",
  "wv",
  "am",
  "bs",
  "bw",
  "st",
  "hint",
  "mu",
  "nv",
  "bf",
  "bs2",
  "js",
  "ar",
  "pz",
  "bcr",
];
for (const id of required)
  if (!$(id)) throw new Error(`Missing required element: #${id}`);
let R;
try {
  R = new T.WebGLRenderer({ canvas: $("c"), antialias: true });
} catch (error) {
  console.error("Unable to initialize WebGL", error);
  document.body.insertAdjacentHTML(
    "beforeend",
    '<p style="position:fixed;z-index:9;inset:20px;font-size:1.1rem">2o7 needs WebGL. Try another browser or update this one.</p>',
  );
  throw error;
}
R.setPixelRatio(Math.min(devicePixelRatio, touch ? 1.5 : 2.5));
R.shadowMap.enabled = !touch;
R.shadowMap.type = T.PCFSoftShadowMap;
R.outputEncoding = T.sRGBEncoding;
R.toneMapping = T.ACESFilmicToneMapping;
R.toneMappingExposure = 1.05;
const sc = new T.Scene(),
  cam = new T.PerspectiveCamera(72, 1, 0.1, 140);
cam.rotation.order = "YXZ";
sc.add(cam);
sc.background = new T.Color(0x3a1c14);
sc.fog = new T.Fog(0x3a1c14, 30, 125);
const hemi = new T.HemisphereLight(0xffa070, 0x2a1a14, 0.9);
sc.add(hemi);
const dl = new T.DirectionalLight(0xff8a50, 0.55);
dl.position.set(-30, 14, -20);
dl.castShadow = true;
dl.shadow.mapSize.set(2048, 2048);
dl.shadow.camera.left = -70;
dl.shadow.camera.right = 70;
dl.shadow.camera.top = 70;
dl.shadow.camera.bottom = -70;
sc.add(dl);
const fill = new T.DirectionalLight(0x9eb7d1, 0.18);
fill.position.set(30, 18, 30);
sc.add(fill);
const M = (c, e) => new T.MeshLambertMaterial({ color: c, emissive: e || 0 }),
  B = (w, h, d) => new T.BoxGeometry(w, h, d);
const baseMapObjects = [];
const mk = (g, m, x, y, z) => {
  const o = new T.Mesh(g, m);
  o.position.set(x, y, z);
  o.castShadow = true;
  o.receiveShadow = true;
  sc.add(o);
  baseMapObjects.push(o);
  return o;
};
const gg = new T.PlaneGeometry(300, 300, 60, 60),
  gc = [],
  _c = new T.Color();
for (let k = 0; k < gg.attributes.position.count; k++) {
  _c.setHex(rnd() < 0.3 ? 0x66662f : 0x7a4a2c).multiplyScalar(
    0.85 + rnd() * 0.3,
  );
  gc.push(_c.r, _c.g, _c.b);
}
gg.setAttribute("color", new T.Float32BufferAttribute(gc, 3));
const gr = new T.Mesh(gg, new T.MeshLambertMaterial({ vertexColors: true }));
gr.rotation.x = -Math.PI / 2;
sc.add(gr);
const rd = mk(new T.PlaneGeometry(7, 150), M(0x5a3720), 12, 0.03, -87);
rd.rotation.x = -Math.PI / 2;
const sky = new T.Group();
sc.add(sky);
const dg = new T.SphereGeometry(135, 16, 12);
dg.setAttribute(
  "color",
  new T.BufferAttribute(new Float32Array(dg.attributes.position.count * 3), 3),
);
sky.add(
  new T.Mesh(
    dg,
    new T.MeshBasicMaterial({
      vertexColors: true,
      side: T.BackSide,
      fog: false,
      depthWrite: false,
    }),
  ),
);
const sunm = new T.Mesh(
  new T.SphereGeometry(10, 16, 12),
  new T.MeshBasicMaterial({ color: 0xff6a2a, fog: false }),
);
sunm.position.set(-60, 16, -100);
sky.add(sunm);
const spp = [];
for (let k = 0; k < 300; k++) {
  const a = rnd() * 6.283,
    e = 0.15 + rnd() * 1.3;
  spp.push(
    Math.cos(a) * Math.cos(e) * 125,
    Math.sin(e) * 125,
    Math.sin(a) * Math.cos(e) * 125,
  );
}
const stars = new T.Points(
  new T.BufferGeometry().setAttribute(
    "position",
    new T.Float32BufferAttribute(spp, 3),
  ),
  new T.PointsMaterial({
    size: 2,
    sizeAttenuation: false,
    transparent: true,
    opacity: 0,
    fog: false,
    depthWrite: false,
  }),
);
sky.add(stars);
const PAL = [
  {
    t: 0x3a2a5a,
    h: 0xff7a3a,
    f: 0x4a2418,
    s: 0xff6a2a,
    hl: 0xffa070,
    dl: 0xff8a50,
    st: 0,
  },
  {
    t: 0x070a1c,
    h: 0x1c2a4a,
    f: 0x0a1222,
    s: 0xdfe8ff,
    hl: 0x5a7ab0,
    dl: 0x8fb0ff,
    st: 1,
  },
  {
    t: 0x2a2250,
    h: 0xff9a8a,
    f: 0x4a2a38,
    s: 0xffd08a,
    hl: 0xff9a90,
    dl: 0xffb090,
    st: 0.4,
  },
];
function setSky(i) {
  const p = PAL[i],
    a = dg.attributes.position,
    c = dg.attributes.color,
    th = new T.Color(p.t),
    hz = new T.Color(p.h),
    o = new T.Color();
  for (let k = 0; k < a.count; k++) {
    o.copy(hz).lerp(th, Math.pow(Math.max(a.getY(k) / 135, 0), 0.55));
    c.setXYZ(k, o.r, o.g, o.b);
  }
  c.needsUpdate = true;
  sc.background.set(p.f);
  sc.fog.color.set(p.f);
  hemi.color.set(p.hl);
  dl.color.set(p.dl);
  sunm.material.color.set(p.s);
  stars.material.opacity = p.st;
}
setSky(0);
mk(B(12, 3.2, 7), M(0xe3d3b0), 0, 1.6, 0);
mk(B(13, 0.4, 8), M(0x6e2a1c), 0, 3.4, 0);
mk(B(1.6, 2.2, 0.1), M(0xffd9a0, 0xffb060), 0, 1.1, 3.55);
for (const k of [-2, 2]) {
  mk(B(1.1, 1, 0.1), M(0xffd9a0, 0xffa040), k * 2.2, 1.8, 3.52);
  mk(B(1.1, 1, 0.1), M(0xffd9a0, 0xffa040), k * 2.2, 1.8, -3.52);
}
for (let k = -6; k <= 6; k += 1.2)
  mk(B(0.12, 0.12, 8.2), M(0x4e1c12), k, 3.65, 0);
const dlight = new T.PointLight(0xffb060, 1.4, 22);
dlight.position.set(0, 2.2, 5);
sc.add(dlight);
[
  [-7, -6],
  [-4, -8],
  [6, -7],
  [8, -3],
].forEach((p) =>
  mk(new T.ConeGeometry(1.7, 1.5, 4), M(0x2f6fa8), p[0], 0.75, p[1]),
);
for (let i = 0; i < 26; i++) {
  const a = rnd() * 6.28,
    r = 24 + rnd() * 34,
    x = Math.sin(a) * r,
    z = Math.cos(a) * r,
    s = 0.8 + rnd() * 0.6,
    g = 0.85 + rnd() * 0.3;
  mk(
    new T.CylinderGeometry(0.18 * s, 0.3 * s, 3.4 * s, 5),
    M(0x3b2a1c),
    x,
    1.7 * s,
    z,
  );
  for (let j = 0; j < 2; j++)
    mk(
      new T.SphereGeometry(2.6 * s, 8, 5),
      M(new T.Color(0x56622c).multiplyScalar(g)),
      x + (j ? 1.4 : -1) * s,
      3.6 * s + j * 0.3,
      z + (j ? -0.8 : 0.6) * s,
    ).scale.y = 0.3;
}
const IM = (g, m, n, fn) => {
  const o = new T.InstancedMesh(g, m, n),
    d = new T.Object3D();
  for (let k = 0; k < n; k++) {
    fn(d, k);
    d.updateMatrix();
    o.setMatrixAt(k, d.matrix);
  }
  sc.add(o);
  return o;
};
IM(new T.ConeGeometry(0.5, 2.2, 4), M(0x6f8a34), 420, (d, k) => {
  d.position.set(
    18 + (k % 20) * 1.6 + rnd() * 0.5,
    1.1,
    -12 + ((k / 20) | 0) * 1.6 + rnd() * 0.5,
  );
  d.scale.set(1, 0.8 + rnd() * 0.5, 1);
  d.rotation.y = rnd() * 3;
});
IM(new T.ConeGeometry(0.12, 0.7, 3), M(0x6a6a2a), 260, (d) => {
  const a = rnd() * 6.28,
    r = 12 + rnd() * 45;
  d.position.set(Math.sin(a) * r, 0.3, Math.cos(a) * r);
  d.rotation.y = rnd() * 3;
});
IM(new T.DodecahedronGeometry(0.5), M(0x6b5a4a), 40, (d) => {
  const a = rnd() * 6.28,
    r = 12 + rnd() * 45,
    s = 0.4 + rnd() * 0.9;
  d.position.set(Math.sin(a) * r, 0.15 * s, Math.cos(a) * r);
  d.scale.set(s, s * 0.7, s);
});
[
  [-22, -4],
  [-22, 2],
  [-22, 8],
].forEach((p, k) => {
  mk(B(2.6, 2.2, 2.2), M([0x2a7a8a, 0xb8892a, 0x8a3a3a][k]), p[0], 1.1, p[1]);
  mk(B(3, 0.2, 2.6), M(0x4a3a30), p[0], 2.3, p[1]);
});
mk(B(2.2, 1.6, 5), M(0xf0e6d2), -27, 1, 16);
mk(B(2.25, 0.35, 5.05), M(0xc0392b), -27, 0.9, 16);
mk(B(2.3, 0.6, 4.2), M(0x1a1a22), -27, 1.55, 16);
const seg = [];
for (let i = 0; i < 14; i++) {
  const a = (i / 14) * 6.283,
    s = mk(
      B(4, 1.2, 0.5),
      M(0x8a6234),
      Math.sin(a) * 10,
      0.6,
      Math.cos(a) * 10,
    );
  s.rotation.y = a;
  seg.push(s);
}
const locationGroup = new T.Group();
sc.add(locationGroup);
const locationMeshes = [];
const locationColliders = [];
const locMk = (g, m, x, y, z) => {
  const o = new T.Mesh(g, m);
  o.position.set(x, y, z);
  o.castShadow = true;
  o.receiveShadow = true;
  locationGroup.add(o);
  locationMeshes.push(o);
  return o;
};
const addCollider = (x1, x2, z1, z2, blocksNPC = true) =>
  locationColliders.push({ x1, x2, z1, z2, blocksNPC });
function hitsCollider(x, z, radius = 0.45, npc = false) {
  return locationColliders.some(
    (box) =>
      (!npc || box.blocksNPC) &&
      x > box.x1 - radius &&
      x < box.x2 + radius &&
      z > box.z1 - radius &&
      z < box.z2 + radius,
  );
}
const locMatCache = new Map();
const locMat = (color, emissive = 0) => {
  const key = `${color}-${emissive}`;
  let m = locMatCache.get(key);
  if (!m) {
    m = new T.MeshLambertMaterial({ color, emissive });
    locMatCache.set(key, m);
  }
  return m;
};
function removeLocationMeshes() {
  for (const o of locationMeshes) {
    locationGroup.remove(o);
    o.geometry.dispose();
  }
  locationMeshes.length = 0;
}
function clearLocationMap() {
  removeLocationMeshes();
  locationColliders.length = 0;
}
// Scenery never moves, so bake every mesh of a location into one mesh per
// material. This turns hundreds of draw calls into a handful on phones.
function mergeLocationMeshes() {
  const groups = new Map();
  for (const o of locationMeshes) {
    o.updateMatrix();
    const g = (
      o.geometry.index ? o.geometry.toNonIndexed() : o.geometry.clone()
    ).applyMatrix4(o.matrix);
    let e = groups.get(o.material);
    if (!e) groups.set(o.material, (e = { pos: [], nor: [] }));
    e.pos.push(g.attributes.position.array);
    e.nor.push(g.attributes.normal.array);
    g.dispose();
  }
  removeLocationMeshes();
  const join = (arrays) => {
    const out = new Float32Array(arrays.reduce((n, a) => n + a.length, 0));
    let i = 0;
    for (const a of arrays) {
      out.set(a, i);
      i += a.length;
    }
    return out;
  };
  for (const [material, e] of groups) {
    const geo = new T.BufferGeometry();
    geo.setAttribute("position", new T.BufferAttribute(join(e.pos), 3));
    geo.setAttribute("normal", new T.BufferAttribute(join(e.nor), 3));
    const m = new T.Mesh(geo, material);
    m.castShadow = true;
    m.receiveShadow = true;
    locationGroup.add(m);
    locationMeshes.push(m);
  }
}
function addRock(x, y, z, scale, color = 0x4b403c) {
  const o = locMk(new T.DodecahedronGeometry(1, 0), locMat(color), x, y, z);
  o.scale.set(scale, scale * (0.7 + rnd() * 0.6), scale);
  o.rotation.y = rnd() * 6.28;
  addCollider(x - scale, x + scale, z - scale, z + scale);
}
function addShack(x, z, color) {
  const trim = locMat(0xb9865d),
    dark = locMat(0x241c1a),
    glass = locMat(0x79c4cf, 0x173b4a),
    roof = locMat(0x514039);
  locMk(B(3.2, 2.2, 2.8), locMat(color), x, 1.1, z);
  locMk(B(3.5, 0.25, 3.1), roof, x, 2.35, z);
  locMk(B(3.7, 0.12, 0.16), trim, x, 2.3, z + 1.48);
  locMk(B(3.7, 0.12, 0.16), trim, x, 2.3, z - 1.48);
  locMk(B(0.9, 1.4, 0.08), dark, x, 0.8, z + 1.42);
  locMk(B(1.08, 0.08, 0.1), trim, x, 1.52, z + 1.48);
  locMk(B(0.08, 1.55, 0.1), trim, x - 0.54, 0.78, z + 1.48);
  locMk(B(0.08, 1.55, 0.1), trim, x + 0.54, 0.78, z + 1.48);
  locMk(B(0.08, 0.08, 0.12), locMat(0xd7b56c, 0xff9a42), x + 0.28, 0.8, z + 1.54);
  for (const wx of [-1.05, 1.05]) {
    locMk(B(0.68, 0.7, 0.08), glass, x + wx, 1.32, z + 1.43);
    locMk(B(0.76, 0.07, 0.1), trim, x + wx, 1.32, z + 1.49);
    locMk(B(0.07, 0.78, 0.1), trim, x + wx, 1.32, z + 1.49);
  }
  for (const sx of [-1, 1])
    locMk(B(0.08, 1.8, 2.5), trim, x + sx * 1.57, 1.1, z);
  addCollider(x - 1.6, x + 1.6, z - 1.4, z + 1.4);
}
function addTree(x, z, color = 0x3f632f) {
  locMk(
    new T.CylinderGeometry(0.16, 0.28, 2.8, 6),
    locMat(0x3c2b20),
    x,
    1.4,
    z,
  );
  locMk(
    new T.CylinderGeometry(0.08, 0.16, 1.1, 5),
    locMat(0x3c2b20),
    x - 0.5,
    2.35,
    z,
  ).rotation.z = -0.5;
  const foliage = locMat(color),
    highlight = locMat(new T.Color(color).offsetHSL(0, 0.04, 0.1).getHex());
  for (const [ox, oy, oz, s] of [
    [0, 3.25, 0, 1.25],
    [-0.8, 3.05, 0.1, 0.9],
    [0.8, 3.05, -0.1, 0.95],
    [0, 3.75, 0.05, 0.75],
  ]) {
    const crown = locMk(
      new T.SphereGeometry(s, 10, 7),
      oy > 3.5 ? highlight : foliage,
      x + ox,
      oy,
      z + oz,
    );
    crown.scale.y = 0.7;
  }
  locMk(B(0.8, 0.08, 0.8), locMat(0x8b6a43), x, 0.05, z);
  addCollider(x - 0.8, x + 0.8, z - 0.8, z + 0.8);
}
function addObjectiveStructure(id) {
  const styles = {
    nairobi: [0xd0b28a, 0x6a2f21],
    rift_valley: [0x9b8064, 0x3b302b],
    western: [0xcab889, 0x75462f],
    coast: [0xd6c29c, 0x315c62],
    nyanza: [0xb69b6b, 0x4b6b6b],
  };
  const [wall, roof] = styles[id];
  locMk(B(10, 2.8, 6), locMat(wall), 0, 1.4, 0);
  locMk(B(11, 0.4, 7), locMat(roof), 0, 3, 0);
  locMk(B(11.6, 0.18, 7.3), locMat(0x211c28), 0, 3.28, 0);
  for (let x = -4.5; x <= 4.5; x += 1.5)
    locMk(B(0.08, 0.12, 6.8), locMat(0xd0a36d), x, 3.5, 0);
  locMk(B(11.4, 0.16, 0.18), locMat(0xf0d4a0), 0, 2.72, 3.08);
  locMk(B(11.4, 0.16, 0.18), locMat(0x6d4636), 0, 2.72, -3.08);
  locMk(B(12.2, 0.22, 1.4), locMat(0x6d302c), 0, 2.42, 3.75);
  for (const x of [-5.2, 5.2])
    locMk(
      new T.CylinderGeometry(0.13, 0.18, 2.8, 8),
      locMat(0x372a2b),
      x,
      1.4,
      3.72,
    );
  locMk(B(1.4, 1.9, 0.1), locMat(0xffd9a0, 0xffb060), 0, 1, 3.05);
  locMk(B(1.65, 2.15, 0.12), locMat(0x41251f), 0, 1, 3.11);
  locMk(B(1.38, 1.88, 0.14), locMat(0xffd9a0, 0xffb060), 0, 1, 3.18);
  locMk(B(3.2, 0.42, 0.16), locMat(0xd8b374), 0, 2.22, 3.2);
  locMk(B(2.6, 0.08, 0.08), locMat(0x4a2d24), 0, 2.48, 3.2);
  for (const x of [-3.6, 3.6]) {
    locMk(B(1.2, 1.1, 0.12), locMat(0x79c4cf, 0x173b4a), x, 1.55, 3.08);
    locMk(B(1.35, 0.1, 0.16), locMat(0xf0d4a0), x, 1.55, 3.16);
    locMk(B(0.1, 1.2, 0.16), locMat(0xf0d4a0), x, 1.55, 3.16);
    locMk(B(0.22, 0.55, 0.18), locMat(0xffb13b, 0xff681f), x, 2.35, 3.2);
  }
  for (const x of [-4.4, 4.4])
    locMk(B(1, 0.9, 0.1), locMat(0xffd9a0, 0xffa040), x, 1.6, 3.02);
  addCollider(-5, 5, -3, 3, false);
}
function buildLocationMap(id) {
  clearLocationMap();
  for (const o of baseMapObjects) o.visible = false;
  gr.visible = true;
  addObjectiveStructure(id);
  if (id === "nairobi") {
    gr.material = locMat(0x5c4737);
    for (let x = -24; x <= 24; x += 6)
      for (let z = -22; z <= 22; z += 7)
        if (Math.abs(x) > 8 || Math.abs(z) > 8) addShack(x, z, 0x76513a);
    for (let x = -18; x <= 18; x += 9)
      locMk(B(0.12, 0.12, 50), locMat(0x171719), x, 7, 0);
    for (const x of [-21, 21])
      locMk(
        new T.CylinderGeometry(0.35, 0.45, 8, 6),
        locMat(0x282323),
        x,
        4,
        0,
      );
    locMk(B(1.8, 2.5, 1.8), locMat(0x304c47), -13, 1.25, -12);
    addCollider(-14, -12, -13, -11);
  } else if (id === "rift_valley") {
    gr.material = locMat(0x6a3b28);
    locMk(
      new T.PlaneGeometry(16, 150),
      locMat(0x8b6a48),
      0,
      0.03,
      -55,
    ).rotation.x = -Math.PI / 2;
    for (let i = 0; i < 7; i++) {
      const x = (i % 2 ? 1 : -1) * (18 + rnd() * 9);
      const z = -30 + i * 10;
      locMk(
        new T.ConeGeometry(5 + rnd() * 3, 10 + rnd() * 7, 7),
        locMat(0x48332e),
        x,
        5,
        z,
      );
    }
    for (let i = 0; i < 18; i++)
      addRock(
        -24 + rnd() * 48,
        0.5,
        -30 + rnd() * 62,
        0.5 + rnd() * 1.5,
        0x493b36,
      );
    locMk(
      new T.TorusGeometry(6, 0.4, 8, 24),
      locMat(0x9b2f18, 0xff3a12),
      16,
      0.35,
      -16,
    ).rotation.x = Math.PI / 2;
    locMk(B(2, 0.08, 26), locMat(0x351e1b), 16, 0.12, -16);
    addCollider(14.5, 17.5, -29, -3);
  } else if (id === "western") {
    gr.material = locMat(0x4d7134);
    const river = locMk(
      new T.PlaneGeometry(12, 100),
      locMat(0x265d73),
      -15,
      0.04,
      -20,
    );
    river.rotation.x = -Math.PI / 2;
    for (let i = 0; i < 28; i++)
      addTree(-25 + rnd() * 48, -42 + rnd() * 84, 0x3f7137);
    locMk(B(15, 0.35, 2), locMat(0x8a6234), -15, 1.7, 4);
    for (let x = -21; x <= -9; x += 3)
      locMk(B(0.3, 1.5, 2.6), locMat(0x5a402c), x, 0.8, 4);
    addShack(9, -15, 0x876142);
    addShack(13, -20, 0x6d503b);
  } else if (id === "coast") {
    gr.material = locMat(0xc69b6b);
    locMk(
      new T.PlaneGeometry(150, 60),
      locMat(0x24647a),
      60,
      -0.02,
      -10,
    ).rotation.x = -Math.PI / 2;
    locMk(B(4, 0.35, 50), locMat(0x68462e), 10, 0.2, 0);
    for (let x = 14; x < 42; x += 7)
      locMk(B(0.35, 0.5, 50), locMat(0x9c7044), x, 0.45, 0);
    for (const z of [-18, 0, 18]) {
      locMk(B(10, 0.3, 2), locMat(0x7d542e), 25, 0.5, z);
      locMk(B(8, 1.4, 2.5), locMat(0x6c3e2b), 42, 1.1, z);
      addCollider(20, 30, z - 1.2, z + 1.2);
      addCollider(38, 46, z - 1.5, z + 1.5);
    }
    locMk(new T.CylinderGeometry(0.3, 0.4, 12, 8), locMat(0x3f342d), 5, 6, -18);
    locMk(B(0.15, 12, 0.15), locMat(0xb07d3b), 5, 10, -18);
    addShack(-15, -12, 0x9c673e);
    addShack(-19, -18, 0x84583c);
  } else if (id === "nyanza") {
    gr.material = locMat(0x657742);
    locMk(
      new T.PlaneGeometry(90, 50),
      locMat(0x235c68),
      28,
      -0.02,
      0,
    ).rotation.x = -Math.PI / 2;
    locMk(B(5, 0.35, 44), locMat(0x765235), 4, 0.25, 0);
    for (let z = -18; z <= 18; z += 9) {
      locMk(B(16, 0.2, 0.35), locMat(0x8f6a43), 12, 0.55, z);
      locMk(B(3, 0.25, 0.25), locMat(0x5d402c), 19, 0.8, z);
      addCollider(8, 20, z - 0.5, z + 0.5);
    }
    for (let i = 0; i < 32; i++)
      addTree(-25 + rnd() * 25, -30 + rnd() * 60, 0x4b773a);
    for (const z of [-12, 0, 12]) {
      const boat = locMk(
        new T.SphereGeometry(1, 10, 8),
        locMat(0x6f3f2a),
        30,
        0.5,
        z,
      );
      boat.scale.set(1, 3.5, 1);
      boat.rotation.z = Math.PI / 2;
      addCollider(26, 34, z - 1.2, z + 1.2);
    }
    addShack(-12, -13, 0x806344);
    addShack(-17, -19, 0x6f583e);
  }
  mergeLocationMeshes();
}
const gun = new T.Mesh(B(0.09, 0.12, 0.45), M(0x3a2a20, 0x401a08));
gun.position.set(0.25, -0.22, -0.55);
cam.add(gun);
const gl2 = new T.PointLight(0xffa040, 0, 16);
gl2.position.set(0.25, -0.1, -1);
cam.add(gl2);
const eg = [
    new T.CylinderGeometry(0.3, 0.36, 1.3, 6),
    new T.SphereGeometry(0.22, 6, 5),
    new T.ConeGeometry(0.09, 0.5, 5),
  ],
  em = [M(0x1b1512), M(0x2a1f1a), M(0xffa030, 0xff6a10)];
const gt = (() => {
  const c = document.createElement("canvas");
  c.width = c.height = 64;
  const x = c.getContext("2d"),
    r = x.createRadialGradient(32, 32, 0, 32, 32, 32);
  r.addColorStop(0, "rgba(255,190,90,1)");
  r.addColorStop(0.35, "rgba(255,120,30,.45)");
  r.addColorStop(1, "rgba(255,90,0,0)");
  x.fillStyle = r;
  x.fillRect(0, 0, 64, 64);
  return new T.CanvasTexture(c);
})();
const gm = new T.SpriteMaterial({
  map: gt,
  blending: T.AdditiveBlending,
  transparent: true,
  depthWrite: false,
  fog: false,
});
function mkE() {
  const g = new T.Group();
  [
    [0, 0.75, 0],
    [0, 1.6, 0],
    [0.38, 1.4, 0.2],
  ].forEach((p, i) => {
    const o = new T.Mesh(eg[i], em[i]);
    o.position.set(p[0], p[1], p[2]);
    g.add(o);
  });
  const arm = new T.Mesh(new T.CylinderGeometry(0.07, 0.07, 0.7, 4), em[0]);
  arm.position.set(0.3, 1.2, 0.1);
  arm.rotation.z = -0.5;
  g.add(arm);
  const gl = new T.Sprite(gm);
  gl.position.set(0.38, 1.7, 0.2);
  gl.scale.set(1.8, 1.8, 1);
  g.add(gl);
  g.userData.gl = gl;
  g.scale.setScalar(0.92 + rnd() * 0.2);
  sc.add(g);
  return g;
}
const WAVES = [
  ["Night one, dusk", 8],
  ["Night one, midnight", 13],
  ["Before dawn", 18],
];
const LOCATIONS = {
  nairobi: {
    name: "Nairobi · Mtaani Estate",
    place: "Mtaani Estate",
    region: "Urban shelter",
    brief:
      "A crowded estate shelter near the capital. Keep the gates closed while neighbours coordinate food, water and safe passage.",
    palette: 0,
    icon: "▦",
    terrain: "Dense urban",
    route: "Gate watch",
    risk: "High density",
  },
  rift_valley: {
    name: "Rift Valley · Kijani Route",
    place: "Kijani Route",
    region: "Displacement route",
    brief:
      "Families are moving along a rural road. Keep a temporary shelter open until transport arrives.",
    palette: 1,
    icon: "▲",
    terrain: "Volcanic route",
    route: "Road convoy",
    risk: "Unstable ground",
  },
  western: {
    name: "Western Kenya · Amani Parish",
    place: "Amani Parish",
    region: "Community mediation",
    brief:
      "Local elders and faith leaders are trying to keep several villages connected while rumours travel faster than help.",
    palette: 2,
    icon: "≋",
    terrain: "River villages",
    route: "Bridge link",
    risk: "Rumour spread",
  },
  coast: {
    name: "Coast · Bahari Relief Hub",
    place: "Bahari Relief Hub",
    region: "Relief hub",
    brief:
      "A transport and relief hub is receiving families from inland. Protect the stores and keep the convoy route clear.",
    palette: 0,
    icon: "⚓",
    terrain: "Docks & stores",
    route: "Harbour route",
    risk: "Open shoreline",
  },
  nyanza: {
    name: "Nyanza · Lakeview Landing",
    place: "Lakeview Landing",
    region: "Lakeside community",
    brief:
      "A lakeside landing has become a refuge. Boats, radios and volunteers are the only link to assistance.",
    palette: 1,
    icon: "≈",
    terrain: "Lake landing",
    route: "Boat relay",
    risk: "Water edge",
  },
};
const placeName = () => (LOCATIONS[S.location] || LOCATIONS.nairobi).place;
const OPT = {
  b: ["Reinforce the barricade", "+30 barricade strength"],
  e: [
    "Call the peace committee",
    "Elders, pastors and imams walk out to talk: fewer attackers come",
  ],
  m: ["Open the first-aid tent", "+25 shelter safety"],
  f: ["Collect more flares", "+12 flares"],
};
const Q = [
  "“Amani! Rudini nyumbani.”",
  "“Sisi ni ndugu. Tuacheni.”",
  "“Hapa kuna watoto. Rudini!”",
];
const HIST =
  "What happened: after the 27 December 2007 election, violence across Kenya killed over a thousand people and displaced hundreds of thousands. Neighbours, elders, faith leaders and the Kenya Red Cross sheltered and fed displaced families. Mediation led by Kofi Annan produced the National Accord on 28 February 2008. This game is fiction: the attackers are an invented gang, and no community is the enemy.";
let AC = null,
  mute = false;
function snd(f, d, ty, v, sl) {
  if (mute || !AC) return;
  const o = AC.createOscillator(),
    g = AC.createGain(),
    t = AC.currentTime;
  o.type = ty;
  o.frequency.setValueAtTime(f, t);
  if (sl) o.frequency.exponentialRampToValueAtTime(sl, t + d);
  g.gain.setValueAtTime(v, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + d);
  o.connect(g);
  g.connect(AC.destination);
  o.start(t);
  o.stop(t + d);
}
const RUM = [
  {
    ok: false,
    t: "“URGENT!!! Gang coming from the river side ONLY. Everyone move to the north gate NOW. Forward to everyone you know!”",
  },
  {
    ok: true,
    t: "“Kenya Red Cross radio update: the convoy is expected at first light on the north road. Please stay calm and keep the gates closed.”",
  },
];
function rcard() {
  if (S.w < 1) return "";
  return `<div id="rc" class="rc"><b>New message, 11:42 pm</b><p>${RUM[S.w - 1].t}</p><button class="op" data-action="rumour-forward"><b>Forward to the neighbourhood group</b><span>Free</span></button><button class="op" data-action="rumour-check"><b>Check with the peace committee first</b><span>Costs 1 action</span></button></div>`;
}
function rumour(fw) {
  const m = GameCore.resolveRumour(S, RUM[S.w - 1], fw);
  if (!m) return;
  speak(m.replace(/ \(.*\)/, ""), fw ? "n" : "j", "en", 1);
  $("ap").textContent = S.ap;
  $("rc").textContent = m;
}
function share(b) {
  const d = {
    title: "2o7",
    text: "2o7: hold a shelter through the night in Kenya, 2008. A free browser game.",
    url: location.href,
  };
  if (navigator.share) {
    navigator.share(d).catch((error) => {
      if (error.name != "AbortError") {
        console.error("Share failed", error);
        say("Sharing was not available");
      }
    });
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(d.url).then(
      () => {
        b.textContent = "Link copied";
      },
      (error) => {
        console.error("Copy failed", error);
        say("Copying was not available");
      },
    );
  } else say("Sharing is not available in this browser");
}
const CH = {
  n: ["Narrator", 0.85, 0.92],
  z: ["Zawadi, on the radio", 1.2, 1],
  j: ["Mzee Jabali", 0.55, 0.85],
  b: ["Mwalimu Baraka", 0.8, 0.95],
  i: ["Daktari Imani", 1.1, 1],
  m: ["Mama Neema", 1.3, 1],
  a: ["Amani", 1, 1],
};
const INTRO =
  "Kenya, January 2008. You are Amani, a volunteer at a shelter holding forty families. Choose two actions, then hold the compound until the Red Cross convoy comes at dawn. Flares scare attackers away. Your voice can calm them. Follow the red arrow to the nearest threat.";
const BUL = [
  "",
  "This is Zawadi, on the radio. Stay indoors, keep the lamps low, and do not share messages you cannot confirm.",
  "Zawadi here. Help is on the way. Hold on until first light.",
];
const LINES = [
  "Night one. Dusk. The first torches appear on the horizon.",
  "Midnight. They are coming again. Hold the gates.",
  "Before dawn. This is the last push. Hold on until first light.",
];
const AMB = [
  ["m", "The children are asleep. Please keep them safe."],
  ["j", "Keep your voice calm. Anger feeds the fire."],
  ["b", "Everyone stay low and away from the doors."],
  ["i", "Water and bandages are ready in the tent."],
];
let nar = true,
  seen = 0;
function speak(t, w, l, must) {
  const ss = window.speechSynthesis;
  if (!must && ss && ss.speaking) return;
  const c = CH[w],
    cp = $("cap");
  cp.innerHTML = "<b>" + c[0] + "</b> " + t;
  cp.style.opacity = 1;
  clearTimeout(speak.t);
  speak.t = setTimeout(() => (cp.style.opacity = 0), 1800 + t.length * 55);
  if (!nar || !ss) return;
  ss.cancel();
  const u = new SpeechSynthesisUtterance(t.replace(/[“”]/g, ""));
  u.pitch = c[1];
  u.rate = c[2];
  u.lang = l == "sw" ? "sw-KE" : "en-GB";
  const vs = ss.getVoices();
  for (const p of l == "sw" ? ["sw"] : ["en-ke", "en-gb", "en"]) {
    const v = vs.find((x) =>
      x.lang.replace("_", "-").toLowerCase().startsWith(p),
    );
    if (v) {
      u.voice = v;
      break;
    }
  }
  ss.speak(u);
}
let S,
  yaw = 0,
  pitch = 0,
  bob = 0,
  shake = 0,
  vx = 0,
  vz = 0,
  jx = 0,
  jy = 0,
  jid = null,
  lid = null,
  jo = null,
  lp = null;
const K = { w: 0, a: 0, s: 0, d: 0, sprint: 0, crouch: 0 },
  kc = {
    KeyW: "w",
    KeyA: "a",
    KeyS: "s",
    KeyD: "d",
    ArrowUp: "w",
    ArrowLeft: "a",
    ArrowDown: "s",
    ArrowRight: "d",
    ShiftLeft: "sprint",
    ShiftRight: "sprint",
    ControlLeft: "crouch",
    ControlRight: "crouch",
    KeyC: "crouch",
  };
const ov = (h) => {
    const o = $("ov");
    o.innerHTML = '<div class="cd">' + h + "</div>";
    o.classList.remove("control-overlay");
    o.style.display = "flex";
  },
  hide = () => ($("ov").style.display = "none");
function say(t) {
  const m = $("msg");
  m.textContent = t;
  m.style.opacity = 1;
  clearTimeout(say.t);
  say.t = setTimeout(() => (m.style.opacity = 0), 2400);
}
function lockPointer() {
  if (touch || !$("c").requestPointerLock) return;
  try {
    $("c").requestPointerLock();
  } catch (error) {
    console.error("Unable to lock pointer", error);
  }
}
const createState = GameCore.createState;
let cinematic = null;
function finishCinematic() {
  const c = cinematic;
  if (!c) return;
  cinematic = null;
  $("cin").className = "";
  $("cinText").textContent = "";
  $("cinText").style.display = "";
  c.done();
}
function startCinematic(kind, done) {
  const captions = {
    intro: "",
    fail: "The barricade falls. In the smoke and confusion, the shelter is lost. The aftermath is shown at a distance; the people are remembered, not displayed.",
    win: `First light. The Red Cross convoy reaches ${placeName()}. The gates open, and the families come out together.`,
  };
  const tone = kind == "fail" ? "fail" : kind == "win" ? "win" : "";
  cinematic = {
    kind,
    started: performance.now(),
    duration: kind == "intro" ? 8 : 6,
    done,
  };
  S.st = "cinematic";
  hide();
  $("hud").style.opacity = 0;
  $("cap").style.opacity = 0;
  $("cin").className = `show ${tone}`;
  $("cinText").textContent = captions[kind];
  $("cinText").style.display = captions[kind] ? "" : "none";
}
function updateCinematic(now) {
  if (!cinematic) return;
  const c = cinematic,
    p = Math.min(1, (now - c.started) / 1000 / c.duration),
    ease = p * p * (3 - 2 * p);
  if (c.kind == "intro") {
    cam.position.set(0, 65 - 63 * ease, 58 - 44 * ease);
    cam.lookAt(0, 1.2 * ease, 14 - 14 * ease);
  } else {
    cam.position.set(
      c.kind == "fail" ? 18 : 28,
      7 - 3 * ease,
      c.kind == "fail" ? 28 - 10 * ease : 34 - 18 * ease,
    );
    cam.lookAt(0, 1.4, 0);
  }
  if (p >= 1) finishCinematic();
}
function setLocation(id) {
  S.location = id;
  setSky(LOCATIONS[id].palette);
  buildLocationMap(id);
}
function reset() {
  if (S) for (const e of S.en) sc.remove(e.g);
  S = createState();
  cam.position.set(0, 2.1, 17);
  yaw = pitch = 0;
  bob = shake = vx = vz = 0;
}
function title() {
  $("hud").style.opacity = 0;
  ov(
    `<div class="title-screen"><h1>2<span class="ring"></span>7</h1><p class="notice">2o7 is fiction set during Kenya’s 2007–08 post-election crisis. It deals with fear, displacement and loss, without graphic violence. You can pause at any time. If it affects you, talk to someone you trust, or call the Kenya Red Cross on 1199 or the Child Helpline on 116 (both free, 24 hours).</p><button class="go" data-action="begin">Start</button></div>`,
  );
}
function begin() {
  reset();
  if (!AC)
    try {
      AC = new (window.AudioContext || window.webkitAudioContext)();
    } catch (error) {
      console.error("Audio is unavailable", error);
      say("Sound is unavailable; the game can still be played");
    }
  if (AC && AC.state == "suspended")
    AC.resume().catch((error) =>
      console.error("Unable to resume audio", error),
    );
  speak(seen ? "Try again. Choose a relief operation." : INTRO, "n", "en", 1);
  seen = 1;
  startCinematic("intro", controlCenter);
}
function controlCenter() {
  S.st = "control";
  hide();
  $("msg").style.opacity = 0;
  $("cap").style.opacity = 0;
  const cards = Object.entries(LOCATIONS)
    .map(
      ([id, l]) =>
        `<button class="op location-card" data-action="select-location" data-location="${id}"><span class="location-icon">${l.icon}</span><span class="location-copy"><small>${l.region}</small><b>${l.name.split(" · ")[1]}</b><span class="location-brief">${l.brief}</span><span class="location-meta"><em>${l.terrain}</em><em>${l.route}</em></span></span><span class="location-arrow">↗</span></button>`,
    )
    .join("");
  ov(
    `<div class="control-shell"><div class="control-head"><div><span class="eyebrow">National relief network</span><h2>Operations desk</h2></div><span class="control-status"><i></i> Live · Jan 2008</span></div><div class="control-summary"><span class="summary-icon">⌁</span><span><b>Choose a field signal</b><small>Five routes are waiting for night watch.</small></span><strong>05</strong></div><div class="location-grid">${cards}</div><div class="control-foot"><span><i class="pulse"></i> Radio network online</span><span>Move with care · protect civilians</span></div></div>`,
  );
  $("ov").classList.add("control-overlay");
}
function selectLocation(id) {
  if (!LOCATIONS[id]) return;
  setLocation(id);
  plan();
}
function plan() {
  if (!S.location) return controlCenter();
  S.st = "plan";
  S.ap = 2;
  S.rd = 0;
  setSky(LOCATIONS[S.location].palette);
  if (S.w > 0) speak(BUL[S.w], "z", "en", 1);
  if (document.exitPointerLock) document.exitPointerLock();
  const l = LOCATIONS[S.location],
    buttons = Object.keys(OPT)
      .map(
        (k) =>
          `<button class="op" data-action="pick" data-choice="${k}"><b>${OPT[k][0]}</b><span>${OPT[k][1]}</span></button>`,
      )
      .join("");
  ov(
    "<h2>" +
      l.name +
      '</h2><p class="h">' +
      l.brief +
      "</p><p>" +
      WAVES[S.w][0] +
      '. Choose two actions before it starts. Actions left: <b id="ap">2</b></p>' +
      rcard() +
      buttons +
      '<button class="go" data-action="go">Begin</button>',
  );
}
function pick(k, b) {
  if (GameCore.chooseAction(S, k)) {
    $("ap").textContent = S.ap;
    b.disabled = true;
  }
}
function go() {
  hide();
  $("hud").style.opacity = 1;
  cam.position.set(0, 2.1, 17);
  yaw = pitch = 0;
  S.q = Math.round(WAVES[S.w][1] * (S.el ? 0.65 : 1)) + S.xt;
  S.el = 0;
  S.xt = 0;
  S.t = 1.5;
  S.st = "fight";
  say(WAVES[S.w][0]);
  speak(LINES[S.w], "n", "en", 1);
  S.ev = 0;
  S.at = 14;
  lockPointer();
}
function resume() {
  hide();
  $("hud").style.opacity = 1;
  S.st = "fight";
  lockPointer();
}
function pauseMenu() {
  S.st = "pause";
  if (document.exitPointerLock) document.exitPointerLock();
  ov(
    '<h2>Paused</h2><p class="h">You can stop at any time. If it affects you, talk to someone you trust, or call the Kenya Red Cross on 1199 or the Child Helpline on 116 (both free, 24 hours).</p><button class="go" data-action="resume">Resume</button> <button class="go ghost" data-action="quit">Back to start</button>',
  );
}
function quitToStart() {
  if (window.speechSynthesis) speechSynthesis.cancel();
  reset();
  title();
}
function readBest() {
  try {
    return Number(localStorage.getItem("2o7b")) || 0;
  } catch (error) {
    console.error("Unable to read best result", error);
    return 0;
  }
}
function writeBest(score) {
  try {
    localStorage.setItem("2o7b", String(score));
  } catch (error) {
    console.error("Unable to save best result", error);
  }
}
function end(w) {
  S.st = "end";
  if (w)
    [523, 659, 784].forEach((f, i) =>
      setTimeout(() => snd(f, 0.5, "sine", 0.2), i * 220),
    );
  else snd(110, 1, "sawtooth", 0.2, 55);
  speak(
    w
      ? `The convoy has reached ${placeName()}. Thank you, neighbours. You kept each other safe.`
      : "The shelter could not hold tonight. But every message you check and every neighbour you calm matters.",
    w ? "z" : "n",
    "en",
    1,
  );
  if (document.exitPointerLock) document.exitPointerLock();
  for (const e of S.en) sc.remove(e.g);
  S.en = [];
  const s = Math.max(0, Math.round(S.safe));
  let bst = readBest();
  if (w && s > bst) {
    bst = s;
    writeBest(s);
  }
  const result = () =>
    ov(
      `<h2>${w ? (s >= 70 ? "Everyone made it to dawn" : "The shelter held, at a cost") : "The shelter was overrun tonight"}</h2><p>${w ? `The Red Cross convoy rolls in at first light. Shelter safety ${s}%. Attackers turned back: ${S.dis}. Best result: ${bst}%.` : `Attackers turned back: ${S.dis}. Try calling the peace committee early and save flares for the ones at the barricade.`}</p><p class="h">${HIST}</p><button class="go" data-action="begin">Play again</button> <button class="go" style="background:#26180f;border:1px solid #5a3a24" data-action="share">Share 2o7</button>`,
    );
  startCinematic(w ? "win" : "fail", result);
}
function reload() {
  if (S.rl > 0 || S.ammo >= 6 || S.sp < 1) return;
  S.rl = 1.4;
  say("Reloading…");
}
function tracer(e) {
  const a = new T.Vector3(0.25, -0.2, -0.6).applyMatrix4(cam.matrixWorld),
    l = new T.Line(
      new T.BufferGeometry().setFromPoints([a, e]),
      new T.LineBasicMaterial({ color: 0xffc060 }),
    );
  sc.add(l);
  S.fx.push({ o: l, t: 0.1 });
  const s2 = new T.Sprite(gm);
  s2.position.copy(e);
  s2.scale.set(2.6, 2.6, 1);
  sc.add(s2);
  S.fx.push({ o: s2, t: 0.14 });
}
function fire() {
  if (S.st != "fight" || S.fc > 0 || S.rl > 0) return;
  if (S.ammo < 1) {
    reload();
    return;
  }
  S.ammo--;
  S.fc = 0.4;
  S.fl = 1;
  gl2.intensity = 2.4;
  snd(700, 0.16, "sawtooth", 0.12, 140);
  const ray = new T.Raycaster();
  ray.setFromCamera({ x: 0, y: 0 }, cam);
  let best = null,
    bd = 1e9;
  for (const e of S.en) {
    if (e.s == 2) continue;
    const c = e.g.position.clone();
    c.y = 1;
    const al = c.distanceTo(cam.position);
    if (ray.ray.distanceSqToPoint(c) < 0.6 && al < 70 && al < bd) {
      bd = al;
      best = e;
    }
  }
  tracer(ray.ray.at(best ? bd : 60, new T.Vector3()));
  if (best) best.s = 2;
  shake = 0.08;
  say(best ? "Flare hit — threat turned back" : "Flare launched");
  if (S.ammo < 1) reload();
}
function shout() {
  if (S.st != "fight" || S.cd > 0) return;
  S.cd = 8;
  snd(170, 0.6, "triangle", 0.25, 260);
  speak(Q[Math.floor(rnd() * Q.length)], "a", "sw", 1);
  for (const e of S.en) {
    if (e.s == 2) continue;
    const p = e.g.position;
    if (Math.hypot(p.x - cam.position.x, p.z - cam.position.z) < 18) {
      e.h--;
      if (e.h <= 0) e.s = 2;
      else {
        e.s = 1;
        e.w = 3;
      }
    }
  }
}
function spawn() {
  const a = rnd() * 6.283,
    g = mkE();
  g.position.set(Math.sin(a) * 55, 0, Math.cos(a) * 55);
  S.en.push({
    g,
    s: 0,
    h: 2,
    t: rnd() * 9,
    w: 0,
    v: 2.4 + S.w * 0.5 + rnd() * 0.6,
  });
}
function upd(dt) {
  let f = K.w - K.s - jy,
    r = K.d - K.a + jx;
  const l = Math.hypot(f, r);
  if (l > 1) {
    f /= l;
    r /= l;
  }
  const sprinting =
      K.sprint && l > 0 && !K.crouch && S.stamina > 1 && S.rl <= 0,
    crouching = K.crouch && !sprinting,
    speed = crouching ? 2.1 : sprinting ? 8.5 : 5,
    sy = Math.sin(yaw),
    cy = Math.cos(yaw),
    p = cam.position;
  const targetX = (-sy * f + cy * r) * speed,
    targetZ = (-cy * f - sy * r) * speed;
  vx += (targetX - vx) * Math.min(1, dt * (sprinting ? 12 : 9));
  vz += (targetZ - vz) * Math.min(1, dt * (sprinting ? 12 : 9));
  const previousX = p.x,
    previousZ = p.z;
  p.x += vx * dt;
  p.z += vz * dt;
  if (hitsCollider(p.x, p.z)) {
    p.x = previousX;
    p.z = previousZ;
    vx *= 0.2;
    vz *= 0.2;
  }
  const d = Math.hypot(p.x, p.z);
  if (d > 58) {
    p.x *= 58 / d;
    p.z *= 58 / d;
  }
  if ((S.location === "coast" || S.location === "nyanza") && p.x > 20) p.x = 20;
  if (S.location === "western" && p.x > -21 && p.x < -9)
    p.x = p.x < -15 ? -21 : -9;
  if (S.location === "rift_valley" && Math.hypot(p.x - 16, p.z + 16) < 7) {
    S.safe = Math.max(0, S.safe - dt * 1.8);
    if (!(S.ev & 8)) {
      S.ev |= 8;
      speak(
        "The ground is hot near the fissure. Keep to the route.",
        "a",
        "en",
        1,
      );
    }
    if (sprinting) S.stamina = Math.max(0, S.stamina - dt * 25);
    else S.stamina = Math.min(100, S.stamina + dt * (crouching ? 28 : 18));
    const moving = Math.hypot(vx, vz) > 0.35;
    if (moving) bob += dt * (sprinting ? 13 : crouching ? 5 : 8);
    const bobAmount = moving
      ? sprinting
        ? 0.055
        : crouching
          ? 0.018
          : 0.032
      : 0;
    p.y = (crouching ? 1.45 : 2.1) + Math.sin(bob) * bobAmount;
  }
  if ((S.location === "coast" || S.location === "nyanza") && p.x > 16) {
    S.safe = Math.max(0, S.safe - dt * 0.35);
  }
  const ax = Math.abs(p.x),
    az = Math.abs(p.z);
  if (ax < 6.9 && az < 4.3) {
    if (6.9 - ax < 4.3 - az) p.x = (p.x < 0 ? -1 : 1) * 6.9;
    else p.z = (p.z < 0 ? -1 : 1) * 4.3;
  }
  S.fc -= dt;
  S.cd -= dt;
  if (S.rl > 0) {
    S.rl -= dt;
    if (S.rl <= 0) {
      const n = Math.min(6 - S.ammo, S.sp);
      S.ammo += n;
      S.sp -= n;
    }
  }
  S.t -= dt;
  if (S.q > 0 && S.t <= 0) {
    spawn();
    S.q--;
    S.t = Math.max(0.7, 2.1 - S.w * 0.5) * (0.6 + rnd() * 0.8);
  }
  for (let i = S.en.length - 1; i >= 0; i--) {
    const e = S.en[i],
      q = e.g.position,
      dd = Math.hypot(q.x, q.z);
    e.t += dt;
    if (e.s == 2) {
      q.x += (q.x / dd) * e.v * 1.6 * dt;
      q.z += (q.z / dd) * e.v * 1.6 * dt;
      e.g.rotation.y = Math.atan2(q.x, q.z);
      if (dd > 62) {
        sc.remove(e.g);
        S.en.splice(i, 1);
        S.dis++;
        continue;
      }
    } else if (e.s == 1) {
      e.w -= dt;
      if (e.w <= 0) e.s = 0;
    } else if (dd > 10.6) {
      const stepX = (-q.x / dd) * e.v * dt;
      const stepZ = (-q.z / dd) * e.v * dt;
      const nextX = q.x + stepX;
      const nextZ = q.z + stepZ;
      if (!hitsCollider(nextX, nextZ, 0.35, true)) {
        q.x = nextX;
        q.z = nextZ;
      } else if (!hitsCollider(q.x + stepX, q.z, 0.35, true)) {
        q.x += stepX;
      } else if (!hitsCollider(q.x, q.z + stepZ, 0.35, true)) {
        q.z += stepZ;
      } else {
        e.t += dt * 2;
      }
      e.g.rotation.y = Math.atan2(-q.x, -q.z);
    } else {
      const x = 0.9 * dt;
      if (S.wall > 0) S.wall = Math.max(0, S.wall - x * 1.3);
      else S.safe -= x;
      shake = Math.min(0.16, shake + dt * 0.25);
    }
    q.y = e.s == 1 ? 0 : Math.abs(Math.sin(e.t * 9)) * 0.08;
    e.g.userData.gl.scale.setScalar(1.6 + Math.sin(e.t * 13) * 0.35);
  }
  S.at -= dt;
  if (S.safe < 40 && !(S.ev & 1)) {
    S.ev |= 1;
    speak(
      "Safety is low! Hold the line, we need more hands at the tent!",
      "i",
      "en",
      1,
    );
  } else if (S.wall < 20 && !(S.ev & 2)) {
    S.ev |= 2;
    speak(
      "The barricade is breaking! Do not let them reach the hall!",
      "b",
      "en",
      1,
    );
  } else if (S.ammo + S.sp < 5 && !(S.ev & 4)) {
    S.ev |= 4;
    speak("Flares are running low. Use your voice.", "a", "en", 1);
  } else if (S.at <= 0) {
    S.at = 22 + rnd() * 10;
    const a = AMB[Math.floor(rnd() * AMB.length)];
    speak(a[1], a[0], "en", 0);
  }
  if (S.safe <= 0) {
    end(false);
    return;
  }
  if (S.q <= 0 && !S.en.length) {
    S.w++;
    if (S.w < WAVES.length) {
      say("The night goes quiet…");
      plan();
    } else end(true);
  }
}
function hud() {
  $("wv").textContent = WAVES[Math.min(S.w, 2)][0];
  $("bs").style.width = Math.max(0, S.safe) + "%";
  $("bw").style.width = S.wall + "%";
  $("st").style.width = Math.max(0, S.stamina) + "%";
  $("pz").style.display = S.st == "fight" ? "block" : "none";
  $("hint").textContent =
    S.st == "fight"
      ? `${K.crouch ? "CROUCH" : K.sprint && S.stamina > 1 ? "SPRINT" : "READY"}  ·  ${touch ? "Push the stick far to sprint" : "Shift sprint  ·  C crouch  ·  P pause"}`
      : "";
  $("am").textContent =
    `Flares ${S.ammo}, spare ${S.sp}, attackers left ${S.en.length + S.q}` +
    (S.rl > 0 ? ", reloading" : "");
  $("bs2").textContent = S.cd > 0 ? Math.ceil(S.cd) : "Shout";
  let nb = null,
    nd = 1e9;
  for (const e of S.en) {
    if (e.s == 2) continue;
    const d2 =
      (e.g.position.x - cam.position.x) ** 2 +
      (e.g.position.z - cam.position.z) ** 2;
    if (d2 < nd) {
      nd = d2;
      nb = e;
    }
  }
  const ar = $("ar");
  if (nb && S.st == "fight") {
    const rr =
      Math.atan2(
        cam.position.x - nb.g.position.x,
        cam.position.z - nb.g.position.z,
      ) - yaw;
    ar.style.display =
      Math.abs(Math.atan2(Math.sin(rr), Math.cos(rr))) > 0.6 ? "block" : "none";
    ar.style.transform = `rotate(${-rr}rad) translateY(-90px)`;
  } else ar.style.display = "none";
  const h = 0.3 + (1.3 * S.wall) / 100;
  seg.forEach((s) => {
    s.scale.y = h / 1.2;
    s.position.y = h / 2;
  });
}
let last = performance.now();
function loop(t) {
  requestAnimationFrame(loop);
  const dt = Math.min((t - last) / 1000, 0.05);
  last = t;
  if (cinematic) updateCinematic(t);
  else {
    if (S.st == "title") yaw = Math.sin(t / 5000) * 0.3;
    if (S.st == "fight") upd(dt);
  }
  for (let i = S.fx.length - 1; i >= 0; i--) {
    S.fx[i].t -= dt;
    if (S.fx[i].t <= 0) {
      sc.remove(S.fx[i].o);
      S.fx.splice(i, 1);
    }
  }
  $("fl").style.opacity = S.fl * 0.3;
  S.fl = Math.max(0, S.fl - dt * 6);
  sky.position.set(cam.position.x, 0, cam.position.z);
  dlight.intensity = 1.3 + Math.sin(t / 90) * 0.15 + rnd() * 0.1;
  gl2.intensity = Math.max(0, gl2.intensity - dt * 18);
  if (!cinematic) {
    shake = Math.max(0, shake - dt);
    cam.rotation.set(
      pitch + (rnd() - 0.5) * shake,
      yaw + (rnd() - 0.5) * shake,
      (rnd() - 0.5) * shake * 0.35,
    );
    const targetFov = S.st == "fight" && K.sprint && S.stamina > 1 ? 78 : 72;
    if (Math.abs(cam.fov - targetFov) > 0.1) {
      cam.fov += (targetFov - cam.fov) * Math.min(1, dt * 8);
      cam.updateProjectionMatrix();
    }
  }
  hud();
  R.render(sc, cam);
}
function rs() {
  R.setSize(innerWidth, innerHeight);
  cam.aspect = innerWidth / innerHeight;
  cam.updateProjectionMatrix();
}
addEventListener("resize", rs);
rs();
addEventListener("keydown", (e) => {
  if (kc[e.code]) K[kc[e.code]] = 1;
  if (e.key == "Shift") K.sprint = 1;
  if (e.key == "Control" || e.key.toLowerCase() == "c") K.crouch = 1;
  if (e.code == "KeyE") shout();
  if (e.code == "KeyM") $("mu").click();
  if (e.code == "KeyV") $("nv").click();
  if (e.code == "KeyR" && S.st == "fight") reload();
  if (e.code == "KeyP" && S.st == "fight") pauseMenu();
});
addEventListener("keyup", (e) => {
  if (kc[e.code]) K[kc[e.code]] = 0;
  if (e.key == "Shift") K.sprint = 0;
  if (e.key == "Control" || e.key.toLowerCase() == "c") K.crouch = 0;
});
addEventListener("mousemove", (e) => {
  if (document.pointerLockElement) {
    yaw -= e.movementX * 0.0023;
    pitch = Math.max(-1.2, Math.min(1.2, pitch - e.movementY * 0.0023));
  }
});
addEventListener("mousedown", (e) => {
  if (document.pointerLockElement) fire();
});
document.addEventListener("click", (e) => {
  const target = e.target.closest("[data-action]");
  if (!target) return;
  const action = target.dataset.action;
  if (action == "skip-cinematic") finishCinematic();
  else if (action == "begin") begin();
  else if (action == "go") go();
  else if (action == "resume") resume();
  else if (action == "share") share(target);
  else if (action == "pick") pick(target.dataset.choice, target);
  else if (action == "rumour-forward") rumour(true);
  else if (action == "rumour-check") rumour(false);
  else if (action == "select-location") selectLocation(target.dataset.location);
  else if (action == "pause") {
    if (S.st == "fight") pauseMenu();
  } else if (action == "quit") quitToStart();
});
document.addEventListener("pointerlockchange", () => {
  if (!touch && S.st == "fight" && !document.pointerLockElement) {
    pauseMenu();
  }
});
if (touch) {
  document.querySelectorAll(".b").forEach((b) => (b.style.display = "block"));
  $("bf").addEventListener("pointerdown", (e) => {
    e.preventDefault();
    fire();
  });
  $("bs2").addEventListener("pointerdown", (e) => {
    e.preventDefault();
    shout();
  });
  $("bcr").addEventListener("pointerdown", (e) => {
    e.preventDefault();
    K.crouch = K.crouch ? 0 : 1;
    $("bcr").classList.toggle("on", !!K.crouch);
  });
  const cl = (v) => Math.max(-1, Math.min(1, v));
  addEventListener("touchstart", (e) => {
    if (S.st != "fight") return;
    for (const t of e.changedTouches) {
      if (t.target.closest(".b,#mu,#nv")) continue;
      if (t.clientX < innerWidth * 0.45 && jid === null) {
        jid = t.identifier;
        jo = [t.clientX, t.clientY];
        const j = $("js");
        j.style.cssText += `display:block;left:${t.clientX}px;top:${t.clientY}px`;
      } else if (lid === null) {
        lid = t.identifier;
        lp = [t.clientX, t.clientY];
      }
    }
  });
  addEventListener("touchmove", (e) => {
    for (const t of e.changedTouches) {
      if (t.identifier === jid) {
        jx = cl((t.clientX - jo[0]) / 50);
        jy = cl((t.clientY - jo[1]) / 50);
        K.sprint = Math.hypot(t.clientX - jo[0], t.clientY - jo[1]) > 90 ? 1 : 0;
      } else if (t.identifier === lid) {
        yaw -= (t.clientX - lp[0]) * 0.006;
        pitch = Math.max(
          -1.2,
          Math.min(1.2, pitch - (t.clientY - lp[1]) * 0.006),
        );
        lp = [t.clientX, t.clientY];
      }
    }
  });
  const te = (e) => {
    for (const t of e.changedTouches) {
      if (t.identifier === jid) {
        jid = null;
        jx = jy = 0;
        K.sprint = 0;
        $("js").style.display = "none";
      }
      if (t.identifier === lid) lid = null;
    }
  };
  addEventListener("touchend", te);
  addEventListener("touchcancel", te);
}
document.addEventListener("visibilitychange", () => {
  if (document.hidden && window.speechSynthesis) speechSynthesis.cancel();
  if (document.hidden && S.st == "fight") {
    pauseMenu();
  }
});
$("mu").addEventListener("click", () => {
  mute = !mute;
  $("mu").textContent = mute ? "Sound off" : "Sound on";
});
$("nv").addEventListener("click", () => {
  nar = !nar;
  $("nv").textContent = nar ? "Voice on" : "Voice off";
  if (!nar && window.speechSynthesis) speechSynthesis.cancel();
});
reset();
title();
requestAnimationFrame(loop);
