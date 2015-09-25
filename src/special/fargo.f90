! $Id$
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lspecial = .true.
!
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
!
!***************************************************************
!
!---------------------------------------------------------------
!
! HOW TO USE THIS FILE
!
!---------------------------------------------------------------
!
! The rest of this file may be used as a template for your own
! special module.  Lines which are double commented are intended
! as examples of code.  Simply fill out the prototypes for the
! features you want to use.
!
! Save the file with a meaningful name, eg. geo_kws.f90 and place
! it in the $PENCIL_HOME/src/special directory.  This path has
! been created to allow users ot optionally check their contributions
! in to the Pencil-Code CVS repository.  This may be useful if you
! are working on/using the additional physics with somebodyelse or
! may require some assistance from one of the main Pencil-Code team.
!
! To use your additional physics code edit the Makefile.local in
! the src directory under the run directory in which you wish to
! use your additional physics.  Add a line with all the module
! selections to say something like:
!
!    SPECIAL=special/nstar
!
! Where nstar it replaced by the filename of your new module
! upto and not including the .f90
!
!--------------------------------------------------------------------
!
module Special
!
  use Cparam
  use Cdata
  use General, only: keep_compiler_quiet
  use Messages
!
  implicit none
!
  include '../special.h'
! Global arrays
  real, dimension (nx,nz) :: uu_average
  real, dimension (nx,nz) :: phidot_average
! "pencils"
  real, dimension (nx,3) :: uuadvec_guu,uuadvec_gaa
  real, dimension (nx) :: uuadvec_grho,uuadvec_glnrho,uuadvec_gss
  real, dimension (nx) :: uu_residual
!
  logical :: lno_radial_advection=.false.
  logical :: lfargoadvection_as_shift=.false.
  logical :: lkeplerian_gauge=.false.
  logical :: lremove_volume_average=.false.
!
  real, dimension (nxgrid) :: xgrid1
  real :: nygrid1
!
  namelist /special_run_pars/ lno_radial_advection, lfargoadvection_as_shift,&
       lkeplerian_gauge,lremove_volume_average
!
  integer :: idiag_nshift=0
!
  contains
!
!***********************************************************************
    subroutine register_special()
!
!  Configure pre-initialised (i.e. before parameter read) variables
!  which should be know to be able to evaluate
!
!  6-oct-03/tony: coded
!
      use Cdata
!
      if (lroot) call svn_id( &
           "$Id$")
!
    endsubroutine register_special
!***********************************************************************
    subroutine initialize_special(f)
!
!  called by run.f90 after reading parameters, but before the time loop
!
!  06-oct-03/tony: coded
!
      use Mpicomm, only: stop_it
!
      real, dimension (mx,my,mz,mvar+maux) :: f
!
!  Make it possible to switch the algorithm off while still
!  having this file compiled, for debug purposes.
!
      if (lrun .and. .not. lfargo_advection) then
        if (lroot) then
          print*,""
          print*,"Switch"
          print*," lfargo_advection=T"
          print*,"in init_pars of start.in if you"
          print*,"want to use the fargo algorithm"
          print*,""
        endif
        call warning("initialize_special","")
      endif
!
!  Not implemented for other than cylindrical coordinates
!
      if (lfargo_advection.and.coord_system/='cylindric') then
        if (lroot) then
          print*,""
          print*,"Fargo advection is only implemented for"
          print*,"cylindrical coordinates. Switch"
          print*," coord_system='cylindric'"
          print*,"in init_pars of start.in if you"
          print*,"want to use the fargo algorithm"
          print*,""
        endif
        call fatal_error("initialize_special","")
      endif
!
!  Not implemented for the energy equation either
!
      if (lfargo_advection.and.(pretend_lnTT.or.ltemperature)) &
          call fatal_error("initialize_special","fargo advection not "//&
          "implemented for the temperature equation")
!
!  Stuff that is only calculated once
!
      xgrid1=1./xgrid
      nygrid1=1./nygrid
