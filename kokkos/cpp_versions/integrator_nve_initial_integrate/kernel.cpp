#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_initial_integrate::operator()(const initial_integrate_tag &,
                                              int i) const {
  int index = type(i);
  double dtfm = ((double)((dtf)) / (mass(index)));
  v(i, 0) += ((dtfm) * (f(i, 0)));
  v(i, 1) += ((dtfm) * (f(i, 1)));
  v(i, 2) += ((dtfm) * (f(i, 2)));
  x(i, 0) += ((dtv) * (v(i, 0)));
  x(i, 1) += ((dtv) * (v(i, 1)));
  x(i, 2) += ((dtv) * (v(i, 2)));
};