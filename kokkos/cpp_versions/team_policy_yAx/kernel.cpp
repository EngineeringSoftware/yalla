#include <Kokkos_Core.hpp>

#include "functor.hpp"

void inner_reduce_functor::operator()(const int &i, double &inner_acc) const {
  inner_acc += ((A_view(j, i)) * (x_view(i)));
}

void pk_functor_yAx::operator()(
    const yAx_tag &,
    const Kokkos::TeamPolicy<Kokkos::OpenMP>::member_type &team_member,
    double &acc) const {
  int j = team_member.league_rank();
  double temp2 = 0;
  inner_reduce_functor IRF(j, x_view, A_view);

  auto TTR = Kokkos::TeamThreadRange(team_member, cols);
  // Kokkos::parallel_reduce(Kokkos::TeamThreadRange(team_member, cols), IRF,
  //                         temp2);
  Kokkos::parallel_reduce(TTR, IRF,
                          temp2);
  if ((team_member.team_rank() == 0)) {
    acc += ((y_view(j)) * (temp2));
  }
};