!
      call keep_compiler_quiet(f)
!
    endsubroutine initialize_special
!***********************************************************************
    subroutine init_special(f)
!
!  initialise special condition; called from start.f90
!  06-oct-2003/tony: coded
!
      use Cdata
      use Mpicomm
!
      real, dimension (mx,my,mz,mvar+maux) :: f
!
      intent(inout) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine init_special
!***********************************************************************
    subroutine pencil_criteria_special()
!
!  All pencils that this special module depends on are specified here.
!
!  18-07-06/tony: coded
!
      if (lfargo_advection) then
!
        lpenc_requested(i_uu)=.true.
!
!  For continuity equation
!
        lpenc_requested(i_divu)=.true.
        if (ldensity_nolog) then
          lpenc_requested(i_grho)=.true.
        else
          lpenc_requested(i_glnrho)=.true.
        endif
!
!  For velocity advection
!
        lpenc_requested(i_uij)=.true.
!
!  For the induction equation
!
        if (lmagnetic) then
          lpenc_requested(i_aa)=.true.
          lpenc_requested(i_aij)=.true.
        endif
!
!  For the entropy equation
!
        if (lentropy) lpenc_requested(i_gss)=.true.
!
      endif
!
    endsubroutine pencil_criteria_special
!***********************************************************************
    subroutine calc_pencils_special(f,p)
!
      use Sub, only: h_dot_grad
!
      real, dimension(mx,my,mz,mfarray) :: f
      real, dimension(nx,3) :: uu_advec,tmp2
      real, dimension(nx) :: tmp
      type (pencil_case) :: p
      integer :: j,nnghost
!
      if (lfargo_advection) then
!
        nnghost=n-nghost
!
! Advect by the relative velocity
!
        uu_residual=p%uu(:,2)-uu_average(:,nnghost)
!
! Advect by the original radial and vertical, but residual azimuthal
!
        uu_advec(:,1)=p%uu(:,1)
        uu_advec(:,2)=uu_residual
        uu_advec(:,3)=p%uu(:,3)
!
!  For the continuity equation
!
        if (ldensity_nolog) then
          call h_dot_grad(uu_advec,p%grho,uuadvec_grho)
        else
          call h_dot_grad(uu_advec,p%glnrho,uuadvec_glnrho)
        endif
!
!  For velocity advection
!
!  Note: It is tempting to use
!
!     call h_dot_grad(uu_advec,p%uij,p%uu,uuadvec_guu)
!
!  instead of the lines coded below, but the line just above
!  would introduce the curvature terms with the residual
!  velocity. Yet the curvature terms do not enter the
!  non-coordinate basis advection that fargo performs.
!  These terms have to be added manually. If one uses
!  h_dot_grad_vec, then the curvature with residual would
!  have to be removed manually and then the full speed
!  added again (for the r-component of uuadvec_guu), like
!  this:
!
!   uuadvec_guu(:,1)=uuadvec_guu(:,1)-&
!      rcyl_mn1*((p%uu(:,2)-uu_advec(:,2))*p%uu(:,2))
!   uuadvec_guu(:,2)=uuadvec_guu(:,2)+&
!      rcyl_mn1*((p%uu(:,1)-uu_advec(:,1))*p%uu(:,2))
!
!
!   Although working (and more line-economically), the
!   piece of code below is more readable in my opinion.
!
        do j=1,3
          call h_dot_grad(uu_advec,p%uij(:,j,:),tmp)
          tmp2(:,j)=tmp
        enddo
        tmp2(:,1)=tmp2(:,1)-rcyl_mn1*p%uu(:,2)*p%uu(:,2)
        tmp2(:,2)=tmp2(:,2)+rcyl_mn1*p%uu(:,1)*p%uu(:,2)
!
        uuadvec_guu=tmp2
