#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_compute_workunit::operator()(const compute_workunit_tag &, int i,
                                           double &acc) const {
  int mass_index = type(i);
  acc += ((((((((v(i, 0)) * (v(i, 0)))) + (((v(i, 1)) * (v(i, 1)))))) +
            (((v(i, 2)) * (v(i, 2)))))) *
          (mass(mass_index)));
};