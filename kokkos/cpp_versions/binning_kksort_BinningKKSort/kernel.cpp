#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_BinningKKSort::operator()(const assign_offsets_tag &,
                                          int i) const {
  int ix = (int)(((i) / (((this->nbiny) * (this->nbinz)))));
  int iy = (((int)(((i) / (this->nbinz)))) % (this->nbiny));
  int iz = ((i) % (this->nbinz));
  binoffsets(ix, iy, iz) = bin_offsets_1d(i);
  bincount(ix, iy, iz) = bin_count_1d(i);
};