!
!  Advection of the magnetic potential
!
        if (lmagnetic) then
          do j=1,3
            call h_dot_grad(uu_advec,p%aij(:,j,:),tmp)
            tmp2(:,j)=tmp
          enddo
          tmp2(:,1)=tmp2(:,1)-rcyl_mn1*p%uu(:,2)*p%aa(:,2)
          tmp2(:,2)=tmp2(:,2)+rcyl_mn1*p%uu(:,1)*p%aa(:,2)
!
          uuadvec_gaa=tmp2
        endif
!
!  Advection of entropy
!
        if (lentropy) &
             call h_dot_grad(uu_advec,p%gss,uuadvec_gss)
!
        call keep_compiler_quiet(f)
!
      endif
!
    endsubroutine calc_pencils_special
!***********************************************************************
    subroutine dspecial_dt(f,df,p)
!
!  Calculate right hand side of ONE OR MORE extra coupled PDEs
!  along the 'current' Pencil, i.e. f(l1:l2,m,n) where
!  m,n are global variables looped over in equ.f90
!
!  Due to the multi-step Runge Kutta timestepping used one MUST always
!  add to the present contents of the df array.  NEVER reset it to zero.
!
!  Several precalculated Pencils of information are passed if for
!  efficiency.
!
!   06-oct-03/tony: coded
!
      use Cdata
      use Diagnostics
      use Mpicomm
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
      integer :: nnghost
      real, dimension (nx) :: nshift,phidot
!
      intent(in) :: f,p
      intent(inout) :: df
!
!  Estimate the shift by nshift=phidot*dt/dy
!  This is just an approximation, since uavg
!  changes from one subtimestep to another, and
!  the correct cumulative shift is
!
!    nshift=0.
!    do itsub=1,3
!       nshift=nshift+phidot*dt_sub/dy
!    enddo
!
!  But it also works fairly well this way, since uavg
!  does not change all that much between subtimesteps.
!
      if (lfargo_advection) then
!
        if (ldiagnos) then
          if (idiag_nshift/=0) then
            nnghost=n-nghost
            phidot=uu_average(:,nnghost)*rcyl_mn1
            nshift=phidot*dt*dy_1(m)
            call max_mn_name(nshift,idiag_nshift)
          endif
        endif
!
        call keep_compiler_quiet(f)
        call keep_compiler_quiet(df)
        call keep_compiler_quiet(p)
!
      endif
!
    endsubroutine dspecial_dt
!***********************************************************************
    subroutine read_special_run_pars(iostat)
!
      use File_io, only: parallel_unit
!
      integer, intent(out) :: iostat
!
      read(parallel_unit, NML=special_run_pars, IOSTAT=iostat)
!
    endsubroutine read_special_run_pars
!***********************************************************************
    subroutine write_special_run_pars(unit)
!
      integer, intent(in) :: unit
!
      write(unit, NML=special_run_pars)
!
    endsubroutine write_special_run_pars
!***********************************************************************
    subroutine rprint_special(lreset,lwrite)
!
      use Diagnostics
!
!  Reads and registers print parameters relevant to special
!
!   06-oct-03/tony: coded
!
      integer :: iname
      logical :: lreset,lwr
      logical, optional :: lwrite
!
!  Write information to index.pro
!
      if (lfargo_advection) then
!
        lwr = .false.
        if (present(lwrite)) lwr=lwrite
!
        if (lreset) then
          idiag_nshift=0
        endif
!
        do iname=1,nname
          call parse_name(iname,cname(iname),cform(iname),'nshift',idiag_nshift)
        enddo
!
        if (lwr) then
          write(3,*) 'i_nshift=',idiag_nshift
        endif
!
      endif
!
    endsubroutine rprint_special
!***********************************************************************
    subroutine special_calc_density(f,df,p)
