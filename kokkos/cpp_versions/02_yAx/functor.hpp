// ******* AUTOMATICALLY GENERATED BY PyKokkos *******
#ifndef PK_FUNCTOR_YAX_HPP
#define PK_FUNCTOR_YAX_HPP

struct pk_functor_yAx {
  struct yAx_tag {};
  int cols;
  Kokkos::View<double *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      y_view;
  Kokkos::View<double *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      x_view;
  Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      A_view;

  pk_functor_yAx(int cols,
                 Kokkos::View<double *, Kokkos::LayoutRight,
                              Kokkos::HostSpace,
                              Kokkos::Experimental::EmptyViewHooks>
                     y_view,
                 Kokkos::View<double *, Kokkos::LayoutRight,
                              Kokkos::HostSpace,
                              Kokkos::Experimental::EmptyViewHooks>
                     x_view,
                 Kokkos::View<double **, Kokkos::LayoutRight,
                              Kokkos::HostSpace,
                              Kokkos::Experimental::EmptyViewHooks>
                     A_view) : cols(cols), y_view(y_view), x_view(x_view), A_view(A_view) {}

  void operator()(const yAx_tag &, int j,
                                  double &acc) const;
};

#endif