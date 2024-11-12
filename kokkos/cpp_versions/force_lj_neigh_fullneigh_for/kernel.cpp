#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_fullneigh_for::operator()(const fullneigh_for_tag &,
                                        int i) const {
  double x_i = x(i, 0);
  double y_i = x(i, 1);
  double z_i = x(i, 2);
  int type_i = type(i);
  double fxi = 0.0;
  double fyi = 0.0;
  double fzi = 0.0;
  int num_neighs = num_neighs_view(i);
  for (int jj = 0; (jj < num_neighs); (jj += 1)) {
    int j = neighs_view(i, jj);
    double dx = ((x_i) - (x(j, 0)));
    double dy = ((y_i) - (x(j, 1)));
    double dz = ((z_i) - (x(j, 2)));
    int type_j = type(j);
    double rsq = ((((((dx) * (dx))) + (((dy) * (dy))))) + (((dz) * (dz))));
    double cutsq_ij = rnd_cutsq(type_i, type_j);
    if ((rsq < cutsq_ij)) {
      double lj1_ij = rnd_lj1(type_i, type_j);
      double lj2_ij = rnd_lj2(type_i, type_j);
      double r2inv = ((double)((1.0)) / (rsq));
      double r6inv = ((((r2inv) * (r2inv))) * (r2inv));
      double fpair =
          ((((r6inv) * (((((lj1_ij) * (r6inv))) - (lj2_ij))))) * (r2inv));
      fxi += ((dx) * (fpair));
      fyi += ((dy) * (fpair));
      fzi += ((dz) * (fpair));
    }
  }
  f(i, 0) += fxi;
  f(i, 1) += fyi;
  f(i, 2) += fzi;
};