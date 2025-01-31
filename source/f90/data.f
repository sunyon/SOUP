*----------------------------------------------------------------------*
*                          SUBROUTINE READCO2                          *
*                          ******************                          *
* This routine reads in co2 values from the file co2 which in found in *
* the stinput directory. If only one record exists in the file then    *
* the co2 value in this record is used throughout the simulation.      *
*----------------------------------------------------------------------*
      SUBROUTINE READCO2(stco2,yr0,yrf,co2)
*----------------------------------------------------------------------*
      INCLUDE 'array_dims.inc'
      REAL*8 co2(maxyrs),ca
      INTEGER yr0,yrf,norecs,year,const,blank,kode
      CHARACTER stco2*1000

      OPEN(98,FILE=stco2,STATUS='OLD',iostat=kode)
      IF (kode.NE.0) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'Co2 file does not exist.'
        WRITE(*,'('' "'',A,''"'')') stco2(1:blank(stco2))
        STOP
      ENDIF

      norecs = 0
      const = 0
10    CONTINUE
        READ(98,*,end=99) year,ca
	IF ((year.GE.yr0).AND.(year.LE.10000)) THEN
          co2(norecs+1) = ca
          norecs = norecs + 1
        ENDIF
        const = const + 1
      GOTO 10
99    CONTINUE

      CLOSE(98)

      IF (const.EQ.1) THEN
	DO year=yr0,yrf
	  co2(year-yr0+1) = ca
	ENDDO
      ENDIF


      RETURN
      END

*----------------------------------------------------------------------*
*                         SUBROUTINE LANDUSE1                          *
*----------------------------------------------------------------------*
      SUBROUTINE LANDUSE1(luse,yr0,yrf)
*----------------------------------------------------------------------*
      INCLUDE 'array_dims.inc'
      INTEGER yr0,yrf,year,early,rep,luse(maxyrs),i,use

      early = yrf+maxyrs

      i = 1
10    CONTINUE
        READ(98,*,end=20) year,use
        IF (year-yr0+1.GT.0)  luse(year-yr0+1) = use
        IF (year.LT.early) rep = use
        i = i+1
      GOTO 10
20    CONTINUE

      DO i=1,maxyrs
        If (luse(i).GT.0) rep = luse(i)
        luse(i) = rep
      ENDDO


      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE EX_CLIM                          *
*                          ******************                          *
*                                                                      *
* Extract climate data from the climate database for the nearest site  *
* to lat,lon, replace lat,lon with the nearest cell from the database. *
*                                                                      *
*            UNIX                DOS                                   *
*                                                                      *
*            ii(4)               ii(5)   for beginning of binary file  *
*                                        records                       *
*            recl = 728          recl = 730     for binary climate     *
*            recl = 577          recl = 578     for text map           *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE EX_CLIM(stinput,lat,lon,xlatf,xlatres,xlatresn,xlon0,
     &xlonres,xlonresn,yr0,yrf,tmpv,humv,prcv,isite,year0,yearf,
     &siteno,du)
