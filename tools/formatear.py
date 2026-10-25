# Escribe una sala en el estilo del repo y le pone la solución de solver.py. Uso: python3 tools/formatear.py boceto.json salas/rio_nn.json
import json, sys, subprocess, os
s = json.load(open(sys.argv[1]))
sol = subprocess.check_output(["python3", os.path.join(os.path.dirname(__file__), "solver.py"), sys.argv[1]], text=True).strip()
assert sol != "None", "sin solución"
def plano(t): return '{ "tipo": "%s", "eje": "%s", "valor": %d }' % (t["tipo"], t["eje"], t["valor"])
pe = s["plano_espiritual"]
pe = plano(pe) if isinstance(pe, dict) else "[\n\t\t" + ",\n\t\t".join(plano(t) for t in pe) + "\n\t]"
def piedra(p): return '\t\t{ "pos": [%d, %d]%s }' % (p["pos"][0], p["pos"][1], ', "fija": true' if p.get("fija") else "")
partes = ['\t"nombre": "%s"' % s["nombre"],
          '\t"mapa": [\n' + ",\n".join('\t\t"%s"' % r for r in s["mapa"]) + "\n\t]",
          '\t"jugador": [%d, %d]' % tuple(s["jugador"]),
          '\t"plano_espiritual": ' + pe]
if "estilo" in s: partes.append('\t"estilo": "%s"' % s["estilo"])
if s.get("salida_fija"): partes.append('\t"salida_fija": true')
if "habilidades" in s: partes.append('\t"habilidades": ' + json.dumps(s["habilidades"]))
if s.get("piedras"): partes.append('\t"piedras": [\n' + ",\n".join(piedra(p) for p in s["piedras"]) + "\n\t]")
if "prenda" in s: partes.append('\t"prenda": { "nombre": "%s", "pos": [%d, %d] }' % (s["prenda"]["nombre"], *s["prenda"]["pos"]))
velas = int(subprocess.check_output(["python3", os.path.join(os.path.dirname(__file__), "solver.py"), sys.argv[1], "--velas"], text=True))
if velas > 2: partes.append('\t"velas": %d' % velas)  # sin traspasos no hay velas
partes.append('\t"solucion": "%s"' % sol)
open(sys.argv[2], "w").write("{\n" + ",\n".join(partes) + "\n}\n")
