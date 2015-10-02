! $Id: particles_charged dhruba.mitra@gmail.com$
!
!  This module takes care of everything related to inertial particles.
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
!
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! MPVAR CONTRIBUTION 6
! MAUX CONTRIBUTION 4
! CPARAM logical, parameter :: lparticles=.true.
! CPARAM logical, parameter :: lparticles_potential=.true.
!
! PENCILS PROVIDED np; rhop
! PENCILS PROVIDED epsp; grhop(3)
!
!***************************************************************
module Particles
!
  use Cdata
  use Cparam
  use General, only: keep_compiler_quiet
  use Messages
  use Particles_cdata
  use Particles_map
  use Particles_mpicomm
  use Particles_sub
  use Particles_radius
!
  implicit none
!
  include 'particles.h'
  include 'particles_common.h'
!
  complex, dimension (7) :: coeff=(0.0,0.0)
  real :: tausp=1.,tausp1=1.
  real, target, dimension (npar_species) :: tausp_species=0.0
  real, target, dimension (npar_species) :: tausp1_species=0.0
  real, dimension (3) :: temp_grad0=(/0.0,0.0,0.0/)
  real, dimension (3) :: pos_sphere=(/0.0,0.0,0.0/)
  real :: xp0=0.0, yp0=0.0, zp0=0.0, vpx0=0.0, vpy0=0.0, vpz0=0.0
  real :: xp1=0.0, yp1=0.0, zp1=0.0, vpx1=0.0, vpy1=0.0, vpz1=0.0
  real :: xp2=0.0, yp2=0.0, zp2=0.0, vpx2=0.0, vpy2=0.0, vpz2=0.0
  real :: xp3=0.0, yp3=0.0, zp3=0.0, vpx3=0.0, vpy3=0.0, vpz3=0.0
  real :: kx_vpx=0.0, kx_vpy=0.0, kx_vpz=0.0
  real :: ky_vpx=0.0, ky_vpy=0.0, ky_vpz=0.0
  real :: kz_vpx=0.0, kz_vpy=0.0, kz_vpz=0.0
  real :: phase_vpx=0.0, phase_vpy=0.0, phase_vpz=0.0
  real :: Lx0=0.0, Ly0=0.0, Lz0=0.0
  real :: delta_vp0=0.
  real :: rad_sphere=0.0
  real :: qbym=0.0
  real :: cdtp=0.2
  real :: particles_insert_rate=0.
  real :: avg_n_insert, remaining_particles=0.0
  real :: max_particle_insert_time=huge1
  real :: kx_xxp=0.0, ky_xxp=0.0, kz_xxp=0.0, amplxxp=0.0
  real :: kx_vvp=0.0, ky_vvp=0.0, kz_vvp=0.0, amplvvp=0.0
  integer :: l_hole=0, m_hole=0, n_hole=0
!
! DM: possibly shall not need this for the time being
!
  character (len=labellen) :: interp_pol_uu ='cic'
  character (len=labellen) :: interp_pol_oo ='cic'
  character (len=labellen) :: interp_pol_TT ='cic'
  character (len=labellen) :: interp_pol_rho='cic'
  character (len=labellen) :: interp_pol_gradTT='cic'
  character (len=labellen) :: interp_pol_bb='cic'
  character (len=labellen) :: interp_pol_ee='cic'
!
  character (len=labellen), dimension (ninit) :: initxxp='nothing'
  character (len=labellen), dimension (ninit) :: initvvp='nothing'
  character (len=labellen) :: gravx_profile='', gravz_profile=''
  character (len=labellen) :: gravr_profile=''
  character (len=labellen) :: thermophoretic_eq= 'nothing'
!
  integer :: init_repeat=0       !repeat particle initialization for distance statistics
!
  real, dimension(3) :: uup_shared=0
  real :: turnover_shared=0
  logical :: vel_call=.false., turnover_call=.false.
  logical :: lsinkpoint=.false., lglobalrandom=.false.
  logical :: lreassign_strat_rhom=.true.,lcentrifugal_force_par=.false.,lcoriolis_force_par=.false.
  logical :: lpar_spec=.false.
  logical :: lflowdrag=.true.
!
  character (len=labellen) :: ppotential='nothing'
  integer :: sigma_in_grid = 1
  real :: psigma_by_dx=0.1,ppowerby2=19,skin_factor=2.,pampl=1.
!
! Note: psigma below is psigma = psigma_by_dx * dx ; because we always like to think of the
! range of the potential in units of dx. While calculating neighbours we look around for 
! sigma_in_grid number of grid points. This should be >= 1 .  Also, if
! psigma is larger than dx then sigma_in_grid must be larger too. 
! Note : psigma should be much smaller than the dissipation range, maybe even less than a grid-spacing
! as we are not including many terms in the Maxey-Riley equations. As far as the interaction
! with the fluid is concerned our particles are point particles with inertia. But the
! interaction potential gives them an effective radius. The interaction potential is
! typically of the form
!   V(r) = function of (r/psigma) , \xi = r/psigma
! The default potential is repulsive
!  V(r) = pampl*(1/xi)^(beta)
! with beta = 2*ppowerby2
! This potential is quite steep (almost hard-sphere) hence the effective force on a particle
! due to other particles which are within a distance of skin_factor*psigma. Particles
! within this distance are included in the neighbourlist.
!
  integer :: idiag_particles_vijm
  integer :: ysteps_int,zsteps_int
  namelist /particles_init_pars/ &
      initxxp, initvvp, xp0, yp0, zp0, vpx0, vpy0, vpz0, delta_vp0, &
      bcpx, bcpy, bcpz,lcheck_exact_frontier, lflowdrag, &
      lnocalc_rhop,lparticlemesh_cic, ppotential, psigma_by_dx, ppowerby2, skin_factor, tausp,&
      sigma_in_grid,pampl,linsert_particles_continuously
!
  namelist /particles_run_pars/ &
      bcpx, bcpy, bcpz,cdtp,lcentrifugal_force_par,lcheck_exact_frontier, lcoriolis_force_par, &
      lpar_spec, tausp,sigma_in_grid,psigma_by_dx,ppowerby2,skin_factor,pampl,linsert_particles_continuously
!
  integer :: idiag_xpm=0, idiag_ypm=0, idiag_zpm=0
  integer :: idiag_xp2m=0, idiag_yp2m=0, idiag_zp2m=0
  integer :: idiag_rpm=0, idiag_rp2m=0
  integer :: idiag_vpxm=0, idiag_vpym=0, idiag_vpzm=0
  integer :: idiag_vpx2m=0, idiag_vpy2m=0, idiag_vpz2m=0, idiag_ekinp=0
  integer :: idiag_vpxmax=0, idiag_vpymax=0, idiag_vpzmax=0, idiag_vpmax=0
  integer :: idiag_vpxvpym=0, idiag_vpxvpzm=0, idiag_vpyvpzm=0
  integer :: idiag_rhopvpxm=0, idiag_rhopvpym=0, idiag_rhopvpzm=0
  integer :: idiag_rhopvpxt=0, idiag_rhopvpyt=0, idiag_rhopvpzt=0
  integer :: idiag_rhopvpysm=0
  integer :: idiag_lpxm=0, idiag_lpym=0, idiag_lpzm=0
  integer :: idiag_lpx2m=0, idiag_lpy2m=0, idiag_lpz2m=0
  integer :: idiag_npm=0, idiag_np2m=0, idiag_npmax=0, idiag_npmin=0
  integer :: idiag_dtdragp=0
  integer :: idiag_nparmin=0, idiag_nparmax=0, idiag_npargone=0
  integer :: idiag_rhopm=0, idiag_rhoprms=0, idiag_rhop2m=0, idiag_rhopmax=0
  integer :: idiag_rhopmin=0, idiag_decollp=0, idiag_rhopmphi=0
  integer :: idiag_epspmin=0, idiag_epspmax=0
  integer :: idiag_npmx=0, idiag_npmy=0, idiag_npmz=0
  integer :: idiag_rhopmx=0, idiag_rhopmy=0, idiag_rhopmz=0
  integer :: idiag_epspmx=0, idiag_epspmy=0, idiag_epspmz=0
  integer :: idiag_mpt=0, idiag_dedragp=0, idiag_rhopmxy=0, idiag_rhopmr=0
  integer :: idiag_dvpx2m=0, idiag_dvpy2m=0, idiag_dvpz2m=0
  integer :: idiag_dvpm=0, idiag_dvpmax=0, idiag_epotpm=0
  integer :: idiag_rhopmxz=0, idiag_nparpmax=0, idiag_npmxy=0
  integer :: idiag_eccpxm=0, idiag_eccpym=0, idiag_eccpzm=0
  integer :: idiag_eccpx2m=0, idiag_eccpy2m=0, idiag_eccpz2m=0
  integer :: idiag_vprms=0, idiag_vpyfull2m=0, idiag_deshearbcsm=0
!
  contains
!***********************************************************************
    subroutine register_particles()
!
!  Set up indices for access to the fp and dfp arrays
!
!  29-dec-04/anders: coded
!
      use FArrayManager, only: farray_register_auxiliary
!
      if (lroot) call svn_id( &
           "$Id: particles_potential.f90 dhruba.mitra@gmail.com $")
!
!  Indices for particle position.
!
      ixp=npvar+1
      pvarname(npvar+1)='ixp'
      iyp=npvar+2
      pvarname(npvar+2)='iyp'
      izp=npvar+3
      pvarname(npvar+3)='izp'
!
!  Indices for particle velocity.
!
      ivpx=npvar+4
      pvarname(npvar+4)='ivpx'
      ivpy=npvar+5
      pvarname(npvar+5)='ivpy'
      ivpz=npvar+6
      pvarname(npvar+6)='ivpz'
!
!  Increase npvar accordingly.
!
      npvar=npvar+6
!
!  Set indices for particle assignment.
!
      if (.not. lnocalc_np) call farray_register_auxiliary('np',inp,&
        communicated=lcommunicate_np)
      if (.not. lnocalc_rhop) call farray_register_auxiliary('rhop',irhop, &
        communicated=lparticles_sink.or.lcommunicate_rhop)
!
! Auxiliary array to invert the ineargrid map
!
      call farray_register_auxiliary('invgrid',iinvgrid,vector=2,&
        communicated=.false.)
!
!  Check that the fp and dfp arrays are big enough.
!
      if (npvar > mpvar) then
        if (lroot) write(0,*) 'npvar = ', npvar, ', mpvar = ', mpvar
        call fatal_error('register_particles','npvar > mpvar')
      endif
!
    endsubroutine register_particles
!***********************************************************************
    subroutine initialize_particles(f)
!
!  Perform any post-parameter-read initialization i.e. calculate derived
!  parameters.
!
!  29-dec-04/anders: coded
!
      use EquationOfState, only: rho0, cs0
      use SharedVariables, only: put_shared_variable
!
      real, dimension (mx,my,mz,mfarray) :: f
!
      real :: rhom
      integer :: ierr, jspec
!
!  The inverse stopping time is needed for drag force and collisional cooling.
!
      if (lflowdrag) then
        if (tausp .gt. tini) then
          tausp1=1./tausp
        else
          call fatal_error('initialize_particles','particles_potential: too small tausp')
        endif
      else
        tausp1=0.
      endif
!
!  Multiple dust species. Friction time is given in the array tausp_species.
!
!
!  Set up interpolation logicals. These logicals can be OR'ed with some logical
!  in the other particle modules' initialization subroutines to enable
!  interpolation based on some condition local to that module.
!  (The particles_spin module will for instance enable interpolation of the
!  vorticity oo)
!
      if (lflowdrag) then
        if (lhydro.or.lhydro_kinematic) then
          interp%luu=.true.
        else
          call fatal_error('initialize_particles','particles_potential: you need velocity')
        endif
      endif
      interp%loo=.false.
      interp%lTT=.false.
      interp%lgradTT=.false.
      interp%lrho=.false.
      interp%lbb=.false.
      interp%lee=.false.
