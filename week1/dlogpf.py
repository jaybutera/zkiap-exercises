import hashlib
import random
import json

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

'''
x = 3
g = 3
p = 21
y,t,r = dlogproof(x,g,p)
verified = verify(y,g,p,(t,r))
print((y,t,r))
print(verified)
'''

# Adjacency list of (node, color, neighbors) pairs
#type Graph = list[tuple[int, int, list[int]]]

# Graph to json object
def g2json(g) -> dict[int, tuple[list[int]]]:
    return {i: (color, nodes) for i, color, nodes in g}

def recolor(g):
    # Assume just 3 colors
    one = random.randint(0,2)
    two = random.randint(0,2)
    while two == one:
        two = random.randint(0,2)
    three = 3 - one - two

    # for each pair in each list, replace color
    return [(i, one if color == 0 else two if color == 1 else three, nodes) for i, color, nodes in g]

def colorproof(g):
    proof = []
    for i in range(10):
        g = recolor(g)
        # Hash the graph and mod number of nodes to choose a node
        challenge = hashlib.sha256(json.dumps(g2json(g)).encode('utf-8'))
        c_i = int.from_bytes(challenge.digest()) % len(g)
        # Choose neighbor of that node with same process padded 0
        neighbor = hashlib.sha256((json.dumps(g2json(g)) + '0').encode('utf-8'))
        c_j = int.from_bytes(neighbor.digest()) % len(g[c_i][2])

        reveal = ((g[c_i][0], g[c_i][1]), (g[c_i][2][c_j], g[c_i][2][c_j]))
        proof.append((challenge, neighbor, reveal))

    return proof

# all colors are different to resolve 3 coloring problem
g = [(0, 0, [1,2]), (1, 1, [0,2]), (2, 2, [0,1])]

proof = colorproof(g)
for challenge, neighbor, reveal in proof:
    print(challenge, neighbor)
    (i, i_color), (j, j_color) = reveal
    print(f'node {i} [color {i_color}] has neighbor {j} [color {j_color}]')
    print()