!
!   Calculate a additional 'special' term on the right hand side of the
!   mass equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-oct-03/tony: coded
!
      use Cdata
      use EquationOfState
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p
!
!  Modified continuity equation
!
      if (lfargo_advection) then
        if (ldensity_nolog) then
          df(l1:l2,m,n,ilnrho) = df(l1:l2,m,n,ilnrho) - &
               uuadvec_grho   - p%rho*p%divu
        else
          df(l1:l2,m,n,ilnrho) = df(l1:l2,m,n,ilnrho) - &
               uuadvec_glnrho - p%divu
        endif
      endif
!
      call keep_compiler_quiet(f)
!
    endsubroutine special_calc_density
!***********************************************************************
    subroutine special_calc_hydro(f,df,p)
!
!   Calculate a additional 'special' term on the right hand side of the
!   momentum equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
      use Cdata
      use Diagnostics
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p
!
!  Modified momentum equation
!
      if (lfargo_advection) then
        df(l1:l2,m,n,iux:iuz)=df(l1:l2,m,n,iux:iuz)-uuadvec_guu
!
!  The lines below are not symmetric. This is on purpose, to better
!  highlight that fargo advects the azimuthal coordinate ONLY!!
!
        if (lfirst.and.ldt) then
          advec_uu=abs(p%uu(:,1))  *dx_1(l1:l2)+ &
                   abs(uu_residual)*dy_1(  m  )*rcyl_mn1+ &
                   abs(p%uu(:,3))  *dz_1(  n  )
        endif
      endif
!
      call keep_compiler_quiet(f)
!
    endsubroutine special_calc_hydro
!***********************************************************************
    subroutine special_calc_magnetic(f,df,p)
!
!   Calculate a additional 'special' term on the right hand side of the
!   induction equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-oct-03/tony: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(inout) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p
!
      if (lfargo_advection) &
           df(l1:l2,m,n,iax:iaz)=df(l1:l2,m,n,iax:iaz)-uuadvec_gaa
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(p)
!
    endsubroutine special_calc_magnetic
!***********************************************************************
    subroutine special_calc_energy(f,df,p)
!
!   Calculate a additional 'special' term on the right hand side of the
!   energy equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-oct-03/tony: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p
!
      if (lfargo_advection) &
           df(l1:l2,m,n,iss)=df(l1:l2,m,n,iss)-uuadvec_gss
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(p)
!
    endsubroutine special_calc_energy
!***********************************************************************
    subroutine special_before_boundary(f)
!
!  Possibility to modify the f array before the boundaries are
!  communicated.
!
!  Some precalculated pencils of data are passed in for efficiency
!  others may be calculated directly from the f array
!
!  06-jul-06/tony: coded
!
      use Cdata
      use Mpicomm, only: mpiallreduce_sum
!
      real, dimension (mx,my,mz,mfarray), intent(in) :: f
      real, dimension (nx,nz) :: fsum_tmp
      real, dimension (nx) :: uphi
      integer :: nnghost
!
!  Just needs to calculate at the first sub-timestep
!
      if (lfargo_advection.and.lfirst) then
!
!  Pre-calculate the average large scale speed of the flow
!
        fsum_tmp=0.
!
        do n=n1,n2;do m=m1,m2
          nnghost=n-nghost
          uphi=f(l1:l2,m,n,iuy)
          fsum_tmp(:,nnghost)=fsum_tmp(:,nnghost)+uphi*nygrid1
        enddo;enddo
!
! The sum has to be done processor-wise
! Sum over processors of same ipz, and different ipy
! --only relevant for 3D, but is here for generality
!
        call mpiallreduce_sum(fsum_tmp,uu_average,&
             (/nx,nz/),idir=2) !idir=2 is equal to old LSUMY=.true.
      endif
!
    endsubroutine special_before_boundary
!***********************************************************************
    subroutine special_after_timestep(f,df,dt_sub)
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real :: dt_sub
!
      if (lmagnetic) then
        if (lkeplerian_gauge)       call apply_keplerian_gauge(f)
        if (lremove_volume_average) call remove_volume_average(f)
      endif