*----------------------------------------------------------------------*
      REAL*8 lat,lon,xlon0,xlatf,xlatres,xlonres,ans(12)
      INTEGER*2 tmpv(500,12,31),humv(500,12,31),prcv(500,12,31)
      INTEGER year,year0,yearf,nrec,ncol,ans2(1000),siteno,i,du
      INTEGER nyears,yr0,mnth,day,isite,yrf,blank,recl1,recl2
      INTEGER xlatresn,xlonresn,fno
      CHARACTER ii(4),jj(5)
      CHARACTER fname1*1000,fname2*1000,fname3*1000,stinput*1000,num*3

      IF (du.eq.1) THEN
        recl1 = 730
        recl2 = 6*xlonresn
      ELSE
        recl1 = 728
        recl2 = 6*xlonresn + 1
      ENDIF

      nyears = yearf - year0 + 1

      nrec = int((xlatf - lat)/xlatres + 1.0d0)
      ncol = int((lon - xlon0)/xlonres + 1.0d0)

      IF ((nrec.LE.xlatresn).AND.(ncol.LE.xlonresn)) THEN

      lat = xlatf - xlatres/2.0 - real(nrec - 1)*xlatres
      lon = xlon0 + xlonres/2.0 + real(ncol - 1)*xlonres

      fno = 90

      OPEN(fno+1,file=stinput(1:blank(stinput))//'/maskmap.dat',
     &ACCESS='DIRECT',RECL=recl2,FORM='formatted',STATUS='OLD')

      READ(fno+1,'(96i6)',REC=nrec) (ans2(i),i=1,xlonresn)
      CLOSE(fno+1)
      siteno = ans2(ncol)

      isite = 0
      IF (siteno.GT.0) THEN

        isite = 1

        WRITE(num,'(i3.3)') (siteno-1)/100
        WRITE(fname1,'(100a)') (stinput(i:i),i=1,blank(stinput)),
     &'/tmp_',num
        WRITE(fname2,'(100a)') (stinput(i:i),i=1,blank(stinput)),
     &'/hum_',num
        WRITE(fname3,'(100a)') (stinput(i:i),i=1,blank(stinput)),
     &'/prc_',num

        siteno = mod(siteno-1,100) + 1

        OPEN(fno+1,file=fname1,access='direct',recl=recl1,
     &form='unformatted',status='old')
        OPEN(fno+2,file=fname2,access='direct',recl=recl1,
     &form='unformatted',status='old')
        OPEN(fno+3,file=fname3,access='direct',recl=recl1,
     &form='unformatted',status='old')

        IF (du.eq.1) THEN
        DO year=yr0,yrf
            READ(fno+1,REC=(siteno-1)*nyears+year-year0+1) jj,
     &((tmpv(year-yr0+1,mnth,day),day=1,30),mnth=1,12)
            READ(fno+2,REC=(siteno-1)*nyears+year-year0+1) jj,
     &((humv(year-yr0+1,mnth,day),day=1,30),mnth=1,12)
            READ(fno+3,REC=(siteno-1)*nyears+year-year0+1) jj,
     &((prcv(year-yr0+1,mnth,day),day=1,30),mnth=1,12)
            DO mnth=1,12
              DO day=1,30
                prcv(year-yr0+1,mnth,day) = 
     &int(real(prcv(year-yr0+1,mnth,day))/10.0 + 0.5)
              ENDDO
            ENDDO
          ENDDO
        ELSE
          DO year=yr0,yrf
            READ(fno+1,REC=(siteno-1)*nyears+year-year0+1) ii,
     &((tmpv(year-yr0+1,mnth,day),day=1,30),mnth=1,12)
            READ(fno+2,REC=(siteno-1)*nyears+year-year0+1) ii,
     &((humv(year-yr0+1,mnth,day),day=1,30),mnth=1,12)
            READ(fno+3,REC=(siteno-1)*nyears+year-year0+1) ii,
     &((prcv(year-yr0+1,mnth,day),day=1,30),mnth=1,12)
            DO mnth=1,12
              DO day=1,30
                prcv(year-yr0+1,mnth,day) = 
     &int(real(prcv(year-yr0+1,mnth,day))/10.0 + 0.5)
              ENDDO
            ENDDO
          ENDDO
        ENDIF

        CLOSE(fno+1)
        CLOSE(fno+2)
        CLOSE(fno+3)

      ENDIF

      ELSE
        siteno = 0
      ENDIF

      do mnth=1,12
        ans(mnth) = 0.0d0
        do day=1,30
          ans(mnth) = ans(mnth) + real(tmpv(1,mnth,day))/100.0d0
        enddo
      enddo


      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE EX_CLIM_SITE                     *
*                          ***********************                     *
*                                                                      *
* Extract climate data from the climate database for the nearest site  *
* to lat,lon, replace lat,lon with the nearest cell from the database. *
*                                                                      *
*            UNIX                DOS                                   *
*                                                                      *
*            ii(4)               ii(5)   for beginning of binary file  *
*                                        records                       *
*            recl = 728          recl = 730     for binary climate     *
*            recl = 577          recl = 578     for text map           *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE EX_CLIM_SITE(stinput,yr0,yrf,tmpv,humv,prcv,year0,
     &yearf)
