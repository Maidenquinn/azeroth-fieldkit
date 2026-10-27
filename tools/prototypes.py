class Chunk:
    def __init__(self, b):
        self.b, self.pos, self.maximum, self.count = b, 12, 0, 0
        self.order = 'little' if b[6] else 'big'
        self.isize, self.ssize, self.ins, self.numsize = b[7:11]
        self.proto()
    def n(self, size):
        val = int.from_bytes(self.b[self.pos:self.pos+size], self.order)
        self.pos += size
        return val
    def integer(self): return self.n(self.isize)
    def string(self):
        size = self.n(self.ssize)
        self.pos += size
    def proto(self):
        self.count += 1
        self.string(); self.integer(); self.integer()
        self.maximum = max(self.maximum, self.n(1)); self.pos += 3
        count = self.integer(); self.pos += count * self.ins
        for _ in range(self.integer()):
            t = self.n(1)
            if t == 1: self.pos += 1
            elif t == 3: self.pos += self.numsize
            elif t == 4: self.string()
            else: assert t == 0
        for _ in range(self.integer()): self.proto()
        count = self.integer(); self.pos += count * self.isize
        for _ in range(self.integer()): self.string(); self.integer(); self.integer()
        for _ in range(self.integer()): self.string()