!
! By default all interpolation policies are chosen as cic in this module.
!
!  Overwrite with new policy variables:
!
      if (interp%luu) then
        select case (interp_pol_uu)
        case ('tsc')
          interp%pol_uu=tsc
        case ('cic')
          interp%pol_uu=cic
        case ('ngp')
          interp%pol_uu=ngp
        case default
          call fatal_error('initialize_particles','No such such value for '// &
            'interp_pol_uu: '//trim(interp_pol_uu))
        endselect
      endif
!
      if (interp%loo) then
        select case (interp_pol_oo)
        case ('tsc')
          interp%pol_oo=tsc
        case ('cic')
          interp%pol_oo=cic
        case ('ngp')
          interp%pol_oo=ngp
        case default
          call fatal_error('initialize_particles','No such such value for '// &
            'interp_pol_oo: '//trim(interp_pol_oo))
        endselect
      endif
!
      if (interp%lTT) then
        select case (interp_pol_TT)
        case ('tsc')
          interp%pol_TT=tsc
        case ('cic')
          interp%pol_TT=cic
        case ('ngp')
          interp%pol_TT=ngp
        case default
          call fatal_error('initialize_particles','No such such value for '// &
            'interp_pol_TT: '//trim(interp_pol_TT))
        endselect
      endif
!
      if (interp%lbb) then
        select case (interp_pol_bb)
        case ('tsc')
          interp%pol_bb=tsc
        case ('cic')
          interp%pol_bb=cic
        case ('ngp')
          interp%pol_bb=ngp
        case default
          call fatal_error('initialize_particles','No such such value for '// &
            'interp_pol_bb: '//trim(interp_pol_bb))
        endselect
      endif
!
      if (interp%lee) then
        select case (interp_pol_ee)
        case ('tsc')
          interp%pol_ee=tsc
        case ('cic')
          interp%pol_ee=cic
        case ('ngp')
          interp%pol_ee=ngp
        case default
          call fatal_error('initialize_particles','No such such value for '// &
            'interp_pol_ee: '//trim(interp_pol_ee))
        endselect
      endif
!
!  Write constants to disk.
!
      if (lroot) then
        open (1,file=trim(datadir)//'/pc_constants.pro',position='append')
          write (1,*) 'np_swarm=', np_swarm
          write (1,*) 'mpmat=', mpmat
          write (1,*) 'mp_swarm=', mp_swarm
          write (1,*) 'rhop_swarm=', rhop_swarm
        close (1)
      endif
!
      call keep_compiler_quiet(f)
!
    endsubroutine initialize_particles
!***********************************************************************
    subroutine particles_potential_clean_up
!
!  cleanup after the particles_potential module
!

!
    endsubroutine particles_potential_clean_up
!***********************************************************************
    subroutine init_particles(f,fp,ineargrid)
!
!  Initial positions and velocities of dust particles.
!
!  29-dec-04/anders: coded
!
      use EquationOfState, only: beta_glnrho_global, cs20
      use General, only: random_number_wrapper
      use Mpicomm, only: mpireduce_sum, mpibcast_real
      use InitialCondition, only: initial_condition_xxp,&
                                  initial_condition_vvp
      use Particles_diagnos_dv, only: repeated_init
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mpar_loc,mparray) :: fp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      real, dimension (3) :: uup, Lxyz_par, xyz0_par, xyz1_par
      real :: vpx_sum, vpy_sum, vpz_sum
      real :: r, p, q, px, py, pz, eps, cs, k2_xxp, rp2
      real :: dim1, npar_loc_x, npar_loc_y, npar_loc_z, dx_par, dy_par, dz_par
      real :: rad,rad_scl,phi,tmp,OO,xx0,yy0,r2
      integer :: l, j, k, ix0, iy0, iz0
      logical :: lequidistant=.false.
!
      intent (out) :: f, fp, ineargrid
!
!  Use either a local random position or a global random position for certain
!  initial conditions. The default is a local random position, but the equal
!  number of particles per processors means that this is not completely random.
!
      if (lglobalrandom) then
        Lxyz_par=Lxyz
        xyz0_par=xyz0
        xyz1_par=xyz1
      else
        Lxyz_par=Lxyz_loc
        xyz0_par=xyz0_loc
        xyz1_par=xyz1_loc
      endif
!
!  Initial particle position.
!
      do j=1,ninit
!
        select case (initxxp(j))
!
        case ('nothing')
          if (lroot .and. j==1) print*, 'init_particles: nothing'
!
        case ('two')
          fp(1,ixp) = xyz0(1)+3*Lx/4.
          fp(1,iyp)=0.; fp(1,izp)=0. ;
          fp(2,ixp) = xyz0(1)+Lx/4.
          fp(2,iyp)=0.; fp(2,izp)=0.;
          fp(3,ixp) = xyz0(1)+Lx/5.
          fp(3,iyp)=0.; fp(3,izp)=0.;
          if (lroot .and. j==1) then 
            print*, 'init_particles: two'
            write(*,*) 'xyz0(1),Lxyz(1)',xyz0(1),Lxyz(1)
            write(*,*) 'x1,x2',fp(1,ixp),fp(2,ixp)
          endif
!
        case ('origin')
          if (lroot) print*, 'init_particles: All particles at origin'
          fp(1:npar_loc,ixp:izp)=0.0
!
        case ('zero-z')
          if (lroot) print*, 'init_particles: Zero z coordinate'
          fp(1:npar_loc,izp)=0.0
!
        case ('constant')
          if (lroot) &
              print*, 'init_particles: All particles at x,y,z=', xp0, yp0, zp0
          fp(1:npar_loc,ixp)=xp0
          fp(1:npar_loc,iyp)=yp0
          fp(1:npar_loc,izp)=zp0
!
        case ('constant-1')
          if (lroot) &
              print*, 'init_particles: Particle 1 at x,y,z=', xp1, yp1, zp1
          do k=1,npar_loc
            if (ipar(k)==1) then
              fp(k,ixp)=xp1
              fp(k,iyp)=yp1
              fp(k,izp)=zp1
            endif
          enddo
!
        case ('constant-2')
          if (lroot) &
              print*, 'init_particles: Particle 2 at x,y,z=', xp2, yp2, zp2
          do k=1,npar_loc
            if (ipar(k)==2) then
              fp(k,ixp)=xp2
              fp(k,iyp)=yp2
              fp(k,izp)=zp2
            endif
          enddo
!
        case ('constant-3')
          if (lroot) &
              print*, 'init_particles: Particle 2 at x,y,z=', xp3, yp3, zp3
          do k=1,npar_loc
            if (ipar(k)==3) then
              fp(k,ixp)=xp3
              fp(k,iyp)=yp3
              fp(k,izp)=zp3
            endif
          enddo
!
        case ('random')
          if (lroot) print*, 'init_particles: Random particle positions'
          do k=1,npar_loc
            if (nxgrid/=1) call random_number_wrapper(fp(k,ixp))
            if (nygrid/=1) call random_number_wrapper(fp(k,iyp))
            if (nzgrid/=1) call random_number_wrapper(fp(k,izp))
          enddo
          if (nxgrid/=1) &
              fp(1:npar_loc,ixp)=xyz0_par(1)+fp(1:npar_loc,ixp)*Lxyz_par(1)
          if (nygrid/=1) &
              fp(1:npar_loc,iyp)=xyz0_par(2)+fp(1:npar_loc,iyp)*Lxyz_par(2)
          if (nzgrid/=1) &
              fp(1:npar_loc,izp)=xyz0_par(3)+fp(1:npar_loc,izp)*Lxyz_par(3)
!          write(*,*) 'DM:x,y,z',fp(1,ixp),fp(1,izp),fp(1,iyp)
!          write(*,*) 'DM:x,y,z',fp(2,ixp),fp(2,izp),fp(2,iyp)
!
        case ('random-circle')
          if (lroot) print*, 'init_particles: Random particle positions'
          do k=1,npar_loc
            call random_number_wrapper(r)
            if (zp0>yp0) then
              fp(k,ixp)=xp0*cos((zp0-yp0)*r+yp0)
              fp(k,iyp)=xp0*sin((zp0-yp0)*r+yp0)
            else
              fp(k,ixp)=xp0*cos(2*pi*r)
              fp(k,iyp)=xp0*sin(2*pi*r)
            endif
          enddo
!
        case ('random-sphere')
          if (lroot) print*, 'init_particles: Random particle positions '// &
              'in a sphere around (0,0,0) with radius=',rad_sphere
          if (rad_sphere==0) then
            call fatal_error('init_particles','random-sphere '// &
                  'radius needs to be larger than zero')
          endif
          if (-rad_sphere+pos_sphere(1)<xyz0(1) .or. &
               rad_sphere+pos_sphere(1)>xyz1(1) .or. &
              -rad_sphere+pos_sphere(2)<xyz0(2) .or. &
               rad_sphere+pos_sphere(2)>xyz1(2) .or. &
              -rad_sphere+pos_sphere(3)<xyz0(3) .or. &
               rad_sphere+pos_sphere(3)>xyz1(3)) then
            call fatal_error('init_particles','random-sphere '// &
                 'sphere needs to fit in the box')
          endif
          if (lcartesian_coords) then
            do k=1,npar_loc
              rp2=2.*rad_sphere**2
              do while (rp2>rad_sphere**2)
                call random_number_wrapper(fp(k,ixp))
                call random_number_wrapper(fp(k,iyp))
                call random_number_wrapper(fp(k,izp))
                fp(k,ixp)=(fp(k,ixp)-0.5)*2.*rad_sphere
                fp(k,iyp)=(fp(k,iyp)-0.5)*2.*rad_sphere
                fp(k,izp)=(fp(k,izp)-0.5)*2.*rad_sphere
                rp2=fp(k,ixp)**2+fp(k,iyp)**2+fp(k,izp)**2
              enddo
              fp(k,ixp)=fp(k,ixp)+pos_sphere(1)
              fp(k,iyp)=fp(k,iyp)+pos_sphere(2)
              fp(k,izp)=fp(k,izp)+pos_sphere(3)
            enddo
          else
            call fatal_error('init_particles','random-sphere '// &
                 'only implemented for cartesian coordinates')
          endif
!
        case ('random-line-x')
          if (lroot) print*, 'init_particles: Random particle positions'
          do k=1,npar_loc
            if (nxgrid/=1) call random_number_wrapper(fp(k,ixp))
          enddo
          if (nxgrid/=1) &
              fp(1:npar_loc,ixp)=xyz0_par(1)+fp(1:npar_loc,ixp)*Lxyz_par(1)
          fp(1:npar_loc,iyp)=yp0
          fp(1:npar_loc,izp)=zp0
!
        case ('random-line-y')
          if (lroot) print*, 'init_particles: Random particle positions'
          do k=1,npar_loc
            if (nygrid/=1) call random_number_wrapper(fp(k,iyp))
          enddo
          if (nygrid/=1) &
              fp(1:npar_loc,iyp)=xyz0_par(2)+fp(1:npar_loc,iyp)*Lxyz_par(2)
          fp(1:npar_loc,ixp)=xp0
          fp(1:npar_loc,izp)=zp0
!
        case ('random-hole')
          if (lroot) print*, 'init_particles: Random particle positions '// &
              'with inner hole'
          do k=1,npar_loc
            rp2=-1.0
            do while (rp2<rp_int**2)
              if (nxgrid/=1) call random_number_wrapper(fp(k,ixp))
              if (nygrid/=1) call random_number_wrapper(fp(k,iyp))
              if (nzgrid/=1) call random_number_wrapper(fp(k,izp))
              if (nxgrid/=1) fp(k,ixp)=xyz0(1)+fp(k,ixp)*Lxyz(1)
              if (nygrid/=1) fp(k,iyp)=xyz0(2)+fp(k,iyp)*Lxyz(2)
              if (nzgrid/=1) fp(k,izp)=xyz0(3)+fp(k,izp)*Lxyz(3)
              rp2=fp(k,ixp)**2+fp(k,iyp)**2+fp(k,izp)**2
            enddo
          enddo
!
        case ('random-box')
          if (lroot) print*, 'init_particles: Random particle positions '// &
               'within a box'
          do k=1,npar_loc
            if (nxgrid/=1) call random_number_wrapper(fp(k,ixp))
            if (nygrid/=1) call random_number_wrapper(fp(k,iyp))
            if (nzgrid/=1) call random_number_wrapper(fp(k,izp))
            if (lcylindrical_coords) then
              xx0=xp0+fp(k,ixp)*Lx0
              yy0=yp0+fp(k,iyp)*Ly0
              r2=xx0**2+yy0**2
              if (nxgrid/=1) fp(k,ixp)=sqrt(r2)
              if (nygrid/=1) fp(k,iyp)=atan(yy0/xx0)+pi*(xx0/abs(xx0)-1)*0.5
              if (nzgrid/=1) fp(k,izp)=zp0+fp(k,izp)*Lz0
            else
              if (nxgrid/=1) fp(k,ixp)=xp0+fp(k,ixp)*Lx0
              if (nygrid/=1) fp(k,iyp)=yp0+fp(k,iyp)*Ly0
              if (nzgrid/=1) fp(k,izp)=zp0+fp(k,izp)*Lz0
            endif
          enddo
!
!
        case ('np-constant')
          if (lroot) print*, 'init_particles: Constant number density'
          k=1
k_loop:   do while (.not. (k>npar_loc))
            do l=l1,l2; do m=m1,m2; do n=n1,n2
              if (nxgrid/=1) call random_number_wrapper(px)
              if (nygrid/=1) call random_number_wrapper(py)
              if (nzgrid/=1) call random_number_wrapper(pz)
              fp(k,ixp)=x(l)+(px-0.5)*dx
              fp(k,iyp)=y(m)+(py-0.5)*dy
              fp(k,izp)=z(n)+(pz-0.5)*dz
              k=k+1
              if (k>npar_loc) exit k_loop
            enddo; enddo; enddo
          enddo k_loop
!
        case ('equidistant')
          if (lroot) print*, 'init_particles: Particles placed equidistantly'
          dim1=1.0/dimensionality
!
!  Number of particles per direction. Found by solving the equation system
!
!    npar_loc_x/npar_loc_y = Lx_loc/Ly_loc
!    npar_loc_x/npar_loc_z = Lx_loc/Lz_loc
!    npar_loc_y/npar_loc_z = Ly_loc/Lz_loc
!    npar_loc_x*npar_loc_y*npar_loc_z = npar_loc
!
!  Found it to be easier to separate in all possible dimensionalities.
!  For a missing direction i, set npar_loc_i=1 in the above equations and
!  ignore any equation that has Li_loc in it.
!
!  Initiate to avoid compiler warnings. Will be overwritten.
          npar_loc_x=1;npar_loc_y=1;npar_loc_z=1
!
          if (dimensionality==3) then
!  3-D
            npar_loc_x=(npar_loc*Lxyz_loc(1)**2/(Lxyz_loc(2)*Lxyz_loc(3)))**dim1
            npar_loc_y=(npar_loc*Lxyz_loc(2)**2/(Lxyz_loc(1)*Lxyz_loc(3)))**dim1
            npar_loc_z=(npar_loc*Lxyz_loc(3)**2/(Lxyz_loc(1)*Lxyz_loc(2)))**dim1
          elseif (dimensionality==2) then
!  2-D
            if (nxgrid==1) then
              npar_loc_x=1
              npar_loc_y=(npar_loc*Lxyz_loc(2)/Lxyz_loc(3))**dim1
              npar_loc_z=(npar_loc*Lxyz_loc(3)/Lxyz_loc(2))**dim1
            elseif (nygrid==1) then
              npar_loc_x=(npar_loc*Lxyz_loc(1)/Lxyz_loc(3))**dim1
              npar_loc_y=1
              npar_loc_z=(npar_loc*Lxyz_loc(3)/Lxyz_loc(2))**dim1
            elseif (nzgrid==1) then
              npar_loc_x=(npar_loc*Lxyz_loc(1)/Lxyz_loc(2))**dim1
              npar_loc_y=(npar_loc*Lxyz_loc(2)/Lxyz_loc(1))**dim1
              npar_loc_z=1
            endif
          elseif (dimensionality==1) then
!  1-D
            if (nxgrid/=1) then
              npar_loc_x=npar_loc
              npar_loc_y=1
              npar_loc_z=1
            elseif (nygrid/=1) then
              npar_loc_x=1
              npar_loc_y=npar_loc
              npar_loc_z=1
            elseif (nzgrid/=1) then
              npar_loc_x=1
              npar_loc_y=1
              npar_loc_z=npar_loc
            endif
          endif
!  Distance between particles.
          dx_par=Lxyz_loc(1)/npar_loc_x
          dy_par=Lxyz_loc(2)/npar_loc_y
          dz_par=Lxyz_loc(3)/npar_loc_z
!  Place first particle.
          fp(1,ixp) = x(l1) ; fp(1,iyp) = y(m1) ; fp(1,izp) = z(n1)
          if (nxgrid/=1) fp(1,ixp) = xyz0_loc(1)+dx_par/2
          if (nygrid/=1) fp(1,iyp) = xyz0_loc(2)+dy_par/2
          if (nzgrid/=1) fp(1,izp) = xyz0_loc(3)+dz_par/2
!  Place all other particles iteratively.
          if (dimensionality==3) then
!  3-D
            do k=2,npar_loc
              fp(k,ixp)=fp(k-1,ixp)+dx_par
              fp(k,iyp)=fp(k-1,iyp)
              fp(k,izp)=fp(k-1,izp)
              if (fp(k,ixp)>xyz1_loc(1)) then
                fp(k,ixp)=fp(1,ixp)
                fp(k,iyp)=fp(k,iyp)+dy_par
              endif
              if (fp(k,iyp)>xyz1_loc(2)) then
                fp(k,iyp)=fp(1,iyp)
                fp(k,izp)=fp(k,izp)+dz_par
              endif
            enddo
          elseif (dimensionality==2) then
!  2-D
            if (nxgrid==1) then
              do k=2,npar_loc
                fp(k,ixp)=fp(k-1,ixp)
                fp(k,iyp)=fp(k-1,iyp)+dy_par
                fp(k,izp)=fp(k-1,izp)
                if (fp(k,iyp)>xyz1_loc(2)) then
                  fp(k,iyp)=fp(1,iyp)
                  fp(k,izp)=fp(k,izp)+dz_par
                endif
              enddo
            elseif (nygrid==1) then
              do k=2,npar_loc
                fp(k,ixp)=fp(k-1,ixp)+dx_par
                fp(k,iyp)=fp(k-1,iyp)
                fp(k,izp)=fp(k-1,izp)
                if (fp(k,ixp)>xyz1_loc(1)) then
                  fp(k,ixp)=fp(1,ixp)
                  fp(k,izp)=fp(k,izp)+dz_par
                endif
              enddo
            elseif (nzgrid==1) then
              do k=2,npar_loc
                fp(k,ixp)=fp(k-1,ixp)+dx_par
                fp(k,iyp)=fp(k-1,iyp)
                fp(k,izp)=fp(k-1,izp)
                if (fp(k,ixp)>xyz1_loc(1)) then
                  fp(k,ixp)=fp(1,ixp)
                  fp(k,iyp)=fp(k,iyp)+dy_par
                endif
              enddo
            endif
          elseif (dimensionality==1) then
!  1-D
            if (nxgrid/=1) then
              do k=2,npar_loc
                fp(k,ixp)=fp(k-1,ixp)+dx_par
                fp(k,iyp)=fp(k-1,iyp)
                fp(k,izp)=fp(k-1,izp)
              enddo
            elseif (nygrid/=1) then
              do k=2,npar_loc
                fp(k,ixp)=fp(k-1,ixp)
                fp(k,iyp)=fp(k-1,iyp)+dy_par
                fp(k,izp)=fp(k-1,izp)
              enddo
            elseif (nzgrid/=1) then
              do k=2,npar_loc
                fp(k,ixp)=fp(k-1,ixp)
                fp(k,iyp)=fp(k-1,iyp)
                fp(k,izp)=fp(k-1,izp)+dz_par
              enddo
            endif
          else
!  0-D
            fp(2:npar_loc,ixp)=fp(1,ixp)
            fp(2:npar_loc,iyp)=fp(1,iyp)
            fp(2:npar_loc,izp)=fp(1,izp)
          endif
          lequidistant=.true.
!
!  Shift particle locations slightly so that a mode appears.
!
        case ('shift')
          if (lroot) print*, 'init_particles: shift particle positions'
          if (.not. lequidistant) then
            if (lroot) print*, 'init_particles: must place particles equidistantly before shifting!'
            call fatal_error('init_particles','')
          endif
          k2_xxp=kx_xxp**2+ky_xxp**2+kz_xxp**2
          if (k2_xxp==0.0) then
            if (lroot) print*, &
                'init_particles: kx_xxp=ky_xxp=kz_xxp=0.0 is not allowed!'
            call fatal_error('init_particles','')
          endif
          do k=1,npar_loc
            fp(k,ixp) = fp(k,ixp) - kx_xxp/k2_xxp*amplxxp* &
                sin(kx_xxp*fp(k,ixp)+ky_xxp*fp(k,iyp)+kz_xxp*fp(k,izp))
            fp(k,iyp) = fp(k,iyp) - ky_xxp/k2_xxp*amplxxp* &
                sin(kx_xxp*fp(k,ixp)+ky_xxp*fp(k,iyp)+kz_xxp*fp(k,izp))
            fp(k,izp) = fp(k,izp) - kz_xxp/k2_xxp*amplxxp* &
                sin(kx_xxp*fp(k,ixp)+ky_xxp*fp(k,iyp)+kz_xxp*fp(k,izp))
          enddo
!
        case ('gaussian-z')
          if (lroot) print*, 'init_particles: Gaussian particle positions'
          do k=1,npar_loc
            do while (.true.)
              if (nxgrid/=1) call random_number_wrapper(fp(k,ixp))
              if (nygrid/=1) call random_number_wrapper(fp(k,iyp))
              call random_number_wrapper(r)
              call random_number_wrapper(p)
              if (nprocz==2) then
                if (lfirst_proc_z) fp(k,izp)=-abs(zp0*sqrt(-2*alog(r))*cos(2*pi*p))
                if (llast_proc_z) fp(k,izp)=abs(zp0*sqrt(-2*alog(r))*cos(2*pi*  p))
              else
                fp(k,izp)= zp0*sqrt(-2*alog(r))*cos(2*pi*p)
              endif
              if ((fp(k,izp)>=xyz0(3)).and.(fp(k,izp)<=xyz1(3))) exit
            enddo
          enddo
          if (nxgrid/=1) &
              fp(1:npar_loc,ixp)=xyz0_par(1)+fp(1:npar_loc,ixp)*Lxyz_par(1)
          if (nygrid/=1) &
              fp(1:npar_loc,iyp)=xyz0_par(2)+fp(1:npar_loc,iyp)*Lxyz_par(2)
!
        case ('gaussian-x')
          if (lroot) print*, 'init_particles: Gaussian particle positions'
          do k=1,npar_loc
            do while (.true.)
              if (nygrid/=1) call random_number_wrapper(fp(k,iyp))
              if (nzgrid/=1) call random_number_wrapper(fp(k,izp))
              call random_number_wrapper(r)
              call random_number_wrapper(p)
              fp(k,ixp)= xp0*sqrt(-2*alog(r))*cos(2*pi*p)
              if ((fp(k,ixp)>=xyz0(1)).and.(fp(k,ixp)<=xyz1(1))) exit
            enddo
          enddo
          if (nygrid/=1) &
              fp(1:npar_loc,iyp)=xyz0_par(2)+fp(1:npar_loc,iyp)*Lxyz_par(2)
          if (nzgrid/=1) &
              fp(1:npar_loc,izp)=xyz0_par(3)+fp(1:npar_loc,izp)*Lxyz_par(3)
!
        case ('gaussian-z-pure')
          if (lroot) print*, 'init_particles: Gaussian particle positions'
          do k=1,npar_loc
            call random_number_wrapper(r)
            call random_number_wrapper(p)
            if (nprocz==2) then
              if (lfirst_proc_z) fp(k,izp)=-abs(zp0*sqrt(-2*alog(r))*cos(2*pi*p))
              if (llast_proc_z) fp(k,izp)=abs(zp0*sqrt(-2*alog(r))*cos(2*pi*p))
            else
              fp(k,izp)= zp0*sqrt(-2*alog(r))*cos(2*pi*p)
            endif
          enddo
!
        case ('gaussian-r')
          if (lroot) print*, 'init_particles: Gaussian particle positions'
          do k=1,npar_loc
            call random_number_wrapper(r)
            call random_number_wrapper(p)
            call random_number_wrapper(q)
            fp(k,ixp)= xp0*sqrt(-2*alog(r))*cos(2*pi*p)*cos(2*pi*q)
            fp(k,iyp)= yp0*sqrt(-2*alog(r))*cos(2*pi*p)*sin(2*pi*q)
          enddo
!
        case ('hole')
!
          call map_nearest_grid(fp,ineargrid)
          call map_xxp_grid(f,fp,ineargrid)
          call sort_particles_imn(fp,ineargrid,ipar,f=f)
          do k=k1_imn(imn_array(m_hole+m1-1,n_hole+n1-1)), &
               k2_imn(imn_array(m_hole+m1-1,n_hole+n1-1))
            if (ineargrid(k,1)==l_hole+l1-1) then
              print*, k
              if (nxgrid/=0) fp(k,ixp)=fp(k,ixp)-dx
            endif
          enddo
!
        case default
          if (lroot) &
              print*, 'init_particles: No such such value for initxxp: ', &
              trim(initxxp(j))
          call fatal_error('init_particles','')
!
        endselect
!
      enddo ! do j=1,ninit
!
!  Interface for user's own initial condition for position
!
      if (linitial_condition) call initial_condition_xxp(f,fp)
!
!  Particles are not allowed to be present in non-existing dimensions.
!  This would give huge problems with interpolation later.
!
      if (nxgrid==1) fp(1:npar_loc,ixp)=x(nghost+1)
      if (nygrid==1) fp(1:npar_loc,iyp)=y(nghost+1)
      if (nzgrid==1) fp(1:npar_loc,izp)=z(nghost+1)
!
      if (init_repeat/=0) call repeated_init(fp,init_repeat)
!
!  Redistribute particles among processors (now that positions are determined).
!
      call boundconds_particles(fp,ipar)
!
!  Map particle position on the grid.
!
      call map_nearest_grid(fp,ineargrid)
      call map_xxp_grid(f,fp,ineargrid)
!
!  Initial particle velocity.
!
      do j=1,ninit
!
        select case (initvvp(j))
!
        case ('nothing')
          if (lroot.and.j==1) print*, 'init_particles: No particle velocity set'
!
        case ('oppose')
          if (lroot .and. j==1) print*, 'init_particles: two'
          fp(1,ivpx) = -vpx0
          fp(1,ivpy)=0; fp(1,ivpz)=0.
          fp(2,ivpx) = vpx0
          fp(2,ivpy)=0; fp(2,ivpz)=0.
!
        case ('zero')
          if (lroot) print*, 'init_particles: Zero particle velocity'
          fp(1:npar_loc,ivpx:ivpz)=0.0
!
        case ('zero-shear')
          if (lroot) print*, 'init_particles: Zero particle velocity'
          fp(1:npar_loc,ivpy)=-Sshear*fp(1:npar_loc,ixp)
          fp(1:npar_loc,ivpx)=0.0
          fp(1:npar_loc,ivpz)=0.0
!
        case ('constant')
          if (lroot) print*, 'init_particles: Constant particle velocity'
          if (lroot) &
              print*, 'init_particles: vpx0, vpy0, vpz0=', vpx0, vpy0, vpz0
          if (lcylindrical_coords) then
            fp(1:npar_loc,ivpx)&
                =vpx0*cos(fp(k,iyp))+vpy0*sin(fp(k,iyp))
            fp(1:npar_loc,ivpy)&
                =vpy0*cos(fp(k,iyp))-vpx0*sin(fp(k,iyp))
            fp(1:npar_loc,ivpz)=vpz0
          else
            fp(1:npar_loc,ivpx)=vpx0
            fp(1:npar_loc,ivpy)=vpy0
            fp(1:npar_loc,ivpz)=vpz0
          endif
!
        case ('constant-1')
          if (lroot) &
              print*, 'init_particles: Particle 1 velocity vx,vy,vz=', &
              vpx1, vpy1, vpz1
          do k=1,npar_loc
            if (ipar(k)==1) then
              fp(k,ivpx)=vpx1
              fp(k,ivpy)=vpy1
              fp(k,ivpz)=vpz1
            endif
          enddo
!
        case ('constant-2')
          if (lroot) &
              print*, 'init_particles: Particle 2 velocity vx,vy,vz=', &
              vpx2, vpy2, vpz2
          do k=1,npar_loc
            if (ipar(k)==2) then
              fp(k,ivpx)=vpx2
              fp(k,ivpy)=vpy2
              fp(k,ivpz)=vpz2
            endif
          enddo
!
        case ('constant-3')
          if (lroot) &
              print*, 'init_particles: Particle 3 velocity vx,vy,vz=', &
              vpx3, vpy3, vpz3
          do k=1,npar_loc
            if (ipar(k)==3) then
              fp(k,ivpx)=vpx3
              fp(k,ivpy)=vpy3
              fp(k,ivpz)=vpz3
            endif
          enddo
!
        case ('sinwave-phase')
          if (lroot) print*, 'init_particles: sinwave-phase'
          if (lroot) &
              print*, 'init_particles: vpx0, vpy0, vpz0=', vpx0, vpy0, vpz0
          do k=1,npar_loc
            fp(k,ivpx)=fp(k,ivpx)+vpx0*sin(kx_vpx*fp(k,ixp)+ky_vpx*fp(k,iyp)+kz_vpx*fp(k,izp)+phase_vpx)
            fp(k,ivpy)=fp(k,ivpy)+vpy0*sin(kx_vpy*fp(k,ixp)+ky_vpy*fp(k,iyp)+kz_vpy*fp(k,izp)+phase_vpy)
            fp(k,ivpz)=fp(k,ivpz)+vpz0*sin(kx_vpz*fp(k,ixp)+ky_vpz*fp(k,iyp)+kz_vpz*fp(k,izp)+phase_vpz)
          enddo
!
        case ('coswave-phase')
          if (lroot) print*, 'init_particles: coswave-phase'
          if (lroot) &
              print*, 'init_particles: vpx0, vpy0, vpz0=', vpx0, vpy0, vpz0
          do k=1,npar_loc
            fp(k,ivpx)=fp(k,ivpx)+vpx0*cos(kx_vpx*fp(k,ixp)+ky_vpx*fp(k,iyp)+kz_vpx*fp(k,izp)+phase_vpx)
            fp(k,ivpy)=fp(k,ivpy)+vpy0*cos(kx_vpy*fp(k,ixp)+ky_vpy*fp(k,iyp)+kz_vpy*fp(k,izp)+phase_vpy)
            fp(k,ivpz)=fp(k,ivpz)+vpz0*cos(kx_vpz*fp(k,ixp)+ky_vpz*fp(k,iyp)+kz_vpz*fp(k,izp)+phase_vpz)
          enddo
!
        case ('random')
          if (lroot) print*, 'init_particles: Random particle velocities; '// &
              'delta_vp0=', delta_vp0
          do k=1,npar_loc
            call random_number_wrapper(r)
            fp(k,ivpx) = fp(k,ivpx) + delta_vp0*(2*r-1)
            call random_number_wrapper(r)
            fp(k,ivpy) = fp(k,ivpy) + delta_vp0*(2*r-1)
            call random_number_wrapper(r)
            fp(k,ivpz) = fp(k,ivpz) + delta_vp0*(2*r-1)
          enddo
!
        case ('random-x')
          if (lroot) print*, 'init_particles: Random particle x-velocity; '// &
              'delta_vp0=', delta_vp0
          do k=1,npar_loc
            call random_number_wrapper(r)
            fp(k,ivpx) = fp(k,ivpx) + delta_vp0*(2*r-1)
          enddo
!
        case ('random-y')
          if (lroot) print*, 'init_particles: Random particle y-velocity; '// &
              'delta_vp0=', delta_vp0
          do k=1,npar_loc
            call random_number_wrapper(r)
            fp(k,ivpy) = fp(k,ivpy) + delta_vp0*(2*r-1)
          enddo
!
        case ('random-z')
          if (lroot) print*, 'init_particles: Random particle z-velocity; '// &
              'delta_vp0=', delta_vp0
          do k=1,npar_loc
            call random_number_wrapper(r)
            fp(k,ivpz) = fp(k,ivpz) + delta_vp0*(2*r-1)
          enddo
!
        case ('average-to-zero')
          call mpireduce_sum(sum(fp(1:npar_loc,ivpx)),vpx_sum)
          call mpireduce_sum(sum(fp(1:npar_loc,ivpy)),vpy_sum)
          call mpireduce_sum(sum(fp(1:npar_loc,ivpz)),vpz_sum)
          call mpibcast_real(vpx_sum)
          call mpibcast_real(vpy_sum)
          call mpibcast_real(vpz_sum)
          fp(1:npar_loc,ivpx)=fp(1:npar_loc,ivpx)-vpx_sum/npar
          fp(1:npar_loc,ivpy)=fp(1:npar_loc,ivpy)-vpy_sum/npar
          fp(1:npar_loc,ivpz)=fp(1:npar_loc,ivpz)-vpz_sum/npar
!
        case ('follow-gas')
          if (lroot) &
              print*, 'init_particles: Particle velocity equal to gas velocity'
          do k=1,npar_loc
            call interpolate_linear(f,iux,iuz,fp(k,ixp:izp),uup, &
                ineargrid(k,:),0,0)
            fp(k,ivpx:ivpz) = uup
          enddo
!
!  Explosion.
!
       case ('explosion')
         do k=1,npar_loc
           rad=sqrt(fp(k,ixp)**2+fp(k,iyp)**2+fp(k,izp)**2)
           fp(k,ivpx) = delta_vp0*fp(k,ixp)/rp_ext
           fp(k,ivpy) = delta_vp0*fp(k,iyp)/rp_ext
           fp(k,ivpz) = delta_vp0*fp(k,izp)/rp_ext
         enddo
!
!
        case default
          if (lroot) &
              print*, 'init_particles: No such such value for initvvp: ', &
              trim(initvvp(j))
          call fatal_error('','')
!
        endselect
!
      enddo ! do j=1,ninit
!
!  Interface for user's own initial condition
!
      if (linitial_condition) call initial_condition_vvp(f,fp)
!
!  Map particle velocity on the grid.
!
      call map_vvp_grid(f,fp,ineargrid)
!
!  Sort particles (must happen at the end of the subroutine so that random
!  positions and velocities are not displaced relative to when there is no
!  sorting).
!
      call sort_particles_imn(fp,ineargrid,ipar,f=f)
!
    endsubroutine init_particles
!***********************************************************************
    subroutine insert_lost_particles(f,fp,ineargrid)
!
!  14-oct-12/dhruba: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mpar_loc,mparray) :: fp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      intent (inout) :: fp,ineargrid
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(fp)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine insert_lost_particles
!***********************************************************************
    subroutine insert_particles(f,fp,ineargrid)
!
! Insert particles continuously (when linsert_particles_continuously == T),
! i.e. in each timestep. If number of particles to be inserted are less
! than unity, accumulate number over several timesteps until the integer value
! is larger than one. Keep the remainder and accumulate this to the next insert.
!
! Works only for particles_dust - add neccessary variable
! declarations in particles_tracers to make it work here.
!
      use General, only: random_number_wrapper
      use Particles_diagnos_state, only: insert_particles_diagnos_state
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mpar_loc,mparray) :: fp
      integer, dimension (mpar_loc,3) :: ineargrid
      logical :: linsertmore=.true.
      real :: xx0, yy0,r2
!
      integer :: j, k, n_insert, npar_loc_old, iii
!
      intent (inout) :: fp,ineargrid
!
! Stop call to this routine when maximum number of particles is reached!
! Since root inserts all new particles, make sure
! npar_total + n_insert < mpar
! so that a processor can not exceed its maximum number of particles.
!
      if (lroot) then
        avg_n_insert=particles_insert_rate*dt
        n_insert=int(avg_n_insert + remaining_particles)
! Remaining particles saved for subsequent timestep:
        remaining_particles=avg_n_insert + remaining_particles - n_insert
        if ((n_insert+npar_total <= mpar_loc) &
            .and. (t<max_particle_insert_time)) then
          linsertmore=.true.
        else
          linsertmore=.false.
        endif
!
        if (linsertmore) then
! Actual (integer) number of particles to be inserted at this timestep:
          do iii=npar_loc+1,npar_loc+n_insert
            ipar(iii)=npar_total+iii-npar_loc
          enddo
          npar_total=npar_total+n_insert
          npar_loc_old=npar_loc
          npar_loc=npar_loc + n_insert
!
! Insert particles in chosen position (as in init_particles).
!
          do j=1,ninit
            select case (initxxp(j))
            case ('random-box')
!
              do k=npar_loc_old+1,npar_loc
                if (nxgrid/=1) call random_number_wrapper(fp(k,ixp))
                if (nygrid/=1) call random_number_wrapper(fp(k,iyp))
                if (nzgrid/=1) call random_number_wrapper(fp(k,izp))
                if (lcylindrical_coords) then
                  xx0=xp0+fp(k,ixp)*Lx0
                  yy0=yp0+fp(k,iyp)*Ly0
                  r2=xx0**2+yy0**2
                  if (nxgrid/=1) fp(k,ixp)=sqrt(r2)
                  if (nygrid/=1) fp(k,iyp)=atan(yy0/xx0)+pi*(xx0/abs(xx0)-1)*0.5
                  if (nzgrid/=1) fp(k,izp)=zp0+fp(k,izp)*Lz0
                else
                  if (nxgrid/=1) fp(k,ixp)=xp0+fp(k,ixp)*Lx0
                  if (nygrid/=1) fp(k,iyp)=yp0+fp(k,iyp)*Ly0
                  if (nzgrid/=1) fp(k,izp)=zp0+fp(k,izp)*Lz0
                endif
              enddo
!
            case ('nothing')
              if (lroot .and. j==1) print*, 'init_particles: nothing'
!
            case default
              print*, 'insert_particles: No such such value for initxxp: ', &
                  trim(initxxp(j))
              call fatal_error('init_particles','')
!
            endselect
          enddo
!
!  Initial particle velocity.
!
          do j=1,ninit
            select case (initvvp(j))
            case ('nothing')
              if (j==1) print*, 'init_particles: No particle velocity set'
!
            case ('constant')
              if (lcylindrical_coords) then
                fp(npar_loc_old+1:npar_loc,ivpx)&
                    =vpx0*cos(fp(npar_loc_old+1:npar_loc,iyp))&
                    +vpy0*sin(fp(npar_loc_old+1:npar_loc,iyp))
                fp(npar_loc_old+1:npar_loc,ivpy)&
                    =vpy0*cos(fp(npar_loc_old+1:npar_loc,iyp))&
                    -vpx0*sin(fp(npar_loc_old+1:npar_loc,iyp))
                fp(npar_loc_old+1:npar_loc,ivpz)=vpz0
              else
                fp(npar_loc_old+1:npar_loc,ivpx)=vpx0
                fp(npar_loc_old+1:npar_loc,ivpy)=vpy0
                fp(npar_loc_old+1:npar_loc,ivpz)=vpz0
              endif
!
            case default
              print*, 'insert_particles: No such such value for initvvp: ', &
                  trim(initvvp(j))
              call fatal_error('','')
              !
            endselect
!
          enddo ! do j=1,ninit
!
!  Initialize particle radius
!
          call set_particle_radius(f,fp,npar_loc_old+1,npar_loc)
!
!  Particles are not allowed to be present in non-existing dimensions.
!  This would give huge problems with interpolation later.
!
          if (nxgrid==1) fp(npar_loc_old+1:npar_loc,ixp)=x(nghost+1)
          if (nygrid==1) fp(npar_loc_old+1:npar_loc,iyp)=y(nghost+1)
          if (nzgrid==1) fp(npar_loc_old+1:npar_loc,izp)=z(nghost+1)
!
          if (lparticles_diagnos_state) &
              call insert_particles_diagnos_state(fp, npar_loc_old)
!
        endif
      endif ! if (lroot) then
!
!  Redistribute particles only when t < max_particle_insert_time.
!  Could have included some other tests here aswell......
!
      if (t<max_particle_insert_time) then
!
!  Redistribute particles among processors.
!
        call boundconds_particles(fp,ipar,linsert=.true.)
!
!  Map particle position on the grid.
!
        call map_nearest_grid(fp,ineargrid)
        call map_xxp_grid(f,fp,ineargrid)
!
!  Map particle velocity on the grid.
!
        call map_vvp_grid(f,fp,ineargrid)
!
!  Sort particles (must happen at the end of the subroutine so that random
!  positions and velocities are not displaced relative to when there is no
!  sorting).
!
        call sort_particles_imn(fp,ineargrid,ipar)
      endif
!
    endsubroutine insert_particles
!***********************************************************************
    subroutine pencil_criteria_particles()
!
!  All pencils that the Particles module depends on are specified here.
!
!  20-04-06/anders: coded
!
      lpenc_requested(i_bb) = .true.
      lpenc_requested(i_ee) = .true.
!
      if (idiag_npm/=0 .or. idiag_np2m/=0 .or. idiag_npmax/=0 .or. &
          idiag_npmin/=0 .or. idiag_npmx/=0 .or. idiag_npmy/=0 .or. &
          idiag_npmz/=0 .or. idiag_nparpmax/=0) lpenc_diagnos(i_np)=.true.
      if (idiag_rhopm/=0 .or. idiag_rhoprms/=0 .or. idiag_rhop2m/=0 .or. &
          idiag_rhopmax/=0 .or. idiag_rhopmin/=0 .or. idiag_rhopmphi/=0 .or. &
          idiag_rhopmx/=0 .or. idiag_rhopmy/=0 .or. idiag_rhopmz/=0) &
          lpenc_diagnos(i_rhop)=.true.
      if (idiag_dedragp/=0 .or. idiag_decollp/=0) then
        lpenc_diagnos(i_TT1)=.true.
        lpenc_diagnos(i_rho1)=.true.
      endif
      if (idiag_epspmx/=0 .or. idiag_epspmy/=0 .or. idiag_epspmz/=0 .or. &
          idiag_epspmin/=0 .or. idiag_epspmax/=0) &
          lpenc_diagnos(i_epsp)=.true.
      if (idiag_rhopmxy/=0 .or. idiag_rhopmxz/=0 .or. idiag_rhopmphi/=0) &
          lpenc_diagnos2d(i_rhop)=.true.
      if (idiag_npmxy/=0 ) lpenc_diagnos2d(i_np)=.true.
!
    endsubroutine pencil_criteria_particles
!***********************************************************************
    subroutine pencil_interdep_particles(lpencil_in)
!
!  Interdependency among pencils provided by the Particles module
!  is specified here.
!
!  16-feb-06/anders: dummy
!
      logical, dimension(npencils) :: lpencil_in
!
      if (lpencil_in(i_rhop) .and. irhop==0) then
        lpencil_in(i_np)=.true.
      endif
!
      if (lpencil_in(i_epsp)) then
        lpencil_in(i_rhop)=.true.
        lpencil_in(i_rho1)=.true.
      endif
!
    endsubroutine pencil_interdep_particles
!***********************************************************************
    subroutine calc_pencils_particles(f,p)
!
      use Sub, only: grad
!
!  Calculate Particles pencils.
!  Most basic pencils should come first, as others may depend on them.
!
!  16-feb-06/anders: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (pencil_case) :: p
!
      if (lpencil(i_np)) then
        if (inp/=0) then
          p%np=f(l1:l2,m,n,inp)
        else
          p%np=0.0
        endif
      endif
!
      if (lpencil(i_rhop)) then
        if (irhop/=0) then
          p%rhop=f(l1:l2,m,n,irhop)
        else
          p%rhop=rhop_swarm*f(l1:l2,m,n,inp)
        endif
      endif
!
      if (lpencil(i_grhop)) then
        if (irhop/=0) then
          if ((nprocx/=1).and.(.not.lcommunicate_rhop)) &
               call fatal_error("calc_pencils_particles",&
               "Switch on lcommunicate_rhop=T in particles_run_pars")
          call grad(f,irhop,p%grhop)
        else
          if ((nprocx/=1).and.(.not.lcommunicate_np)) &
               call fatal_error("calc_pencils_particles",&
               "Switch on lcommunicate_np=T in particles_run_pars")
          call grad(f,inp,p%grhop)
          p%grhop=rhop_swarm*p%grhop
        endif
      endif
!
      if (lpencil(i_epsp)) p%epsp=p%rhop*p%rho1
!
    endsubroutine calc_pencils_particles
!***********************************************************************
    subroutine dxxp_dt(f,df,fp,dfp,ineargrid)
!
!  Evolution of dust particle position.
!
!  02-jan-05/anders: coded
!
      use General, only: random_number_wrapper, random_seed_wrapper
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      logical :: lheader, lfirstcall=.true.
!
      intent (in) :: f, fp, ineargrid
      intent (inout) :: df, dfp
!
!  Print out header information in first time step.
!
      lheader=lfirstcall .and. lroot
!
!  Identify module and boundary conditions.
!
      if (lheader) print*,'dxxp_dt: Calculate dxxp_dt'
      if (lheader) then
        print*, 'dxxp_dt: Particles boundary condition bcpx=', bcpx
        print*, 'dxxp_dt: Particles boundary condition bcpy=', bcpy
        print*, 'dxxp_dt: Particles boundary condition bcpz=', bcpz
      endif
!
      if (lheader) print*, 'dxxp_dt: Set rate of change of particle '// &
          'position equal to particle velocity.'
!
!  The rate of change of a particle's position is the particle's velocity.
!
      if (lcartesian_coords) then
!
        if (nxgrid/=1) then
            dfp(1:npar_loc,ixp) = dfp(1:npar_loc,ixp) + fp(1:npar_loc,ivpx)
        endif
        if (nygrid/=1) &
            dfp(1:npar_loc,iyp) = dfp(1:npar_loc,iyp) + fp(1:npar_loc,ivpy)
        if (nzgrid/=1) &
            dfp(1:npar_loc,izp) = dfp(1:npar_loc,izp) + fp(1:npar_loc,ivpz)
!
      elseif (lcylindrical_coords) then
!
        if (nxgrid/=1) &
            dfp(1:npar_loc,ixp) = dfp(1:npar_loc,ixp) + fp(1:npar_loc,ivpx)
        if (nygrid/=1) &
            dfp(1:npar_loc,iyp) = dfp(1:npar_loc,iyp) + &
            fp(1:npar_loc,ivpy)/max(fp(1:npar_loc,ixp),tini)
        if (nzgrid/=1) &
            dfp(1:npar_loc,izp) = dfp(1:npar_loc,izp) + fp(1:npar_loc,ivpz)
!
      elseif (lspherical_coords) then
!
        if (nxgrid/=1) &
            dfp(1:npar_loc,ixp) = dfp(1:npar_loc,ixp) + fp(1:npar_loc,ivpx)
        if (nygrid/=1) &
            dfp(1:npar_loc,iyp) = dfp(1:npar_loc,iyp) + &
            fp(1:npar_loc,ivpy)/max(fp(1:npar_loc,ixp),tini)
        if (nzgrid/=1) &
            dfp(1:npar_loc,izp) = dfp(1:npar_loc,izp) + &
            fp(1:npar_loc,ivpz)/(max(fp(1:npar_loc,ixp),tini)*&
            sin(fp(1:npar_loc,iyp)))
!
      endif
!
!  With shear there is an extra term due to the background shear flow.
!
      if (lshear.and.nygrid/=1) dfp(1:npar_loc,iyp) = &
          dfp(1:npar_loc,iyp) - qshear*Omega*fp(1:npar_loc,ixp)
!
      if (lfirstcall) lfirstcall=.false.
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine dxxp_dt
!***********************************************************************
    subroutine dvvp_dt(f,df,fp,dfp,ineargrid)
!
!  Evolution of dust particle velocity.
!
!  29-dec-04/anders: coded
!
      use Diagnostics
      use EquationOfState, only: cs20
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      real :: Omega2
      integer :: npar_found
      logical :: lheader, lfirstcall=.true.
!
      intent (in) :: f, fp, ineargrid
      intent (inout) :: df, dfp
!
!  Print out header information in first time step.
!
      lheader=lfirstcall .and. lroot
      if (lheader) then
        print*,'dvvp_dt: Calculate dvvp_dt'
      endif
!
!  Add Coriolis force from rotating coordinate frame.
!
      if (Omega/=0.) then
        if (lcoriolis_force_par) then
          if (lheader) print*,'dvvp_dt: Add Coriolis force; Omega=', Omega
          Omega2=2*Omega
          if (.not.lspherical_coords) then
            dfp(1:npar_loc,ivpx) = dfp(1:npar_loc,ivpx) + &
                Omega2*fp(1:npar_loc,ivpy)
            dfp(1:npar_loc,ivpy) = dfp(1:npar_loc,ivpy) - &
                Omega2*fp(1:npar_loc,ivpx)
          else
            print*,'dvvp_dt: Coriolis force on the particles is '
            print*,'not yet implemented for spherical coordinates.'
            call fatal_error('dvvp_dt','')
          endif
        endif
!
!  Add centrifugal force.
!
        if (lcentrifugal_force_par) then
          if (lheader) print*,'dvvp_dt: Add Centrifugal force; Omega=', Omega
          if (lcartesian_coords) then
!
            dfp(1:npar_loc,ivpx) = dfp(1:npar_loc,ivpx) + &
                Omega**2*fp(1:npar_loc,ixp)
!
            dfp(1:npar_loc,ivpy) = dfp(1:npar_loc,ivpy) + &
                Omega**2*fp(1:npar_loc,iyp)
!
          elseif (lcylindrical_coords) then
            dfp(1:npar_loc,ivpx) = &
                dfp(1:npar_loc,ivpx) + Omega**2*fp(1:npar_loc,ixp)
          else
            print*,'dvvp_dt: Centrifugal force on the particles is '
            print*,'not implemented for spherical coordinates.'
            call fatal_error('dvvp_dt','')
          endif
        endif
!
!  With shear there is an extra term due to the background shear flow.
!
        if (lshear) dfp(1:npar_loc,ivpy) = &
            dfp(1:npar_loc,ivpy) + qshear*Omega*fp(1:npar_loc,ivpx)
      endif
!
!  Diagnostic output
!
      if (ldiagnos) then
        if (idiag_nparmin/=0) call max_name(-npar_loc,idiag_nparmin,lneg=.true.)
        if (idiag_nparmax/=0) call max_name(+npar_loc,idiag_nparmax)
        if (idiag_nparpmax/=0) call max_name(maxval(npar_imn),idiag_nparpmax)
        if (idiag_xpm/=0)  call sum_par_name(fp(1:npar_loc,ixp),idiag_xpm)
        if (idiag_ypm/=0)  call sum_par_name(fp(1:npar_loc,iyp),idiag_ypm)
        if (idiag_zpm/=0)  call sum_par_name(fp(1:npar_loc,izp),idiag_zpm)
        if (idiag_xp2m/=0) call sum_par_name(fp(1:npar_loc,ixp)**2,idiag_xp2m)
        if (idiag_yp2m/=0) call sum_par_name(fp(1:npar_loc,iyp)**2,idiag_yp2m)
        if (idiag_zp2m/=0) call sum_par_name(fp(1:npar_loc,izp)**2,idiag_zp2m)
        if (idiag_rpm/=0)  call sum_par_name(sqrt(fp(1:npar_loc,ixp)**2+ &
            fp(1:npar_loc,iyp)**2+fp(1:npar_loc,izp)**2),idiag_rpm)
        if (idiag_rp2m/=0) call sum_par_name(fp(1:npar_loc,ixp)**2+ &
            fp(1:npar_loc,iyp)**2+fp(1:npar_loc,izp)**2,idiag_rp2m)
        if (idiag_vpxm/=0) call sum_par_name(fp(1:npar_loc,ivpx),idiag_vpxm)
        if (idiag_vpym/=0) call sum_par_name(fp(1:npar_loc,ivpy),idiag_vpym)
        if (idiag_vpzm/=0) call sum_par_name(fp(1:npar_loc,ivpz),idiag_vpzm)
        if (idiag_vpxvpym/=0) call sum_par_name( &
            fp(1:npar_loc,ivpx)*fp(1:npar_loc,ivpy),idiag_vpxvpym)
        if (idiag_vpxvpzm/=0) call sum_par_name( &
            fp(1:npar_loc,ivpx)*fp(1:npar_loc,ivpz),idiag_vpxvpzm)
        if (idiag_vpyvpzm/=0) call sum_par_name( &
            fp(1:npar_loc,ivpy)*fp(1:npar_loc,ivpz),idiag_vpyvpzm)
        if (idiag_lpxm/=0) call sum_par_name( &
            fp(1:npar_loc,iyp)*fp(1:npar_loc,ivpz)- &
            fp(1:npar_loc,izp)*fp(1:npar_loc,ivpy),idiag_lpxm)
        if (idiag_lpym/=0) call sum_par_name( &
            fp(1:npar_loc,izp)*fp(1:npar_loc,ivpx)- &
            fp(1:npar_loc,ixp)*fp(1:npar_loc,ivpz),idiag_lpym)
        if (idiag_lpzm/=0) call sum_par_name( &
            fp(1:npar_loc,ixp)*fp(1:npar_loc,ivpy)- &
            fp(1:npar_loc,iyp)*fp(1:npar_loc,ivpx),idiag_lpzm)
        if (idiag_lpx2m/=0) call sum_par_name( &
            (fp(1:npar_loc,iyp)*fp(1:npar_loc,ivpz)- &
            fp(1:npar_loc,izp)*fp(1:npar_loc,ivpy))**2,idiag_lpx2m)
        if (idiag_lpy2m/=0) call sum_par_name( &
            (fp(1:npar_loc,izp)*fp(1:npar_loc,ivpx)- &
            fp(1:npar_loc,ixp)*fp(1:npar_loc,ivpz))**2,idiag_lpy2m)
        if (idiag_lpz2m/=0) call sum_par_name( &
            (fp(1:npar_loc,ixp)*fp(1:npar_loc,ivpy)- &
            fp(1:npar_loc,iyp)*fp(1:npar_loc,ivpx))**2,idiag_lpz2m)
        if (idiag_vpx2m/=0) &
            call sum_par_name(fp(1:npar_loc,ivpx)**2,idiag_vpx2m)
        if (idiag_vpy2m/=0) &
            call sum_par_name(fp(1:npar_loc,ivpy)**2,idiag_vpy2m)
        if (idiag_vpz2m/=0) &
            call sum_par_name(fp(1:npar_loc,ivpz)**2,idiag_vpz2m)
        if (idiag_vprms/=0) &
            call sum_par_name((fp(1:npar_loc,ivpx)**2 &
                              +fp(1:npar_loc,ivpy)**2 &
                              +fp(1:npar_loc,ivpz)**2),idiag_vprms,lsqrt=.true.)
        if (idiag_vpyfull2m/=0) &
            call sum_par_name((fp(1:npar_loc,ivpy)- &
            qshear*Omega*fp(1:npar_loc,ixp))**2,idiag_vpyfull2m)
        if (idiag_ekinp/=0) then
          if (lparticles_density) then
            call sum_par_name(0.5*fp(1:npar_loc,irhopswarm)* &
                sum(fp(1:npar_loc,ivpx:ivpz)**2,dim=2),idiag_ekinp)
          else
            call sum_par_name(0.5*(fp(1:npar_loc,ivpx)**2 &
                              +fp(1:npar_loc,ivpy)**2 &
                              +fp(1:npar_loc,ivpz)**2),idiag_ekinp)
          endif
        endif
        if (idiag_vpmax/=0) call max_par_name( &
            sqrt(sum(fp(1:npar_loc,ivpx:ivpz)**2,2)),idiag_vpmax)
        if (idiag_vpxmax/=0) call max_par_name(fp(1:npar_loc,ivpx),idiag_vpxmax)
        if (idiag_vpymax/=0) call max_par_name(fp(1:npar_loc,ivpy),idiag_vpymax)
        if (idiag_vpzmax/=0) call max_par_name(fp(1:npar_loc,ivpz),idiag_vpzmax)
        if (idiag_rhopvpxm/=0) then
          if (lparticles_density) then
            call sum_par_name(fp(1:npar_loc,irhopswarm)*fp(1:npar_loc,ivpx), &
                idiag_rhopvpxm)
          elseif (lparticles_radius.and.lparticles_number) then
            call sum_par_name(four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)* &
                fp(1:npar_loc,ivpx),idiag_rhopvpxm)
          endif
        endif
        if (idiag_rhopvpym/=0) then
          if (lparticles_density) then
            call sum_par_name(fp(1:npar_loc,irhopswarm)*fp(1:npar_loc,ivpy), &
                idiag_rhopvpym)
          elseif (lparticles_radius.and.lparticles_number) then
            call sum_par_name(four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)* &
                fp(1:npar_loc,ivpy),idiag_rhopvpym)
          endif
        endif
        if (idiag_rhopvpzm/=0) then
          if (lparticles_density) then
            call sum_par_name(fp(1:npar_loc,irhopswarm)*fp(1:npar_loc,ivpz), &
                idiag_rhopvpzm)
          elseif (lparticles_radius.and.lparticles_number) then
            call sum_par_name(four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)* &
                fp(1:npar_loc,ivpz),idiag_rhopvpzm)
          endif
        endif
        if (idiag_rhopvpxt/=0) then
          if (lparticles_density) then
            call integrate_par_name(fp(1:npar_loc,irhopswarm)* &
                fp(1:npar_loc,ivpx),idiag_rhopvpxt)
          elseif (lparticles_radius.and.lparticles_number) then
            call integrate_par_name(four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)* &
                fp(1:npar_loc,ivpx),idiag_rhopvpxt)
          endif
        endif
        if (idiag_rhopvpyt/=0) then
          if (lparticles_density) then
            call integrate_par_name(fp(1:npar_loc,irhopswarm)* &
                fp(1:npar_loc,ivpy),idiag_rhopvpyt)
          elseif (lparticles_radius.and.lparticles_number) then
            call integrate_par_name(four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)* &
                fp(1:npar_loc,ivpy),idiag_rhopvpyt)
          endif
        endif
        if (idiag_rhopvpzt/=0) then
          if (lparticles_density) then
            call integrate_par_name(fp(1:npar_loc,irhopswarm)* &
                fp(1:npar_loc,ivpz),idiag_rhopvpzt)
          elseif (lparticles_radius.and.lparticles_number) then
            call integrate_par_name(four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)* &
                fp(1:npar_loc,ivpz),idiag_rhopvpzt)
          endif
        endif
        if (idiag_rhopvpysm/=0) then
          if (lparticles_density) then
            call sum_par_name(fp(1:npar_loc,irhopswarm)* &
                Sshear*fp(1:npar_loc,ixp),idiag_rhopvpysm)
          elseif (lparticles_radius.and.lparticles_number) then
            call sum_par_name(four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)* &
                Sshear*fp(1:npar_loc,ixp),idiag_rhopvpysm)
          endif
        endif
        if (idiag_mpt/=0) then
          if (lparticles_density) then
            call integrate_par_name((/fp(1:npar_loc,irhopswarm)/),idiag_mpt)
          elseif (lparticles_radius.and.lparticles_number) then
            call integrate_par_name((/four_pi_rhopmat_over_three* &
                fp(1:npar_loc,iap)**3*fp(1:npar_loc,inpswarm)/),idiag_mpt)
          endif
        endif
        if (idiag_npargone/=0) then
          call count_particles(ipar,npar_found)
          call save_name(float(npar-npar_found),idiag_npargone)
        endif
        if (idiag_deshearbcsm/=0) then
          call sum_name(energy_gain_shear_bcs/npar,idiag_deshearbcsm)
        endif
      endif