*----------------------------------------------------------------------*
      REAL*8 tmp,prc,hum
      REAL*8 tmpv(500,12,31),humv(500,12,31),prcv(500,12,31)
      INTEGER year,year0,yearf,yr0,mnth,day,yrf,iyear,imnth,iday
      INTEGER blank,no_days
      CHARACTER stinput*1000

      OPEN(91,file=stinput(1:blank(stinput))//'/site.dat')

      DO year=year0,yearf
        DO mnth=1,12
          DO day=1,no_days(year,mnth,0)
            READ(91,*) iyear,imnth,iday,tmp,prc,hum
            IF ((iday.NE.day).OR.(imnth.NE.mnth).OR.(iyear.NE.year)) 
     &THEN
              WRITE(*,'('' PROGRAM TERMINATED'')')
              WRITE(*,*) 'Error in climate data file',year,mnth,day
              STOP
            ENDIF

            IF ((year.LE.yrf).AND.(year.GE.yr0)) THEN
              tmpv(year-yr0+1,mnth,day) = tmp*100.0d0
              prcv(year-yr0+1,mnth,day) = prc*10.0d0
              humv(year-yr0+1,mnth,day) = hum*100.0d0
            ENDIF
          ENDDO
        ENDDO
      ENDDO

      CLOSE(91)


      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE EX_CLIM_SITE_MONTH               *
*                          *****************************               *
*                                                                      *
* Extract climate data from the climate database for the nearest site  *
* to lat,lon, replace lat,lon with the nearest cell from the database. *
*                                                                      *
*            UNIX                DOS                                   *
*                                                                      *
*            ii(4)               ii(5)   for beginning of binary file  *
*                                        records                       *
*            recl = 728          recl = 730     for binary climate     *
*            recl = 577          recl = 578     for text map           *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE EX_CLIM_SITE_MONTH(stinput,yr0,yrf,tmpv,humv,prcv,cldv,
     &year0,yearf)
*----------------------------------------------------------------------*
      REAL*8 tmp(12),prc(12),hum(12),cld(12),cldv(500,12)
      REAL*8 tmpv(500,12,31),humv(500,12,31),prcv(500,12,31)
      INTEGER year,year0,yearf,yr0,mnth,day,yrf,iyear,imnth,iday
      INTEGER blank,no_days,fno,cld_default,kode
      LOGICAL cloud
      CHARACTER stinput*1000

      cld_default = 50

      fno = 90

      OPEN(fno+1,file=stinput(1:blank(stinput))//'/tmp.dat',
     &status='old',iostat=kode)
      OPEN(fno+2,file=stinput(1:blank(stinput))//'/prc.dat',
     &status='old',iostat=kode)
      OPEN(fno+3,file=stinput(1:blank(stinput))//'/hum.dat',
     &status='old',iostat=kode)
      INQUIRE(file=stinput(1:blank(stinput))//'/cld.dat',
     &exist=cloud)
      IF (cloud) THEN
        OPEN(fno+4,file=stinput(1:blank(stinput))//'/cld.dat',
     &status='old',iostat=kode)
      ENDIF

      DO year=year0,yearf
        READ(fno+1,*) iyear,tmp
        READ(fno+2,*) iyear,prc
        READ(fno+3,*) iyear,hum
        IF (cloud)  READ(fno+4,*) iyear,cld
        IF (iyear.NE.year) THEN
          WRITE(*,'('' PROGRAM TERMINATED'')')
          WRITE(*,*) 'Error in climate data file',year,mnth,day
          STOP
        ENDIF

        IF ((year.LE.yrf).AND.(year.GE.yr0)) THEN
          DO mnth=1,12
            tmpv(year-yr0+1,mnth,1) = tmp(mnth)
            prcv(year-yr0+1,mnth,1) = prc(mnth)
            humv(year-yr0+1,mnth,1) = hum(mnth)
            IF (cloud) THEN
              cldv(year-yr0+1,mnth) = cld(mnth)
            ELSE
              cldv(year-yr0+1,mnth) = cld_default
            ENDIF
          ENDDO
        ENDIF

      ENDDO

      CLOSE(fno+1)
      CLOSE(fno+2)
      CLOSE(fno+3)
      CLOSE(fno+4)

      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE EX_SOIL                          *
*                          ******************                          *
*                                                                      *
* Extract % sand % silt bulk density and depth from soils database.    *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE EX_SOIL(fname1,lat,lon,sol_chr2,du,l_soil)
*----------------------------------------------------------------------*
      REAL*8 lat,lon,lon0,latf,latr,lonr,xlat,xlon,sol_chr2(10)
      INTEGER blank,row,col,recn,recl1,du,latn,lonn,i,ii,jj,kode
      CHARACTER fname1*1000
      INTEGER indx1(4,4),indx2(4,4),indx3(4,4),indx4(4,4)
      INTEGER indx5(4,4),indx6(4,4),indx7(4,4),indx8(4,4)
      REAL*8 xx1(4,4),xx2(4,4),xx3(4,4),xx4(4,4)
      REAL*8 xx5(4,4),xx6(4,4),xx7(4,4),xx8(4,4)
      REAL*8 ynorm,xnorm,rrow,rcol
      REAL*8 ans
      LOGICAL l_soil(20)

      IF (du.eq.1) THEN
        recl1 = 16+8*10
      ELSE
        recl1 = 16+8*10+1
      ENDIF

      OPEN(99,FILE=fname1(1:blank(fname1))//'/readme.dat',STATUS='old',
     &iostat=kode)
      IF (kode.NE.0) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'Soil data file does not exist.'
        WRITE(*,'('' "'',A,''/readme.dat"'')') fname1(1:blank(fname1))
        STOP
      ENDIF

      READ(99,*)
      READ(99,*) latf,lon0
      READ(99,*)
      READ(99,*) latr,lonr
      READ(99,*)
      READ(99,*) latn,lonn
      CLOSE(99)

*----------------------------------------------------------------------*
* Find the real row col corresponding to lat and lon.                  *
*----------------------------------------------------------------------*
      rrow = (latf - lat)/latr
      rcol = (lon - lon0)/lonr

      ynorm = rrow - real(int(rrow))
      xnorm = rcol - real(int(rcol))
*----------------------------------------------------------------------*

      OPEN(99,FILE=fname1(1:blank(fname1))//'/data.dat',STATUS='old',
     &FORM='formatted',ACCESS='direct',RECL=recl1,iostat=kode)
      IF (kode.NE.0) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'Soil data-base.'
        WRITE(*,*) 'File does not exist:',fname1(1:blank(fname1)),
     &'/data.dat'
        WRITE(*,*) 'Or record length missmatch, 16 + 8*10.'
        STOP
      ENDIF

      DO ii=1,4
        DO jj=1,4
          row = int(rrow)+jj-1
          col = int(rcol)+ii-1
          IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.
     &(col.LE.lonn)) THEN
            recn = (row-1)*lonn + col
            READ(99,'(f7.3,f9.3,8f10.4)',rec=recn)
     & xlat,xlon,(sol_chr2(i),i=1,8)
            xx1(ii,jj) = sol_chr2(1)
            xx2(ii,jj) = sol_chr2(2)
            xx3(ii,jj) = sol_chr2(3)
            xx4(ii,jj) = sol_chr2(4)
            xx5(ii,jj) = sol_chr2(5)
            xx6(ii,jj) = sol_chr2(6)
            xx7(ii,jj) = sol_chr2(7)
            xx8(ii,jj) = sol_chr2(8)
            IF (sol_chr2(1).LT.0.0d0) THEN
              indx1(ii,jj) = 0
            ELSE
              indx1(ii,jj) = 1
            ENDIF
            IF (sol_chr2(2).LT.0.0d0) THEN
              indx2(ii,jj) = 0
            ELSE
              indx2(ii,jj) = 1
            ENDIF
            IF (sol_chr2(3).LT.0.0d0) THEN
              indx3(ii,jj) = 0
            ELSE
              indx3(ii,jj) = 1
            ENDIF
            IF (sol_chr2(4).LT.0.0d0) THEN
              indx4(ii,jj) = 0
            ELSE
              indx4(ii,jj) = 1
            ENDIF
            IF (sol_chr2(5).LT.0.0d0) THEN
              indx5(ii,jj) = 0
            ELSE
              indx5(ii,jj) = 1
            ENDIF
            IF (sol_chr2(6).LT.0.0d0) THEN
              indx6(ii,jj) = 0
            ELSE
              indx6(ii,jj) = 1
            ENDIF
            IF (sol_chr2(7).LT.0.0d0) THEN
              indx7(ii,jj) = 0
            ELSE
              indx7(ii,jj) = 1
            ENDIF
            IF (sol_chr2(8).LT.0.0d0) THEN
              indx8(ii,jj) = 0
            ELSE
              indx8(ii,jj) = 1
            ENDIF
          ELSE
            indx1(ii,jj) = -1
            indx2(ii,jj) = -1
            indx3(ii,jj) = -1
            indx4(ii,jj) = -1
            indx5(ii,jj) = -1
            indx6(ii,jj) = -1
            indx7(ii,jj) = -1
            indx8(ii,jj) = -1
          ENDIF
        ENDDO
      ENDDO

      CLOSE(99)

      IF ((indx1(2,2).EQ.1).OR.(indx1(2,3).EQ.1).OR.(indx1(3,2).EQ.1).OR
     &.(indx1(3,3).EQ.1)) THEN
        CALL BI_LIN(xx1,indx1,xnorm,ynorm,ans)
        sol_chr2(1) = ans
        l_soil(1) = .TRUE.
      ELSE
        l_soil(1) = .FALSE.
      ENDIF
      IF ((indx2(2,2).EQ.1).OR.(indx2(2,3).EQ.1).OR.(indx2(3,2).EQ.1).OR
     &.(indx2(3,3).EQ.1)) THEN
        CALL BI_LIN(xx2,indx2,xnorm,ynorm,ans)
        sol_chr2(2) = ans
        l_soil(2) = .TRUE.
      ELSE
        l_soil(2) = .FALSE.
      ENDIF
      IF ((indx3(2,2).EQ.1).OR.(indx3(2,3).EQ.1).OR.(indx3(3,2).EQ.1).OR
     &.(indx3(3,3).EQ.1)) THEN
        CALL BI_LIN(xx3,indx3,xnorm,ynorm,ans)
        sol_chr2(3) = ans
        l_soil(3) = .TRUE.
      ELSE
        l_soil(3) = .FALSE.
      ENDIF
      IF ((indx4(2,2).EQ.1).OR.(indx4(2,3).EQ.1).OR.(indx4(3,2).EQ.1).OR
     &.(indx4(3,3).EQ.1)) THEN
        CALL BI_LIN(xx4,indx4,xnorm,ynorm,ans)
        sol_chr2(4) = ans
        l_soil(4) = .TRUE.
      ELSE
        l_soil(4) = .FALSE.
      ENDIF
      IF ((indx5(2,2).EQ.1).OR.(indx5(2,3).EQ.1).OR.(indx5(3,2).EQ.1).OR
     &.(indx5(3,3).EQ.1)) THEN
        CALL BI_LIN(xx5,indx5,xnorm,ynorm,ans)
        sol_chr2(5) = ans
        l_soil(5) = .TRUE.
      ELSE
        l_soil(5) = .FALSE.
      ENDIF
      IF ((indx6(2,2).EQ.1).OR.(indx6(2,3).EQ.1).OR.(indx6(3,2).EQ.1).OR
     &.(indx6(3,3).EQ.1)) THEN
        CALL BI_LIN(xx6,indx6,xnorm,ynorm,ans)
        sol_chr2(6) = ans
        l_soil(6) = .TRUE.
      ELSE
        l_soil(6) = .FALSE.
      ENDIF
      IF ((indx7(2,2).EQ.1).OR.(indx7(2,3).EQ.1).OR.(indx7(3,2).EQ.1).OR
     &.(indx7(3,3).EQ.1)) THEN
        CALL BI_LIN(xx7,indx7,xnorm,ynorm,ans)
        sol_chr2(7) = ans
        l_soil(7) = .TRUE.
      ELSE
        l_soil(7) = .FALSE.
      ENDIF
      IF ((indx8(2,2).EQ.1).OR.(indx8(2,3).EQ.1).OR.(indx8(3,2).EQ.1).OR
     &.(indx8(3,3).EQ.1)) THEN
        CALL BI_LIN(xx8,indx8,xnorm,ynorm,ans)
        sol_chr2(8) = ans
        l_soil(8) = .TRUE.
      ELSE
        l_soil(8) = .FALSE.
      ENDIF


      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE EX_LU                            *
