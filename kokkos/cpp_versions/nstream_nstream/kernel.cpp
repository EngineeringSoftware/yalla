#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_nstream::operator()(const nstream_tag &, int i) const {
  A_view(i) += ((B_view(i)) + (((scalar) * (C_view(i)))));
};