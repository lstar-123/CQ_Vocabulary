// ============================================================
// Generate Q-style mascot Lottie JSON animations (Bodymovin 5.7)
// 奶龙 (dragon) / 咕咕嘎嘎 (chick) / 噜噜 (pig)
// 90-frame celebration loops @30fps = 3s, seamless loop
//
// Coordinate convention (AE-style):
//   shapes live in LOCAL coordinates relative to the part's pivot
//   layer ks.p  = pivot position in canvas coords
//   layer ks.a  = [0,0] (rotation/scale pivot = local origin)
// ============================================================
const fs = require('fs');
const OUT = 'E:/07_Projects/agent_projects/VocabularyMemorization/frontend/assets/lottie/';

const FR = 30, OP = 90;

// ---------- helpers ----------
const V = (t, s, e, ix, iy, ox, oy) => ({ i: { x: [ix], y: [iy] }, o: { x: [ox], y: [oy] }, t, s, e });
const RV = (t, s, e, ix, iy, ox, oy) => V(t, [s], [e], ix, iy, ox, oy); // rotation kf: s/e must be arrays
const C = (a, k) => ({ a, k });

const el = (nm, x, y, w, h) => ({ ty: 'el', nm, p: C(0, [x, y]), s: C(0, [w, h]) });
const fl = (nm, r, g, b, o = 100) => ({ ty: 'fl', nm, c: C(0, [r / 255, g / 255, b / 255, 1]), o: C(0, o) });
const st = (nm, r, g, b, w) => ({ ty: 'st', nm, c: C(0, [r / 255, g / 255, b / 255, 1]), o: C(0, 100), w: C(0, w), lc: 2, lj: 2 });
const tr = () => ({
  ty: 'tr', nm: 'Transform',
  p: C(0, [0, 0]), a: C(0, [0, 0]), s: C(0, [100, 100]), r: C(0, 0), o: C(0, 100), sk: C(0, 0), sa: C(0, 0),
});
const tri = (nm, pts) => ({
  ty: 'sh', nm,
  ks: C(0, { c: true, v: pts.map(p => [p[0], p[1]]), i: pts.map(() => [0, 0]), o: pts.map(() => [0, 0]) }),
});
const smile = (nm, cx, cy, spread, depth) => ({
  ty: 'sh', nm,
  ks: C(0, {
    c: false,
    v: [[cx - spread, cy], [cx, cy + depth], [cx + spread, cy]],
    i: [[0, 0], [-spread * 0.55, depth * 0.35], [0, 0]],
    o: [[0, 0], [spread * 0.55, depth * 0.35], [0, 0]],
  }),
});

// one part = one layer; shapes in local coords, pivot via ks.p
function part(nm, ind, shapes, ks) {
  return {
    ddd: 0, ind, ty: 4, nm, sr: 1,
    ks: Object.assign(
      { o: C(0, 100), r: C(0, 0), p: C(0, [0, 0]), a: C(0, [0, 0]), s: C(0, [100, 100]) },
      ks || {}
    ),
    ao: 0, shapes: [{ ty: 'gr', it: shapes.concat([tr()]), nm: 'g' }],
    ip: 0, op: OP, st: 0,
  };
}
const KF = arr => ({ a: 1, k: arr });

// position anim synced to the body hop (y0 -> y0-16 -> y0 -> y0-10 -> y0)
function syncY(x, y0) {
  return KF([
    V(0, [x, y0], [x, y0 - 16], 0.45, 0.5, 0.55, 0.5),
    V(20, [x, y0 - 16], [x, y0], 0.45, 0.5, 0.55, 0.5),
    V(45, [x, y0], [x, y0 - 10], 0.45, 0.5, 0.55, 0.5),
    V(62, [x, y0 - 10], [x, y0], 0.45, 0.5, 0.55, 0.5),
  ]);
}


function emit(name, layers, w = 200, h = 200) {
  const json = { v: '5.7.4', fr: FR, ip: 0, op: OP, w, h, nm: name, ddd: 0, assets: [], layers };
  fs.writeFileSync(OUT + name + '.json', JSON.stringify(json));
  console.log('wrote', OUT + name + '.json', fs.statSync(OUT + name + '.json').size, 'bytes');
}