!
      if (lfargo_advection) then
        if (lfargoadvection_as_shift) then
          call fourier_shift_fargo(f,df,dt_sub)
        else
          if (lroot) then
            print*,'Fargo advection without Fourier shift'
            print*,'is not functional yet. Advecting only'
            print*,'at the last subtimestep was leading to'
            print*,'errors. Rewrite.'
            call fatal_error("special_after_timestep","")
          endif
          call advect_fargo(f)
        endif
      endif
!
!  Just for test purposes and comparison with the loop advection
!  in Stone, J. et al., JCP 250, 509 (2005)
!
      if (lno_radial_advection) then
        f(:,:,:,iux) = 0.
        df(:,:,:,iux) = 0.
      endif
!
      call keep_compiler_quiet(dt_sub)
!
    endsubroutine special_after_timestep
!***********************************************************************
    subroutine fourier_shift_fargo(f,df,dt_)
!
!  Possibility to modify the f array after the evolution equations
!  are solved.
!
!  In this case, add the fargo shift to the f and df-array, in
!  fourier space.
!
!  06-jul-06/tony: coded
!
      use Sub
      use Fourier, only: fft_y_parallel
      use Cdata
      use Mpicomm
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (nx,ny) :: a_re,a_im
      real, dimension (nx) :: phidot
      integer :: ivar,ng
      real :: dt_
!
!  Pencil uses linear velocity. Fargo will shift based on
!  angular velocity. Get phidot from uphi.
!
      do n=n1,n2
        ng=n-n1+1
        phidot=uu_average(:,ng)*rcyl_mn1
!
        do ivar=1,mvar
!
          a_re=f(l1:l2,m1:m2,n,ivar); a_im=0.
!
!  Forward transform. No need for computing the imaginary part.
!  The transform is just a shift in y, so no need to compute
!  the x-transform either.
!
          call fft_y_parallel(a_re,a_im,SHIFT_Y=phidot*dt_,lneed_im=.false.)
!
!  Inverse transform of the shifted array back into real space.
!  No need again for either imaginary part of x-transform.
!
          call fft_y_parallel(a_re,a_im,linv=.true.)
          f(l1:l2,m1:m2,n,ivar)=a_re
!
!  Also shift df, unless it is the last subtimestep.
!
          if (.not.llast) then
            a_re=df(l1:l2,m1:m2,n,ivar); a_im=0.
            call fft_y_parallel(a_re,a_im,SHIFT_Y=phidot*dt_,lneed_im=.false.)
            call fft_y_parallel(a_re,a_im,linv=.true.)
            df(l1:l2,m1:m2,n,ivar)=a_re
          endif
!
        enddo
      enddo
!
    endsubroutine fourier_shift_fargo
!********************************************************************
    subroutine advect_fargo(f)
!
!  Possibility to modify the f array after the evolution equations
!  are solved.
!
!  In this case, do the fargo shift to the f and df-array, in
!  real space.
!
!  06-jul-06/tony: coded
!
      use Sub
      use Cdata
      use Mpicomm
!
      real, dimension (mx,my,mz,mfarray) :: f
!
      real, dimension (nx,nygrid,mvar) :: faux_remap,faux_remap_shift
!
      real, dimension (nx,ny) :: faux,tmp2
      real, dimension (nx,nygrid) :: tmp
!
      integer :: ivar,ng,ig,mshift,cellshift,i,mserial
!
      integer, dimension (nx,nz) :: shift_intg
      real, dimension (nx,nz) :: shift_total,shift_frac
!
! For shift in real space, the shift is done in integer number of
! cells in the azimuthal direction, so, take only the integer part
! of the velocity for fargo advection.
!
      do n=1,nz
        phidot_average(:,n) = uu_average(:,n)*rcyl_mn1
      enddo
!
! Define the integer circular shift
!
      shift_total = phidot_average*dt*dy_1(mpoint)
      shift_intg  = nint(shift_total)
!
! Do circular shift of cells
!
      do n=n1,n2
