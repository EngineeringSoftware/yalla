// ******* AUTOMATICALLY GENERATED BY PyKokkos *******
#include <Kokkos_Core.hpp>
#include <functor.hpp>
#include <pybind11/pybind11.h>

int32_t run_get_n(
    int32_t ix_start, int32_t ix_end, int32_t iy_start, int32_t iy_end,
    int32_t iz_start, int32_t iz_end, double lattice_constant,
    double sub_domain_hi_x, double sub_domain_hi_y, double sub_domain_hi_z,
    double sub_domain_lo_x, double sub_domain_lo_y, double sub_domain_lo_z,
    Kokkos::View<double **, pk_exec_space::array_layout, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        basis,
    Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        x,
    Kokkos::View<int32_t *, pk_exec_space::array_layout, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        type,
    Kokkos::View<int32_t *, pk_exec_space::array_layout, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        id,
    pk_exec_space pk_exec_space_instance, const std::string &pk_kernel_name,
    int pk_threads_begin, int pk_threads_end, int pk_randpool_seed,
    int pk_randpool_num_states) {
  int32_t pk_acc = 0;
  auto pk_d_basis =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, basis);
  auto pk_d_x = Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, x);
  auto pk_d_type =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, type);
  auto pk_d_id =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, id);
  pk_functor_init_system pk_f(
      ix_start, ix_end, iy_start, iy_end, iz_start, iz_end, lattice_constant,
      sub_domain_hi_x, sub_domain_hi_y, sub_domain_hi_z, sub_domain_lo_x,
      sub_domain_lo_y, sub_domain_lo_z, pk_d_basis, pk_d_x, pk_d_type, pk_d_id);
  Kokkos::parallel_reduce(
      pk_kernel_name,
      Kokkos::RangePolicy<pk_exec_space,
                          pk_functor_init_system::get_n_tag>(
          pk_exec_space_instance, pk_threads_begin, pk_threads_end),
      pk_f, pk_acc);
  Kokkos::resize(basis, pk_d_basis.extent(0), pk_d_basis.extent(1));
  Kokkos::deep_copy(basis, pk_d_basis);
  Kokkos::resize(x, pk_d_x.extent(0), pk_d_x.extent(1));
  Kokkos::deep_copy(x, pk_d_x);
  Kokkos::resize(type, pk_d_type.extent(0));
  Kokkos::deep_copy(type, pk_d_type);
  Kokkos::resize(id, pk_d_id.extent(0));
  Kokkos::deep_copy(id, pk_d_id);
  return pk_acc;
}
int32_t wrapper_get_n(pybind11::kwargs kwargs) {
  return run_get_n(
      kwargs["ix_start"].cast<int32_t>(), kwargs["ix_end"].cast<int32_t>(),
      kwargs["iy_start"].cast<int32_t>(), kwargs["iy_end"].cast<int32_t>(),
      kwargs["iz_start"].cast<int32_t>(), kwargs["iz_end"].cast<int32_t>(),
      kwargs["lattice_constant"].cast<double>(),
      kwargs["sub_domain_hi_x"].cast<double>(),
      kwargs["sub_domain_hi_y"].cast<double>(),
      kwargs["sub_domain_hi_z"].cast<double>(),
      kwargs["sub_domain_lo_x"].cast<double>(),
      kwargs["sub_domain_lo_y"].cast<double>(),
      kwargs["sub_domain_lo_z"].cast<double>(),
      kwargs["basis"]
          .cast<Kokkos::View<double **, pk_exec_space::array_layout,
                             pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["x"]
          .cast<Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["type"]
          .cast<Kokkos::View<int32_t *, pk_exec_space::array_layout,
                             pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["id"]
          .cast<Kokkos::View<int32_t *, pk_exec_space::array_layout,
                             pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["pk_exec_space_instance"].cast<pk_exec_space>(),
      kwargs["pk_kernel_name"].cast<std::string>(),
      kwargs["pk_threads_begin"].cast<int>(),
      kwargs["pk_threads_end"].cast<int>(),
      kwargs["pk_randpool_seed"].cast<int>(),
      kwargs["pk_randpool_num_states"].cast<int>());
  ;
}
int32_t run_init_x(
    int32_t ix_start, int32_t ix_end, int32_t iy_start, int32_t iy_end,
    int32_t iz_start, int32_t iz_end, double lattice_constant,
    double sub_domain_hi_x, double sub_domain_hi_y, double sub_domain_hi_z,
    double sub_domain_lo_x, double sub_domain_lo_y, double sub_domain_lo_z,
    Kokkos::View<double **, pk_exec_space::array_layout, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        basis,
    Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        x,
    Kokkos::View<int32_t *, pk_exec_space::array_layout, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        type,
    Kokkos::View<int32_t *, pk_exec_space::array_layout, pk_arg_memspace,
                 Kokkos::Experimental::DefaultViewHooks>
        id,
    pk_exec_space pk_exec_space_instance, const std::string &pk_kernel_name,
    int pk_threads_begin, int pk_threads_end, int pk_randpool_seed,
    int pk_randpool_num_states) {
  int32_t pk_acc = 0;
  auto pk_d_basis =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, basis);
  auto pk_d_x = Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, x);
  auto pk_d_type =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, type);
  auto pk_d_id =
      Kokkos::create_mirror_view_and_copy(pk_exec_space_instance, id);
  pk_functor_init_system pk_f(
      ix_start, ix_end, iy_start, iy_end, iz_start, iz_end, lattice_constant,
      sub_domain_hi_x, sub_domain_hi_y, sub_domain_hi_z, sub_domain_lo_x,
      sub_domain_lo_y, sub_domain_lo_z, pk_d_basis, pk_d_x, pk_d_type, pk_d_id);
  Kokkos::parallel_reduce(
      pk_kernel_name,
      Kokkos::RangePolicy<pk_exec_space,
                          pk_functor_init_system::init_x_tag>(
          pk_exec_space_instance, pk_threads_begin, pk_threads_end),
      pk_f, pk_acc);
  Kokkos::resize(basis, pk_d_basis.extent(0), pk_d_basis.extent(1));
  Kokkos::deep_copy(basis, pk_d_basis);
  Kokkos::resize(x, pk_d_x.extent(0), pk_d_x.extent(1));
  Kokkos::deep_copy(x, pk_d_x);
  Kokkos::resize(type, pk_d_type.extent(0));
  Kokkos::deep_copy(type, pk_d_type);
  Kokkos::resize(id, pk_d_id.extent(0));
  Kokkos::deep_copy(id, pk_d_id);
  return pk_acc;
}
int32_t wrapper_init_x(pybind11::kwargs kwargs) {
  return run_init_x(
      kwargs["ix_start"].cast<int32_t>(), kwargs["ix_end"].cast<int32_t>(),
      kwargs["iy_start"].cast<int32_t>(), kwargs["iy_end"].cast<int32_t>(),
      kwargs["iz_start"].cast<int32_t>(), kwargs["iz_end"].cast<int32_t>(),
      kwargs["lattice_constant"].cast<double>(),
      kwargs["sub_domain_hi_x"].cast<double>(),
      kwargs["sub_domain_hi_y"].cast<double>(),
      kwargs["sub_domain_hi_z"].cast<double>(),
      kwargs["sub_domain_lo_x"].cast<double>(),
      kwargs["sub_domain_lo_y"].cast<double>(),
      kwargs["sub_domain_lo_z"].cast<double>(),
      kwargs["basis"]
          .cast<Kokkos::View<double **, pk_exec_space::array_layout,
                             pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["x"]
          .cast<Kokkos::View<double **, Kokkos::LayoutRight, pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["type"]
          .cast<Kokkos::View<int32_t *, pk_exec_space::array_layout,
                             pk_arg_memspace,
                             Kokkos::Experimental::DefaultViewHooks>>(),
      kwargs["id"]
          .cast<Kokkos::View<int32_t *, pk_exec_space::array_layout,
                             pk_arg_memspace,
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
  k.def("wrapper_get_n", &wrapper_get_n);
  k.def("wrapper_init_x", &wrapper_init_x);
}