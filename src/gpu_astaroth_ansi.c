/*                             gpu_astaroth_ansi.c
                              --------------------
*/

/* Date:   8-Feb-2017
   Author: M. Rheinhardt
   Description:
 ANSI C and standard library callable function wrappers for ASTAROTH-nucleus functions to be called from Fortran.
*/
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dlfcn.h>

#include "headers_c.h"

void intitializeGPU(int nx, int ny, int nz, int nghost, float *x, float *y, float *z, float nu, float cs2);
int finalizeGPU();
void substepGPU(float *uu_x, float *uu_y, float *uu_z, float *lnrho, int isubstep, int full);

/* for Intel Compiler
extern REAL cdata_mp_dx_;
extern REAL cdata_mp_dy_;
extern REAL cdata_mp_dz_;
extern REAL cdata_mp_omega_;
extern REAL cdata_mp_theta_;
extern REAL viscosity_mp_nu_;
extern REAL equationofstate_mp_cs20_;
*/
// for Gnu Compiler
extern REAL __cdata_MOD_dx;
extern REAL __cdata_MOD_dy;
extern REAL __cdata_MOD_dz;
extern REAL __cdata_MOD_omega;
extern REAL __cdata_MOD_theta;
//extern REAL __viscosity_MOD_nu;
static REAL __viscosity_MOD_nu=1.;
extern REAL __equationofstate_MOD_cs20;
extern FINT __cdata_MOD_iproc;
extern char *__cparam_MOD_coornames;

FINT mx, my, mz, nx, ny, nz, nghost, iproc;

// ----------------------------------------------------------------------
void FTNIZE(initialize_gpu_c)
     (FINT *nx_, FINT *ny_, FINT *nz_, FINT *nghost_, REAL *x, REAL *y, REAL *z )
/* Initializes GPU.
*/
{
  /*
  printf("omega = %e\n", __cdata_MOD_omega);
  printf("nu = %e\n", __viscosity_MOD_nu);

  printf("omega = %e\n", cdata_mp_omega_);
  printf("nu = %e\n", viscosity_mp_nu_);
  printf("nx = %d\n", *nx_);
  printf("ny = %d\n", *ny_);
  printf("nz = %d\n", *nz_);
  */
  nx=*nx_;
  ny=*ny_;
  nz=*nz_;
  nghost=*nghost_;
  mx=nx+2*nghost;
  my=ny+2*nghost;
  mz=nz+2*nghost;
  iproc=__cdata_MOD_iproc;
  //printf("coornames(1)= %s", __cparam_MOD_coornames[0]);
  REAL nu=__viscosity_MOD_nu;
  //REAL nu=viscosity_mp_nu_;
  REAL cs2=__equationofstate_MOD_cs20;
  //REAL cs2=equationofstate_mp_cs20_;
  intitializeGPU(mx, my, mz, nghost, x, y, z, nu, cs2);

/*
  printf("xmin = %e\n", x[4]);
  printf("xmax = %e\n", x[nx-1+3]);
  printf("ymin = %e\n", y[4]);
  printf("ymax = %e\n", y[ny-1+3]);
  printf("zmin = %e\n", z[4]);
  printf("zmax = %e\n", z[nz-1+3]);
*/
}
/* ---------------------------------------------------------------------- */
void FTNIZE(finalize_gpu_c)()
{

// Frees memory allocated on GPU.

  finalizeGPU();
}
/* ---------------------------------------------------------------------- */
void FTNIZE(rhs_gpu_c)
     (REAL *uu_x, REAL *uu_y, REAL *uu_z, REAL *lnrho, FINT *isubstep, FINT *full)

/* Communication between CPU and GPU: copy (outer) halos from CPU to GPU, 
   copy "inner halos" from GPU to CPU; calculation of rhss of momentum eq.
   and of continuity eq. by GPU kernels. Perform the Runge-Kutta substep 
   with number isubstep.
   Value at position ix=1,...,nx, iy=1,...,ny, iz=1,...,nz in the grid
   is found at the position ix-1+nghost + mx*(iy+nghost-1) + mx*my*(iz+nghost-1) in uu or lnrho.
   Here mx=nx+2*nghost etc.

   At beginning of substep: copy (outer) halos from host memory to device memory, that is (Fortran indexing)

   uu_x(1   :nghost,:,:), 
   uu_x(nx+1:mx,    :,:),

   uu_x(nghost+1:nghost+nx,1   :nghost,:), 
   uu_x(nghost+1:nghost+nx,ny+1:my,    :),

   uu_x(nghost+1:nghost+nx,nghost+1:nghost+ny,1   :nghost),
   uu_x(nghost+1:nghost+nx,nghost+1:nghost+ny,nz+1:mz    ).

   At end of substep: copy "inner halos" from device memory to host memory, that is

   uu_x(nghost+1:2*nghost ,nghost+1:nghost+ny,nghost+1:nghost+nz), 
   uu_x(nx+1    :nx+nghost,nghost+1:nghost+ny,nghost+1:nghost+nz),

   uu_x(2*nghost+1:nx,nghost+1:2*nghost ,nghost+1:nghost+nz), 
   uu_x(2*nghost+1:nx,ny+1    :ny+nghost,nghost+1:nghost+nz), 

   uu_x(2*nghost+1:nx,2*nghost+1:ny,nghost+1:2*nghost), 
   uu_x(2*nghost+1:nx,2*nghost+1:ny,nz+1    :nz+nghost) 

   If full=1, however, copy the full arrays.
*/
{
  // copies data back and forth and peforms integration substep isubstep

  substepGPU(uu_x, uu_y, uu_z, lnrho, *isubstep, *full);
}
/* ---------------------------------------------------------------------- */
