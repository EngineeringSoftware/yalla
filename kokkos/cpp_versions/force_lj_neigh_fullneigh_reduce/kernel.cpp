#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_fullneigh_reduce::operator()(const fullneigh_reduce_tag &, int i,
                                           double &PE) const {
  double x_i = x(i, 0);
  double y_i = x(i, 1);
  double z_i = x(i, 2);
  int type_i = type(i);
  bool shift_flag = true;
  int num_neighs = num_neighs_view(i);
  for (int jj = 0; (jj < num_neighs); (jj += 1)) {
    int j = neighs_view(i, jj);
    double dx = ((x_i) - (x(j, 0)));
    double dy = ((y_i) - (x(j, 1)));
    double dz = ((z_i) - (x(j, 2)));
    int type_j = type(j);
    double rsq = ((((((dx) * (dx))) + (((dy) * (dy))))) + (((dz) * (dz))));
    double cutsq_ij = 0.0;
    if (use_stackparams) {
      {
      }
    } else {
      cutsq_ij = rnd_cutsq(type_i, type_j);
    }
    if ((rsq < cutsq_ij)) {
      double lj1_ij = 0.0;
      if (use_stackparams) {
        {
        }
      } else {
        lj1_ij = rnd_lj1(type_i, type_j);
      }
      double lj2_ij = 0.0;
      if (use_stackparams) {
        {
        }
      } else {
        lj2_ij = rnd_lj2(type_i, type_j);
      }
      double r2inv = ((double)((1.0)) / (rsq));
      double r6inv = ((((r2inv) * (r2inv))) * (r2inv));
      PE += ((double)((((((0.5) * (r6inv))) *
                        (((((((0.5) * (lj1_ij))) * (r6inv))) - (lj2_ij)))))) /
             (6.0));
      if (shift_flag) {
        double r2invc = ((double)((1.0)) / (cutsq_ij));
        double r6invc = ((((r2invc) * (r2invc))) * (r2invc));
        PE -=
            ((double)((((((0.5) * (r6invc))) *
                        (((((((0.5) * (lj1_ij))) * (r6invc))) - (lj2_ij)))))) /
             (6.0));
      }
    }
  }
};