!
      if (lfirstcall) lfirstcall=.false.
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine dvvp_dt
!***********************************************************************
    subroutine dxxp_dt_pencil(f,df,fp,dfp,p,ineargrid)
!
!  Evolution of particle position (called from main pencil loop).
!
!  25-apr-06/anders: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      type (pencil_case) :: p
      integer, dimension (mpar_loc,3) :: ineargrid
!
      integer :: k, ix0, iy0, iz0
      real :: dt1_advpx, dt1_advpy, dt1_advpz
      logical :: lnbody
!
!  Contribution of dust particles to time step.
!
      if (lfirst.and.ldt) then
        if (npar_imn(imn)/=0) then
          do k=k1_imn(imn),k2_imn(imn)
            lnbody=(lparticles_nbody.and.any(ipar(k)==ipar_nbody))
            if (.not.lnbody) then
              ix0=ineargrid(k,1); iy0=ineargrid(k,2); iz0=ineargrid(k,3)
              dt1_advpx=abs(fp(k,ivpx))*dx_1(ix0)
              if (lshear) then
                dt1_advpy=(-qshear*Omega*fp(k,ixp)+abs(fp(k,ivpy)))*dy_1(iy0)
              else
                dt1_advpy=abs(fp(k,ivpy))*dy_1(iy0)
              endif
              dt1_advpz=abs(fp(k,ivpz))*dz_1(iz0)
              dt1_max(ix0-nghost)=max(dt1_max(ix0-nghost), &
                   sqrt(dt1_advpx**2+dt1_advpy**2+dt1_advpz**2)/cdtp)
            endif
          enddo
        endif
      endif
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(dfp)
      call keep_compiler_quiet(p)
