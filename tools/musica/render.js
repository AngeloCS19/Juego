// Graba la música a assets/musica/*.ogg desde los bocetos de sonido.html (los mismos que Angelo
// escuchó). Usa el navegador sin ventana (Playwright) y un OfflineAudioContext, que calcula el
// audio más rápido que en tiempo real. Necesita node, Playwright con Chromium y ffmpeg.
//   node tools/musica/render.js          (todas)
//   node tools/musica/render.js huida    (solo las que empiezan así)
// Cada pista se graba dos veces: plano normal y plano espiritual, con el mismo largo.
// Todo lo que suena después del final del bucle (el eco, las notas largas, la anacrusa que
// entra al compás siguiente) se suma al inicio, así el archivo empalma consigo mismo sin un salto.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const COLA = 5, SR = 44100;
const SALIDA = path.join(__dirname, '../../assets/musica');
// nombre del archivo, segundos por paso, pasos que dura el bucle, ganancia (los bocetos suenan bajo:
// esto deja cada pieza completa cerca de -6 dB, sin saturar)
const PISTAS = [
  ['templo_marimba', .34, 192, 12], ['templo_bajo', .34, 192, 12], ['templo_ocarina', .34, 192, 12],
  ['huida', .15, 18 * 16, 6],  // las cuatro melodías de Angelo seguidas: 4 + 4 + 6 + 4 compases
  // el jefe: una capa por fase; el bombo cae en cada paso de Narciso (normal 1 s, difícil 0,6 s)
  ['jefe_normal_base', .125, 64, 2], ['jefe_normal_ocarina', .125, 64, 2], ['jefe_normal_fase3', .125, 64, 2],
  ['jefe_dificil_base', .15, 64, 2], ['jefe_dificil_ocarina', .15, 64, 2], ['jefe_dificil_fase3', .15, 64, 2],
  ['altar', .25, 64, 12],
];

let html = fs.readFileSync(path.join(__dirname, 'sonido.html'), 'utf8');
for (const [a, b] of [
  ['const now = () => AC.currentTime;', 'let T0 = 0; const now = () => T0;'],
  ['AC = new (window.AudioContext || window.webkitAudioContext)();', 'AC = window.__OFF;'],
  ['if (AC.state === "suspended") AC.resume();', ''],
]) { if (!html.includes(a)) throw new Error('sonido.html cambió: no encuentro ' + a); html = html.replace(a, b); }
const fin = html.lastIndexOf('})();');
html = html.slice(0, fin) + 'window.__R = { reset: () => { AC = null; rio = null; }, ac, marimba, bajo, ocarina, empezarRio, huida, melodia, jefe, altar, PENTA, MOTIVOS, setT: v => { T0 = v; }, setE: v => { espiritual = v; } };\n' + html.slice(fin);

(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  p.on('pageerror', e => { console.error(e.message); process.exit(1); });
  await p.setContent(html);
  const pedidas = process.argv.slice(2);  // p. ej. «node render.js huida»: solo esas pistas
  for (const [pista, PASO, PASOS, GANANCIA] of PISTAS.filter(([n]) => !pedidas.length || pedidas.some(x => n.startsWith(x)))) for (const esp of [false, true]) {
    const b64 = await p.evaluate(async ([pista, esp, PASO, PASOS, COLA, SR]) => {
      // la huida graba una vuelta más: las melodías empiezan 8 pasos antes del final y siguen
      // todo un bucle después; lo que pasa del final se dobla al inicio
      const EXTRA = pista === 'huida' ? PASOS : 0;
      window.__OFF = new OfflineAudioContext(2, Math.ceil(((PASOS + EXTRA) * PASO + COLA) * SR), SR);
      const R = window.__R; R.reset(); R.setE(esp); R.setT(0); R.ac();
      if (pista === 'templo_marimba') R.empezarRio(.012);
      if (pista === 'altar') R.empezarRio(.03);
      for (let s = 0; s < PASOS + EXTRA; s++) {
        R.setT(s * PASO);
        if (pista.startsWith('templo') && s < PASOS) {
          // igual que ocaMar() de sonido.html, con los tres motivos alternándose, una capa a la vez
          const [o, mel, bj] = R.MOTIVOS[(s >> 6) % 3], q = s % 64;
          if (pista === 'templo_marimba' && q % 2 === 0) R.marimba(R.PENTA[o[(q >> 1) % 8]] - 12, .12);
          if (pista === 'templo_bajo' && q % 16 === 0) R.bajo(bj[(q >> 4) % bj.length], 5, .1);
          const m = mel[(q >> 1) % 16];
          if (pista === 'templo_ocarina' && q % 2 === 0 && m >= 0) R.ocarina(R.PENTA[m] + 12, 1.2, .06);
        }
        if (pista.startsWith('jefe') && s < PASOS) R.jefe(s, 3, pista.includes('dificil') ? 4 : 8, PASO, ['base', 'ocarina', 'fase3'].indexOf(pista.split('_')[2]) + 1);
        if (pista === 'altar' && s < PASOS) R.altar(s);
        if (pista === 'huida') {
          if (s < PASOS) R.huida(s);
          // melodia() empieza la anacrusa en su paso 56; corrida para que caiga 8 pasos antes del final
          // y el primer compás de la primera melodía sea el inicio del archivo
          const k = s - (PASOS - 8 - 56);
          if (k >= 0) R.melodia(k, [0, 1, 2, 3]);
        }
      }
      const buf = await window.__OFF.startRendering();
      const n = Math.round(PASOS * PASO * SR), suma = [new Float32Array(n), new Float32Array(n)];
      for (let c = 0; c < 2; c++) { const d = buf.getChannelData(c); for (let i = 0; i < d.length; i++) suma[c][i % n] += d[i]; }
      const out = new Int16Array(n * 2);
      for (let i = 0; i < n; i++) for (let c = 0; c < 2; c++) out[i * 2 + c] = Math.max(-1, Math.min(1, suma[c][i])) * 32767;
      let bin = ''; const u8 = new Uint8Array(out.buffer);
      for (let i = 0; i < u8.length; i += 32768) bin += String.fromCharCode.apply(null, u8.subarray(i, i + 32768));
      return btoa(bin);
    }, [pista, esp, PASO, PASOS, COLA, SR]);
    const nombre = `${pista}_${esp ? 'espiritual' : 'normal'}.ogg`;
    execFileSync('ffmpeg', ['-loglevel', 'error', '-y', '-f', 's16le', '-ar', String(SR), '-ac', '2', '-i', '-',
      '-af', `volume=${GANANCIA}dB`, '-c:a', 'libvorbis', '-q:a', '4', path.join(SALIDA, nombre)], { input: Buffer.from(b64, 'base64') });
    console.log(nombre);
  }
  await b.close();
})();