!
        do ivar=1,mvar
          faux=f(l1:l2,m1:m2,n,ivar)
          call remap_to_pencil_y(faux,tmp)
          faux_remap(:,:,ivar)=tmp
        enddo
!
        ng=n-n1+1
!
        do i=l1,l2
          ig=i-l1+1
          cellshift=shift_intg(ig,ng)
!
          do m=1,ny
            mserial=m+ipy*ny
            mshift=mserial-cellshift
            if (mshift .lt. 1 )     mshift = mshift + nygrid
            if (mshift .gt. nygrid) mshift = mshift - nygrid
!
            do ivar=1,mvar
              faux_remap_shift(ig,mserial,ivar) = faux_remap(ig,mshift,ivar)
            enddo
          enddo
        enddo
!
        do ivar=1,mvar
          tmp=faux_remap_shift(:,:,ivar)
          call unmap_from_pencil_y(tmp, tmp2)
          f(l1:l2,m1:m2,n,ivar)=tmp2
        enddo
      enddo
!
! Fractional step
!
      shift_frac  = shift_total-shift_intg
      call fractional_shift(f,shift_frac)
!
    endsubroutine advect_fargo
!********************************************************************
    subroutine fractional_shift(f,shift_frac)
!
      use Deriv, only:der
      use Mpicomm
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df_frac
      real, dimension (nx,nz) :: shift_frac,uu_frac
      real, dimension(3) :: dt_sub
      real, dimension(nx) :: ushift,dfdy,facx
      integer :: j,itsubstep
!
! Set boundaries
!
      if (nprocy==1) then
        f(:,1:m1-1,:,:)  = f(:,m2i:m2,:,:)
        f(:,m2+1:my,:,:) = f(:,m1:m1i,:,:)
      else
        call initiate_isendrcv_bdry(f)
        call finalize_isendrcv_bdry(f)
      endif
!
      dt_sub=dt*beta_ts
!
      facx=1./(dt*dy_1(mpoint)*rcyl_mn1)
!
      do n=1,nz
        uu_frac(:,n)=shift_frac(:,n)*facx
      enddo
!
      do itsubstep=1,itorder
        if (itsubstep==1) then
          df_frac=0.
        else
          df_frac=alpha_ts(itsubstep)*df_frac
        endif
!
        do n=n1,n2;do m=m1,m2
!
          ushift=uu_frac(:,n-n1+1)
!
          do j=1,mvar
            call der(f,j,dfdy,2)
            df_frac(l1:l2,m,n,j)=df_frac(l1:l2,m,n,j)-ushift*dfdy
            f(l1:l2,m,n,j) = &
                 f(l1:l2,m,n,j)+ dt_sub(itsubstep)*df_frac(l1:l2,m,n,j)
          enddo
!
        enddo;enddo
!
      enddo
!
    endsubroutine fractional_shift
!********************************************************************
    subroutine apply_keplerian_gauge(f)
!
      use Mpicomm , only: mpiallreduce_sum
      use Deriv, only: der
!
!  Substract mean emf from the radial component of the induction
!  equation. Activated only when large Bz fields and are present
!  keplerian advection. Due to this u_phi x Bz term, the radial
!  component of the magnetic potential
!  develops a divergence that grows linearly in time. Since it is
!  purely divergent, it is okay analytically. But numerically it leads to
!  problems if this divergent grows bigger than the curl, which it does
!  eventually.
!
!  This is a cylindrical version of the rtime_phiavg special file.
!
!  13-sep-07/wlad: adapted from remove_mean_momenta
!
      real, dimension (mx,my,mz,mfarray), intent (inout) :: f
      real, dimension (mx,mz) :: fsum_tmp,glambda_rz
      real, dimension (mx,my,mz) :: lambda
      real, dimension (nx) :: glambda_z
      real                    :: fac
      integer :: i