!
    endsubroutine dxxp_dt_pencil
!***********************************************************************
    subroutine dvvp_dt_pencil(f,df,fp,dfp,p,ineargrid)
!
!  Evolution of dust particle velocity (called from main pencil loop).
!
!  25-apr-06/anders: coded
!
      use Diagnostics
      use EquationOfState, only: cs20
      use Sub, only: cross
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension (mpar_loc,3) :: ineargrid
      real :: vsqr
      real, dimension (3) :: uup,accn,interparticle_accn,velocity,fmagnetic
      real,save :: vsqr_max=0.
      integer :: ix0,iy0,iz0,k
      real :: Vij
!
      intent (inout) :: f, df, dfp, fp, ineargrid
!
!  Identify module.
!
      if (headtt) then
        if (lroot) print*,'dvvp_dt_pencil: calculate dvvp_dt'
      endif
!
      if (npar_imn(imn)/=0) then
!
!  Loop over all particles in current pencil.
!
        do k=k1_imn(imn),k2_imn(imn)
!
          ix0=ineargrid(k,1)
          iy0=ineargrid(k,2)
          iz0=ineargrid(k,3)
!
!  The interpolated gas velocity is either precalculated, and stored in
!  interp_uu, or it must be calculated here.
!
          if (lflowdrag) then
            call interpolate_linear(f,iux,iuz,fp(k,ixp:izp), uup,ineargrid(k,:),0,ipar(k))
            accn = tausp1*(uup-fp(k,ivpx:ivpz))
          endif
