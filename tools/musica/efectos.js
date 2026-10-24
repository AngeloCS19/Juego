// Graba los efectos de sonido a assets/sonidos/*.ogg desde los bocetos de sonido.html,
// con las versiones que eligió Angelo. Igual que render.js: navegador sin ventana y OfflineAudioContext.
//   node tools/musica/efectos.js
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path'), { execFileSync, spawnSync } = require('child_process');
const SR = 44100, LARGO = 4;
// pico de cada efecto en dB (0 = lo más fuerte posible): los pasos, la voz y los botones más bajos que las acciones
const PICO = { boton: -14, silbido: -12, paso_arenisca: -16, paso_madera: -16, paso_pasto: -16, golpe_narciso: -4, dano: -4, reflejo: -8 };
const pico = n => PICO[n] ?? (n.startsWith('voz') ? -14 : -6);
const SALIDA = path.join(__dirname, '../../assets/sonidos');
// archivo: código que lo toca (R tiene las funciones de sonido.html; E(id, versión) toca un efecto de la página)
const EFECTOS = {
  reflejo: "E('reflejo', 'C')",
  traspasar: "E('traspasar', 'B')",
  volver: "E('volver2', 'B')",
  empujar: "E('empujar2', 'B')",
  lava: "E('lava', 'A')",
  caer: "E('caer', 'A')",
  prenda: "E('prenda', 'B')",
  salida: "E('salida', 'B')",
  golpe_narciso: "E('golpe', 'A')",
  dano: "E('dano', 'B')",
  boton: "E('ui', 'B')",
  // «Narciso lanza una piedra» (A), partido en dos: el silbido mientras cae y el golpe al llegar
  silbido: "R.tono('sine', 1400, 300, .9, .06)",
  piedra_cae: "R.tono('sine', 90, 40, .25, .6); R.ruido(.2, .3, 'lowpass', 800, 300)",
  // un solo paso de cada superficie (la página toca dos seguidos)
  paso_arenisca: "R.ruido(.06, .18, 'lowpass', 900, 500)",
  paso_madera: "R.tono('triangle', 190, 150, .08, .15); R.ruido(.04, .1, 'bandpass', 1400, 1400, 0, { q: 3 })",
  paso_pasto: "R.ruido(.1, .1, 'highpass', 3500, 2500, 0, { a: .02 })",
};
// la voz de Narciso (A): una sílaba por nota de su escala; el juego elige una al azar por letra
[69, 73, 74, 65, 62].forEach((n, i) => { EFECTOS['voz_narciso_' + i] = `R.tono('triangle', R.nf(${n}), R.nf(${n}), .07, .1, 0, { lp: 2000 })`; });

let html = fs.readFileSync(path.join(__dirname, 'sonido.html'), 'utf8');
for (const [a, b] of [
  ['const now = () => AC.currentTime;', 'let T0 = 0; const now = () => T0;'],
  ['AC = new (window.AudioContext || window.webkitAudioContext)();', 'AC = window.__OFF;'],
  ['if (AC.state === "suspended") AC.resume();', ''],
]) { if (!html.includes(a)) throw new Error('sonido.html cambió: no encuentro ' + a); html = html.replace(a, b); }
const fin = html.lastIndexOf('})();');
html = html.slice(0, fin) + 'window.__R = { reset: () => { AC = null; rio = null; }, ac, tono, ruido, nf, EFECTOS };\n' + html.slice(fin);

(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  p.on('pageerror', e => { console.error(e.message); process.exit(1); });
  await p.setContent(html);
  for (const [nombre, codigo] of Object.entries(EFECTOS)) {
    const b64 = await p.evaluate(async ([codigo, SR, LARGO]) => {
      window.__OFF = new OfflineAudioContext(2, SR * LARGO, SR);
      const R = window.__R; R.reset(); R.ac();
      const E = (id, L) => R.EFECTOS.find(e => e.id === id).v["ABCD".indexOf(L)][1]();
      new Function('R', 'E', codigo)(R, E);
      const buf = await window.__OFF.startRendering();
      const n = buf.length, out = new Int16Array(n * 2);
      for (let c = 0; c < 2; c++) { const d = buf.getChannelData(c); for (let i = 0; i < n; i++) out[i * 2 + c] = Math.max(-1, Math.min(1, d[i])) * 32767; }
      let bin = ''; const u8 = new Uint8Array(out.buffer);
      for (let i = 0; i < u8.length; i += 32768) bin += String.fromCharCode.apply(null, u8.subarray(i, i + 32768));
      return btoa(bin);
    }, [codigo, SR, LARGO]);
    // lleva el pico a PICO y quita el silencio del final (el eco ya se apagó)
    const pcm = Buffer.from(b64, 'base64'), crudo = ['-f', 's16le', '-ar', String(SR), '-ac', '2', '-i', '-'];
    const r = spawnSync('ffmpeg', ['-hide_banner', ...crudo, '-af', 'volumedetect', '-f', 'null', '-'], { input: pcm });
    const max = parseFloat(/max_volume: (-?[\d.]+)/.exec(r.stderr.toString())[1]);
    execFileSync('ffmpeg', ['-loglevel', 'error', '-y', ...crudo,
      '-af', `volume=${pico(nombre) - max}dB,areverse,silenceremove=start_periods=1:start_threshold=-70dB,areverse`,
      '-c:a', 'libvorbis', '-q:a', '4', path.join(SALIDA, nombre + '.ogg')], { input: pcm });
    console.log(nombre);
  }
  await b.close();
})();
