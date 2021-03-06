// Simulate planer cell polarity aligned by gradient
#include "../include/dtypes.cuh"
#include "../include/inits.cuh"
#include "../include/polarity.cuh"
#include "../include/solvers.cuh"
#include "../include/vtk.cuh"


const auto r_max = 1;
const auto r_min = 0.6;
const auto D = 0.5f;
const auto n_cells = 500;
const auto n_time_steps = 300;
const auto dt = 0.025;

MAKE_PT(Po_cell4, w, theta, phi);


__device__ Po_cell4 biased_pcp(
    Po_cell4 Xi, Po_cell4 r, float dist, int i, int j)
{
    Po_cell4 dF{0};
    if (i == j) return dF;

    if (dist > r_max) return dF;

    auto F = 2 * (r_min - dist) * (r_max - dist) + powf(r_max - dist, 2);
    dF.x = r.x * F / dist;
    dF.y = r.y * F / dist;
    dF.z = r.z * F / dist;
    dF.w = i == 0 ? 0 : -r.w * D;

    // U_PCP = - Σ(n_i . n_j)^2/2
    dF += pcp_force(Xi, Xi - r);
    if (r.w > 0) return dF;

    // U_WNT = - ΣXj.w*(n_i . r_ij/r)^2/2 to bias along w
    Polarity rhat{acosf(-r.z / dist), atan2(-r.y, -r.x)};
    dF += (Xi.w - r.w) * pcp_force(Xi, rhat);
    return dF;
}


int main(int argc, char const* argv[])
{
    // Prepare initial state
    Solution<Po_cell4, n_cells, Grid_solver> bolls;
    for (auto i = 0; i < n_cells; i++) {
        bolls.h_X[i].w = (i == 0) * 10;
        bolls.h_X[i].theta = acos(2. * rand() / (RAND_MAX + 1.) - 1.);
        bolls.h_X[i].phi = 2. * M_PI * rand() / (RAND_MAX + 1.);
    }
    random_sphere(0.5, bolls);

    // Integrate cell positions
    Vtk_output output("pcp");
    for (auto time_step = 0; time_step <= n_time_steps; time_step++) {
        bolls.copy_to_host();
        bolls.take_step<biased_pcp>(dt);
        output.write_positions(bolls);
        output.write_field(bolls);
        output.write_polarity(bolls);
    }

    return 0;
}