!
          call get_interparticle_accn(fp,f,k,ineargrid,interparticle_accn,Vij)
          dfp(k,ivpx:ivpz) = dfp(k,ivpx:ivpz) + accn + interparticle_accn
          write(*,*) 'DM,ipaccn',interparticle_accn
        enddo
!
!  No particles in this pencil.
!
      endif
!
!  Diagnostic output.
!
      if (ldiagnos) then
        if (idiag_npm/=0)      call sum_mn_name(p%np,idiag_npm)
        if (idiag_np2m/=0)     call sum_mn_name(p%np**2,idiag_np2m)
        if (idiag_npmax/=0)    call max_mn_name(p%np,idiag_npmax)
        if (idiag_npmin/=0)    call max_mn_name(-p%np,idiag_npmin,lneg=.true.)
        if (idiag_rhopm/=0)    call sum_mn_name(p%rhop,idiag_rhopm)
        if (idiag_rhop2m/=0 )  call sum_mn_name(p%rhop**2,idiag_rhop2m)
        if (idiag_rhoprms/=0)  call sum_mn_name(p%rhop**2,idiag_rhoprms,lsqrt=.true.)
        if (idiag_rhopmax/=0)  call max_mn_name(p%rhop,idiag_rhopmax)
        if (idiag_rhopmin/=0)  call max_mn_name(-p%rhop,idiag_rhopmin,lneg=.true.)
        if (idiag_epspmax/=0)  call max_mn_name(p%epsp,idiag_epspmax)
        if (idiag_epspmin/=0)  call max_mn_name(-p%epsp,idiag_epspmin,lneg=.true.)
        if (idiag_dvpx2m/=0 .or. idiag_dvpx2m/=0 .or. idiag_dvpx2m/=0 .or. &
            idiag_dvpm  /=0 .or. idiag_dvpmax/=0) &
            call calculate_rms_speed(fp,ineargrid,p)
