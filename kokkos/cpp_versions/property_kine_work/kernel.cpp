#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_work::operator()(const work_tag &, int i, double &KE) const {
  int index = type(i);
  KE += ((((((((v(i, 0)) * (v(i, 0)))) + (((v(i, 1)) * (v(i, 1)))))) +
           (((v(i, 2)) * (v(i, 2)))))) *
         (mass(index)));
};