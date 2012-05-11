MODULE modfd_problem_Setup

PRIVATE
PUBLIC :: fd_problem_setup,fd_problem_restart,fd_copy_time_arrays,fd_print_var,fd_alloc_surfforce_arrays, fd_write_restart,&
          fd_update_visc
CONTAINS
!============================================
SUBROUTINE fd_problem_setup

USE real_parameters,        ONLY : zero,one,two,pi,half
USE parameters,             ONLY : set_unit,alloc_create,nphi,grd_unit,max_char_len,solver_sparsekit,solver_sip,&
                                    solver_cg,solver_hypre,plt_unit
USE precision,              ONLY : r_single
USE shared_data,            ONLY : solver_type,NNZ,NCel,lli,itim,time,lread,lwrite,ltest,louts,loute,ltime,&
                                   maxit,imon,jmon,ipr,jpr,sormax,slarge,alfa,minit,&
                                   densit,visc,prm,gravx,gravy,beta,tref,problem_name,problem_len,lamvisc,&
                                   ulid,tper,itst,nprt,dt,gamt,iu,iv,ip,ien,dtr,tper,&
                                   nsw,lcal,sor,resor,urf,gds,om,prm,prr,nim,njm,ni,nj,&
                                   li,x,y,xc,yc,fx,fy,laxis,r,nij,u,v,nsw,sor,lcal,p,t,th,tc,den,deno,&
                                   vo,uo,to,title,duct,flomas,flomom,f1,stationary,celprr,celbeta,&  !--FD aspect
                                   objcentx,objcenty,objradius,putobj,nsurfpoints,read_fd_geom,&
                                   betap,prandtlp,movingmesh,forcedmotion,up,vp,omp,isotherm,objqp,objbradius,&
                                   densitp,fd_urf,mcellpercv,objtp,nsphere,calcsurfforce,& !--filament
                                   filgravx,filgravy,nfilpoints,nfil,densitfil,filbenrig,fillen,&
                                   filalpha,filbeta,filgamma,&
                                   filfirstposx,filfirstposy,fillasttheta,filnprt,filfr,& !--heat
                                   nnusseltpoints,calclocalnusselt,deltalen,sphnprt,betap,&
                                   mpi_comm,Hypre_A,Hypre_b,Hypre_x,nprocs_mpi,myrank_mpi,& !--viscosity temperature dependance
                                   temp_visc,viscgamma,calclocalnusselt_ave,naverage_steps

USE modfd_set_bc,           ONLY : fd_bctime
USE modfd_create_geom,      ONLY : fd_create_geom,fd_calc_mi,fd_calc_physprops,fd_calc_geom_volf,fd_calc_physprops,&
                                   fd_calc_quality
USE modfil_create_geom,     ONLY : fil_create_geom
USE modfd_tecwrite,     ONLY : fd_tecwrite_sph_s,fd_tecwrite_sph_v,fd_tecwrite_eul

IMPLICIT NONE

REAL(KIND = r_single) :: uin,vin,pin,tin
INTEGER               :: i,j,ij
!REAL(KIND = r_single),ALLOCATABLE :: volp(:,:),q(:)

solver_type = solver_sparsekit
itim = 0
time = zero
naverage_steps = 0

CALL fd_alloc_solctrl_arrays(alloc_create)

READ(set_unit,6)title
READ(set_unit,*)lread,lwrite,ltest,laxis,louts,loute,ltime,duct
READ(set_unit,*)maxit,minit,imon,jmon,ipr,jpr,sormax,slarge,alfa
READ(set_unit,*)densit,visc,prm,gravx,gravy,beta,th,tc,tref
READ(set_unit,*)uin,vin,pin,tin,ulid,tper
READ(set_unit,*)itst,nprt,dt,gamt

READ(set_unit,*)(lcal(i),i=1,nphi)
READ(set_unit,*)(urf(i),i=1,nphi)
READ(set_unit,*)(sor(i),i=1,nphi)
READ(set_unit,*)(nsw(i),i=1,nphi)
READ(set_unit,*)(gds(i),i=1,nphi)

READ(set_unit,*)temp_visc
IF(temp_visc)READ(set_unit,*)viscgamma
READ(set_unit,*)putobj,read_fd_geom,stationary,forcedmotion,movingmesh,calcsurfforce,calclocalnusselt,isotherm
IF(calclocalnusselt)READ(set_unit,*)calclocalnusselt_ave,naverage_steps
IF(putobj)THEN
  READ(set_unit,*)deltalen
  READ(set_unit,*)fd_urf
  READ(set_unit,*)nsphere
  IF(nsphere > 0)THEN
    READ(set_unit,*)sphnprt
    CALL fd_alloc_objprop_arrays(alloc_create)
    DO i = 1,nsphere
      IF(isotherm)THEN
        READ(set_unit,*)objcentx(i),objcenty(i),objradius(i),objbradius(i),densitp(i),objtp(i),betap(i),prandtlp(i)
      ELSE
        READ(set_unit,*)objcentx(i),objcenty(i),objradius(i),objbradius(i),densitp(i),objtp(i),betap(i),prandtlp(i),objqp(i)
      ENDIF
      READ(set_unit,*)nsurfpoints(i),nnusseltpoints(i),mcellpercv(i)
    ENDDO
    IF(.NOT. lread)THEN
      CALL fd_alloc_objgeom_arrays(alloc_create,MAXVAL(nsurfpoints(:),1))
      IF(calclocalnusselt)CALL fd_alloc_nusselt_arrays(alloc_create,MAXVAL(nnusseltpoints(:),1))
      IF(calcsurfforce)CALL fd_alloc_surfforce_arrays(alloc_create,MAXVAL(nsurfpoints(:),1))
    ENDIF
  ENDIF
  READ(set_unit,*)nfil
  IF(nfil > 0)THEN
    READ(set_unit,*)filnprt,filgravx,filgravy,filalpha,filbeta
 
    CALL fd_alloc_filprop_arrays(alloc_create)
 
    DO i=1,nfil
      READ(set_unit,*)nfilpoints(i),densitfil(i),filbenrig(i),fillen(i)
      READ(set_unit,*)filfirstposx(i),filfirstposy(i),fillasttheta(i)
    ENDDO
    IF(.NOT.lread)THEN
      CALL fd_alloc_filwork_arrays(alloc_create,MAXVAL(nfilpoints(:),1))
      CALL fd_alloc_filgeom_arrays(alloc_create,MAXVAL(nfilpoints(:),1))
    ENDIF
  ENDIF

ENDIF