!        if (idiag_dtdragp/=0.and.(lfirst.and.ldt))  &
!            call max_mn_name(dt1_drag,idiag_dtdragp,l_dt=.true.)
      endif
!
!  1d-averages. Happens at every it1d timesteps, NOT at every it1
!
      if (l1davgfirst) then
        if (idiag_npmx/=0)    call yzsum_mn_name_x(p%np,idiag_npmx)
        if (idiag_npmy/=0)    call xzsum_mn_name_y(p%np,idiag_npmy)
        if (idiag_npmz/=0)    call xysum_mn_name_z(p%np,idiag_npmz)
        if (idiag_rhopmx/=0)  call yzsum_mn_name_x(p%rhop,idiag_rhopmx)
        if (idiag_rhopmy/=0)  call xzsum_mn_name_y(p%rhop,idiag_rhopmy)
        if (idiag_rhopmz/=0)  call xysum_mn_name_z(p%rhop,idiag_rhopmz)
        if (idiag_epspmx/=0)  call yzsum_mn_name_x(p%epsp,idiag_epspmx)
        if (idiag_epspmy/=0)  call xzsum_mn_name_y(p%epsp,idiag_epspmy)
        if (idiag_epspmz/=0)  call xysum_mn_name_z(p%epsp,idiag_epspmz)
        if (idiag_rhopmr/=0)  call phizsum_mn_name_r(p%rhop,idiag_rhopmr)
      endif