!
      !if (.not.lupdate_bounds_before_special) then
      !  print*,'The boundaries have not been updated prior '
      !  print*,'to calling this subroutine. This may lead '
      !  print*,'to troubles since it needs derivatives '
      !  print*,'and integrals, thus properly set ghost zones. '
      !  print*,'Use lupdate_bounds_before_special=T in '
      !  print*,'the run_pars of run.in.'
      !  call fatal_error("apply_keplerian_gauge","")
      !endif
!
      fac = 1.0/nygrid
!
! Set boundaries of iax
!
      !call update_ghosts(f,iax)
!
! Average over phi - the result is a (nr,nz) array
!
      fsum_tmp = 0.
      do m=m1,m2; do n=1,mz
        fsum_tmp(:,n) = fsum_tmp(:,n) + fac*f(:,m,n,iax)
      enddo; enddo
!
! The sum has to be done processor-wise
! Sum over processors of same ipz, and different ipy
!
      call mpiallreduce_sum(fsum_tmp,glambda_rz,(/mx,mz/),idir=2)
!
! Gauge-transform radial A
!
      do m=m1,m2
        f(l1:l2,m,n1:n2,iax) = f(l1:l2,m,n1:n2,iax) - glambda_rz(l1:l2,n1:n2)
      enddo
!
! Integrate in R to get lambda, using N=6 composite Simpson's rule.
! Ghost zones in r needed for glambda_r.
!
      do i=l1,l2 ; do n=1,mz
        lambda(i,:,n) = dx/6.*(   glambda_rz(i-3,n)+glambda_rz(i+3,n)+&
                               4*(glambda_rz(i-2,n)+glambda_rz(i  ,n)+glambda_rz(i+2,n))+&
                               2*(glambda_rz(i-1,n)+glambda_rz(i+1,n)))
      enddo; enddo
!
!  Gauge-transform vertical A. Ghost zones in z needed for lambda.
!
      do m=m1,m2; do n=n1,n2
        call der(lambda,glambda_z,3)
        f(l1:l2,m,n,iaz) = f(l1:l2,m,n,iaz) - glambda_z
      enddo; enddo
!
    endsubroutine apply_keplerian_gauge
!********************************************************************
    subroutine remove_volume_average(f)
!
      use Mpicomm , only: mpiallreduce_sum
!
!  Substract mean emf from the radial component of the induction
!  equation. Activated only when large Bz fields and are present
!  keplerian advection. Due to this u_phi x Bz term, the radial
!  component of the magnetic potential
!  develops a divergence that grows linearly in time. Since it is
!  purely divergent, it is okay analytically. But numerically it leads to
!  problems if this divergent grows bigger than the curl, which it does
!  eventually.
!
!  This is a cylindrical version of the rtime_phiavg special file.
!
!  13-sep-07/wlad: adapted from remove_mean_momenta
!
      real, dimension (mx,my,mz,mfarray), intent (inout) :: f
      real :: fsum_tmp,mean_ax,fac
      integer :: i
!
      fac = 1.0/nwgrid
!
! Set boundaries of iax
!
      !call update_ghosts(f,iax)
!
! Average over phi - the result is a (nr,nz) array
!
      fsum_tmp = 0.
      do m=m1,m2; do n=n1,n2 ; do i=l1,l2
        fsum_tmp = fsum_tmp + fac*f(i,m,n,iax)
      enddo; enddo; enddo
!
! The sum has to be done processor-wise
! Sum over processors of same ipz, and different ipy
!
      call mpiallreduce_sum(fsum_tmp,mean_ax)
!
! Gauge-transform radial A
!
      f(l1:l2,m1:m2,n1:n2,iax) = f(l1:l2,m1:m2,n1:n2,iax) - mean_ax
!
    endsubroutine remove_volume_average
!********************************************************************
!
!********************************************************************
!************        DO NOT DELETE THE FOLLOWING       **************
!********************************************************************
!**  This is an automatically generated include file that creates  **
!**  copies dummy routines from nospecial.f90 for any Special      **
!**  routines not implemented in this file                         **
!**                                                                **
    include '../special_dummies.inc'
!********************************************************************
endmodule Special
