// ******* AUTOMATICALLY GENERATED BY PyKokkos *******
#ifndef PK_FUNCTOR_COMPUTE_WORKUNIT_HPP
#define PK_FUNCTOR_COMPUTE_WORKUNIT_HPP

struct pk_functor_compute_workunit {
  struct compute_workunit_tag {};
  Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      v;
  Kokkos::View<double *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      mass;
  Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      type;
  pk_functor_compute_workunit(
      Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          v,
      Kokkos::View<double *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          mass,
      Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          type) : v(v), mass(mass), type(type) {
  };
  void operator()(const compute_workunit_tag &, int i, double &acc) const;
};

#endif