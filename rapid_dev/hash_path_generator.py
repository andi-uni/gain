import hashlib
import random
import binascii

def make_little_big(little): # 256
    big_1 = (bytearray(reversed(little[:16])))
    big_2 = (bytearray(reversed(little[16:])))
    return big_1, big_2 

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
    return direction, parent.digest(), rand

# generate random leaf
leaf = generate_random_hash()

direction_selector = list()
path_digest = list()

next_child = leaf
for i in range(0,2): #+1 for root node
    direction, next_child, pd = generate_random_junction(next_child)
    direction_selector.append(direction)
    path_digest.append(pd)


print("leaf:", ([int.from_bytes(x,'little') for x in make_little_big(leaf)]))
for i in range(0,len(direction_selector)):
    if direction_selector[i]==True:
        d = "Left"
    else:
        d="Right"
    print('Digest',i,':',d,[int.from_bytes(x,'little') for x in make_little_big(path_digest[i])])

print("Root:", [int.from_bytes(x,'little') for x in make_little_big(next_child)])
