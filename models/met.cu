// Simulate a mesenchyme-to-epithelium transition
#include "../lib/dtypes.cuh"
#include "../lib/solvers.cuh"
#include "../lib/inits.cuh"
#include "../lib/vtk.cuh"
#include "../lib/polarity.cuh"


const auto r_max = 1;
const auto r_min = 0.6;
const auto n_cells = 250;
const auto n_time_steps = 100;
const auto dt = 0.1;


// Cubic potential plus k*(n_i . r_ij/r)^2/2 for all r_ij <= r_max
__device__ Po_cell rigid_cubic_force(Po_cell Xi, Po_cell Xj, int i, int j) {
    Po_cell dF {0};
    if (i == j) return dF;

    auto r = Xi - Xj;
    auto dist = norm3df(r.x, r.y, r.z);
    if (dist > r_max) return dF;

    auto F = 2*(r_min - dist)*(r_max - dist) + powf(r_max - dist, 2);
    dF.x = r.x*F/dist;
    dF.y = r.y*F/dist;
    dF.z = r.z*F/dist;

    dF += rigidity_force(Xi, Xj)*0.2;
    return dF;
}


int main(int argc, char const *argv[]) {
    // Prepare initial state
    Solution<Po_cell, n_cells, Lattice_solver> bolls;
    uniform_sphere(0.733333, bolls);
    for (auto i = 0; i < n_cells; i++) {
        auto dist = sqrtf(bolls.h_X[i].x*bolls.h_X[i].x + bolls.h_X[i].y*bolls.h_X[i].y
            + bolls.h_X[i].z*bolls.h_X[i].z);
        bolls.h_X[i].phi = atan2(bolls.h_X[i].y, bolls.h_X[i].x) + rand()/(RAND_MAX + 1.)*0.5;
        bolls.h_X[i].theta = acosf(bolls.h_X[i].z/dist) + rand()/(RAND_MAX + 1.)*0.5;
    }
    bolls.copy_to_device();

    // Integrate cell positions
    Vtk_output output("epithelium");
    for (auto time_step = 0; time_step <= n_time_steps; time_step++) {
        bolls.copy_to_host();
        bolls.take_step<rigid_cubic_force>(dt);
        output.write_positions(bolls);
        output.write_polarity(bolls);
    }

    return 0;
}
