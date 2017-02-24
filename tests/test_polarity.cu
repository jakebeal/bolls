#include "../lib/dtypes.cuh"
#include "../lib/solvers.cuh"
#include "../lib/polarity.cuh"
#include "minunit.cuh"


__device__ Po_cell rigid_cubic_force(Po_cell Xi, Po_cell Xj, int i, int j) {
    Po_cell dF {0};
    if (i == j) return dF;

    auto r = Xi - Xj;
    auto dist = norm3df(r.x, r.y, r.z);
    if (dist > 1) return dF;

    auto F = 2*(0.6 - dist)*(1 - dist) + powf(1 - dist, 2);
    dF.x = r.x*F/dist;
    dF.y = r.y*F/dist;
    dF.z = r.z*F/dist;

    dF += rigidity_force(Xi, Xj)*0.2;
    return dF;
}


Solution<Po_cell, 4, N2n_solver> bolls;

const char* test_line_of_four() {
    for (auto i = 0; i < 4; i++) {
        bolls.h_X[i].x = 0.733333*cosf((i - 0.5)*M_PI/3);
        bolls.h_X[i].y = 0.733333*sinf((i - 0.5)*M_PI/3);
        bolls.h_X[i].z = 0;
        bolls.h_X[i].phi = (i - 0.5)*M_PI/3;
        bolls.h_X[i].theta = M_PI/2;
    }
    bolls.copy_to_device();
    auto com_i = center_of_mass(bolls);
    for (auto i = 0; i < 500; i++) {
        bolls.take_step<rigid_cubic_force>(0.5);
    }

    bolls.copy_to_host();
    for (auto i = 1; i < 4; i++) {
        auto prod = sinf(bolls.h_X[0].theta)*sinf(bolls.h_X[i].theta)*cosf(bolls.h_X[0].phi - bolls.h_X[i].phi)
            + cosf(bolls.h_X[0].theta)*cosf(bolls.h_X[i].theta);
        MU_ASSERT("Polarity not aligned", MU_ISCLOSE(prod, 1));
    }

    float3 r_01 {bolls.h_X[1].x - bolls.h_X[0].x,
        bolls.h_X[1].y - bolls.h_X[0].y, bolls.h_X[1].z - bolls.h_X[0].z};
    float3 r_12 {bolls.h_X[2].x - bolls.h_X[1].x,
        bolls.h_X[2].y - bolls.h_X[1].y, bolls.h_X[2].z - bolls.h_X[1].z};
    float3 r_23 {bolls.h_X[3].x - bolls.h_X[2].x,
        bolls.h_X[3].y - bolls.h_X[2].y, bolls.h_X[3].z - bolls.h_X[2].z};
    MU_ASSERT("Cells not on line", MU_ISCLOSE(r_01.x, r_12.x));
    MU_ASSERT("Cells not on line", MU_ISCLOSE(r_12.x, r_23.x));
    MU_ASSERT("Cells not on line", MU_ISCLOSE(r_01.y, r_12.y));
    MU_ASSERT("Cells not on line", MU_ISCLOSE(r_12.y, r_23.y));
    MU_ASSERT("Cells not on line", MU_ISCLOSE(r_01.z, r_12.z));
    MU_ASSERT("Cells not on line", MU_ISCLOSE(r_12.z, r_23.z));

    auto com_f = center_of_mass(bolls);
    MU_ASSERT("Momentum in line", MU_ISCLOSE(com_i.x, com_f.x));
    MU_ASSERT("Momentum in line", MU_ISCLOSE(com_i.y, com_f.y));
    MU_ASSERT("Momentum in line", MU_ISCLOSE(com_i.z, com_f.z));

    return NULL;
}


const char* all_tests() {
    MU_RUN_TEST(test_line_of_four);
    return NULL;
}

MU_RUN_SUITE(all_tests);
