# BFS que imita las reglas de sala.gd, para diseñar salas. Uso: python3 tools/solver.py salas/rio_05.json [letras_prohibidas]
# Con --velas dice cuántas velas lleva la sala (ver min_traspasos).
# Con letras prohibidas (por ejemplo "R", Reflejo) comprueba que la sala NO se resuelva sin esa acción: así se cierran atajos.
# Con "salida_fija", Q y E giran la cámara: la puerta S solo abre si queda arriba en la pantalla.
# Si la sala tiene prenda, la solución la recoge (la prenda es opcional en el juego, pero la "solucion" la muestra).
import json, sys, heapq
from collections import deque

D = {"W": (0, -1), "S": (0, 1), "A": (-1, 0), "D": (1, 0)}

def refl(eje, v, x, y):
    return {"horizontal": (x, 2*v-y), "vertical": (2*v-x, y),
            "diagonal": (y-v, x+v), "antidiagonal": (v-y, v-x)}[eje]

def grafo(s, prohibidas=""):
    m = s["mapa"]; W, H = len(m[0]), len(m)
    pe = s["plano_espiritual"]; pe = pe if isinstance(pe, list) else [pe]
    ejes = [(t["eje"], t["valor"]) for t in pe]
    hab = s.get("habilidades", ["traspasar", "reflejo"])
    cel = lambda x, y: "#" if x < 0 or y < 0 or x >= W or y >= H else m[y][x]
    def en(st, x, y):
        for i, p in enumerate(st):
            if (p[0], p[1]) == (x, y): return i
        return -1
    fija = s.get("salida_fija", False)
    sx, sy = next((r.index("S"), y) for y, r in enumerate(m) if "S" in r)
    afuera = (0, -1) if sy == 0 else (0, 1) if sy == H-1 else (-1, 0) if sx == 0 else (1, 0)
    def abierta(g):  # gira "afuera" g cuartos de vuelta en sentido horario (en pantalla, y hacia abajo)
        v = afuera
        for _ in range(g): v = (-v[1], v[0])
        return not fija or v == (0, -1)
    def trans(st, esp, x, y, g):
        t = cel(x, y)
        if t == "#" or (t == "S" and not abierta(g)): return False
        if esp:
            if t == "^": return False
            return any(p[4] and refl(e, v, p[0], p[1]) == (x, y) for p in st for e, v in ejes) or t in ".=S~"
        i = en(st, x, y)
        if i >= 0: return st[i][3]
        return t in ".=S"
    st0 = tuple((p["pos"][0], p["pos"][1], p.get("fija", False), False, False) for p in s.get("piedras", []))
    pr = tuple(s["prenda"]["pos"]) if "prenda" in s else None
    ini = (tuple(s["jugador"]), (0, -1), st0, False, pr is None, 0)
    acc = [a for a in "WSADPTR" + ("QE" if fija else "") if a not in prohibidas]
    def vecinos(e):  # cada acción posible desde el estado e: (acción, estado nuevo, ¿llega a la salida?)
        (px, py), mir, st, esp, tom, g = e
        for a in acc:
            n = None; gana = False
            if a in D:
                d = D[a]; nx, ny = px+d[0], py+d[1]
                if trans(st, esp, nx, ny, g):
                    t2 = tom or (esp and (nx, ny) == pr)
                    n = ((nx, ny), d, st, esp, t2, g); gana = cel(nx, ny) == "S" and t2
                else:
                    n = ((px, py), d, st, esp, tom, g)
            elif a == "P":
                if esp: continue
                tx, ty = px+mir[0], py+mir[1]; i = en(st, tx, ty)
                if i < 0 or st[i][2] or st[i][3]: continue
                dx, dy = tx+mir[0], ty+mir[1]
                if en(st, dx, dy) >= 0 or cel(dx, dy) not in ".~^": continue
                l = list(st); p = l[i]; l[i] = (dx, dy, p[2], cel(dx, dy) in "~^", p[4])
                n = ((tx, ty), mir, tuple(l), esp, tom, g); gana = cel(tx, ty) == "S" and tom
            elif a == "T":
                if "traspasar" not in hab: continue
                if esp and not trans(st, False, px, py, g): continue  # caer o no poder volver
                n = ((px, py), mir, st, not esp, tom, g)
            elif a == "R":
                if "reflejo" not in hab or esp: continue
                i = en(st, px+mir[0], py+mir[1])
                if i < 0: continue
                l = list(st); p = l[i]; l[i] = p[:4] + (not p[4],)
                n = ((px, py), mir, tuple(l), esp, tom, g)
            elif a in "QE":
                n = ((px, py), mir, st, esp, tom, (g + (1 if a == "E" else -1)) % 4)
            yield a, n, gana
    return ini, vecinos

def resolver(s, prohibidas=""):
    ini, vecinos = grafo(s, prohibidas)
    prev = {ini: None}; q = deque([ini])
    while q:
        e = q.popleft()
        for a, n, gana in vecinos(e):
            if n in prev: continue
            prev[n] = (e, a)
            if gana:
                r = []; k = n
                while prev[k]: k, a2 = prev[k]; r.append(a2)
                return "".join(reversed(r))
            q.append(n)
    return None

# Las velas de una sala: el menor número de veces que hay que entrar al plano espiritual, más 2 de margen.
def min_traspasos(s):
    ini, vecinos = grafo(s)
    dist = {ini: 0}; q = deque([ini])  # BFS 0-1: entrar al plano espiritual cuesta 1, lo demás 0
    while q:
        e = q.popleft()
        for a, n, gana in vecinos(e):
            c = dist[e] + (a == "T" and not e[3])
            if gana: return c  # el primero que llega por el frente de la cola tiene el menor costo
            if c < dist.get(n, 1 << 30):
                dist[n] = c; q.append(n) if c > dist[e] else q.appendleft(n)
    return None

# La "solucion" que se guarda: la más corta entre las que entran al plano espiritual lo mínimo,
# para que jugarla deje las 2 velas de margen. Devuelve (solución, entradas al plano espiritual).
def ruta_con_velas(s):
    ini, vecinos = grafo(s)
    costo = {ini: (0, 0)}; prev = {ini: None}; cola = [(0, 0, 0, ini)]; orden = 1
    while cola:
        t, p, _, e = heapq.heappop(cola)
        if (t, p) > costo[e]: continue
        if e == "fin":
            r = []; k = e
            while prev[k]: k, a = prev[k]; r.append(a)
            return "".join(reversed(r)), t
        for a, n, gana in vecinos(e):
            n = "fin" if gana else n
            c = (t + (a == "T" and not e[3]), p + 1)
            if c < costo.get(n, (1 << 30, 0)):
                costo[n] = c; prev[n] = (e, a); heapq.heappush(cola, (*c, orden, n)); orden += 1
    return None, None

if __name__ == "__main__":
    s = json.load(open(sys.argv[1]))
    if sys.argv[2:] == ["--velas"]:
        print(min_traspasos(s) + 2)
    else:
        print(resolver(s, sys.argv[2] if len(sys.argv) > 2 else ""))