*                          ****************                            *
*                                                                      *
* Extract land use from land use soils database for the nearest        *
* site to lat,lon, replace lat,lon with the nearest cell from the      *
* database.                                                            *
*                                                                      *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE EX_LU(fname1,lat,lon,luse,yr0,yrf,du)
*----------------------------------------------------------------------*
      INCLUDE 'array_dims.inc'
      REAL*8 lat,lon,lon0,latf,latr,lonr,xlat,xlon
      INTEGER i,n_fields,n,j,du,latn,lonn,blank,row,col,recn,kode
      INTEGER luse(maxyrs),yr0,yrf,rep,years(1000),lu(1000),nrecl
      CHARACTER fname1*1000,st1*1000

      OPEN(99,FILE=fname1(1:blank(fname1))//'/readme.dat')
      READ(99,*)
      READ(99,*) latf,lon0
      READ(99,*)
      READ(99,*) latr,lonr
      READ(99,*)
      READ(99,*) latn,lonn
      READ(99,*)
      READ(99,'(A)') st1
      CLOSE(99)

      n = n_fields(st1)
      CALL ST2ARR(st1,years,1000,n)

      IF (du.eq.1) THEN
        nrecl = 16+n*3
      ELSE
        nrecl = 16+n*3+1
      ENDIF

      lu(1) = 0
      OPEN(99,FILE=fname1(1:blank(fname1))//'/landuse.dat',STATUS='old',
     &FORM='formatted',ACCESS='direct',RECL=nrecl,iostat=kode)
      IF (kode.NE.0) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'File does not exist:',fname1(1:blank(fname1)),'/lan
     &duse.dat'
        STOP
      ENDIF


      row = int((latf - lat)/latr + 1.0d0)
      col = int((lon - lon0)/lonr + 1.0d0)

      recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',REC=recn) xlat,xlon,(lu(i),i=1,n)

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat + latr))/latr + 1.0d0)
        col = int(((lon) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat - latr))/latr + 1.0d0)
        col = int(((lon) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat))/latr + 1.0d0)
        col = int(((lon + lonr) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat))/latr + 1.0d0)
        col = int(((lon - lonr) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat + latr))/latr + 1.0d0)
        col = int(((lon + lonr) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat - latr))/latr + 1.0d0)
        col = int(((lon + lonr) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat + latr))/latr + 1.0d0)
        col = int(((lon - lonr) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      IF (lu(1).eq.0) THEN
        row = int((latf - (lat - latr))/latr + 1.0d0)
        col = int(((lon - lonr) - lon0)/lonr + 1.0d0)
        recn = (row-1)*lonn + col
      IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.(col.LE.lonn))
     &READ(99,'(f7.3,f9.3,1000i3)',
     &REC=int(min(recn,latn*lonn))) xlat,xlon,(lu(i),i=1,n)
      ENDIF

      CLOSE(99)

      rep = lu(1)
      j = 1
      DO i=1,n
        IF (yr0.GE.years(j+1)) THEN
          rep = lu(i)
          j = i
        ENDIF
      ENDDO

      DO i=1,yrf-yr0+1
        IF ((i+yr0-1.GE.years(j+1)).AND.(j.LT.n)) THEN
          j = j+1
          rep = lu(j)
        ENDIF
        luse(i) = rep
      ENDDO


      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE EX_CLU                           *
*                          *****************                           *
*                                                                      *
* Extract land use from land use soils database for the nearest        *
* site to lat,lon, replace lat,lon with the nearest cell from the      *
* database.                                                            *
* The data contains the percent (in byte format) for each pft from 2   *
* to nft                                                               *
*                                                                      *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE EX_CLU(fname1,lat,lon,nft,lutab,cluse,yr0,yrf,du,l_lu)
*----------------------------------------------------------------------*
      INCLUDE 'array_dims.inc'
      REAL*8 lat,lon,lon0,latf,latr,lonr,classprop(255)
      REAL*8 cluse(maxnft,maxyrs),lutab(255,100),ans
      REAL*8 ftprop(maxnft),rrow,rcol,xx(4,4),xnorm,ynorm
      INTEGER i,n_fields,n,j,du,latn,lonn,blank,row,col,recn,k,x,nft,ift
      INTEGER ii,jj,stcmp,indx(4,4),yr0,yrf,years(1000),nrecl
      INTEGER classes(1000),nclasses,kode
      CHARACTER fname1*1000,st1*1000,st2*1000,in2st*1000,st3*1000
      LOGICAL l_lu

*----------------------------------------------------------------------*
* Read in the readme file 'readme.dat'.                                *
*----------------------------------------------------------------------*
      OPEN(99,FILE=fname1(1:blank(fname1))//'/readme.dat',status='old',
     &iostat=kode)
      IF (kode.NE.0) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'Land use file does not exist.'
        WRITE(*,'('' "'',A,''/readme.dat"'')') fname1(1:blank(fname1))
        STOP
      ENDIF

      READ(99,*) st1
      st2='CONTINUOUS'
      IF (stcmp(st1,st2).EQ.0) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'landuse is not a continuous field ?'
        WRITE(*,*) 'readme.dat should begin with CONTINUOUS'
        STOP
      ENDIF
      READ(99,*)
      READ(99,*) latf,lon0
      READ(99,*)
      READ(99,*) latr,lonr
      READ(99,*)
      READ(99,*) latn,lonn
      READ(99,*)
      READ(99,'(A)') st1
      n = n_fields(st1)
      CALL ST2ARR(st1,years,1000,n)
      READ(99,*)
      READ(99,'(A)') st1
      CLOSE(99)
      nclasses = n_fields(st1)
      CALL ST2ARR(st1,classes,1000,nclasses)
*----------------------------------------------------------------------*

      IF (du.eq.1) THEN
        nrecl = 3
      ELSE
        nrecl = 4
      ENDIF

      IF ((n.GT.1).AND.(yr0.LT.years(1))) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'Can''t start running in ',yr0,
     &        ' since landuse map begin in ',years(1)
        STOP
      ENDIF

c     look for the first year
      j=1

 10   CONTINUE
      IF ((j.LT.n).AND.(years(j).LT.yr0)) THEN
         j = j + 1
         GOTO 10
      ENDIF

*----------------------------------------------------------------------*
* Find the real row col corresponding to lat and lon.                  *
*----------------------------------------------------------------------*
      rrow = (latf - lat)/latr
      rcol = (lon - lon0)/lonr

      ynorm = rrow - real(int(rrow))
      xnorm = rcol - real(int(rcol))
*----------------------------------------------------------------------*

      j=1
      DO i=1,yrf-yr0+1
        IF ((i.EQ.1).OR.((i+yr0-1).EQ.years(j))) THEN
          st2=in2st(years(j))
          CALL STRIPB(st2)
          j=j+1

          DO k=1,nclasses
            classprop(classes(k)) = 0

            st3=in2st(classes(k))
            CALL STRIPB(st3)
            OPEN(99,FILE=fname1(1:blank(fname1))//'/cont_lu-'//st3(1:bla
     &nk(st3))//'-'//st2(1:4)//'.dat',STATUS='old',FORM='formatted',
     &ACCESS='direct',RECL=nrecl,iostat=kode)
            IF (kode.NE.0) THEN
              WRITE(*,'('' PROGRAM TERMINATED'')')
              WRITE(*,*) 'Land Use data-base.'
              WRITE(*,*) 'File does not exist:'
              WRITE(*,*) fname1(1:blank(fname1)),
     &'/cont_lu-',st3(1:blank(st3)),'-',st2(1:4),'.dat'
              STOP
            ENDIF


            DO ii=1,4
              DO jj=1,4
                row = int(rrow)+jj-1
                col = int(rcol)+ii-1
                IF ((row.GE.1).AND.(row.LE.latn).AND.(col.GE.1).AND.
     &(col.LE.lonn)) THEN
                  recn = (row-1)*lonn + col
                  READ(99,'(i3)',REC=recn) x
                  xx(ii,jj) = real(x)
                  IF (x.LT.200) THEN
                    indx(ii,jj) = 1
                  ELSE
                    indx(ii,jj) = 0
                  ENDIF
                ELSE
                  indx(ii,jj) = -1
                ENDIF
              ENDDO
            ENDDO

            CALL BI_LIN(xx,indx,xnorm,ynorm,ans)

            x = int(ans+0.5d0)

            classprop(classes(k)) = ans
            CLOSE(99)

          ENDDO ! end of loop over the classes