!
      if (l2davgfirst) then
        if (idiag_npmxy/=0)    call zsum_mn_name_xy(p%np,idiag_npmxy)
        if (idiag_rhopmphi/=0) call phisum_mn_name_rz(p%rhop,idiag_rhopmphi)
        if (idiag_rhopmxy/=0)  call zsum_mn_name_xy(p%rhop,idiag_rhopmxy)
        if (idiag_rhopmxz/=0)  call ysum_mn_name_xz(p%rhop,idiag_rhopmxz)
      endif
!
!  particle-particle separation and relative velocity diagnostics
!
      if (lparticles_diagnos_dv .and. lfirstpoint .and. lfirst) then
        if (t > t_nextcol) call collisions(fp)
      endif
!
    endsubroutine dvvp_dt_pencil
!***********************************************************************
    subroutine dxxp_dt_blocks(f,df,fp,dfp,ineargrid)
!
!  Evolution of particle position in blocks.
!
!  29-nov-09/anders: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(fp)
      call keep_compiler_quiet(dfp)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine dxxp_dt_blocks
!***********************************************************************
    subroutine dvvp_dt_blocks(f,df,fp,dfp,ineargrid)
!
!  Evolution of particle velocity in blocks.
!
!  29-nov-09/anders: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(fp)
      call keep_compiler_quiet(dfp)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine dvvp_dt_blocks
!***********************************************************************
    subroutine get_interparticle_accn(fp,f,k,ineargrid,interparticle_accn,Vij)
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mpar_loc,mparray) :: fp
      integer, dimension (mpar_loc,3) :: ineargrid
      integer :: k
      integer :: ineighbour,kneighbour,nindex
      real :: Vij
      real,dimension(3) :: unit_vector,interparticle_accn,force_ij
      real :: xi,yi,zi,xj,yj,zj,rij_sqr,force
      integer :: ll,mm,nn,startp,endp,ip,ix0,iy0,iz0
!
      xi=fp(k,ixp);yi=fp(k,iyp);zi=fp(k,izp);
      ix0=ineargrid(k,1);iy0=ineargrid(k,2);iz0=ineargrid(k,3);
      interparticle_accn=0.
      do nn=-sigma_in_grid,sigma_in_grid
        do mm=-sigma_in_grid,sigma_in_grid
          do ll=-sigma_in_grid,sigma_in_grid
            startp=int(f(ix0+ll,iy0+mm,iz0+nn,iinvgrid))
            endp=int(f(ix0+ll,iy0+mm,iz0+nn,iinvgrid+1))
!            write(*,*) 'out:startp,endp,k,ip',startp,endp,k,ip
            do ip=startp,endp
              if ((ip.ne.k).and.(ip.ne.0)) then 
                xj=fp(ip,ixp);yj=fp(ip,iyp);zj=fp(ip,izp);
                unit_vector(1)=xj-xi
                unit_vector(2)=yj-yi
                unit_vector(3)=zj-zi
                write(*,*)'DM unitvector',unit_vector
                write(*,*) 'startp,endp,k,ip',startp,endp,k,ip
                write(*,*) 'DM fp1',fp(k,:)
                write(*,*) 'DM ip',xi,yi,zi
                write(*,*) 'DM fp2',fp(ip,:)
                write(*,*) 'DM jp',xj,yj,zj
                rij_sqr=(xi-xj)**2+(yi-yj)**2+(zi-zj)**2
                call get_interaction_force(rij_sqr,force,Vij)
                force_ij=force*unit_vector
! Note : This assumes that the mass of the particles are unity. If we use
! particles_density with this module then we need to change here
!
                interparticle_accn=interparticle_accn+force_ij
              endif
            enddo
          enddo
        enddo
      enddo
!
    endsubroutine get_interparticle_accn
!***********************************************************************
    subroutine get_interaction_force(rij_sqr,force,Vij)
!
!  calculates the force due to interparticle interaction
!
      real :: rij_sqr
      real :: sigma,xi_sqr,force,Vij
!
!Note : there are two powers of 1/r in the force compared to the potential
! one is due to radial derivative the other because we have not multiplied by
! 1/r while calculating the unit vector.
!Note :  While calculating the force we have assumed that the interparticle potential
! is given as a function of (r/sigma) where sigma is the particle
! radius. If we use the particle_radius module we need to change the calculation of
! sigma below
!
      sigma=psigma_by_dx*dx
      xi_sqr=rij_sqr/(sigma**2)
      select case (ppotential)
      case ('rep-power-law')
!
! repulsive power law
!
        force=pampl*(2*ppowerby2/sigma**2)*(1./xi_sqr**(ppowerby2+1))
        Vij = pampl*(1./xi_sqr**(ppowerby2))
      case default
        call fatal_error('particles_potential: no potential coded ','get_interaction_force')
      endselect
!
    endsubroutine get_interaction_force
!***********************************************************************
!    subroutine update_neighbour_list(fp)
!
!  Update the neighbour list for all the particles
!
!      real, dimension (mpar_loc,mparray) :: fp
!      integer :: k,kneighbour,kn
!      real :: xi,yi,zi,xj,yj,zj,rij_sqr
!      integer :: jp
!
! Go through the whole array fp to find the neighbours
!
!      do ip=1,npar_loc
!
! The coordinate of the particle in question
!
!        xi=fp(ip,ixp)
!        yi=fp(ip,iyp)
!        zi=fp(ip,izp)
!        kn=1
!        neighbour_list(ip,:) = 0.
!!
! Now loop over mpar_loc number of particles. This is of course very time consuming.
! This can be improved upon.
!
!        do jp=1,mpar_loc
!
! The neighbourlist cannot include the particle itself
!
!          if (jp .ne. ip) then
!            xj=fp(jp,ixp)
!            yj=fp(jp,iyp)
!            zj=fp(jp,izp)
!            rij_sqr=(xj-xi)**2+(yj-yi)**2+(zj-zi)**2
!            if (rij_sqr <= (skin_factor*psigma)**2) then
! If the distance of between the particles are less than a skin_factor multiplied by the
! effective radius (psigma) of the particles then they are included in the neighbour list
!              kn=kn+1
!              neighbour_list(ip,kn)=jp
!            endif
!          endif
!        enddo
!        neighbour_list(ip,1)=kn-1
!      enddo
!
!    endsubroutine update_neighbour_list
!***********************************************************************
    subroutine remove_particles_sink_simple(f,fp,dfp,ineargrid)
!
!  Subroutine for taking particles out of the simulation due to their proximity
!  to a sink particle or sink point.
!
!  25-sep-08/anders: coded
!
      use Mpicomm
      use Solid_Cells
!
      real, dimension(mx,my,mz,mfarray) :: f
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension(mpar_loc,3) :: ineargrid
!
      real, dimension(3) :: momp_swarm_removed, momp_swarm_removed_send
      real :: rp, rp_box, rhop_swarm_removed, rhop_swarm_removed_send
      real :: xsinkpar, ysinkpar, zsinkpar
      integer :: k, ksink, iproc_sink, iproc_sink_send
      integer :: ix, ix1, ix2, iy, iy1, iy2, iz, iz1, iz2
      integer, parameter :: itag1=100, itag2=101
      real :: particle_radius
!
      call keep_compiler_quiet(f)
!
    endsubroutine remove_particles_sink_simple
!***********************************************************************
    subroutine create_particles_sink_simple(f,fp,dfp,ineargrid)
!
!  Subroutine for creating new sink particles or sink points.
!
!  Just a dummy routine for now.
!
!  25-sep-08/anders: coded
!
      real, dimension(mx,my,mz,mfarray) :: f
      real, dimension (mpar_loc,mparray) :: fp
      real, dimension (mpar_loc,mpvar) :: dfp
      integer, dimension(mpar_loc,3) :: ineargrid
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(fp)
      call keep_compiler_quiet(dfp)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine create_particles_sink_simple
!***********************************************************************


!***********************************************************************

!***********************************************************************
    subroutine calculate_rms_speed(fp,ineargrid,p)
!
      use Diagnostics
!
!  Calculate the rms speed dvpm=sqrt(<(vvp-<vvp>)^2>) of the
!  particle for diagnostic purposes
!
!  08-04-08/wlad: coded
!
      real, dimension (mpar_loc,mparray) :: fp
      integer, dimension (mpar_loc,3) :: ineargrid
      real,dimension(nx,3) :: vvpm,dvp2m
      integer :: inx0,k,l
      type (pencil_case) :: p
      logical :: lnbody
!
!  Initialize the variables
!
      vvpm=0.0; dvp2m=0.0
!
!  Calculate the average velocity at each cell
!  if there are particles in the pencil only
!
      if (npar_imn(imn)/=0) then
!
        do k=k1_imn(imn),k2_imn(imn)
          lnbody=any(ipar(k)==ipar_nbody)
          if (.not.lnbody) then
            inx0=ineargrid(k,1)-nghost
            vvpm(inx0,:) = vvpm(inx0,:) + fp(k,ivpx:ivpz)
          endif
        enddo
        do l=1,nx
          if (p%np(l)>1.0) vvpm(l,:)=vvpm(l,:)/p%np(l)
        enddo
!
!  Get the residual in quadrature, dvp2m. Need vvpm calculated above.
!
        do k=k1_imn(imn),k2_imn(imn)
          lnbody=any(ipar(k)==ipar_nbody)
          if (.not.lnbody) then
            inx0=ineargrid(k,1)-nghost
            dvp2m(inx0,1)=dvp2m(inx0,1)+(fp(k,ivpx)-vvpm(inx0,1))**2
            dvp2m(inx0,2)=dvp2m(inx0,2)+(fp(k,ivpy)-vvpm(inx0,2))**2
            dvp2m(inx0,3)=dvp2m(inx0,3)+(fp(k,ivpz)-vvpm(inx0,3))**2
          endif
        enddo
        do l=1,nx
          if (p%np(l)>1.0) dvp2m(l,:)=dvp2m(l,:)/p%np(l)
        enddo
!
      endif
!
!  Output the diagnostics
!
      if (idiag_dvpx2m/=0) call sum_mn_name(dvp2m(:,1),idiag_dvpx2m)
      if (idiag_dvpy2m/=0) call sum_mn_name(dvp2m(:,2),idiag_dvpy2m)
      if (idiag_dvpz2m/=0) call sum_mn_name(dvp2m(:,3),idiag_dvpz2m)
      if (idiag_dvpm/=0)   call sum_mn_name(dvp2m(:,1)+dvp2m(:,2)+dvp2m(:,3),&
                                            idiag_dvpm,lsqrt=.true.)
      if (idiag_dvpmax/=0) call max_mn_name(dvp2m(:,1)+dvp2m(:,2)+dvp2m(:,3),&
                                            idiag_dvpmax,lsqrt=.true.)
!
    endsubroutine calculate_rms_speed
!***********************************************************************
    subroutine read_particles_init_pars(iostat)
!
      use File_io, only: parallel_unit
!
      integer, intent(out) :: iostat
!
      read(parallel_unit, NML=particles_init_pars, IOSTAT=iostat)
!
    endsubroutine read_particles_init_pars
!***********************************************************************
    subroutine write_particles_init_pars(unit)
!
      integer, intent(in) :: unit
!
      write(unit, NML=particles_init_pars)
!
    endsubroutine write_particles_init_pars
!***********************************************************************
    subroutine read_particles_run_pars(iostat)
!
      use File_io, only: parallel_unit
!
      integer, intent(out) :: iostat
!
      read(parallel_unit, NML=particles_run_pars, IOSTAT=iostat)
!
    endsubroutine read_particles_run_pars
!***********************************************************************
    subroutine write_particles_run_pars(unit)
!
      integer, intent(in) :: unit
!
      write(unit, NML=particles_run_pars)
!
    endsubroutine write_particles_run_pars
!***********************************************************************
    subroutine powersnap_particles(f)
!
!  Calculate power spectra of dust particle variables.
!
!  01-jan-06/anders: coded
!
      use Power_spectrum, only: power_1d
!
      real, dimension (mx,my,mz,mfarray) :: f
!
      if (lpar_spec) call power_1d(f,'p',0,irhop)
!
    endsubroutine powersnap_particles
!***********************************************************************
    subroutine rprint_particles(lreset,lwrite)
!
!  Read and register print parameters relevant for particles.
!
!  29-dec-04/anders: coded
!
      use Diagnostics
!
      logical :: lreset
      logical, optional :: lwrite
!
      integer :: iname,inamez,inamey,inamex,inamexy,inamexz,inamer,inamerz
      logical :: lwr
!
!  Write information to index.pro.
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
      if (lwr) then
        write(3,*) 'ixp=', ixp
        write(3,*) 'iyp=', iyp
        write(3,*) 'izp=', izp
        write(3,*) 'ivpx=', ivpx
        write(3,*) 'ivpy=', ivpy
        write(3,*) 'ivpz=', ivpz
        write(3,*) 'inp=', inp
        write(3,*) 'irhop=', irhop
        write(3,*) 'iupx=', iupx
        write(3,*) 'iupy=', iupy
        write(3,*) 'iupz=', iupz
      endif
