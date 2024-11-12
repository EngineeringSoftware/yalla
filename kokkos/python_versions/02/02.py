import pykokkos as pk

@pk.workunit
def yAx(j, acc, cols, y_view, x_view, A_view):
    temp2: float = 0
    for i in range(cols):
        temp2 += A_view[j][i] * x_view[i]

    acc += y_view[j] * temp2

def run():
    N: int = 128
    M: int = 128

    pk.set_default_space(pk.OpenMP)

    y: pk.View1D = pk.View([N], pk.double)
    x: pk.View1D = pk.View([M], pk.double)
    A: pk.View2D = pk.View([N, M], pk.double)

    y.fill(1)
    x.fill(1)
    A.fill(1)

    p = pk.RangePolicy(0, N)
    pk.parallel_reduce(p, yAx, cols=M, y_view=y, x_view=x, A_view=A)

if __name__ == "__main__":
    run()
