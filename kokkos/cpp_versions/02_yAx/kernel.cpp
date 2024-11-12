#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_yAx::operator()(const pk_functor_yAx::yAx_tag &, int j,
                                double &acc) const {
  double temp2 = 0;
  for (int i = 0; (i < cols); (i += 1)) {
    temp2 += ((A_view(j, i)) * (x_view(i)));
  }
  acc += ((y_view(j)) * (temp2));
};
