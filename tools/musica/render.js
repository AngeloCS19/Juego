// Graba la música del templo a assets/musica/*.ogg desde los bocetos de sonido.html (los mismos que
// Angelo escuchó). Usa el navegador sin ventana (Playwright) y un OfflineAudioContext, que calcula
// el audio más rápido que en tiempo real. Necesita node, Playwright con Chromium y ffmpeg.
//   node tools/musica/render.js
// Por cada capa (marimba, bajo, ocarina) graba dos versiones: plano normal y plano espiritual.
// Lo que suena después del final del bucle (el eco, las notas largas) se suma al inicio,
// así el archivo empalma consigo mismo sin un salto.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const PASO = .34, PASOS = 192, LARGO = PASO * PASOS, COLA = 5, SR = 44100;
const GANANCIA = '12dB';  // los bocetos suenan bajo; esto deja la mezcla completa cerca de -6 dB
const SALIDA = path.join(__dirname, '../../assets/musica');

let html = fs.readFileSync(path.join(__dirname, 'sonido.html'), 'utf8');
for (const [a, b] of [
  ['const now = () => AC.currentTime;', 'let T0 = 0; const now = () => T0;'],
  ['AC = new (window.AudioContext || window.webkitAudioContext)();', 'AC = window.__OFF;'],
  ['if (AC.state === "suspended") AC.resume();', ''],
]) { if (!html.includes(a)) throw new Error('sonido.html cambió: no encuentro ' + a); html = html.replace(a, b); }
const fin = html.lastIndexOf('})();');
html = html.slice(0, fin) + 'window.__R = { reset: () => { AC = null; rio = null; }, ac, marimba, bajo, ocarina, empezarRio, PENTA, MOTIVOS, setT: v => { T0 = v; }, setE: v => { espiritual = v; } };\n' + html.slice(fin);

(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  p.on('pageerror', e => { console.error(e.message); process.exit(1); });
  await p.setContent(html);
  for (const capa of ['marimba', 'bajo', 'ocarina']) for (const esp of [false, true]) {
    const b64 = await p.evaluate(async ([capa, esp, PASO, PASOS, LARGO, COLA, SR]) => {
      window.__OFF = new OfflineAudioContext(2, Math.ceil((LARGO + COLA) * SR), SR);
      const R = window.__R; R.reset(); R.setE(esp); R.setT(0); R.ac();
      if (capa === 'marimba') R.empezarRio(.012);
      // igual que ocaMar() de sonido.html, con los tres motivos alternándose (opción D), pero una capa a la vez
      for (let s = 0; s < PASOS; s++) {
        R.setT(s * PASO);
        const [o, mel, bj] = R.MOTIVOS[(s >> 6) % 3], q = s % 64;
        if (capa === 'marimba' && q % 2 === 0) R.marimba(R.PENTA[o[(q >> 1) % 8]] - 12, .12);
        if (capa === 'bajo' && q % 16 === 0) R.bajo(bj[(q >> 4) % bj.length], 5, .1);
        const m = mel[(q >> 1) % 16];
        if (capa === 'ocarina' && q % 2 === 0 && m >= 0) R.ocarina(R.PENTA[m] + 12, 1.2, .06);
      }
      const buf = await window.__OFF.startRendering();
      const n = Math.round(LARGO * SR), out = new Int16Array(n * 2);
      for (let c = 0; c < 2; c++) {
        const d = buf.getChannelData(c);
        for (let i = 0; i < n; i++) out[i * 2 + c] = Math.max(-1, Math.min(1, d[i] + (i + n < d.length ? d[i + n] : 0))) * 32767;
      }
      let bin = ''; const u8 = new Uint8Array(out.buffer);
      for (let i = 0; i < u8.length; i += 32768) bin += String.fromCharCode.apply(null, u8.subarray(i, i + 32768));
      return btoa(bin);
    }, [capa, esp, PASO, PASOS, LARGO, COLA, SR]);
    const nombre = `templo_${capa}_${esp ? 'espiritual' : 'normal'}.ogg`;
    execFileSync('ffmpeg', ['-loglevel', 'error', '-y', '-f', 's16le', '-ar', String(SR), '-ac', '2', '-i', '-',
      '-af', 'volume=' + GANANCIA, '-c:a', 'libvorbis', '-q:a', '4', path.join(SALIDA, nombre)], { input: Buffer.from(b64, 'base64') });
    console.log(nombre);
  }
  await b.close();
})();
