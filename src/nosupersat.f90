! $Id$
!
!  This modules solves the passive scalar advection equation.
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lsupersat = .false.
!
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
! PENCILS PROVIDED cc; cc1; gcc(3)
!
!***************************************************************
module Supersat
!
  use Cparam
  use Cdata
  use General, only: keep_compiler_quiet
  use Messages
!
  implicit none
!
  include 'supersat.h'
!
!  Should not be public:
!
  real :: rhoccm=0.0, cc2m=0.0, gcc2m=0.0
  integer :: idiag_gcc2m=0, idiag_cc2m=0, idiag_rhoccm=0
!
  contains
!***********************************************************************
    subroutine register_supersat()
!
!  Initialise variables which should know that we solve for passive
!  scalar: ilncc; increase nvar accordingly.
!
!  6-jul-02/axel: coded
!
!  Identify version number.
!
      if (lroot) call svn_id( &
          "$Id$")
!
    endsubroutine register_supersat
!***********************************************************************
    subroutine initialize_supersat(f)
!
!  Perform any necessary post-parameter read initialization.
!
!  24-nov-02/tony: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine initialize_supersat
!***********************************************************************
    subroutine init_lncc(f)
!
!  Initialise passive scalar field.
!
!   6-jul-02/axel: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine init_lncc
!***********************************************************************
    subroutine pencil_criteria_supersat()
!
!  All pencils that the Pscalar module depends on are specified here.
!
!  20-11-04/anders: coded
!
    endsubroutine pencil_criteria_supersat
!***********************************************************************
    subroutine pencil_interdep_supersat(lpencil_in)
!
!  Interdependency among pencils provided by the Pscalar module
!  is specified here.
!
!  20-11-04/anders: coded
!
      logical, dimension(npencils) :: lpencil_in
!
      call keep_compiler_quiet(lpencil_in)
!
    endsubroutine pencil_interdep_supersat
!***********************************************************************
    subroutine calc_pencils_supersat(f,p)
!
!  Calculate Pscalar pencils.
!  Most basic pencils should come first, as others may depend on them.
!
!  20-11-04/anders: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (pencil_case) :: p
!
      intent(in) :: f
      intent(inout) :: p
! cc
      if (lpencil(i_cc)) p%cc=1.0
! cc1
      if (lpencil(i_cc1)) p%cc1=1.0
! gcc
      if (lpencil(i_gcc)) p%gcc=0.0
!
      call keep_compiler_quiet(f)
!
    endsubroutine calc_pencils_supersat
!***********************************************************************
    subroutine dlncc_dt(f,df,p)
!
!  Passive scalar evolution.
!
!   6-jul-02/axel: dummy
!
      real, dimension (mx,my,mz,mfarray) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
!
      intent(in)  :: f,df,p
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(p)
!
    endsubroutine dlncc_dt
!***********************************************************************
    subroutine read_supersat_init_pars(iostat)
!
      integer, intent(out) :: iostat
!
      iostat = 0
!
    endsubroutine read_supersat_init_pars
!***********************************************************************
    subroutine write_supersat_init_pars(unit)
!
      integer, intent(in) :: unit
!
      call keep_compiler_quiet(unit)
!
    endsubroutine write_supersat_init_pars
!***********************************************************************
    subroutine read_supersat_run_pars(iostat)
!
      integer, intent(out) :: iostat
!
      iostat = 0
!
    endsubroutine read_supersat_run_pars
!***********************************************************************
    subroutine write_supersat_run_pars(unit)
!
      integer, intent(in) :: unit
!
      call keep_compiler_quiet(unit)
!
    endsubroutine write_supersat_run_pars
!***********************************************************************
    subroutine rprint_supersat(lreset,lwrite)
!
!  Reads and registers print parameters relevant for passive scalar.
!
!   6-jul-02/axel: coded
!
      logical :: lreset,lwr
      logical, optional :: lwrite
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
!  Write column where which passive scalar variable is stored.
!
      if (lwr) then
        write(3,*) 'ilncc=0'
        write(3,*) 'icc=0'
      endif
!
      call keep_compiler_quiet(lreset)
!
    endsubroutine rprint_supersat
!***********************************************************************
    subroutine get_slices_supersat(f,slices)
!
      real, dimension (mx,my,mz,mfarray) :: f
      type (slice_data) :: slices
!
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(slices%ready)
!
    endsubroutine get_slices_supersat
!***********************************************************************
    subroutine supersat_after_boundary(f)
!
!  Removes overall means of passive scalars.
!
!  5-dec-11/MR: coded
!
      real, dimension (mx,my,mz,mfarray), intent(IN) :: f

      call keep_compiler_quiet(f)

    endsubroutine supersat_after_boundary
!***********************************************************************
    subroutine calc_msupersat
!
    endsubroutine calc_msupersat
!***********************************************************************
endmodule Supersat