c
c Now calculate the ftprop.
c
          DO ift=2,nft
            ftprop(ift)=0.0d0
            DO k=1,nclasses
              ftprop(ift)=ftprop(ift)+lutab(classes(k),ift)*
     &classprop(classes(k))/100.0d0
*              print*,ift,k,x,lutab(classes(k),ift),classes(k)
            ENDDO
          ENDDO

c
c Calculate the bare soil.
c
          IF ((ftprop(2).LE.100).AND.(ftprop(2).GE.0)) THEN
            ftprop(1)=100
            DO ift=2,nft
              ftprop(1)=ftprop(1)-ftprop(ift)
            ENDDO
          ENDIF

        ENDIF ! finished reading

        DO ift=1,nft
          cluse(ift,i) = ftprop(ift)
        ENDDO

      ENDDO

*      CLOSE(99)

      IF ((indx(2,2).EQ.1).OR.(indx(2,3).EQ.1).OR.(indx(3,2).EQ.1).OR.
     &(indx(3,3).EQ.1)) THEN
        l_lu = .TRUE.
      ELSE
        l_lu = .FALSE.
      ENDIF


      RETURN
      END

*----------------------------------------------------------------------*
      SUBROUTINE lorc(du,lat,lon,latdel,londel,stmask,xx)