!
!  Reset everything in case of reset.
!
      if (lreset) then
        idiag_xpm=0; idiag_ypm=0; idiag_zpm=0
        idiag_xp2m=0; idiag_yp2m=0; idiag_zp2m=0; idiag_rpm=0; idiag_rp2m=0
        idiag_vpxm=0; idiag_vpym=0; idiag_vpzm=0
        idiag_vpxvpym=0; idiag_vpxvpzm=0; idiag_vpyvpzm=0
        idiag_vpx2m=0; idiag_vpy2m=0; idiag_vpz2m=0; idiag_ekinp=0
        idiag_vpxmax=0; idiag_vpymax=0; idiag_vpzmax=0; idiag_vpmax=0
        idiag_rhopvpxm=0; idiag_rhopvpym=0; idiag_rhopvpzm=0; idiag_rhopvpysm=0
        idiag_rhopvpxt=0; idiag_rhopvpyt=0; idiag_rhopvpzt=0
        idiag_lpxm=0; idiag_lpym=0; idiag_lpzm=0
        idiag_lpx2m=0; idiag_lpy2m=0; idiag_lpz2m=0
        idiag_npm=0; idiag_np2m=0; idiag_npmax=0; idiag_npmin=0
        idiag_dtdragp=0; idiag_dedragp=0
        idiag_rhopm=0; idiag_rhoprms=0; idiag_rhop2m=0; idiag_rhopmax=0
        idiag_rhopmin=0; idiag_decollp=0; idiag_rhopmphi=0
        idiag_epspmin=0; idiag_epspmax=0
        idiag_nparmin=0; idiag_nparmax=0; idiag_nmigmax=0; idiag_mpt=0
        idiag_npmx=0; idiag_npmy=0; idiag_npmz=0; idiag_epotpm=0
        idiag_rhopmx=0; idiag_rhopmy=0; idiag_rhopmz=0
        idiag_epspmx=0; idiag_epspmy=0; idiag_epspmz=0
        idiag_rhopmxy=0; idiag_rhopmxz=0; idiag_rhopmr=0
        idiag_dvpx2m=0; idiag_dvpy2m=0; idiag_dvpz2m=0
        idiag_dvpmax=0; idiag_dvpm=0; idiag_nparpmax=0
        idiag_eccpxm=0; idiag_eccpym=0; idiag_eccpzm=0
        idiag_eccpx2m=0; idiag_eccpy2m=0; idiag_eccpz2m=0
        idiag_npargone=0; idiag_vpyfull2m=0; idiag_deshearbcsm=0
        idiag_npmxy=0; idiag_vprms=0
      endif
!
!  Run through all possible names that may be listed in print.in.
!
      if (lroot .and. ip<14) print*,'rprint_particles: run through parse list'
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'nparmin',idiag_nparmin)
        call parse_name(iname,cname(iname),cform(iname),'nparmax',idiag_nparmax)
        call parse_name(iname,cname(iname),cform(iname),'nparpmax',idiag_nparpmax)
        call parse_name(iname,cname(iname),cform(iname),'xpm',idiag_xpm)
        call parse_name(iname,cname(iname),cform(iname),'ypm',idiag_ypm)
        call parse_name(iname,cname(iname),cform(iname),'zpm',idiag_zpm)
        call parse_name(iname,cname(iname),cform(iname),'xp2m',idiag_xp2m)
        call parse_name(iname,cname(iname),cform(iname),'yp2m',idiag_yp2m)
        call parse_name(iname,cname(iname),cform(iname),'zp2m',idiag_zp2m)
        call parse_name(iname,cname(iname),cform(iname),'rpm',idiag_rpm)
        call parse_name(iname,cname(iname),cform(iname),'rp2m',idiag_rp2m)
        call parse_name(iname,cname(iname),cform(iname),'vpxm',idiag_vpxm)
        call parse_name(iname,cname(iname),cform(iname),'vpym',idiag_vpym)
        call parse_name(iname,cname(iname),cform(iname),'vpzm',idiag_vpzm)
        call parse_name(iname,cname(iname),cform(iname),'vpxvpym',idiag_vpxvpym)
        call parse_name(iname,cname(iname),cform(iname),'vpxvpzm',idiag_vpxvpzm)
        call parse_name(iname,cname(iname),cform(iname),'vpyvpzm',idiag_vpyvpzm)
        call parse_name(iname,cname(iname),cform(iname),'vpx2m',idiag_vpx2m)
        call parse_name(iname,cname(iname),cform(iname),'vpy2m',idiag_vpy2m)
        call parse_name(iname,cname(iname),cform(iname),'vpz2m',idiag_vpz2m)
        call parse_name(iname,cname(iname),cform(iname),'ekinp',idiag_ekinp)
        call parse_name(iname,cname(iname),cform(iname),'vpxmax',idiag_vpxmax)
        call parse_name(iname,cname(iname),cform(iname),'vpymax',idiag_vpymax)
        call parse_name(iname,cname(iname),cform(iname),'vpzmax',idiag_vpzmax)
        call parse_name(iname,cname(iname),cform(iname),'vpmax',idiag_vpmax)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpxm', &
            idiag_rhopvpxm)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpym', &
            idiag_rhopvpym)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpzm', &
            idiag_rhopvpzm)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpysm', &
            idiag_rhopvpysm)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpxt', &
            idiag_rhopvpxt)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpyt', &
            idiag_rhopvpyt)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpzt', &
            idiag_rhopvpzt)
        call parse_name(iname,cname(iname),cform(iname),'rhopvpysm', &
            idiag_rhopvpysm)
        call parse_name(iname,cname(iname),cform(iname),'lpxm',idiag_lpxm)
        call parse_name(iname,cname(iname),cform(iname),'lpym',idiag_lpym)
        call parse_name(iname,cname(iname),cform(iname),'lpzm',idiag_lpzm)
        call parse_name(iname,cname(iname),cform(iname),'lpx2m',idiag_lpx2m)
        call parse_name(iname,cname(iname),cform(iname),'lpy2m',idiag_lpy2m)
        call parse_name(iname,cname(iname),cform(iname),'lpz2m',idiag_lpz2m)
        call parse_name(iname,cname(iname),cform(iname),'eccpxm',idiag_eccpxm)
        call parse_name(iname,cname(iname),cform(iname),'eccpym',idiag_eccpym)
        call parse_name(iname,cname(iname),cform(iname),'eccpzm',idiag_eccpzm)
        call parse_name(iname,cname(iname),cform(iname),'eccpx2m',idiag_eccpx2m)
        call parse_name(iname,cname(iname),cform(iname),'eccpy2m',idiag_eccpy2m)
        call parse_name(iname,cname(iname),cform(iname),'eccpz2m',idiag_eccpz2m)
        call parse_name(iname,cname(iname),cform(iname),'dtdragp',idiag_dtdragp)
        call parse_name(iname,cname(iname),cform(iname),'npm',idiag_npm)
        call parse_name(iname,cname(iname),cform(iname),'np2m',idiag_np2m)
        call parse_name(iname,cname(iname),cform(iname),'npmax',idiag_npmax)
        call parse_name(iname,cname(iname),cform(iname),'npmin',idiag_npmin)
        call parse_name(iname,cname(iname),cform(iname),'rhopm',idiag_rhopm)
        call parse_name(iname,cname(iname),cform(iname),'rhoprms',idiag_rhoprms)
        call parse_name(iname,cname(iname),cform(iname),'rhop2m',idiag_rhop2m)
        call parse_name(iname,cname(iname),cform(iname),'rhopmin',idiag_rhopmin)
        call parse_name(iname,cname(iname),cform(iname),'rhopmax',idiag_rhopmax)
        call parse_name(iname,cname(iname),cform(iname),'epspmin',idiag_epspmin)
        call parse_name(iname,cname(iname),cform(iname),'epspmax',idiag_epspmax)
        call parse_name(iname,cname(iname),cform(iname),'rhopmphi',idiag_rhopmphi)
        call parse_name(iname,cname(iname),cform(iname),'nmigmax',idiag_nmigmax)
        call parse_name(iname,cname(iname),cform(iname),'mpt',idiag_mpt)
        call parse_name(iname,cname(iname),cform(iname),'dvpx2m',idiag_dvpx2m)
        call parse_name(iname,cname(iname),cform(iname),'dvpy2m',idiag_dvpy2m)
        call parse_name(iname,cname(iname),cform(iname),'dvpz2m',idiag_dvpz2m)
        call parse_name(iname,cname(iname),cform(iname),'dvpm',idiag_dvpm)
        call parse_name(iname,cname(iname),cform(iname),'dvpmax',idiag_dvpmax)
        call parse_name(iname,cname(iname),cform(iname), &
            'dedragp',idiag_dedragp)
        call parse_name(iname,cname(iname),cform(iname), &
            'decollp',idiag_decollp)
        call parse_name(iname,cname(iname),cform(iname), &
            'epotpm',idiag_epotpm)
        call parse_name(iname,cname(iname),cform(iname), &
            'npargone',idiag_npargone)
        call parse_name(iname,cname(iname),cform(iname), &
            'vpyfull2m',idiag_vpyfull2m)
        call parse_name(iname,cname(iname),cform(iname),'vprms',idiag_vprms)
        call parse_name(iname,cname(iname),cform(iname), &
            'deshearbcsm',idiag_deshearbcsm)
      enddo
!
!  Check for those quantities for which we want x-averages.
!
      do inamex=1,nnamex
        call parse_name(inamex,cnamex(inamex),cformx(inamex),'npmx',idiag_npmx)
        call parse_name(inamex,cnamex(inamex),cformx(inamex),'rhopmx',idiag_rhopmx)
        call parse_name(inamex,cnamex(inamex),cformx(inamex),'epspmx',idiag_epspmx)
      enddo
!
!  Check for those quantities for which we want y-averages.
!
      do inamey=1,nnamey
        call parse_name(inamey,cnamey(inamey),cformy(inamey),'npmy',idiag_npmy)
        call parse_name(inamey,cnamey(inamey),cformy(inamey),'rhopmy',idiag_npmy)
        call parse_name(inamey,cnamey(inamey),cformy(inamey),'epspmy',idiag_epspmy)
      enddo
!
!  Check for those quantities for which we want z-averages.
!
      do inamez=1,nnamez
        call parse_name(inamez,cnamez(inamez),cformz(inamez),'npmz',idiag_npmz)
        call parse_name(inamez,cnamez(inamez),cformz(inamez),'rhopmz',idiag_rhopmz)
        call parse_name(inamez,cnamez(inamez),cformz(inamez),'epspmz',idiag_epspmz)
      enddo
!
!  Check for those quantities for which we want xy-averages.
!
      do inamexy=1,nnamexy
        call parse_name(inamexy,cnamexy(inamexy),cformxy(inamexy),'npmxy',idiag_npmxy)
        call parse_name(inamexy,cnamexy(inamexy),cformxy(inamexy),'rhopmxy',idiag_rhopmxy)
      enddo
!
!  Check for those quantities for which we want xz-averages.
!
      do inamexz=1,nnamexz
        call parse_name(inamexz,cnamexz(inamexz),cformxz(inamexz),'rhopmxz',idiag_rhopmxz)
      enddo
!
!  Check for those quantities for which we want phiz-averages.
!
      do inamer=1,nnamer
        call parse_name(inamer,cnamer(inamer),cformr(inamer),'rhopmr',idiag_rhopmr)
      enddo
!
!  Check for those quantities for which we want phi-averages.
!
      do inamerz=1,nnamerz
        call parse_name(inamerz,cnamerz(inamerz),cformrz(inamerz),'rhopmphi',idiag_rhopmphi)
      enddo
!
    endsubroutine rprint_particles
!***********************************************************************
    subroutine periodic_boundcond_on_aux(f)
!
! Impose periodic boundary condition on bb and EE
!
      use Boundcond, only: set_periodic_boundcond_on_aux
      real, dimension(mx,my,mz,mfarray), intent(in) :: f

! dummy
      call keep_compiler_quiet(f)
    endsubroutine periodic_boundcond_on_aux
!***********************************************************************
    subroutine list_particles_near_boundary(fp)
!
!  Makes a list of properties of the particles close to processor boundaries.
! These information about these particles must be communicated to processors
! who share those boundaries. This subroutine is useless in a single processor
! hence does nothing when a single processor is used; otherwise calls the subroutine
! that actually lists the particles near boundary
!
      real, dimension (mpar_loc,mparray) :: fp

      if (ncpus .ne. 1) then
        call really_list_particles_near_boundary(fp)
      else
        call keep_compiler_quiet(fp)
      endif
    endsubroutine list_particles_near_boundary
!***********************************************************************
    subroutine particles_dragforce_stiff(f,fp,ineargrid)
!
!  10-june-11/anders: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mpar_loc,mparray) :: fp
      integer, dimension (mpar_loc,3) :: ineargrid
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(fp)
      call keep_compiler_quiet(ineargrid)
!
    endsubroutine particles_dragforce_stiff
!***********************************************************************
endmodule Particles