!filfr(n) = SQRT(filgravx*filgravx + filgravy&filgravy)*fillen(n)(/ulid**2

!-- Init solved variable index
iu = 1
iv = 2
ip = 3
ien = 4


dtr = one/dt !--dt inverse
om = two*pi/tper !--omega (for oscilatory lid)
prr = one/prm !--inverse prandtl

READ(grd_unit,*) i
READ(grd_unit,*) i
READ(grd_unit,*) ni
READ(grd_unit,*) nj
READ(grd_unit,*) ij

nim=ni-1
njm=nj-1
nij=ni*nj

CALL fd_alloc_geom_arrays(alloc_create)

READ(grd_unit,*) (x(i),i=1,ni)
READ(grd_unit,*) (y(j),j=1,nj)
DO i=1,ni
  li(i)=(i-1)*nj
END DO


IF(solver_type == solver_sparsekit .OR. solver_type == solver_hypre)THEN
  !-----number of s-n faces + number of e-w faces + central coefficients
  NCel = 0
  DO i=2,nim
    DO j=2,njm
      NCel = NCel + 1
      lli(li(i) + j) = NCel
    ENDDO
  ENDDO

  NNZ = 2*(njm - 2)*(nim - 1) + 2*(nim - 2)*(njm - 1) + NCel
ENDIF
IF(solver_type == solver_sparsekit)CALL fd_alloc_spkit_arrays(alloc_create)
!IF(solver_type == solver_hypre)CALL solve_hypre_sys_init(mpi_comm,myrank_mpi,nprocs_mpi,ncel,Hypre_A,Hypre_b,Hypre_x) 

!--cv centres
DO i=2,nim
  xc(i)=half*(x(i)+x(i-1))
END DO
xc(1)=x(1)
xc(ni)=x(nim)

DO j=2,njm
  yc(j)=half*(y(j)+y(j-1))
END DO
yc(1)=y(1)
yc(nj)=y(njm)

!--interpolation factors
DO i=1,nim
  fx(i)=(x(i)-xc(i))/(xc(i+1)-xc(i))
END DO

DO j=1,njm
  fy(j)=(y(j)-yc(j))/(yc(j+1)-yc(j))
END DO

!--radius (significant only if axi-symmetric)
IF(laxis) THEN
  DO j=1,nj
    r(j)=y(j)
  END DO
ELSE
  DO j=1,nj
    r(j)=one
  END DO
ENDIF

!--Setup the object
IF(putobj)THEN
  IF(.NOT.lread)THEN
    IF(nsphere > 0)CALL fd_create_geom
    IF(nfil > 0)CALL fil_create_geom
    IF(nsphere > 0)CALL fd_alloc_objcell_vars(alloc_create)
    CALL fd_alloc_sources(alloc_create)
  ENDIF
  CALL fd_calc_mi
ENDIF

!---------------------------------------------------
!--BOUNDARY AND INITIAL CONDITIONS
!---------------------------------------------------

!--Allocate working arrays (matrix diagnals, sources etc...)
CALl fd_alloc_work_arrays(alloc_create)

!--WEST AND EAST ISOTHERMAL BOUNDARIES
!
IF(.NOT.movingmesh)THEN
  DO j=1,nj
    t(j)=th
  END DO

  DO j=1,nj
    t(li(ni)+j)=tc
  END DO
ELSE
  DO j=1,nj
    t(j)=th
  END DO

  DO i=1,ni
    t(li(i)+1)=th
  END DO

  DO i=1,ni
    t(li(i)+nj)=th
  END DO

ENDIF

!--NORTH WALL VELOCITY (FOR LID-DRIVEN CAVITY)
IF(ltime) THEN
  CALL fd_bctime
ELSE
 IF(duct)THEN
   flomas=zero
   flomom=zero
   DO j=2,njm
     ij=li(1)+j 
     u(ij)=ulid
     f1(ij)=half*densit*(y(j)-y(j-1))*(r(j)+r(j-1))*u(ij)
     flomas=flomas+f1(ij)
     flomom=flomom+f1(ij)*u(ij)
   END DO
 ELSE 
  DO i=2,nim
    u(li(i)+nj)=ulid
  END DO
 ENDIF
ENDIF


!--INITIAL VARIBLE VALUES (INITIAL CONDITIONS)
DO i=2,nim
  DO ij=li(i)+2,li(i)+njm
    u(ij)=uin
    v(ij)=vin
    t(ij)=tin
    p(ij)=pin
    uo(ij)=uin
    vo(ij)=vin
    to(ij)=tin
  END DO
END DO

den  = densit
deno = densit
celbeta = beta
celprr = prr
lamvisc = visc

IF(putobj)THEN
  IF(nsphere > 0)  CALL fd_calc_physprops
  deno = den
ENDIF

CALL fd_print_problem_setup

!ALLOCATE(volp(nij,nsphere),q(nsphere))
!
!volp = zero
!CALL fd_calc_geom_volf(volp)
!OPEN(UNIT = plt_unit,FILE=problem_name(1:problem_len)//'_init'//'_geomvolp.plt',STATUS='NEW')
!CALL fd_tecwrite_eul(plt_unit,volp)
!CLOSE(plt_unit)
!
!volp = zero
!CALL fd_calc_physprops(volp)
!OPEN(UNIT = plt_unit,FILE=problem_name(1:problem_len)//'_init'//'_volp.plt',STATUS='NEW')
!CALL fd_tecwrite_eul(plt_unit,volp)
!CLOSE(plt_unit)
!CALL fd_calc_quality(volp,q)
!WRITE(*,*)q
!DEALLOCATE(volp,q)

6 FORMAT(A80)

END SUBROUTINE fd_problem_setup

SUBROUTINE fd_problem_restart

USE real_parameters,        ONLY : zero
USE parameters,             ONLY : sres_unit,alloc_create,out_unit
USE shared_data

IMPLICIT NONE

INTEGER :: lni,lnj,lnim,lnjm,lnij,ij,i,j,lnsphere,nn,ik,maxnobjcell,lnfil,maxnfilpoints
LOGICAL :: lputobj,lread_fd_geom,lstationary,lforcedmotion,lmovingmesh,&
                  lcalcsurfforce,lcalclocalnusselt,lisotherm,ltemp_visc
IF(putobj)THEN
  READ(sres_unit) itim,time,lni,lnj,lnim,lnjm,lnij
  IF(lni /= ni .OR. lnj /= nj .OR. lnij /= nij .OR. lnim /= nim .OR. lnjm /= njm)THEN
      WRITE(out_unit,*)'fd_problem_restart: restart file inconsistency.'
      STOP
  ENDIF
  
  CALL  fd_alloc_sources(alloc_create)

  READ(sres_unit)((x(i),j=1,nj),i=1,ni),((y(j),j=1,nj),i=1,ni),&
         ((xc(i),j=1,nj),i=1,ni),((yc(j),j=1,nj),i=1,ni),&
         (f1(ij),ij=1,nij),(f2(ij),ij=1,nij),(u(ij),ij=1,nij),&
         (v(ij),ij=1,nij),(p(ij),ij=1,nij),(t(ij),ij=1,nij),&
         (uo(ij),ij=1,nij),(vo(ij),ij=1,nij),(to(ij),ij=1,nij),&
         (uoo(ij),ij=1,nij),(voo(ij),ij=1,nij),(too(ij),ij=1,nij),&
         (dpx(ij),ij=1,nij),(dpy(ij),ij=1,nij),(dux(ij),ij=1,nij),&
         (duy(ij),ij=1,nij),(dvx(ij),ij=1,nij),(dvy(ij),ij=1,nij),&
         (dtx(ij),ij=1,nij),(dty(ij),ij=1,nij),(den(ij),ij=1,nij),&
         (deno(ij),ij=1,nij),(celbeta(ij),ij=1,nij),(celprr(ij),ij=1,nij),&
         (fdsu(ij),ij=1,nij),(fdsv(ij),ij=1,nij),(fdsub(ij),ij=1,nij),&
         (fdsvb(ij),ij=1,nij),(fdsuc(ij),ij=1,nij),(fdsvc(ij),ij=1,nij),&
         (fdst(ij),ij=1,nij),(fdstc(ij),ij=1,nij),(lamvisc(ij),ij=1,nij)
  
  READ(sres_unit)ltemp_visc
  IF(ltemp_visc /= temp_visc)THEN
    WRITE(out_unit,*)'fd_problem_restart: restart file inconsistency in viscosity dependant switches.'
    STOP
  ENDIF

  READ(sres_unit)lputobj,lread_fd_geom,lstationary,lforcedmotion,lmovingmesh,&
                  lcalcsurfforce,lcalclocalnusselt,lisotherm

  IF(lputobj /= putobj .OR. lread_fd_geom /= read_fd_geom .OR. lstationary /= stationary .OR. &
     lforcedmotion /= forcedmotion .OR. lmovingmesh /= movingmesh .OR. lcalcsurfforce /= calcsurfforce .OR. &
     lcalclocalnusselt /= calclocalnusselt .OR. lisotherm /= isotherm)THEN
      WRITE(out_unit,*)'fd_problem_restart: restart file inconsistency in lagrangian switches.'
      STOP
  ENDIF

  READ(sres_unit)lnsphere

  IF(lnsphere /= nsphere)THEN
      WRITE(out_unit,*)'fd_problem_restart: restart file inconsistency in the number of objects.'
      STOP
  ENDIF

  READ(sres_unit)(objtp(ij),ij=1,nsphere),(densitp(ij),ij=1,nsphere),(objcentx(ij),ij=1,nsphere),&
                  (objcenty(ij),ij=1,nsphere),(objradius(ij),ij=1,nsphere),(objbradius(ij),ij=1,nsphere),&
                  (objcentu(ij),ij=1,nsphere),&
                  (objcentv(ij),ij=1,nsphere),(objcentom(ij),ij=1,nsphere),(nsurfpoints(ij),ij=1,nsphere),&
                  (nobjcells(ij),ij=1,nsphere),(mcellpercv(ij),ij=1,nsphere),(nnusseltpoints(ij),ij=1,nsphere),&
                  (objcentmi(ij),ij=1,nsphere),(objvol(ij),ij=1,nsphere),&
                  (objcentxo(ij),ij=1,nsphere),(objcentyo(ij),ij=1,nsphere),(objcentvo(ij),ij=1,nsphere),&
                  (objcentuo(ij),ij=1,nsphere),(objcentomo(ij),ij=1,nsphere),(betap(ij),ij=1,nsphere),&
                  (prandtlp(ij),ij=1,nsphere)
  DO nn=1,nsphere
    READ(sres_unit)(objcento(ij,nn),ij=1,4)
  ENDDO

  CALL fd_alloc_objgeom_arrays(alloc_create,MAXVAL(nsurfpoints(:),1))

  IF(forcedmotion)THEN
    DO nn = 1,nsphere
      READ(sres_unit)(surfpointx(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointy(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointxinit(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointyinit(ij,nn),ij=1,nsurfpoints(nn))
    ENDDO
  ELSE
    DO nn = 1,nsphere
      READ(sres_unit)(surfpointx(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointy(ij,nn),ij=1,nsurfpoints(nn))
    ENDDO
  ENDIF

  IF(calclocalnusselt)THEN
    CALL fd_alloc_nusselt_arrays(alloc_create,MAXVAL(nnusseltpoints(:),1))
    DO nn=1,nsphere
      READ(sres_unit)(nusseltpointx(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltpointy(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltnx(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltny(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltds(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltcentx(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltcenty(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (localnusselt(ij,nn),ij=1,nnusseltpoints(nn))
    ENDDO
    DO nn=1,nsphere
      DO ij=1,nnusseltpoints(nn)
        READ(sres_unit)(nusseltpoint_cvy(i,ij,nn),i=1,3),&
                        (nusseltpoint_cvx(i,ij,nn),i=1,3),&
                        (nusseltinterpx(i,ij,nn),i=1,2),&
                        (nusseltinterpy(i,ij,nn),i=1,2)
        DO ik=1,2
           READ(sres_unit)(nusseltpoint_interp(i,ik,ij,nn),i=1,4)
        ENDDO
      ENDDO
    ENDDO
  ENDIF
  
  IF(calcsurfforce)THEN
    CALL fd_alloc_surfforce_arrays(alloc_create,MAXVAL(nsurfpoints(:),1))
    DO nn = 1,nsphere
      READ(sres_unit)(surfds(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfnx(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfny(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfcentrex(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfcentrey(ij,nn),ij=1,nsurfpoints(nn))
      DO ij=1,nsurfpoints(nn)
        READ(sres_unit)(surfpoint_cvx(i,ij,nn),i=1,3),&
                        (surfpoint_cvy(i,ij,nn),i=1,3)
        DO ik = 1,2
          READ(sres_unit)(surfpoint_interp(i,ik,ij,nn),i=1,4),surfinterpx(ik,ij,nn),surfinterpy(ik,ij,nn)
        ENDDO
      ENDDO
    ENDDO      
  ENDIF

  maxnobjcell = MAXVAL(nobjcells(:),1)
  CALL fd_alloc_objcell_vars(alloc_create)
  ALLOCATE(objcellx(maxnobjcell,nsphere),objcelly(maxnobjcell,nsphere),&
           objcellvol(maxnobjcell,nsphere),objpoint_cvx(maxnobjcell,nsphere),&
           objpoint_cvy(maxnobjcell,nsphere),objcellvertx(4,maxnobjcell,nsphere),objcellverty(4,maxnobjcell,nsphere),&
           objpoint_interpx(2,maxnobjcell,nsphere),objpoint_interpy(2,maxnobjcell,nsphere))
  objcellx = zero;objcelly = zero
  objcellvol = zero;objcellvertx = zero;objcellverty = zero
  objpoint_cvx = 0;objpoint_cvy = 0;objpoint_interpx = 0;objpoint_interpy = 0

  DO nn=1,nsphere
    READ(sres_unit)(objcellx(ij,nn),ij=1,nobjcells(nn)),&
                    (objcelly(ij,nn),ij=1,nobjcells(nn)),&
                    (objcellvol(ij,nn),ij=1,nobjcells(nn)),&
                    (objpoint_cvx(ij,nn),ij=1,nobjcells(nn)),&
                    (objpoint_cvy(ij,nn),ij=1,nobjcells(nn))
    DO ij=1,nobjcells(nn)
      READ(sres_unit)(objcellvertx(i,ij,nn),i=1,4),&
                      (objcellverty(i,ij,nn),i=1,4),&
                      (objpoint_interpx(i,ij,nn),i=1,2),&
                      (objpoint_interpy(i,ij,nn),i=1,2)
    ENDDO

  ENDDO

  IF(forcedmotion)THEN
    ALLOCATE(objcentxinit(nsphere),objcentyinit(nsphere),objcellxinit(maxnobjcell,nsphere),&
           objcellyinit(maxnobjcell,nsphere),objcellvertxinit(4,maxnobjcell,nsphere),&
           objcellvertyinit(4,maxnobjcell,nsphere))
    objcentxinit = zero;objcentyinit = zero;objcellxinit = zero
    objcellyinit = zero;objcellvertxinit = zero
    objcellvertyinit = zero

    READ(sres_unit)(objcentxinit(nn),nn=1,nsphere),(objcentyinit(nn),nn=1,nsphere)
    DO nn=1,nsphere
      READ(sres_unit)(objcellxinit(ij,nn),ij=1,nobjcells(nn)),&
                      (objcellyinit(ij,nn),ij=1,nobjcells(nn))
      DO ij=1,nobjcells(nn)
        READ(sres_unit)(objcellvertxinit(i,ij,nn),i=1,4),&
                        (objcellvertyinit(i,ij,nn),i=1,4)
      ENDDO

    ENDDO
        
  ENDIF

  IF(nfil > 0)THEN

    READ(sres_unit)lnfil,filgravx,filgravy,filfr,filalpha,filbeta,filgamma
    IF(lnfil /= nfil)THEN
      WRITE(out_unit,*)'fd_problem_restart: restart file inconsistency in the number of objects.'
      STOP
    ENDIF
    
    !CALL fd_alloc_filprop_arrays(alloc_create)      
    READ(sres_unit)(nfilpoints(nn),nn=1,nfil),(densitfil(nn),nn=1,nfil),&
                    (filbenrig(nn),nn=1,nfil),(fillen(nn),nn=1,nfil),&
                    (fillenc(nn),nn=1,nfil),(filfirstposx(nn),nn=1,nfil),&
                    (filfirstposy(nn),nn=1,nfil),(fillasttheta(nn),nn=1,nfil)
    
    maxnfilpoints = MAXVAL(nfilpoints(:),1)
    CALL fd_alloc_filwork_arrays(alloc_create,maxnfilpoints)
    CALL fd_alloc_filgeom_arrays(alloc_create,maxnfilpoints)
    DO nn=1,nfil
      READ(sres_unit)(filpointx(i,nn),i=1,nfilpoints(nn)),(filpointy(i,nn),i=1,nfilpoints(nn)),&
                      (filpointyo(i,nn),i=1,nfilpoints(nn)),(filpointxo(i,nn),i=1,nfilpoints(nn)),&
                      (filten(i,nn),i=1,nfilpoints(nn)),(filds(i,nn),i=1,nfilpoints(nn)),&
                      (filpointxpen(i,nn),i=1,nfilpoints(nn)),(filpointypen(i,nn),i=1,nfilpoints(nn)),&
                      (filru(i,nn),i=1,nfilpoints(nn)),(filrv(i,nn),i=1,nfilpoints(nn)),&
                      (filintegfx(i,nn),i=1,nfilpoints(nn)),(filintegfy(i,nn),i=1,nfilpoints(nn)),&
                      (filcintegfx(i,nn),i=1,nfilpoints(nn)),(filcintegfy(i,nn),i=1,nfilpoints(nn)),&
                      (filpoint_cvx(i,nn),i=1,nfilpoints(nn)),(filpoint_cvy(i,nn),i=1,nfilpoints(nn))
      DO i = 1,nfilpoints(nn)
        READ(sres_unit)(filpoint_interpx(j,i,nn),j=1,2),(filpoint_interpy(j,i,nn),j=1,2)
      ENDDO
    ENDDO

    READ(sres_unit)(ibsu(ij),ij=1,nij),(ibsv(ij),ij=1,nij)
  ENDIF

ELSE
  READ(sres_unit) itim,time,ni,nj,nim,njm,nij
  IF(lni /= ni .OR. lnj /= nj .OR. lnij /= nij .OR. lnim /= nim .OR. lnjm /= njm)THEN
      WRITE(out_unit,*)'fd_problem_restart: restart file inconsistency.'
      STOP
  ENDIF
  READ(sres_unit)((x(i),j=1,nj),i=1,ni),((y(j),j=1,nj),i=1,ni),&
      ((xc(i),j=1,nj),i=1,ni),((yc(j),j=1,nj),i=1,ni),&
      (f1(ij),ij=1,nij),(f2(ij),ij=1,nij),(u(ij),ij=1,nij),&
      (v(ij),ij=1,nij),(p(ij),ij=1,nij),(t(ij),ij=1,nij),&
      (uo(ij),ij=1,nij),(vo(ij),ij=1,nij),(to(ij),ij=1,nij)
  REWIND sres_unit
ENDIF
END SUBROUTINE fd_problem_restart

SUBROUTINE fd_alloc_solctrl_arrays(create_or_destroy)

USE real_parameters,        ONLY : zero
USE parameters,             ONLY : alloc_create,alloc_destroy,nphi
USE shared_data,            ONLY : nsw,lcal,sor,resor,urf,gds

IMPLICIT NONE
INTEGER,INTENT(IN)      :: create_or_destroy

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(nsw(nphi),lcal(nphi),sor(nphi),resor(nphi),urf(nphi),gds(nphi))
  urf = zero
  gds = zero
  resor = zero
  sor = zero
  nsw = 0
  lcal = .FALSE.
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(nsw,lcal,sor,resor,urf,gds)
ENDIF

END SUBROUTINE fd_alloc_solctrl_arrays

SUBROUTINE fd_alloc_geom_arrays(create_or_destroy)

USE parameters,             ONLY : alloc_create,alloc_destroy,nphi
USE shared_data,            ONLY : r,x,y,xc,yc,fx,fy,li,nj,ni,lli,nij
USE real_parameters,        ONLY : zero

IMPLICIT NONE
INTEGER,INTENT(IN)      :: create_or_destroy

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(x(ni),y(nj),r(nj),xc(ni),yc(nj),fx(ni-1),fy(nj-1),li(ni),lli(nij))
  x = zero
  y = zero
  yc = zero
  xc = zero
  fx = zero
  fy = zero
  r = zero
  lli = -1
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(x,y,r,xc,yc,fx,fy,li,lli)
ENDIF

END SUBROUTINE fd_alloc_geom_arrays

SUBROUTINE fd_alloc_spkit_arrays(create_or_destroy)

USE parameters,             ONLY : alloc_create,alloc_destroy,nphi
USE shared_data,            ONLY : Work,Acoo,Arow,Acol,Acsr,Arwc,Aclc,RHS,SOL,NCel,NNZ,&
                                   alu,jlu,ju,jw
USE real_parameters,        ONLY : zero

IMPLICIT NONE
INTEGER,INTENT(IN)      :: create_or_destroy

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(Work(NNZ,8),Acoo(NNZ),Arow(NNZ),Acol(NNZ),Acsr(NNZ),Arwc(NCel+1),Aclc(NNZ),RHS(NCel),SOL(NCel),&
           Alu(NNZ),jlu(NNZ),Ju(NCel),Jw(2*NCel))
  Work = 0.D0
  Acoo = 0.D0
  Acsr = 0.D0
  RHS  = 0.D0
  SOL  = 0.D0
  Alu  = 0.D0
  Arow = 0
  Acol = 0
  Arwc = 0
  Aclc = 0
  jlu  = 0
  Ju   = 0
  Jw   = 0
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(Work,Acoo,Arow,Acol,Acsr,Arwc,Aclc,RHS,SOL,Alu,jlu,Ju,Jw)
ENDIF

END SUBROUTINE fd_alloc_spkit_arrays


SUBROUTINE fd_print_problem_setup

USE real_parameters, ONLY : zero
USE shared_data,  ONLY : ulid,gravx,gravy,ni,li,t,prm,alfa,urf,gds,dt,gamt,tper,densit,visc,ien,&
                         ltime,iu,iv,ip,lcal
USE parameters,   ONLY : out_unit
IMPLICIT NONE 

WRITE(out_unit,601) densit,visc

IF(ULID /= zero) THEN
  WRITE(out_unit,*) '          MAX. LID VELOCITY:  ',ULID
ENDIF
IF(LCAL(IEN)) THEN
  WRITE(out_unit,*) '          GRAVITY IN X-DIR.:  ',GRAVX
  WRITE(out_unit,*) '          GRAVITY IN Y-DIR.:  ',GRAVY
  WRITE(out_unit,*) '          HOT  WALL TEMPER.:  ',t(2)
  WRITE(out_unit,*) '          COLD WALL TEMPER.:  ',t(li(ni)+1)
  WRITE(out_unit,*) '          PRANDTL NUMBER   :  ',PRM
ENDIF
WRITE(out_unit,*) '  '
WRITE(out_unit,*) '          ALFA  PARAMETER  :  ',ALFA
WRITE(out_unit,*) '  '
WRITE(out_unit,*) '          UNDERRELAXATION  FACTORS'
WRITE(out_unit,*) '          ========================'
WRITE(out_unit,*) '          U-VELOCITY  :  ',URF(IU)
WRITE(out_unit,*) '          V-VELOCITY  :  ',URF(IV)
WRITE(out_unit,*) '          PRESSURE    :  ',URF(IP)
WRITE(out_unit,*) '          TEMPERATURE :  ',URF(IEN)
WRITE(out_unit,*) '  '
WRITE(out_unit,*) '          SPATIAL BLENDING FACTORS (CDS-UDS)'
WRITE(out_unit,*) '          =================================='
WRITE(out_unit,*) '          U-VELOCITY  :  ',GDS(IU)
WRITE(out_unit,*) '          V-VELOCITY  :  ',GDS(IV)
WRITE(out_unit,*) '          TEMPERATURE :  ',GDS(IEN)
WRITE(out_unit,*) '  '
IF(LTIME) THEN
  WRITE(out_unit,*) '          UNSTEADY FLOW SIMULATION'
  WRITE(out_unit,*) '          ================================='
  WRITE(out_unit,*) '          TIME STEP SIZE       : ',DT
  WRITE(out_unit,*) '          BLEND. FACTOR (3L-IE): ',GAMT
  WRITE(out_unit,*) '          OSCILLATION PERIOD   : ',TPER
ENDIF
WRITE(out_unit,*) '  '
WRITE(out_unit,*) '  '
RETURN

601 FORMAT(10X,' FLUID DENSITY    :  ',1P1E12.4,/,10X,' DYNAMIC VISCOSITY:  ',1P1E12.4)
END SUBROUTINE fd_print_problem_setup

SUBROUTINE fd_alloc_work_arrays(create_or_destroy)

USE parameters,             ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,            ONLY : nij,u,v,p,t,pp,uo,vo,to,uoo,voo,too,&
                                   ap,an,as,ae,aw,su,sv,apu,apv,apt,f1,f2,dpx,dpy,&
                                   dux,duy,dvx,dvy,dtx,dty,apt,den,deno,celbeta,celprr,lamvisc
USE real_parameters,        ONLY : zero

IMPLICIT NONE
INTEGER,INTENT(IN)      :: create_or_destroy
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(u(nij),v(nij),t(nij),p(nij),pp(nij),to(nij),uo(nij),vo(nij),voo(nij),too(nij),uoo(nij),&
           ap(nij),an(nij),as(nij),ae(nij),aw(nij),su(nij),sv(nij),apu(nij),apv(nij),f1(nij),f2(nij),&
           dpx(nij),dpy(nij),dux(nij),duy(nij),dvx(nij),dvy(nij),dtx(nij),dty(nij),den(nij),deno(nij),&
           celbeta(nij),celprr(nij),lamvisc(nij),STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate working arrays.'
  u = zero
  v = zero
  t = zero
  p = zero
  pp = zero
  uo = zero;vo = zero;to = zero
  uoo = zero;voo = zero;too = zero
  ap = zero;an = zero;as = zero;ae = zero;aw = zero
  su = zero;sv = zero
  apu = zero;apv = zero
  f1 = zero;f2 = zero
  dpx = zero;dpy = zero
  dux = zero;duy = zero
  dvx = zero;dvy = zero
  dtx = zero;dty = zero
  den = zero;deno = zero
  celbeta = zero;celprr = zero;lamvisc = zero
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(u,v,t,p,pp,to,uo,vo,voo,too,uoo,&
           ap,an,as,ae,aw,su,sv,apu,apv,f1,f2,dpx,dpy,dux,duy,dvx,dvy,dtx,dty,apt,den,deno,celbeta,celprr,lamvisc)
ENDIF

END SUBROUTINE fd_alloc_work_arrays

SUBROUTINE fd_copy_time_arrays(do_extrap)

USE precision,              ONLY : r_single
USE shared_data,            ONLY : v,t,u,vo,uo,to,voo,uoo,too,nij,iu,iv,ip,ien,lcal,&
                                   nim,njm,li
USE real_parameters,        ONLY : two

IMPLICIT NONE
LOGICAL,INTENT(IN) :: do_extrap
REAL(KIND = r_single)   :: uvt
INTEGER                 :: i,ij

IF(do_extrap)THEN
  DO i=2,nim
    DO ij=li(i)+2,li(i)+njm
      uvt = two*u(ij) - uo(ij)
      uoo(ij) = uo(ij)
      uo(ij) = u(ij)
      u(ij) = uvt

      uvt = two*v(ij) - vo(ij)
      voo(ij) = vo(ij)
      vo(ij) = v(ij)
      v(ij) = uvt

      uvt = two*t(ij) - to(ij)
      too(ij) = to(ij)
      to(ij) = t(ij)
      t(ij) = uvt
    ENDDO
  ENDDO
ELSE
  !--Array copy
  TOO=TO
  UOO=UO
  VOO=VO
  TO=T
  UO=U
  VO=V
ENDIF

END SUBROUTINE fd_copy_time_arrays

SUBROUTINE fd_print_var(phi,str)

USE precision,      ONLY : r_single
USE parameters,     ONLY : out_unit
USE shared_data,    ONLY : ni,nj,li
IMPLICIT NONE

CHARACTER(LEN = 6),INTENT(IN) :: str
REAL(KIND = r_single),DIMENSION(:),INTENT(IN) :: phi
INTEGER :: is,ie,nl,i,j,l

WRITE(2,20) str

nl=(ni-1)/12+1

DO l=1,nl
  is=(l-1)*12+1
  ie=MIN(ni,l*12)
  WRITE(out_unit,21) (i,i=is,ie)
  WRITE(out_unit,22)

  DO j=nj,1,-1
    WRITE(out_unit,23) j,(phi(li(i)+j),i=is,ie)
  END DO
END DO

20 FORMAT(2X,26('*-'),5X,A6,5X,26('-*'))
21 FORMAT(3X,'I = ',I3,11I10)
22 FORMAT(2X,'J')
23 FORMAT(1X,I3,1P12E10.2)

END SUBROUTINE fd_print_var


SUBROUTINE fd_alloc_objprop_arrays(create_or_destroy)

USE parameters,       ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,      ONLY : nsphere,objtp,objqp,fd_urf,densitp,objcentx,objcenty,&
                             objradius,objcentu,objcentv,objcentom,nsurfpoints,&
                             nobjcells,mcellpercv,nnusseltpoints,objcentmi,objvol,&
                             objcento,objcentxo,objcentyo,objcentvo,objcentuo,objcentomo,&
                             betap,prandtlp,up,vp,omp,forcedmotion,stationary,isotherm,objbradius
USE real_parameters,  ONLY : zero

IMPLICIT NONE

INTEGER,INTENT(IN)      :: create_or_destroy
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(objtp(nsphere),densitp(nsphere),objcentx(nsphere),objcenty(nsphere),&
          objradius(nsphere),objcentu(nsphere),objcentv(nsphere),objcentom(nsphere),&
          nsurfpoints(nsphere),nobjcells(nsphere),mcellpercv(nsphere),nnusseltpoints(nsphere),&
          objcentmi(nsphere),objvol(nsphere),objcento(4,nsphere),&
          objcentxo(nsphere),objcentyo(nsphere),objcentvo(nsphere),objcentuo(nsphere),&
          objcentomo(nsphere),betap(nsphere),prandtlp(nsphere),objbradius(nsphere),STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate onject arrays.'
  IF(forcedmotion .OR. stationary)THEN
    ALLOCATE(up(nsphere),vp(nsphere),omp(nsphere))
    up = zero;vp = zero;omp = zero
  ENDIF
  IF(.NOT. isotherm)THEN
    ALLOCATE(objqp(nsphere))
    objqp = zero
  ENDIF
  objtp = zero;objcentx = zero;objcenty = zero
  objradius = zero; objcentu = zero
  densitp = zero;objcentv = zero; objcentom = zero; objcentmi = zero
  nsurfpoints = 0;nobjcells = 0;mcellpercv = zero;nnusseltpoints = 0;objvol = zero
  objcento = zero;objcentxo = zero ;objcentyo = zero
  objcentvo = zero;objcentuo = zero;objcentomo = zero;betap = zero;prandtlp = zero
  objbradius = zero
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(objtp,densitp,objcentx,objcenty,objradius,objcentu,objcentv,objcentom,nsurfpoints,nobjcells,&
             mcellpercv,objcentmi,objvol,objcento,objcentxo,objcentyo,objcentvo,objcentuo,objcentomo,betap,&
             prandtlp,objbradius)
  IF(forcedmotion .OR. stationary)DEALLOCATE(up,vp,omp)
  IF(.NOT. isotherm)DEALLOCATE(objqp)
ENDIF

END SUBROUTINE fd_alloc_objprop_arrays

SUBROUTINE fd_alloc_nusselt_arrays(create_or_destroy,max_point)

USE parameters,       ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,      ONLY : nusseltpointx,nusseltpointy,nsphere,nusseltpoint_cvx,nusseltpoint_cvy,&
                             nusseltds,nusseltnx,nusseltny,nusseltcentx,nusseltcenty,&
                             nusseltinterpx,nusseltinterpy,nusseltpoint_interp,localnusselt
USE real_parameters,  ONLY : zero

IMPLICIT NONE

INTEGER,INTENT(IN)      :: create_or_destroy,max_point
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(nusseltpointx(max_point,nsphere),nusseltpointy(max_point,nsphere),&
           nusseltpoint_cvy(3,max_point,nsphere),nusseltpoint_cvx(3,max_point,nsphere),&
           nusseltnx(max_point,nsphere),nusseltny(max_point,nsphere),nusseltds(max_point,nsphere),&
           nusseltcentx(max_point,nsphere),nusseltcenty(max_point,nsphere),&
           nusseltinterpx(2,max_point,nsphere),nusseltinterpy(2,max_point,nsphere),&
           nusseltpoint_interp(4,2,max_point,nsphere),localnusselt(max_point,nsphere),STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate onject arrays.'
  nusseltpointx = zero
  nusseltpointy = zero
  nusseltpoint_cvy = 0
  nusseltpoint_cvx = 0
  nusseltds = zero
  nusseltnx = zero
  nusseltny = zero
  nusseltcentx = zero
  nusseltcenty = zero
  nusseltpoint_interp = zero
  nusseltinterpy = zero
  nusseltinterpx = zero
  localnusselt = zero 
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(nusseltpointx,nusseltpointy,nusseltpoint_cvy,nusseltpoint_cvx,&
           nusseltnx,nusseltny,nusseltds,nusseltcentx,nusseltcenty,&
           nusseltinterpx,nusseltinterpy,nusseltpoint_interp,localnusselt)
ENDIF

END SUBROUTINE fd_alloc_nusselt_arrays

SUBROUTINE fd_alloc_objgeom_arrays(create_or_destroy,max_point)

USE parameters,       ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,      ONLY : surfpointx,surfpointy,nsurfpoints,nsphere,&
                             surfpointxinit,surfpointyinit,forcedmotion
USE real_parameters,  ONLY : zero

IMPLICIT NONE

INTEGER,INTENT(IN)      :: create_or_destroy,max_point
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  IF(.NOT.forcedmotion)THEN
    ALLOCATE(surfpointx(max_point,nsphere),surfpointy(max_point,nsphere),STAT=ierror)
    IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate onject arrays.'
    surfpointx = zero
    surfpointy = zero
  ELSE
    ALLOCATE(surfpointx(max_point,nsphere),surfpointy(max_point,nsphere),&
             surfpointxinit(max_point,nsphere),surfpointyinit(max_point,nsphere),STAT=ierror)
    IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate onject arrays.'
    surfpointx = zero
    surfpointy = zero
    surfpointxinit = zero
    surfpointyinit = zero
  ENDIF
ELSEIF(create_or_destroy == alloc_destroy)THEN
  IF(.NOT.forcedmotion)THEN
    DEALLOCATE(surfpointx,surfpointy)
  ELSE
    DEALLOCATE(surfpointxinit,surfpointyinit)
  ENDIF
ENDIF

END SUBROUTINE fd_alloc_objgeom_arrays

SUBROUTINE fd_alloc_surfforce_arrays(create_or_destroy,max_point)

USE parameters,       ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,      ONLY : surfds,surfnx,surfny,nsphere,surfpoint_cvx,surfpoint_cvy,&
                             surfcentrex,surfcentrey,surfpoint_interp,surfinterpx,surfinterpy
USE real_parameters,  ONLY : zero

IMPLICIT NONE

INTEGER,INTENT(IN)      :: create_or_destroy,max_point
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(surfds(max_point,nsphere),surfnx(max_point,nsphere),surfny(max_point,nsphere),surfcentrex(max_point,nsphere),&
           surfcentrey(max_point,nsphere),surfpoint_cvx(3,max_point,nsphere),surfpoint_cvy(3,max_point,nsphere),&
           surfpoint_interp(4,2,max_point,nsphere),surfinterpx(2,max_point,nsphere),surfinterpy(2,max_point,nsphere),&
           STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate surface arrays.'
  surfds = zero
  surfnx = zero
  surfny = zero
  surfcentrex = zero
  surfcentrey = zero
  surfinterpx = zero
  surfinterpy = zero
  surfpoint_cvx = 0
  surfpoint_cvy = 0
  surfpoint_interp = 0
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(surfds,surfnx,surfny,surfpoint_cvx,surfpoint_cvy)
ENDIF

END SUBROUTINE fd_alloc_surfforce_arrays

SUBROUTINE fd_alloc_sources(create_or_destroy)

USE parameters,             ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,            ONLY : fdsu,fdsv,nij,fdsub,fdsvb,fdst,&
                                   fdsuc,fdsvc,fdstc,nfil,ibsu,ibsv
USE real_parameters,        ONLY : zero

IMPLICIT NONE
INTEGER,INTENT(IN)      :: create_or_destroy
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(fdsu(nij),fdsv(nij),fdsub(nij),fdsvb(nij),fdsuc(nij),fdsvc(nij),&
            fdst(nij),fdstc(nij),STAT=ierror)
  IF(nfil > 0)THEN
    ALLOCATE(ibsu(nij),ibsv(nij),STAT=ierror)
    ibsu = zero
    ibsv = zero
  ENDIF
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate working arrays.'
  fdsu = zero
  fdsv = zero
  fdsub= zero
  fdsvb= zero
  fdsuc=zero
  fdsvc=zero
  fdst =zero
  fdstc =zero
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(fdsu,fdsv,fdsub,fdsvb,fdst,fdsuc,fdsvc)
  IF(nfil>0)DEALLOCATE(ibsu,ibsv)
ENDIF

END SUBROUTINE fd_alloc_sources

SUBROUTINE fd_alloc_objcell_vars(create_or_destroy)

USE parameters,             ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,            ONLY : nobjcells,obju,objv,objfx,objfy,objru,objrv,&
                                   objq,objrt,objt,nsphere,objapu,objapv,objapt
USE real_parameters,        ONLY : zero

IMPLICIT NONE
INTEGER,INTENT(IN)      :: create_or_destroy
INTEGER                 :: ierror,maxpoint

maxpoint = MAXVAL(nobjcells(:),1)
IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(obju(maxpoint,nsphere),objv(maxpoint,nsphere),objfx(maxpoint,nsphere),objfy(maxpoint,nsphere),&
           objru(maxpoint,nsphere),objrv(maxpoint,nsphere),&
           objrt(maxpoint,nsphere),objt(maxpoint,nsphere),objq(maxpoint,nsphere),STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate working arrays.'
  obju = zero
  objv = zero
  objru = zero
  objrv = zero
  objfx = zero
  objfy = zero
  objrt = zero
  objt  = zero
  objq  = zero
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(obju,objv,objru,objrv,objfx,objfy,objrt,objt,objq)
ENDIF

END SUBROUTINE fd_alloc_objcell_vars

SUBROUTINE fd_alloc_filprop_arrays(create_or_destroy)

USE parameters,       ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,      ONLY : nfil,densitfil,filbenrig,nfilpoints,fillen,fillenc,&
                             fillasttheta,filfirstposx,filfirstposy
USE real_parameters,  ONLY : zero

IMPLICIT NONE

INTEGER,INTENT(IN)      :: create_or_destroy
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(densitfil(nfil),filbenrig(nfil),nfilpoints(nfil),fillen(nfil),fillenc(nfil),&
           filfirstposx(nfil),filfirstposy(nfil),fillasttheta(nfil),STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate filament arrays.'
  densitfil = zero;filbenrig = zero;fillen = zero;fillenc = zero
  filfirstposx = zero;filfirstposy = zero;fillasttheta = zero
  nfilpoints = 0
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(densitfil,filbenrig,nfilpoints,fillen,fillenc,filfirstposx,filfirstposy,fillasttheta)
ENDIF

END SUBROUTINE fd_alloc_filprop_arrays

SUBROUTINE fd_alloc_filwork_arrays(create_or_destroy,maxpoints)

USE parameters,       ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,      ONLY : filap,filaw,filae,filst,filsx,filsy
USE real_parameters,  ONLY : zero

IMPLICIT NONE

INTEGER,INTENT(IN)      :: create_or_destroy,maxpoints
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(filap(maxpoints),filaw(maxpoints),filae(maxpoints),filst(maxpoints),filsx(maxpoints),filsy(maxpoints),STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate filament arrays.'
  filap = zero; filaw = zero; filae = zero; filst = zero; filsx = zero; filsy = zero
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(filap,filaw,filae,filst,filsx,filsy)
ENDIF

END SUBROUTINE fd_alloc_filwork_arrays

SUBROUTINE fd_alloc_filgeom_arrays(create_or_destroy,maxpoints)

USE parameters,       ONLY : alloc_create,alloc_destroy,out_unit
USE shared_data,      ONLY : filpointx,filpointy,filpointyo,filpointxo,&
                             filten,filds,filpointxpen,filpointypen,filu,filv,&
                             filru,filrv,filfx,filfy,filintegfx,filintegfy,nfil,&
                             filpoint_cvy,filpoint_cvx,filcintegfx,filcintegfy,&
                             filpoint_interpx,filpoint_interpy
USE real_parameters,  ONLY : zero

IMPLICIT NONE

INTEGER,INTENT(IN)      :: create_or_destroy,maxpoints
INTEGER                 :: ierror

IF(create_or_destroy == alloc_create)THEN
  ALLOCATE(filpointx(maxpoints,nfil),filpointy(maxpoints,nfil),filpointyo(maxpoints,nfil),filpointxo(maxpoints,nfil),&
           filten(maxpoints,nfil),filds(maxpoints,nfil),filpointxpen(maxpoints,nfil),filpointypen(maxpoints,nfil),&
           filu(maxpoints,nfil),filv(maxpoints,nfil),filru(maxpoints,nfil),filrv(maxpoints,nfil),filfx(maxpoints,nfil),&
           filfy(maxpoints,nfil),filintegfx(maxpoints,nfil),filintegfy(maxpoints,nfil),filpoint_cvx(maxpoints,nfil),&
           filpoint_cvy(maxpoints,nfil),filcintegfx(maxpoints,nfil),filcintegfy(maxpoints,nfil),&
           filpoint_interpx(2,maxpoints,nfil),filpoint_interpy(2,maxpoints,nfil),STAT=ierror)
  IF(ierror /= 0)WRITE(out_unit,*)'Not enough memory to allocate filament arrays.'
  filpointx = zero;filpointy = zero;filpointyo = zero;filpointxo = zero
  filten = zero;filds = zero;filpointxpen = zero;filpointypen = zero;filu = zero;filv = zero
  filru = zero;filrv = zero;filfx = zero;filfy = zero;filintegfx = zero;filintegfy = zero
  filcintegfx = zero;filcintegfy = zero
  filpoint_interpx = 0;filpoint_interpy = 0
ELSEIF(create_or_destroy == alloc_destroy)THEN
  DEALLOCATE(filpointx,filpointy,filpointyo,filpointxo,filten,filds,filpointxpen,filpointypen,filu,filv,&
             filru,filrv,filfx,filfy,filintegfx,filintegfy,filpoint_cvy,filpoint_cvx,filcintegfx,filcintegfy,&
             filpoint_interpx,filpoint_interpy)
ENDIF

END SUBROUTINE fd_alloc_filgeom_arrays

SUBROUTINE fd_write_restart

USE shared_data
USE parameters,     ONLY : eres_unit  

IMPLICIT NONE

INTEGER       :: ij,nn,ik,i,j

  WRITE(eres_unit) itim,time,ni,nj,nim,njm,nij

  WRITE(eres_unit)((x(i),j=1,nj),i=1,ni),((y(j),j=1,nj),i=1,ni),&
         ((xc(i),j=1,nj),i=1,ni),((yc(j),j=1,nj),i=1,ni),&
         (f1(ij),ij=1,nij),(f2(ij),ij=1,nij),(u(ij),ij=1,nij),&
         (v(ij),ij=1,nij),(p(ij),ij=1,nij),(t(ij),ij=1,nij),&
         (uo(ij),ij=1,nij),(vo(ij),ij=1,nij),(to(ij),ij=1,nij),&
         (uoo(ij),ij=1,nij),(voo(ij),ij=1,nij),(too(ij),ij=1,nij),&
         (dpx(ij),ij=1,nij),(dpy(ij),ij=1,nij),(dux(ij),ij=1,nij),&
         (duy(ij),ij=1,nij),(dvx(ij),ij=1,nij),(dvy(ij),ij=1,nij),&
         (dtx(ij),ij=1,nij),(dty(ij),ij=1,nij),(den(ij),ij=1,nij),&
         (deno(ij),ij=1,nij),(celbeta(ij),ij=1,nij),(celprr(ij),ij=1,nij),&
         (fdsu(ij),ij=1,nij),(fdsv(ij),ij=1,nij),(fdsub(ij),ij=1,nij),&
         (fdsvb(ij),ij=1,nij),(fdsuc(ij),ij=1,nij),(fdsvc(ij),ij=1,nij),&
         (fdst(ij),ij=1,nij),(fdstc(ij),ij=1,nij),(lamvisc(ij),ij=1,nij)

  WRITE(eres_unit)temp_visc

  WRITE(eres_unit)putobj,read_fd_geom,stationary,forcedmotion,movingmesh,&
                  calcsurfforce,calclocalnusselt,isotherm

  WRITE(eres_unit)nsphere

  WRITE(eres_unit)(objtp(ij),ij=1,nsphere),(densitp(ij),ij=1,nsphere),(objcentx(ij),ij=1,nsphere),&
                  (objcenty(ij),ij=1,nsphere),(objradius(ij),ij=1,nsphere),(objbradius(ij),ij=1,nsphere),&
                  (objcentu(ij),ij=1,nsphere),&
                  (objcentv(ij),ij=1,nsphere),(objcentom(ij),ij=1,nsphere),(nsurfpoints(ij),ij=1,nsphere),&
                  (nobjcells(ij),ij=1,nsphere),(mcellpercv(ij),ij=1,nsphere),(nnusseltpoints(ij),ij=1,nsphere),&
                  (objcentmi(ij),ij=1,nsphere),(objvol(ij),ij=1,nsphere),&
                  (objcentxo(ij),ij=1,nsphere),(objcentyo(ij),ij=1,nsphere),(objcentvo(ij),ij=1,nsphere),&
                  (objcentuo(ij),ij=1,nsphere),(objcentomo(ij),ij=1,nsphere),(betap(ij),ij=1,nsphere),&
                  (prandtlp(ij),ij=1,nsphere)
  DO nn=1,nsphere
    WRITE(eres_unit)(objcento(ij,nn),ij=1,4)
  ENDDO

  IF(forcedmotion)THEN
    DO nn = 1,nsphere
      WRITE(eres_unit)(surfpointx(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointy(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointxinit(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointyinit(ij,nn),ij=1,nsurfpoints(nn))
    ENDDO
  ELSE
    DO nn = 1,nsphere
      WRITE(eres_unit)(surfpointx(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfpointy(ij,nn),ij=1,nsurfpoints(nn))
    ENDDO
  ENDIF

  IF(calclocalnusselt)THEN
    DO nn=1,nsphere
      WRITE(eres_unit)(nusseltpointx(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltpointy(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltnx(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltny(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltds(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltcentx(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (nusseltcenty(ij,nn),ij=1,nnusseltpoints(nn)),&
                      (localnusselt(ij,nn),ij=1,nnusseltpoints(nn))
    ENDDO
    DO nn=1,nsphere
      DO ij=1,nnusseltpoints(nn)
        WRITE(eres_unit)(nusseltpoint_cvy(i,ij,nn),i=1,3),&
                        (nusseltpoint_cvx(i,ij,nn),i=1,3),&
                        (nusseltinterpx(i,ij,nn),i=1,2),&
                        (nusseltinterpy(i,ij,nn),i=1,2)
        DO ik=1,2
           WRITE(eres_unit)(nusseltpoint_interp(i,ik,ij,nn),i=1,4)
        ENDDO
      ENDDO
    ENDDO
  ENDIF
  
  IF(calcsurfforce)THEN
    DO nn = 1,nsphere
      WRITE(eres_unit)(surfds(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfnx(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfny(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfcentrex(ij,nn),ij=1,nsurfpoints(nn)),&
                      (surfcentrey(ij,nn),ij=1,nsurfpoints(nn))
      DO ij=1,nsurfpoints(nn)
        WRITE(eres_unit)(surfpoint_cvx(i,ij,nn),i=1,3),&
                        (surfpoint_cvy(i,ij,nn),i=1,3)
        DO ik = 1,2
          WRITE(eres_unit)(surfpoint_interp(i,ik,ij,nn),i=1,4),surfinterpx(ik,ij,nn),surfinterpy(ik,ij,nn)
        ENDDO
      ENDDO
    ENDDO      
  ENDIF

  DO nn=1,nsphere
    WRITE(eres_unit)(objcellx(ij,nn),ij=1,nobjcells(nn)),&
                    (objcelly(ij,nn),ij=1,nobjcells(nn)),&
                    (objcellvol(ij,nn),ij=1,nobjcells(nn)),&
                    (objpoint_cvx(ij,nn),ij=1,nobjcells(nn)),&
                    (objpoint_cvy(ij,nn),ij=1,nobjcells(nn))
    DO ij=1,nobjcells(nn)
      WRITE(eres_unit)(objcellvertx(i,ij,nn),i=1,4),&
                      (objcellverty(i,ij,nn),i=1,4),&
                      (objpoint_interpx(i,ij,nn),i=1,2),&
                      (objpoint_interpy(i,ij,nn),i=1,2)
    ENDDO

  ENDDO

  IF(forcedmotion)THEN
    WRITE(eres_unit)(objcentxinit(nn),nn=1,nsphere),(objcentyinit(nn),nn=1,nsphere)
    DO nn=1,nsphere
      WRITE(eres_unit)(objcellxinit(ij,nn),ij=1,nobjcells(nn)),&
                      (objcellyinit(ij,nn),ij=1,nobjcells(nn))
      DO ij=1,nobjcells(nn)
        WRITE(eres_unit)(objcellvertxinit(i,ij,nn),i=1,4),&
                        (objcellvertyinit(i,ij,nn),i=1,4)
      ENDDO

    ENDDO
        
  ENDIF

  IF(nfil > 0)THEN

    WRITE(eres_unit)nfil,filgravx,filgravy,filfr,filalpha,filbeta,filgamma

    WRITE(eres_unit)(nfilpoints(nn),nn=1,nfil),(densitfil(nn),nn=1,nfil),&
                    (filbenrig(nn),nn=1,nfil),(fillen(nn),nn=1,nfil),&
                    (fillenc(nn),nn=1,nfil),(filfirstposx(nn),nn=1,nfil),&
                    (filfirstposy(nn),nn=1,nfil),(fillasttheta(nn),nn=1,nfil)

    DO nn=1,nfil
      WRITE(eres_unit)(filpointx(i,nn),i=1,nfilpoints(nn)),(filpointy(i,nn),i=1,nfilpoints(nn)),&
                      (filpointyo(i,nn),i=1,nfilpoints(nn)),(filpointxo(i,nn),i=1,nfilpoints(nn)),&
                      (filten(i,nn),i=1,nfilpoints(nn)),(filds(i,nn),i=1,nfilpoints(nn)),&
                      (filpointxpen(i,nn),i=1,nfilpoints(nn)),(filpointypen(i,nn),i=1,nfilpoints(nn)),&
                      (filru(i,nn),i=1,nfilpoints(nn)),(filrv(i,nn),i=1,nfilpoints(nn)),&
                      (filintegfx(i,nn),i=1,nfilpoints(nn)),(filintegfy(i,nn),i=1,nfilpoints(nn)),&
                      (filcintegfx(i,nn),i=1,nfilpoints(nn)),(filcintegfy(i,nn),i=1,nfilpoints(nn)),&
                      (filpoint_cvx(i,nn),i=1,nfilpoints(nn)),(filpoint_cvy(i,nn),i=1,nfilpoints(nn))
      DO i = 1,nfilpoints(nn)
        WRITE(eres_unit)(filpoint_interpx(j,i,nn),j=1,2),(filpoint_interpy(j,i,nn),j=1,2)
      ENDDO

    ENDDO

    WRITE(eres_unit)(ibsu(ij),ij=1,nij),(ibsv(ij),ij=1,nij)
  ENDIF

END SUBROUTINE fd_write_restart


SUBROUTINE fd_update_visc

USE shared_data,      ONLY : lamvisc,nim,njm,visc,tref,li,viscgamma,t,duct,movingmesh,ni,nj,th,tc
USE real_parameters,  ONLY : one

IMPLICIT NONE

INTEGER       :: i,j,ij

DO i = 2,nim
  DO j = 2,njm
    ij = li(i) + j
    lamvisc(ij) = -26.99 + 0.09*t(ij) !/(one + viscgamma*(t(ij) - tref))
  ENDDO
ENDDO

!--NORTH BOUNDARY
DO i=2,nim
  ij=li(i)+nj
  lamvisc(ij) = -26.99 + 0.09*t(ij) !visc !/(one + viscgamma*(t(ij) - tref))
ENDDO

!--SOUTH BOUNDARY (ISOTHERMAL WALL, NON-ZERO DIFFUSIVE FLUX)
DO i=2,nim
  ij=li(i)+1
  lamvisc(ij) = -26.99 + 0.09*t(ij) !/(one + viscgamma*(t(ij) - tref)) 
ENDDO

!--WEST BOUNDARY 
DO j=2,njm
  ij=li(1)+j
  lamvisc(ij) = -26.99 + 0.09*t(ij) !/(one + viscgamma*(t(ij) - tref)) 
ENDDO


!--EAST BOUNDARY
IF(duct)THEN !--Outlet (zero grdient but t is not available use previous node)
  DO j=2,njm
    ij=li(ni)+j
    lamvisc(ij) = -26.99 + 0.09*t(ij-nj) !/(one + viscgamma*(t(ij-nj) - tref)) 
  END DO
ELSE
  IF(movingmesh)THEN !--Outlet
    DO j=2,njm
      ij=li(ni)+j
      lamvisc(ij) = -26.99 + 0.09*t(ij-nj) !/(one + viscgamma*(t(ij-nj) - tref)) 
    END DO
  ELSE
    !--EAST BOUNDARY
    DO j=2,njm
      ij=li(ni)+j
      lamvisc(ij) = -26.99 + 0.09*t(ij) !/(one + viscgamma*(t(ij) - tref)) 
    ENDDO
  ENDIF
ENDIF


END SUBROUTINE fd_update_visc 

END MODULE modfd_problem_setup