*----------------------------------------------------------------------*
      IMPLICIT NONE
      LOGICAL xx
      REAL*8 lat,lon,latdel,londel,del,latf,lon0
      CHARACTER outc(6200),stmask*1000
      INTEGER i,j,k,x(7),ians(43300),sum1,n,col,row,check,nrecl,du,blank
      INTEGER kode,ii

      IF (du.eq.1) THEN
        nrecl = 6172
      ELSE
        nrecl = 6172 + 1
      ENDIF

      OPEN(99,file=stmask(1:blank(stmask))//'/land_mask.dat',
     &form='formatted',recl=nrecl,access='direct',status='old',
     &iostat=kode)
      IF (kode.NE.0) THEN
        WRITE(*,'('' PROGRAM TERMINATED'')')
        WRITE(*,*) 'Land sea mask.'
        WRITE(*,*) 'Either the file doesn''t exist or there is a record 
     & length miss match.'
        WRITE(*,*) 'Check that the correct DOS|UNIX switch is being use
     &d in the input file.' 
        WRITE(*,*) 'Land sea file :',stmask(1:blank(stmask))
        STOP
      ENDIF

      del = 1.0d0/60.0d0/2.0d0
      latf = 90.0d0 - del/2.0d0
      lon0 =-180.0d0 + del/2.0d0


      col = int((lon - lon0)/del + 0.5d0)
      row = int((latf - lat)/del + 0.5d0)

      n = min((latdel/del-1.0d0)/2.0d0,(londel/del-1.0d0)/2.0d0)

