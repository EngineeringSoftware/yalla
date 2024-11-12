import pykokkos as pk

@pk.workunit
def yAx(team_member, acc, cols, y_view, x_view, A_view):
    j: int = team_member.league_rank()

    def inner_reduce(i: int, inner_acc: pk.Acc[float]):
        inner_acc += A_view[j][i] * x_view[i]

    temp2: float = pk.parallel_reduce(
        pk.TeamThreadRange(team_member, cols), inner_reduce)

    if team_member.team_rank() == 0:
        acc += y_view[j] * temp2

def run():
    N: int = 128
    M: int = 128

    y: pk.View1D = pk.View([N], pk.double, layout=pk.Layout.LayoutRight)
    x: pk.View1D = pk.View([M], pk.double, layout=pk.Layout.LayoutRight)
    A: pk.View2D = pk.View([N, M], pk.double, layout=pk.Layout.LayoutRight)

    y.fill(1)
    x.fill(1)
    A.fill(1)

    p = pk.TeamPolicy(N, pk.AUTO)
    pk.parallel_reduce(p, yAx, cols=M, y_view=y, x_view=x, A_view=A)

if __name__ == "__main__":
    run()
