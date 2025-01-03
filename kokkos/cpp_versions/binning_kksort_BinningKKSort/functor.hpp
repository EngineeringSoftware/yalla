// ******* AUTOMATICALLY GENERATED BY PyKokkos *******
#ifndef PK_FUNCTOR_BINNINGKKSORT_HPP
#define PK_FUNCTOR_BINNINGKKSORT_HPP

struct pk_functor_BinningKKSort {
  struct assign_offsets_tag {};
  int nbinx;
  int nbiny;
  int nbinz;
  int nhalo;
  double minx;
  double maxx;
  double miny;
  double maxy;
  double minz;
  double maxz;
  int range_min;
  int range_max;
  bool sort;
  Kokkos::View<int ***, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      bincount;
  Kokkos::View<int ***, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      binoffsets;
  Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      x;
  Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      v;
  Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      f;
  Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      type;
  Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      id;
  Kokkos::View<double *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      q;
  Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      permute_vector;
  Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      bin_count_1d;
  Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
               Kokkos::Experimental::EmptyViewHooks>
      bin_offsets_1d;

  pk_functor_BinningKKSort(
      int nbinx, int nbiny, int nbinz, int nhalo, double minx, double maxx,
      double miny, double maxy, double minz, double maxz, int range_min,
      int range_max, bool sort,
      Kokkos::View<int ***, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          bincount,
      Kokkos::View<int ***, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          binoffsets,
      Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          x,
      Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          v,
      Kokkos::View<double **, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          f,
      Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          type,
      Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          id,
      Kokkos::View<double *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          q,
      Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          permute_vector,
      Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          bin_count_1d,
      Kokkos::View<int *, Kokkos::LayoutRight, Kokkos::HostSpace,
                   Kokkos::Experimental::EmptyViewHooks>
          bin_offsets_1d)
      : nbinx(nbinx), nbiny(nbiny), nbinz(nbinz), nhalo(nhalo), minx(minx),
        maxx(maxx), miny(miny), maxy(maxy), minz(minz), maxz(maxz),
        range_min(range_min), range_max(range_max), sort(sort),
        bincount(bincount), binoffsets(binoffsets), x(x), v(v), f(f),
        type(type), id(id), q(q), permute_vector(permute_vector),
        bin_count_1d(bin_count_1d), bin_offsets_1d(bin_offsets_1d){};

  void operator()(const assign_offsets_tag &, int i) const;
};

#endif