*----------------------------------------------------------------------*
* Check nearest pixel for land.                                        *
*----------------------------------------------------------------------*
      sum1 = 0
      READ(99,'(6172a)',rec=row) (outc(j),j=1,6172)

      DO j=1,6172
        CALL base72i(outc(j),x)
        DO k=1,7
          ians(7*(j-1)+k) = x(k)
        ENDDO
      ENDDO
      IF (ians(col).GT.0) sum1 = sum1 + 1
      check = 1

*----------------------------------------------------------------------*

      IF (n.GT.0) THEN
*----------------------------------------------------------------------*
* Check outward diagonals for land.                                    *
*----------------------------------------------------------------------*
        DO ii=1,n/4
          i = 4*ii
          READ(99,'(6172a)',rec=row+i) (outc(j),j=1,6172)
          DO j=1,6172
            CALL base72i(outc(j),x)
            DO k=1,7
              ians(7*(j-1)+k) = x(k)
            ENDDO
          ENDDO
          IF (ians(col+i).GT.0) sum1 = sum1 + 1
          IF (ians(col-i).GT.0) sum1 = sum1 + 1

          READ(99,'(6172a)',rec=row-i) (outc(j),j=1,6172)
          DO j=1,6172
            CALL base72i(outc(j),x)
            DO k=1,7
              ians(7*(j-1)+k) = x(k)
            ENDDO
          ENDDO
          IF (ians(col+i).GT.0) sum1 = sum1 + 1
          IF (ians(col-i).GT.0) sum1 = sum1 + 1
          check = check + 4
        ENDDO
