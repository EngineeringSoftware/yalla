// ******* AUTOMATICALLY GENERATED BY PyKokkos *******
#include <Kokkos_Core.hpp>
#include <functor.hpp>
#include <pybind11/pybind11.h>

void run_nstream(int32_t scalar,
                 Kokkos::View<double *, Kokkos::LayoutRight, pk_arg_memspace,
                              Kokkos::Experimental::DefaultViewHooks>
                     A_view,
                 Kokkos::View<double *, Kokkos::LayoutRight, pk_arg_memspace,
                              Kokkos::Experimental::DefaultViewHooks>
                     B_view,
                 Kokkos::View<double *, Kokkos::LayoutRight, pk_arg_memspace,
                              Kokkos::Experimental::DefaultViewHooks>
                     C_view,
                 pk_exec_space pk_exec_space_instance,
                 const std::string &pk_kernel_name, int pk_threads_begin,
                 int pk_threads_end, int pk_randpool_seed,
                 int pk_randpool_num_states) {
  auto pk_d_A_view =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, A_view);
  auto pk_d_B_view =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, B_view);
  auto pk_d_C_view =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, C_view);
  pk_functor_nstream pk_f(scalar, pk_d_A_view, pk_d_B_view,
                                         pk_d_C_view);
  Kokkos::parallel_for(
      pk_kernel_name,
      Kokkos::RangePolicy<pk_exec_space,
                          pk_functor_nstream::nstream_tag>(
          pk_exec_space_instance, pk_threads_begin, pk_threads_end),
      pk_f);
  Kokkos::resize(A_view, pk_d_A_view.extent(0));
  Kokkos::deep_copy(A_view, pk_d_A_view);
  Kokkos::resize(B_view, pk_d_B_view.extent(0));
  Kokkos::deep_copy(B_view, pk_d_B_view);
  Kokkos::resize(C_view, pk_d_C_view.extent(0));
  Kokkos::deep_copy(C_view, pk_d_C_view);
}
void wrapper_nstream(pybind11::kwargs kwargs) {
  run_nstream(
      kwargs["scalar"].cast<int32_t>(),
      kwargs["A_view"]
          .cast<Kokkos::View<double *, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["B_view"]
          .cast<Kokkos::View<double *, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["C_view"]
          .cast<Kokkos::View<double *, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["pk_exec_space_instance"].cast<pk_exec_space>(),
      kwargs["pk_kernel_name"].cast<std::string>(),
      kwargs["pk_threads_begin"].cast<int>(),
      kwargs["pk_threads_end"].cast<int>(),
      kwargs["pk_randpool_seed"].cast<int>(),
      kwargs["pk_randpool_num_states"].cast<int>());
  ;
}
PYBIND11_MODULE(
    PLACEHOLDER, k) {
  k.def("wrapper_nstream", &wrapper_nstream);
}