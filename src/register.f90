! $Id: register.f90,v 1.82 2003-06-14 16:41:44 brandenb Exp $

!!!  A module for setting up the f-array and related variables (`register' the
!!!  entropy, magnetic, etc modules).


module Register

  implicit none 

  contains

!***********************************************************************
    subroutine register_modules()
!
!  Call all registration routines, i.e. initialise MPI and register
!  physics modules. Registration implies getting slices of the f-array
!  and setting logicals like lentropy to .true. This routine is called by
!  both, start.x and run.x .
!
!  6-nov-01/wolf: coded
!
      use Cdata
      use Mpicomm
      use Sub
      use IO
      use Param_io
      use Gravity
      use Hydro
      use Forcing
      use Entropy
      use Magnetic
      use Radiation
      use Ionization
      use Pscalar
      use Dustdensity
      use Dustvelocity
      use Interstellar
      use Shear
      use Viscosity
!
!  initialize all mpi stuff
!
      call mpicomm_init
!
!  initialize nvar; is increased by the following routines
!
      nvar = 0 
      naux = 0 
!
      call register_io
!
      call register_hydro
      call register_density
      call register_viscosity
      call register_forcing
      call register_entropy
      call register_magnetic
      call register_radiation
      call register_ionization
      call register_pscalar
      call register_dustvelocity
      call register_dustdensity
      call register_gravity
      call register_interstellar
      call register_shear
!
      if (nvar /= mvar) then
        if (lroot) write(0,*) 'nvar = ', nvar, ', mvar = ', mvar
        call stop_it('Initialize: nvar /= mvar. Fix mvar in cparam.local')
      endif
!
!  initialize headt for root processor only
!
      if (lroot) headt=.true.
!
!  overwrite datadir from datadir.in, if that exists
!
      call get_datadir(datadir)
      call get_snapdir(directory_snap)
!
    endsubroutine register_modules
!***********************************************************************
    subroutine initialize_modules(f,lstart)
!
!  Call initialization routines, i.e. initialize physics and technical
!  modules. This implies some preparation of auxiliary quantities, often
!  based on input parameters. This routine is called by run.x (but not by
!  start.x) initially and each time the run parameters have been reread.
!
!  6-nov-01/wolf: coded
! 23-feb-03/axel: added physical constants conversion
!
      use Cdata
      use Print
      use Timeavg
      use Gravity
      use Hydro
      use Forcing
      use Entropy
      use Magnetic
      use Radiation
      use Ionization
      use Pscalar
      use Dustdensity
      use Dustvelocity
      use Interstellar
      use Shear
      use Viscosity
      use Param_IO

      real, dimension(mx,my,mz,mvar) :: f
      double precision :: unit_mass,unit_energy,unit_time,unit_flux
      logical :: lstart
!
!  Defaults for some logicals; will later be set to true if needed
      lneed_sij = .false.
      lneed_glnrho = .false.
!
!  evaluate physical units
!  used currently only in ionization, but later also in
!  the interstellar and radiation modules, for example
!
      unit_mass=unit_density*unit_length**3
      unit_energy=unit_mass*unit_velocity**2
      unit_time=unit_length/unit_velocity
      unit_flux=unit_energy/(unit_length**2*unit_time)
!
!  convert physical constants
!
      if (unit_system=='cgs') then
        if(lionization) print*,'unit_velocity, unit_density, etc, are in cgs'
        hbar=hbar_cgs/(unit_energy*unit_time)
        k_B=k_B_cgs/(unit_energy/unit_temperature)
        m_p=m_p_cgs/unit_mass
        m_e=m_e_cgs/unit_mass
        eV=eV_cgs/unit_energy
        sigmaH_=sigmaH_cgs/unit_length**2
        sigmaSB=sigmaSB_cgs/(unit_flux/unit_temperature**4)
        kappa_es=kappa_es_cgs/(unit_length**2/unit_mass)
      elseif (unit_system=='SI') then
        if(lionization) print*,'unit_velocity, unit_density, etc, are in SI'
        k_B=1e-7*k_B_cgs/(unit_energy/unit_temperature)
        m_p=m_p_cgs*1e-3/unit_mass
        m_e=m_e_cgs*1e-3/unit_mass
        eV=eV_cgs*1e-7/unit_energy
        sigmaH_=sigmaH_cgs*1e-4/unit_length**2
        sigmaSB=sigmaSB_cgs*1e-3/(unit_flux/unit_temperature**4)
        kappa_es=kappa_es_cgs*1e-1/(unit_length**2/unit_mass)
      endif
!
!  print parameters in code units, but only when used
!
      if (lroot) then
         if (lionization.or.lradiation.or.lradiation_ray.or.linterstellar) then
            print'(a,1p,4e14.6)',' register: k_B,m_p,m_e,eV=',k_B,m_p,m_e,eV
         endif
      endif
!
!  set gamma1, cs20, and lnrho0
!  (used currently for non-dimensional equation of state)
!
      gamma1=gamma-1.
      cs20=cs0**2
      lnrho0=alog(rho0)
!
!  run initialization of individual modules
!
!      call initialize_io
      call initialize_prints
!ajwm timeavg needs tidying to be similar structure to other modules
      call initialize_timeavg(f) ! initialize time averages
!
!      call initialize_hydro
!      call initialize_density
      call initialize_forcing(lstart)  ! get random seed from file, ..
      call initialize_entropy          ! calculate radiative conductivity, etc.
!      call initialize_magnetic
      call initialize_radiation
      call initialize_ionization
      call initialize_pscalar(f)
!      call initialize_dustvelocity
!      call initialize_dustdensity
      call initialize_gravity
      call initialize_interstellar(lstart)
      call initialize_shear
      call initialize_viscosity
!
!  timestep: if dt=0 (ie not initialized), ldt=.true.
!
!ajwm should this be moved to timestep.f90 as run_hooks_timestep() ??
!AB: maybe not, because initialize_modules can also be run from start.f90,
!AB: which has no knowledge of timestep.f90
!
      ldt = (dt==0.)            ! need to calculate dt dynamically?
      if (lroot .and. ip<14) then
        if (ldt) then
          print*,'timestep based on CFL cond; cdt=',cdt
        else
          print*, 'absolute timestep dt=', dt
        endif
      endif
!
    endsubroutine initialize_modules
!***********************************************************************
    subroutine rprint_list(lreset)
!
!  read variables to print and to calculate averages of from control files
!
!   3-may-01/axel: coded
!
      use Cdata
      use Hydro
      use Entropy
      use Magnetic
      use Radiation
      use Pscalar
      use Dustvelocity
      use Dustdensity
      use Gravity
!
      integer :: iname,inamez,inamexy,inamerz
      logical :: lreset,exist
!
!  read in the list of variables to be printed
!
      open(1,file='print.in')
      do iname=1,mname
        read(1,*,end=99) cname(iname)
      enddo
99    nname=iname-1
      if (lroot.and.ip<14) print*,'nname=',nname
      close(1)
!
!  read in the list of variables for xy-averages
!
      inquire(file='xyaver.in',exist=exist)
      if (exist) then
        open(1,file='xyaver.in')
        do inamez=1,mnamez
          read(1,*,end=98) cnamez(inamez)
        enddo
98      nnamez=inamez-1
        close(1)
      endif
      if (lroot.and.ip<14) print*,'nnamez=',nnamez
!
!  read in the list of variables for z-averages
!
      inquire(file='zaver.in',exist=exist)
      if (exist) then
        open(1,file='zaver.in')
        do inamexy=1,mnamexy
          read(1,*,end=97) cnamexy(inamexy)
        enddo
97      nnamexy=inamexy-1
        close(1)
      endif
      if (lroot.and.ip<14) print*,'nnamexy=',nnamexy
!
!  read in the list of variables for phi-averages
!
      inquire(file='phiaver.in',exist=exist)
      if (exist) then
        open(1,file='phiaver.in')
        do inamerz=1,mnamerz
          read(1,*,end=96) cnamerz(inamerz)
        enddo
96      nnamerz=inamerz-1
        close(1)
      endif
      if (lroot.and.ip<14) print*,'nnamerz=',nnamerz
!
!  check which variables are set
!  For the convenience of idl users, the indices of variables in
!  the f-array and the time_series.dat files are written to data/index.pro
!
      open(3,file=trim(datadir)//'/index.pro')
      call rprint_general(lreset)
      call rprint_hydro(lreset)
      call rprint_density(lreset)
      call rprint_entropy(lreset)
      call rprint_magnetic(lreset)
      call rprint_radiation(lreset)
      call rprint_ionization(lreset)
      call rprint_pscalar(lreset)
      call rprint_dustvelocity(lreset)
      call rprint_dustdensity(lreset)
      call rprint_gravity(lreset)
      close(3)
!
    endsubroutine rprint_list
!***********************************************************************
    subroutine rprint_general(lreset)
!
!  reads and registers *general* print parameters
!
!   8-jun-02/axel: adapted from hydro
!
      use Cdata
      use Sub
!
      integer :: iname
      logical :: lreset
!
!  reset everything in case of reset
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        i_t=0;i_it=0;i_dt=0;i_dtc=0;i_walltime=0
      endif
!
!  iname runs through all possible names that may be listed in print.in
!
      if(lroot.and.ip<14) print*,'run through parse list'
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'t',i_t)
        call parse_name(iname,cname(iname),cform(iname),'it',i_it)
        call parse_name(iname,cname(iname),cform(iname),'dt',i_dt)
        call parse_name(iname,cname(iname),cform(iname),'dtc',i_dtc)
        call parse_name(iname,cname(iname),cform(iname),'walltime',i_walltime)
      enddo
!
!  write column where which magnetic variable is stored
!
      write(3,*) 'i_t=',i_t
      write(3,*) 'i_it=',i_it
      write(3,*) 'i_dt=',i_dt
      write(3,*) 'i_dtc=',i_dtc
      write(3,*) 'i_walltime=',i_walltime
      write(3,*) 'nname=',nname
!
    endsubroutine rprint_general
!***********************************************************************

endmodule Register

!!! End of file register.f90