*----------------------------------------------------------------------*
      ENDIF

      CLOSE(99)

      IF (real(sum1).GE.(check+1)/2) then
        xx = .true.
      ELSE
        xx = .false.
      ENDIF
      xx = .true.

      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE BASE72I                          *
*                          ******************                          *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE base72i(c,x)
*----------------------------------------------------------------------*
      CHARACTER c
      INTEGER x(7),i

      i=ichar(c)-100
      x(1)=i/64
      i=i-x(1)*64
      x(2)=i/32
      i=i-x(2)*32
      x(3)=i/16
      i=i-x(3)*16
      x(4)=i/8
      i=i-x(4)*8
      x(5)=i/4
      i=i-x(5)*4
      x(6)=i/2
      i=i-x(6)*2
      x(7)=i


      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          FUNCTION n7                                 *
*                          ***********                                 *
*                                                                      *
* Returns the value of a seven digit binary number given as a seven    *
* dimensional array of 0's and 1's                                     *
*                                                                      *
*----------------------------------------------------------------------*
      FUNCTION n7(x)
*----------------------------------------------------------------------*
      INTEGER n7,x(7)

      n7 = 64*x(1)+32*x(2)+16*x(3)+8*x(4)+4*x(5)+2*x(6)+x(7)
 

      RETURN
      END

*----------------------------------------------------------------------*
*                                                                      *
*                          SUBROUTINE BI_LIN                           *
*                          *****************                           *
*                                                                      *
* Performs bilinear interpolation between four points, the normalised  *
* distances from the point (1,1) are given by 'xnorm' and 'ynorm'.     *
*                                                                      *
*----------------------------------------------------------------------*
      SUBROUTINE BI_LIN(xx,indx,xnorm,ynorm,ans)
*----------------------------------------------------------------------*
      REAL*8 xx(4,4),xnorm,ynorm,ans,av
      INTEGER indx(4,4),iav,ii,jj

*----------------------------------------------------------------------*
* Fill in averages if necessary.                                       *
*----------------------------------------------------------------------*
      DO ii=2,3
        DO jj=2,3
          IF (indx(ii,jj).NE.1) THEN
            av = 0.0d0
            iav = 0
            IF (indx(ii+1,jj).EQ.1) THEN
              av = av + xx(ii+1,jj)
              iav = iav + 1
            ENDIF 
            IF (indx(ii-1,jj).EQ.1) THEN
              av = av + xx(ii-1,jj)
              iav = iav + 1
            ENDIF 
            IF (indx(ii,jj+1).EQ.1) THEN
              av = av + xx(ii,jj+1)
              iav = iav + 1
            ENDIF 
            IF (indx(ii,jj-1).EQ.1) THEN
              av = av + xx(ii,jj-1)
              iav = iav + 1
            ENDIF
            IF (indx(ii+1,jj+1).EQ.1) THEN
              av = av + xx(ii+1,jj+1)
              iav = iav + 1
            ENDIF
            IF (indx(ii-1,jj-1).EQ.1) THEN
              av = av + xx(ii-1,jj-1)
              iav = iav + 1
            ENDIF
            IF (indx(ii+1,jj-1).EQ.1) THEN
              av = av + xx(ii+1,jj-1)
              iav = iav + 1
            ENDIF
            IF (indx(ii-1,jj+1).EQ.1) THEN
              av = av + xx(ii-1,jj+1)
              iav = iav + 1
            ENDIF
            IF (iav.GT.0) THEN
              xx(ii,jj) = av/real(iav)
            ENDIF
          ENDIF
        ENDDO
      ENDDO

*----------------------------------------------------------------------*
* Bilinear interpolation.                                              *
*----------------------------------------------------------------------*
        ans = xx(2,2)*(1.0d0-xnorm)*(1.0d0-ynorm) + 
     &        xx(3,2)*xnorm*(1.0d0-ynorm) + 
     &        xx(2,3)*(1.0d0-xnorm)*ynorm + 
     &        xx(3,3)*xnorm*ynorm

*----------------------------------------------------------------------*
* Nearest pixel.                                                       *
*----------------------------------------------------------------------*
*        ans = xx(int(xnorm+2.5d0),int(ynorm+2.5d0))
*----------------------------------------------------------------------*


      RETURN
      END


