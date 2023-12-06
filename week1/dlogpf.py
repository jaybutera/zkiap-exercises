import hashlib
import random

def dlogproof(x: int, g: int, p: int) -> (int, int, int):
    y = (g**x) % p
    #v = random.randint(p//2, p) # Probably not secure to choose low numbers
    v = p // 2 # deterministic random
    t = (g**v) % p
    c = int.from_bytes(hashlib.sha256(bytes(g) + bytes(y) + bytes(t)).digest())
    r = (v + x*c) % p
    return (y, t, r)

def verify(y: int, g: int, p: int, pf: (int, int)) -> bool:
    t, r = pf
    c = int.from_bytes(hashlib.sha256(bytes(g) + bytes(y) + bytes(t)).digest()) % p
    return (t * y**c) % p == (g**r % p)

x = 3
g = 3
p = 21
y,t,r = dlogproof(x,g,p)
verified = verify(y,g,p,(t,r))
print((y,t,r))
print(verified)