// ============================================================
// 奶龙 NAILONG — sage-green chubby baby dragon
// body #7BC8A4, deep #4A9E7C, belly #F4FAF7, blush #F9A8C4
// ============================================================
function nailong() {
  const layers = [];

  // face (pivot at 100,105) — blink via scaleY
  const blinkY = KF([
    V(0, [100, 100], [100, 100], 0.5, 0.5, 0.5, 0.5),
    V(34, [100, 100], [100, 12], 0.5, 0.5, 0.5, 0.5),
    V(36, [100, 12], [100, 100], 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('face', 1, [
    el('eyeW_L', -19, 0, 20, 20), fl('eyeW_L_f', 255, 255, 255),
    el('eyeP_L', -17, 2, 10, 10), fl('eyeP_L_f', 40, 60, 50),
    el('eyeW_R', 19, 0, 20, 20), fl('eyeW_R_f', 255, 255, 255),
    el('eyeP_R', 21, 2, 10, 10), fl('eyeP_R_f', 40, 60, 50),
    el('blushL', -30, 14, 12, 7), fl('blushL_f', 249, 168, 196, 70),
    el('blushR', 30, 14, 12, 7), fl('blushR_f', 249, 168, 196, 70),
    smile('mouth', 0, 22, 11, 5), st('mouth_st', 60, 80, 70, 3),
  ], { p: syncY(100, 105), s: blinkY }));

  layers.push(part('belly', 2, [
    el('belly', 0, 0, 62, 48), fl('belly_f', 244, 250, 247),
  ], { p: syncY(100, 150) }));

  // body — floats & squashes on each hop (pivot = body center)
  const bodyY = KF([
    V(0, [100, 132], [100, 116], 0.45, 0.5, 0.55, 0.5),
    V(20, [100, 116], [100, 132], 0.45, 0.5, 0.55, 0.5),
    V(45, [100, 132], [100, 122], 0.45, 0.5, 0.55, 0.5),
    V(62, [100, 122], [100, 132], 0.45, 0.5, 0.55, 0.5),
  ]);
  const bodyS = KF([
    V(0, [100, 100], [106, 94], 0.45, 0.5, 0.55, 0.5),
    V(20, [106, 94], [100, 100], 0.45, 0.5, 0.55, 0.5),
    V(45, [100, 100], [103, 97], 0.45, 0.5, 0.55, 0.5),
    V(62, [103, 97], [100, 100], 0.45, 0.5, 0.55, 0.5),
  ]);
  layers.push(part('body', 3, [
    el('body', 0, 0, 110, 92), fl('body_f', 123, 200, 164),
  ], { p: bodyY, s: bodyS }));

  const wingSwing = KF([
    RV(0, -14, -26, 0.5, 0.5, 0.5, 0.5), RV(20, -26, -14, 0.5, 0.5, 0.5, 0.5),
    RV(45, -14, -22, 0.5, 0.5, 0.5, 0.5), RV(62, -22, -14, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('wingL', 4, [
    el('wingL', 0, -10, 26, 42), fl('wingL_f', 74, 158, 124),
  ], { p: syncY(46, 118), r: wingSwing }));

  layers.push(part('wingR', 5, [
    el('wingR', 0, -10, 26, 42), fl('wingR_f', 74, 158, 124),
  ], { p: syncY(154, 118), r: wingSwing }));

  const hornBob = KF([
    RV(0, -8, -16, 0.5, 0.5, 0.5, 0.5), RV(20, -16, -8, 0.5, 0.5, 0.5, 0.5),
    RV(45, -8, -14, 0.5, 0.5, 0.5, 0.5), RV(62, -14, -8, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('hornL', 6, [
    tri('hornL', [[-13, 0], [13, 0], [0, -28]]), fl('hornL_f', 74, 158, 124),
  ], { p: syncY(72, 88), r: hornBob }));

  layers.push(part('hornR', 7, [
    tri('hornR', [[-13, 0], [13, 0], [0, -28]]), fl('hornR_f', 74, 158, 124),
  ], { p: syncY(128, 88), r: hornBob }));

  const tailWag = KF([
    RV(0, 0, -28, 0.5, 0.5, 0.5, 0.5), RV(15, -28, 28, 0.5, 0.5, 0.5, 0.5),
    RV(30, 28, -28, 0.5, 0.5, 0.5, 0.5), RV(45, -28, 28, 0.5, 0.5, 0.5, 0.5),
    RV(60, 28, -28, 0.5, 0.5, 0.5, 0.5), RV(75, -28, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('tail', 8, [
    el('tail', 8, 0, 34, 22), fl('tail_f', 123, 200, 164),
  ], { p: syncY(38, 140), r: tailWag }));

  emit('nailong', layers);
}

// ============================================================
// 咕咕嘎嘎 CHICK — sunny yellow chick, orange beak
// body #F7C948, deep #E8A33D, beak #F59E0B, feet #E8912D
// ============================================================
function chick() {
  const layers = [];

  const eyeS = KF([
    V(0, [100, 100], [132, 132], 0.5, 0.5, 0.5, 0.5),
    V(16, [132, 132], [100, 100], 0.5, 0.5, 0.5, 0.5),
    V(40, [100, 100], [132, 132], 0.5, 0.5, 0.5, 0.5),
    V(56, [132, 132], [100, 100], 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('eyeL', 1, [
    el('eyeL', 0, 0, 16, 16), fl('eyeL_f', 60, 50, 40),
  ], { p: C(0, [84, 112]), s: eyeS }));

  layers.push(part('eyeR', 2, [
    el('eyeR', 0, 0, 16, 16), fl('eyeR_f', 60, 50, 40),
  ], { p: C(0, [116, 112]), s: eyeS }));

  layers.push(part('blushL', 3, [
    el('blushL', 0, 0, 12, 7), fl('blushL_f', 249, 168, 196, 70),
  ], { p: C(0, [68, 122]) }));

  layers.push(part('blushR', 4, [
    el('blushR', 0, 0, 12, 7), fl('blushR_f', 249, 168, 196, 70),
  ], { p: C(0, [132, 122]) }));

  const beakS = KF([
    V(0, [100, 100], [100, 62], 0.4, 0.5, 0.6, 0.5),
    V(12, [100, 62], [100, 100], 0.4, 0.5, 0.6, 0.5),
    V(45, [100, 100], [100, 66], 0.4, 0.5, 0.6, 0.5),
    V(58, [100, 66], [100, 100], 0.4, 0.5, 0.6, 0.5),
  ]);
  layers.push(part('beak', 5, [
    tri('beak', [[-15, 4], [15, 4], [0, 20]]), fl('beak_f', 245, 158, 11),
  ], { p: C(0, [100, 124]), s: beakS }));

  const crestSwing = KF([
    RV(0, -10, 8, 0.5, 0.5, 0.5, 0.5), RV(20, 8, -10, 0.5, 0.5, 0.5, 0.5),
    RV(45, -10, 6, 0.5, 0.5, 0.5, 0.5), RV(62, 6, -10, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('crest', 6, [
    tri('crest', [[-9, 0], [9, 0], [0, -20]]), fl('crest_f', 247, 201, 72),
  ], { p: C(0, [100, 95]), r: crestSwing }));

  const bodyR = KF([
    RV(0, -12, 12, 0.5, 0.5, 0.5, 0.5), RV(30, 12, -12, 0.5, 0.5, 0.5, 0.5),
    RV(60, -12, 12, 0.5, 0.5, 0.5, 0.5), RV(90, 12, -12, 0.5, 0.5, 0.5, 0.5),
  ]);
  const bodyY = KF([
    V(0, [100, 136], [100, 122], 0.45, 0.5, 0.55, 0.5), V(28, [100, 122], [100, 136], 0.45, 0.5, 0.55, 0.5),
    V(58, [100, 136], [100, 126], 0.45, 0.5, 0.55, 0.5), V(76, [100, 126], [100, 136], 0.45, 0.5, 0.55, 0.5),
  ]);
  layers.push(part('body', 7, [
    el('body', 0, 0, 92, 84), fl('body_f', 247, 201, 72),
    el('belly', 0, 14, 56, 44), fl('belly_f', 252, 240, 200),
  ], { p: bodyY, r: bodyR }));

  const wingLr = KF([
    RV(0, 0, -30, 0.5, 0.5, 0.5, 0.5), RV(14, -30, 0, 0.5, 0.5, 0.5, 0.5),
    RV(45, 0, -26, 0.5, 0.5, 0.5, 0.5), RV(58, -26, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  const wingRr = KF([
    RV(0, 0, 30, 0.5, 0.5, 0.5, 0.5), RV(14, 30, 0, 0.5, 0.5, 0.5, 0.5),
    RV(45, 0, 26, 0.5, 0.5, 0.5, 0.5), RV(58, 26, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('wingL', 8, [
    el('wingL', -6, 8, 24, 40), fl('wingL_f', 232, 172, 58),
  ], { p: C(0, [50, 130]), r: wingLr }));

  layers.push(part('wingR', 9, [
    el('wingR', 6, 8, 24, 40), fl('wingR_f', 232, 172, 58),
  ], { p: C(0, [150, 130]), r: wingRr }));

  const footR = KF([
    RV(0, 0, -14, 0.5, 0.5, 0.5, 0.5), RV(30, -14, 0, 0.5, 0.5, 0.5, 0.5),
    RV(60, 0, -10, 0.5, 0.5, 0.5, 0.5), RV(76, -10, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  const footY = KF([
    V(0, [88, 172], [88, 167], 0.45, 0.5, 0.55, 0.5), V(28, [88, 167], [88, 172], 0.45, 0.5, 0.55, 0.5),
    V(58, [88, 172], [88, 169], 0.45, 0.5, 0.55, 0.5), V(76, [88, 169], [88, 172], 0.45, 0.5, 0.55, 0.5),
  ]);
  const footYR = KF([
    V(0, [112, 172], [112, 167], 0.45, 0.5, 0.55, 0.5), V(28, [112, 167], [112, 172], 0.45, 0.5, 0.55, 0.5),
    V(58, [112, 172], [112, 169], 0.45, 0.5, 0.55, 0.5), V(76, [112, 169], [112, 172], 0.45, 0.5, 0.55, 0.5),
  ]);
  layers.push(part('footL', 10, [
    el('footL', 0, 4, 14, 8), fl('footL_f', 232, 145, 45),
  ], { p: footY, r: footR }));

  layers.push(part('footR', 11, [
    el('footR', 0, 4, 14, 8), fl('footR_f', 232, 145, 45),
  ], { p: footYR, r: footR }));

  emit('chick', layers);
}

// ============================================================
// 噜噜 PIG — soft pink piglet, floppy ears
// body #F9A8D4, deep #EC7BB0, snout #FBC9E2
// ============================================================
function pig() {
  const layers = [];

  const eyeS = KF([
    V(0, [100, 100], [130, 130], 0.5, 0.5, 0.5, 0.5),
    V(14, [130, 130], [100, 100], 0.5, 0.5, 0.5, 0.5),
    V(48, [100, 100], [130, 130], 0.5, 0.5, 0.5, 0.5),
    V(62, [130, 130], [100, 100], 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('eyeL', 1, [
    el('eyeL', 0, 0, 14, 14), fl('eyeL_f', 90, 50, 80),
    el('hlL', -3, -4, 4, 4), fl('hlL_f', 255, 255, 255, 90),
  ], { p: C(0, [86, 116]), s: eyeS }));

  layers.push(part('eyeR', 2, [
    el('eyeR', 0, 0, 14, 14), fl('eyeR_f', 90, 50, 80),
    el('hlR', -3, -4, 4, 4), fl('hlR_f', 255, 255, 255, 90),
  ], { p: C(0, [114, 116]), s: eyeS }));

  layers.push(part('blushL', 3, [
    el('blushL', 0, 0, 13, 8), fl('blushL_f', 236, 140, 186, 75),
  ], { p: C(0, [70, 126]) }));

  layers.push(part('blushR', 4, [
    el('blushR', 0, 0, 13, 8), fl('blushR_f', 236, 140, 186, 75),
  ], { p: C(0, [130, 126]) }));

  const snoutS = KF([
    V(0, [100, 100], [100, 88], 0.45, 0.5, 0.55, 0.5),
    V(12, [100, 88], [100, 100], 0.45, 0.5, 0.55, 0.5),
    V(48, [100, 100], [100, 90], 0.45, 0.5, 0.55, 0.5),
    V(60, [100, 90], [100, 100], 0.45, 0.5, 0.55, 0.5),
  ]);
  layers.push(part('snout', 5, [
    el('snout', 0, 0, 36, 28), fl('snout_f', 251, 201, 226),
    el('n1', -9, -1, 14, 16), fl('n1_f', 158, 76, 130),
    el('n2', 9, -1, 14, 16), fl('n2_f', 158, 76, 130),
  ], { p: C(0, [100, 140]), s: snoutS }));

  const earLr = KF([
    RV(0, 0, -18, 0.5, 0.5, 0.5, 0.5), RV(18, -18, 0, 0.5, 0.5, 0.5, 0.5),
    RV(48, 0, -14, 0.5, 0.5, 0.5, 0.5), RV(64, -14, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  const earRr = KF([
    RV(0, 0, 18, 0.5, 0.5, 0.5, 0.5), RV(18, 18, 0, 0.5, 0.5, 0.5, 0.5),
    RV(48, 0, 14, 0.5, 0.5, 0.5, 0.5), RV(64, 14, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('earL', 6, [
    el('earL', 0, -8, 26, 34), fl('earL_f', 249, 168, 212),
    el('earL_in', 0, -6, 14, 22), fl('earL_in_f', 240, 140, 190),
  ], { p: C(0, [74, 86]), r: earLr }));

  layers.push(part('earR', 7, [
    el('earR', 0, -8, 26, 34), fl('earR_f', 249, 168, 212),
    el('earR_in', 0, -6, 14, 22), fl('earR_in_f', 240, 140, 190),
  ], { p: C(0, [126, 86]), r: earRr }));

  const bodyY = KF([
    V(0, [100, 134], [100, 118], 0.42, 0.5, 0.58, 0.5), V(24, [100, 118], [100, 134], 0.42, 0.5, 0.58, 0.5),
    V(50, [100, 134], [100, 124], 0.42, 0.5, 0.58, 0.5), V(70, [100, 124], [100, 134], 0.42, 0.5, 0.58, 0.5),
  ]);
  const bodyS = KF([
    V(0, [100, 100], [108, 92], 0.42, 0.5, 0.58, 0.5), V(24, [108, 92], [100, 100], 0.42, 0.5, 0.58, 0.5),
    V(50, [100, 100], [104, 96], 0.42, 0.5, 0.58, 0.5), V(70, [104, 96], [100, 100], 0.42, 0.5, 0.58, 0.5),
  ]);
  layers.push(part('body', 8, [
    el('body', 0, 0, 100, 90), fl('body_f', 249, 168, 212),
    el('belly', 0, 16, 60, 48), fl('belly_f', 253, 226, 238),
  ], { p: bodyY, s: bodyS }));

  const tailR = KF([
    RV(0, 0, 30, 0.5, 0.5, 0.5, 0.5), RV(14, 30, -24, 0.5, 0.5, 0.5, 0.5),
    RV(30, -24, 30, 0.5, 0.5, 0.5, 0.5), RV(48, 30, -20, 0.5, 0.5, 0.5, 0.5),
    RV(64, -20, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('tail', 9, [
    el('tail', 6, 10, 20, 26), fl('tail_f', 249, 168, 212),
  ], { p: C(0, [146, 120]), r: tailR }));

  const footR = KF([
    RV(0, 0, -10, 0.5, 0.5, 0.5, 0.5), RV(24, -10, 0, 0.5, 0.5, 0.5, 0.5),
    RV(50, 0, -6, 0.5, 0.5, 0.5, 0.5), RV(70, -6, 0, 0.5, 0.5, 0.5, 0.5),
  ]);
  layers.push(part('footL', 10, [
    el('footL', 0, 4, 16, 10), fl('footL_f', 236, 140, 186),
  ], { p: C(0, [88, 174]), r: footR }));

  layers.push(part('footR', 11, [
    el('footR', 0, 4, 16, 10), fl('footR_f', 236, 140, 186),
  ], { p: C(0, [112, 174]), r: footR }));

  emit('pig', layers);
}

nailong();
chick();
pig();
