#include <Kokkos_Core.hpp>

#include "functor.hpp"

void pk_functor_init_system::operator()(const get_n_tag &, int iz, int &n) const {
  iz -= 1;
  for (int iy = this->iy_start; (iy < ((this->iy_end) + (1))); (iy += 1)) {
    for (int ix = this->ix_start; (ix < ((this->ix_end) + (1))); (ix += 1)) {
      for (int k = 0; (k < 4); (k += 1)) {
        double xtmp =
            ((this->lattice_constant) * (((((1.0) * (ix))) + (basis(k, 0)))));
        double ytmp =
            ((this->lattice_constant) * (((((1.0) * (iy))) + (basis(k, 1)))));
        double ztmp =
            ((this->lattice_constant) * (((((1.0) * (iz))) + (basis(k, 2)))));
        if ((xtmp >= this->sub_domain_lo_x) &&
            (ytmp >= this->sub_domain_lo_y) &&
            (ztmp >= this->sub_domain_lo_z) && (xtmp < this->sub_domain_hi_x) &&
            (ytmp < this->sub_domain_hi_y) && (ztmp < this->sub_domain_hi_z)) {
          n += 1;
        }
      }
    }
  }
};

void pk_functor_init_system::operator()(const init_x_tag &,
                                                      int iz, int &n) const {
  iz -= 1;
  for (int iy = this->iy_start; (iy < ((this->iy_end) + (1))); (iy += 1)) {
    for (int ix = this->ix_start; (ix < ((this->ix_end) + (1))); (ix += 1)) {
      for (int k = 0; (k < 4); (k += 1)) {
        double xtmp =
            ((this->lattice_constant) * (((((1.0) * (ix))) + (basis(k, 0)))));
        double ytmp =
            ((this->lattice_constant) * (((((1.0) * (iy))) + (basis(k, 1)))));
        double ztmp =
            ((this->lattice_constant) * (((((1.0) * (iz))) + (basis(k, 2)))));
        if ((xtmp >= this->sub_domain_lo_x) &&
            (ytmp >= this->sub_domain_lo_y) &&
            (ztmp >= this->sub_domain_lo_z) && (xtmp < this->sub_domain_hi_x) &&
            (ytmp < this->sub_domain_hi_y) && (ztmp < this->sub_domain_hi_z)) {
          x(n, 0) = xtmp;
          x(n, 1) = ytmp;
          x(n, 2) = ztmp;
          type(n) = 0;
          id(n) = ((n) + (1));
          n += 1;
        }
      }
    }
  }
};