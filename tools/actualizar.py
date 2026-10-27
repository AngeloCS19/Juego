# Pone al día "solucion", "pasos" y "velas" de las salas de puzzle, sin tocar lo demás del archivo.
# Uso: python tools/actualizar.py                    (todas las salas)
#      python tools/actualizar.py salas/rio_05.json  (solo esa)
# Correrlo después de crear o cambiar una sala. El jefe, la huida y el altar no se tocan (su solución sale de gen_jefe.gd).
import glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solver import resolver, ruta_con_velas

def poner(texto, campo, valor):  # cambia el campo si está; si no, lo agrega antes de "solucion" (o al final)
    linea = '\t"%s": %s' % (campo, valor)
    if re.search(r'^\t"%s": ' % campo, texto, re.M):
        return re.sub(r'^\t"%s": .*?(,?)$' % campo, lambda m: linea + m.group(1), texto, count=1, flags=re.M)
    if '\n\t"solucion": ' in texto:
        return texto.replace('\n\t"solucion": ', "\n" + linea + ',\n\t"solucion": ', 1)
    return re.sub(r'\n}\s*$', ',\n' + linea + '\n}\n', texto)

def quitar(texto, campo):
    return re.sub(r'^\t"%s": .*\n' % campo, "", texto, flags=re.M)

errores = 0
for ruta in sys.argv[1:] or sorted(glob.glob(os.path.join(os.path.dirname(__file__), "..", "salas", "*.json"))):
    nombre = os.path.basename(ruta)
    texto = open(ruta, encoding="utf-8").read()
    sala = json.loads(texto)
    if "tipo" in sala:
        continue
    sol, entradas = ruta_con_velas(sala)
    if sol is None:
        print("%s: SIN SOLUCIÓN, no se cambió" % nombre); errores += 1; continue
    nuevo = poner(texto, "pasos", len(resolver(sala)))
    nuevo = poner(nuevo, "velas", entradas + 2) if entradas else quitar(nuevo, "velas")  # sin traspasos no hay velas
    nuevo = poner(nuevo, "solucion", '"%s"' % sol)
    json.loads(nuevo)  # que siga siendo un JSON válido
    if nuevo != texto:
        open(ruta, "w", encoding="utf-8").write(nuevo)
        print("%s: actualizada" % nombre)
    else:
        print("%s: ya estaba al día" % nombre)
sys.exit(1 if errores else 0)
