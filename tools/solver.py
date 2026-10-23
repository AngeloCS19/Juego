# BFS que imita las reglas de sala.gd, para diseñar salas. Uso: python3 tools/solver.py salas/rio_05.json [letras_prohibidas]
# Con letras prohibidas (por ejemplo "F") comprueba que la sala NO se resuelva sin esa acción: así se cierran atajos.
# Si la sala tiene prenda, la solución la recoge (la prenda es opcional en el juego, pero la "solucion" la muestra).
import json, sys
from collections import deque

D = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}

def refl(eje, v, x, y):
    return {"horizontal": (x, 2*v-y), "vertical": (2*v-x, y),
            "diagonal": (y-v, x+v), "antidiagonal": (v-y, v-x)}[eje]

def resolver(s, prohibidas=""):
    m = s["mapa"]; W, H = len(m[0]), len(m)
    pe = s["plano_espiritual"]; pe = pe if isinstance(pe, list) else [pe]
    ejes = [(t["eje"], t["valor"]) for t in pe]
    hab = s.get("habilidades", ["traspasar", "reflejo"])
    cel = lambda x, y: "#" if x < 0 or y < 0 or x >= W or y >= H else m[y][x]
    def en(st, x, y):
        for i, p in enumerate(st):
            if (p[0], p[1]) == (x, y): return i
        return -1
    def trans(st, esp, x, y):
        t = cel(x, y)
        if t == "#": return False
        if esp:
            if t == "^": return False
            return any(p[4] and refl(e, v, p[0], p[1]) == (x, y) for p in st for e, v in ejes) or t in ".=E~"
        i = en(st, x, y)
        if i >= 0: return st[i][3]
        return t in ".=E"
    st0 = tuple((p["pos"][0], p["pos"][1], p.get("fija", False), False, False) for p in s.get("piedras", []))
    pr = tuple(s["prenda"]["pos"]) if "prenda" in s else None
    ini = (tuple(s["jugador"]), (0, -1), st0, False, pr is None)
    prev = {ini: None}; q = deque([ini])
    acc = [a for a in "UDLREPF" if a not in prohibidas]
    while q:
        e = q.popleft(); (px, py), mir, st, esp, tom = e
        for a in acc:
            n = None; gana = False
            if a in D:
                d = D[a]; nx, ny = px+d[0], py+d[1]
                if trans(st, esp, nx, ny):
                    t2 = tom or (esp and (nx, ny) == pr)
                    n = ((nx, ny), d, st, esp, t2); gana = cel(nx, ny) == "E" and t2
                else:
                    n = ((px, py), d, st, esp, tom)
            elif a == "E":
                if esp: continue
                tx, ty = px+mir[0], py+mir[1]; i = en(st, tx, ty)
                if i < 0 or st[i][2] or st[i][3]: continue
                dx, dy = tx+mir[0], ty+mir[1]
                if en(st, dx, dy) >= 0 or cel(dx, dy) not in ".~^": continue
                l = list(st); p = l[i]; l[i] = (dx, dy, p[2], cel(dx, dy) in "~^", p[4])
                n = ((tx, ty), mir, tuple(l), esp, tom); gana = cel(tx, ty) == "E" and tom
            elif a == "P":
                if "traspasar" not in hab: continue
                if esp and not trans(st, False, px, py): continue  # caer o no poder volver
                n = ((px, py), mir, st, not esp, tom)
            elif a == "F":
                if "reflejo" not in hab or esp: continue
                i = en(st, px+mir[0], py+mir[1])
                if i < 0: continue
                l = list(st); p = l[i]; l[i] = p[:4] + (not p[4],)
                n = ((px, py), mir, tuple(l), esp, tom)
            if n in prev: continue
            prev[n] = (e, a)
            if gana:
                r = []; k = n
                while prev[k]: k, a2 = prev[k]; r.append(a2)
                return "".join(reversed(r))
            q.append(n)
    return None

if __name__ == "__main__":
    s = json.load(open(sys.argv[1]))
    print(resolver(s, sys.argv[2] if len(sys.argv) > 2 else ""))
