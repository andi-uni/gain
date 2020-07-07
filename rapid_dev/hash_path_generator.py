import hashlib
import random
import binascii

def print_big_endian_split(little):
    l.l = split(little)
    l.r = split(little)
    rerturn little1, little2

def generate_random_hash():
    return bytearray((random.getrandbits(8) for i in range(0,32)))

def get_parent_node(a,b):
    h = hashlib.sha256()
    h.update(a)
    h.update(b)
    return h

def generate_random_junction(child):
    rand = generate_random_hash()
    parent = hashlib.sha256()
    direction = bool(random.getrandbits(1))
    if direction==True:        
        parent = get_parent_node(rand,child)
    else:
        parent = get_parent_node(child,rand)
    return direction, parent.digest()

# generate random leaf
leaf = generate_random_hash()

direction_selector = list()
path_digest = list()

next_child = leaf
for i in range(0,2+1): #+1 for root node
    direction, next_child = generate_random_junction(next_child)
    direction_selector.append(direction)
    path_digest.append(next_child)

print("leaf:", binascii.hexlify(leaf))
for i in range(0,len(direction_selector)-1):
    if direction_selector[i]==True:
        d = "Left:"
    else:
        d="Right:"
    print(i,d,binascii.hexlify(path_digest[i]))

print("Root:", binascii.hexlify(path_digest[-1]))
