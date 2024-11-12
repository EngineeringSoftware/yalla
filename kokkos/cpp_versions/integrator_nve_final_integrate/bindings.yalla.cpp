// ******* AUTOMATICALLY GENERATED BY PyKokkos *******
#include <Kokkos_Core.hpp>
#include <functor.yalla.hpp>
#include <pybind11/pybind11.h>

void run_final_integrate(
    double dtf,
    Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        v,
    Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        f,
    Kokkos::View<int32_t *, Kokkos::LayoutRight, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        type,
    Kokkos::View<double *, Kokkos::LayoutRight, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        mass,
    pk_exec_space pk_exec_space_instance, const std::string &pk_kernel_name,
    int pk_threads_begin, int pk_threads_end, int pk_randpool_seed,
    int pk_randpool_num_states) {
  auto pk_d_v = Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, v);
  auto pk_d_f = Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, f);
  auto pk_d_type =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, type);
  auto pk_d_mass =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, mass);
  pk_functor_final_integrate pk_f(dtf, &pk_d_v, &pk_d_f, &pk_d_type,
                                                 &pk_d_mass);
  Kokkos::parallel_for(
      pk_kernel_name,
      Kokkos::RangePolicy<
          pk_exec_space,
          pk_functor_final_integrate::final_integrate_tag>(
          pk_exec_space_instance, pk_threads_begin, pk_threads_end),
      pk_f);
  Kokkos::resize(v, pk_d_v.extent(0), pk_d_v.extent(1));
  Kokkos::deep_copy(v, pk_d_v);
  Kokkos::resize(f, pk_d_f.extent(0), pk_d_f.extent(1));
  Kokkos::deep_copy(f, pk_d_f);
  Kokkos::resize(type, pk_d_type.extent(0));
  Kokkos::deep_copy(type, pk_d_type);
  Kokkos::resize(mass, pk_d_mass.extent(0));
  Kokkos::deep_copy(mass, pk_d_mass);
}
void wrapper_final_integrate(pybind11::kwargs kwargs) {
  run_final_integrate(
      kwargs["dtf"].cast<double>(),
      kwargs["v"]
          .cast<Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["f"]
          .cast<Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["type"]
          .cast<Kokkos::View<int32_t *, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["mass"]
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
  k.def("wrapper_final_integrate", &wrapper_final_integrate);
}