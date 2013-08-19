C
C
      SUBROUTINE SFT5AR(IN)
C***********************************************************************
C     THIS SUBROUTINE ALLOCATES SPACE FOR SFR VARIABLES
C***********************************************************************
      USE SFRVARS
      USE MT3DMS_MODULE, ONLY: INSFT,IOUT,NCOMP
      INTEGER IN
      LOGICAL OPND
C
      ALLOCATE(NSFINIT,MXSFBC,ICBCSF,IOUTOBS,IETSFR,MXUZCON)      !# NEW
      ALLOCATE(NSSSF)                                             !# NEW
C
C--PRINT PACKAGE NAME AND VERSION NUMBER
      WRITE(IOUT,1030) INSFT
 1030 FORMAT(1X,'SFT -- STREAM TRANSPORT PACKAGE,',
     & ' VERSION 1, AUGUST 2012, INPUT READ FROM UNIT',I3)
C
C--READ NUMBER OF STREAMS
      READ(INSFT,*) NSFINIT,MXSFBC,ICBCSF,IOUTOBS,IETSFR,MXUZCON
      WRITE(IOUT,10) NSFINIT,MXSFBC
10    FORMAT(1X,'NUMBER OF STREAMS = ',I5,
     &      /1X,'MAXIMUM NUMBER OF STREAM BOUNDARY CONDITIONS = ',I5)
      IF(ICBCSF.GT.0) WRITE(IOUT,12) ICBCSF
12    FORMAT(1X,'RCH-BY-RCH INFORMATION WILL BE PRINTED ON UNIT ',I5)
      IF(IOUTOBS.GT.0) THEN
        WRITE(IOUT,13) IOUTOBS
13      FORMAT(1X,'STREAM-FLOW OBSERVATION OUTPUT ',
     &   ' WILL BE SAVED IN UNIT:',I3)
        INQUIRE(UNIT=IOUTOBS,OPENED=OPND)
        IF(.NOT.OPND) THEN
          WRITE(IOUT,*) 'TO CREATE STREAM-FLOW OBSERVATION OUTPUT FILE',
     1    'NAM FILE MUST CONTAIN UNIT NUMBER ',IOUTOBS
          WRITE(*,*) 'TO CREATE STREAM-FLOW OBSERVATION OUTPUT FILE, ',
     1    'NAM FILE MUST CONTAIN UNIT NUMBER ',IOUTOBS
          STOP
        ENDIF
      ENDIF
      WRITE(IOUT,14) MXUZCON
14    FORMAT(1X,'MAX NUMBER OF ANTICIPATED UZF->SFR & UZF->LAK ',
     &       'CONNECTIONS ',I6)
C
      IF(IETSFR.EQ.0) THEN
        WRITE(IOUT,15)
      ELSE
        WRITE(IOUT,16)
      ENDIF
15    FORMAT(1X,'MASS DOES NOT EXIT VIA STREAM ET')
16    FORMAT(1X,'MASS IS ALLOWED TO EXIT VIA STREAM ET')
C
C--ALLOCATE INITIAL AND BOUNDARY CONDITION ARRAYS
      ALLOCATE(CNEWSF(NSFINIT,NCOMP),COLDSF(NSFINIT,NCOMP),
     1  COLDSF2(NSFINIT,NCOMP),CNEWSFTMP(NSFINIT,NCOMP),
     1  DISPSF(NSFINIT,NCOMP),IBNDSF(NSFINIT))
      ALLOCATE(ISEGBC(MXSFBC),IRCHBC(MXSFBC),ISFBCTYP(MXSFBC))    !# MOVED
      ALLOCATE(CBCSF(MXSFBC,NCOMP))                               !# MOVED
      CBCSF=0.
      ALLOCATE(RMASSF(NLKINIT),VOUTSF(NLKINIT))
      RMASSF=0.
      IBNDSF=1
      ALLOCATE(IROUTE(7,MXUZCON),UZQ(4,MXUZCON))
C
C--CUMULATIVE BUDGET TERMS
      ALLOCATE(CFLOINSF(NCOMP),CFLOOUTSF(NCOMP),CGW2SFR(NCOMP),
     1  CGWFROMSFR(NCOMP),CLAK2SFR(NCOMP),CLAKFROMSFR(NCOMP),
     1  CPRECSF(NCOMP),CRUNOFSF(NCOMP),CETSF(NCOMP),CSTORINSF(NCOMP),
     1  CSTOROTSF(NCOMP),CCCINSF(NCOMP),CCCOUTSF(NCOMP))
      CFLOINSF=0.
      CFLOOUTSF=0.
      CGW2SFR=0.
      CGWFROMSFR=0.
      CLAK2SFR=0.
      CLAKFROMSFR=0.
      CPRECSF=0.
      CRUNOFSF=0.
      CETSF=0.
      CSTORINSF=0.
      CSTOROTSF=0.
      CCCINSF=0.
      CCCOUTSF=0.
C
C--RETURN
      RETURN
      END
C
C
      SUBROUTINE SFT5RP(KPER)
C***********************************************************************
C     THIS SUBROUTINE ALLOCATES READS LAK VARIABLES - INITIAL CONCS
C***********************************************************************
      USE SFRVARS
      USE MT3DMS_MODULE, ONLY: INSFT,IOUT,NCOMP
      CHARACTER ANAME*24
      INTEGER   KPER
C
C--PRINT A HEADER
      WRITE(IOUT,1000)
 1000 FORMAT(//1X,'STREAM INPUT PARAMETERS'/1X,23('-')/)
C
C--STREAM SOLVER SETTINGS
      READ(INSFT,*) ISFSOLV,WIMP,WUPS,CCLOSESF,MXITERSF,CRNTSF
      ISFSOLV=1
      WRITE(IOUT,20) ISFSOLV
20    FORMAT(' STREAM SOLVER OPTION = ',I5,
     1     /,'   1 = FINITE DIFFERENCE FORMULATION')
      WRITE(IOUT,22) WIMP
22    FORMAT(' STREAM SOLVER TIME WEIGHTING FACTOR = ',G12.5,
     1     /,'   0.0 = EXPLICIT SCHEME IS USED',
     1     /,'   0.5 = CRANK-NICOLSON SCHEME IS USED',
     1     /,'   1.0 = FULLY IMPLICIT SCHEME IS USED')
      WRITE(IOUT,23) WUPS
23    FORMAT(' STREAM SOLVER SPACE WEIGHTING FACTOR = ',G12.5,
     1     /,'   0.0 = CENTRAL-IN-SPACE WEIGHTING',
     1     /,'   1.0 = UPSTREAM WEIGHTING')
      WRITE(IOUT,24) CCLOSESF
24    FORMAT(' CLOSURE CRITERION FOR SFT SOLVER = ',G12.5)
      WRITE(IOUT,26) MXITERSF
26    FORMAT(' MAXIMUM NUMBER OF SFR ITERATIONS = ',I5)
      WRITE(IOUT,28) CRNTSF
28    FORMAT(' COURANT CONSTRAINT FOR SFR TIME-STEP = ',I5)
C
C--CALL RARRAY TO READ IN INITIAL CONCENTRATIONS
      DO INDEX=1,NCOMP
        ANAME='STRM INIT CONC COMP#    '
        WRITE(ANAME(22:24),'(I3.3)') INDEX
        CALL RARRAY(COLDSF(:,INDEX),ANAME,1,NSFINIT,0,INSFT,IOUT)
      ENDDO
      CNEWSF=COLDSF
C
C--CALL RARRAY TO READ DISPERSION COEFFICIENTS (L2/T)
      DO INDEX=1,NCOMP
        ANAME='DISP COEF L2/T COMP#    '
        WRITE(ANAME(22:24),'(I3.3)') INDEX
        CALL RARRAY(DISPSF(:,INDEX),ANAME,1,NSFINIT,0,INSFT,IOUT)
      ENDDO
C
C--READ LIST OF STREAM GAGES
      READ(INSFT,*) NOBSSF
      ALLOCATE(ISOBS(NOBSSF),IROBS(NOBSSF))
      DO I=1,NOBSSF
        READ(INSFT,*) ISOBS(I),IROBS(I)
      ENDDO
      IF(IOUTOBS.GT.0) THEN
        WRITE(IOUTOBS,*) ' STREAM OBSERVATION OUTPUT'
        WRITE(IOUTOBS,*) ' TIME      SEGMENT     REACH    CONCENTRATION'
      ENDIF
      IF(NOBSSF.GT.0 .AND. IOUTOBS.LE.0) THEN
        WRITE(IOUT,*) '***STREAM-FLOW OBSERVATION WILL NOT BE OUTPUT***'
        WRITE(IOUT,*) 'IOUTOBS IS NON-POSITIVE'
      ENDIF
C
      RETURN
      END
C
C
      SUBROUTINE SFT5SS(KPER)
C***********************************************************************
C     THIS SUBROUTINE ALLOCATES SFR BOUNDARY CONDITIONS
C***********************************************************************
      USE SFRVARS
      USE MT3DMS_MODULE, ONLY: INSFT,IOUT,NCOMP
      CHARACTER*10 BCTYPSF
      INTEGER      KPER
C
      IN=INSFT
C
C--PRINT A HEADER
      WRITE(IOUT,1000)
 1000 FORMAT(//1X,'STREAM BOUNDARY CONDITIONS'/1X,26('-')/)
C
C--READ AND ECHO POINT SINKS/SOURCES OF SPECIFIED CONCENTRATIONS
      READ(IN,'(I10)') NTMP
C
C--BASIC CHECKS ON NTMP
      IF(KPER.EQ.1.AND.NTMP.LT.0) THEN
        WRITE(IOUT,*) 'NTMP<0 NOT ALLOWED FOR FIRST STRESS PERIOD'
        WRITE(*,*) 'NTMP<0 NOT ALLOWED FOR FIRST STRESS PERIOD'
        STOP
      ENDIF
      IF(NTMP.EQ.0) THEN
        RETURN
      ENDIF
C
C--RESET ARRAYS
      IF(NTMP.GE.0) THEN
        ISEGBC=0
        IRCHBC=0
        ISFBCTYP=0
        CBCSF=0.
      ENDIF
C
C
      IF(NTMP.GT.MXSFBC) THEN
        WRITE(*,30)
        CALL USTOP(' ')
      ELSEIF(NTMP.LT.0) THEN
        WRITE(IOUT,40)
        RETURN
      ELSEIF(NTMP.GE.0) THEN
        WRITE(IOUT,50) NTMP,KPER
        NSSSF=NTMP
        IF(NTMP.EQ.0) RETURN
      ENDIF
C
C--READ BOUNDARY CONDITIONS
      IBNDSF=1
      WRITE(IOUT,60)
      DO NUM=1,NTMP
          READ(IN,*) ISEGBC(NUM),IRCHBC(NUM),ISFBCTYP(NUM),
     1      (CBCSF(NUM,INDEX),INDEX=1,NCOMP)
C
          IF(ISFBCTYP(NUM).EQ.0) THEN
            BCTYPSF=' HEADWATER'
          ELSEIF(ISFBCTYP(NUM).EQ.1) THEN
            BCTYPSF='    PRECIP'
          ELSEIF(ISFBCTYP(NUM).EQ.2) THEN
            BCTYPSF='    RUNOFF'
          ELSEIF(ISFBCTYP(NUM).EQ.3) THEN
            BCTYPSF='CNST. CONC'
          ELSEIF(ISFBCTYP(NUM).EQ.4) THEN
            BCTYPSF='   PUMPING'
          ELSEIF(ISFBCTYP(NUM).EQ.5) THEN
            BCTYPSF='      EVAP'
          ENDIF
C
C          IF(IETSFR.EQ.0.AND.ISFBCTYP(NUM).EQ.4) THEN
C            WRITE(IOUT,*) 'ISFBCTYP=4 IS NOT VALID WHEN IETSFR=0'
C            WRITE(*,*) 'ISFBCTYP=4 IS NOT VALID WHEN IETSFR=0'
C            STOP
C          ENDIF
C
          WRITE(IOUT,70) ISEGBC(NUM),IRCHBC(NUM),BCTYPSF,
     1      (CBCSF(NUM,INDEX),INDEX=1,NCOMP)
C
C          IF(ILKBC(NUM).GT.NLKINIT) THEN
C            WRITE(IOUT,*) 'INVALID LAKE NUMBER'
C            WRITE(*,*) 'INVALID LAKE NUMBER'
C            STOP
C          ENDIF
          IF(ISFBCTYP(NUM).LT.0.OR.ISFBCTYP(NUM).GT.3) THEN
            WRITE(IOUT,*) 'INVALID STREAM BC-TYPE'
            WRITE(*,*) 'INVALID STREAM BC-TYPE'
            STOP
          ENDIF
      ENDDO
C
   30 FORMAT(/1X,'ERROR: MAXIMUM NUMBER OF STREAM SINKS/SOURCES',
     & ' EXCEEDED'/1X,'INCREASE [MXSFBC] IN SFT INPUT FILE')
   40 FORMAT(/1X,'STREAM SINKS/SOURCES OF SPECIFIED CONCENTRATION',
     & ' REUSED FROM LAST STRESS PERIOD')
   50 FORMAT(/1X,'NO. OF STREAM SINKS/SOURCES OF SPECIFIED',
     & ' CONCONCENTRATIONS =',I5,' IN STRESS PERIOD',I3)
   60 FORMAT(/5X,' SEG  RCH     BC-TYPE       CONC(1,NCOMP)')
70    FORMAT(5X,2I5,1X,A10,3X,1000(1X,G15.7))
C
      RETURN
      END
C
C
      SUBROUTINE SFT5FMGW(ICOMP)
C***********************************************************************
C     THIS SUBROUTINE FORMULATES SFT PACKAGE
C***********************************************************************
      USE SFRVARS
      USE LAKVARS, ONLY : CNEWLAK
      USE MT3DMS_MODULE, ONLY: IOUT,NCOMP,UPDLHS,CNEW,A,RHS,
     &                             DTRANS,NLAY,NROW,NCOL,ICBUND,NODES,
     &                             MIXELM
      IMPLICIT  NONE
      INTEGER N,K,I,J,NN
      INTEGER ICOMP
      REAL    Q
      REAL    CONC
C
C--FILL COEFFICIENT MATRIX A - WITH GW TO SFR TERMS
      DO N=1,NSTRM
        K=ISFL(N)     !LAYER
        I=ISFR(N)     !ROW
        J=ISFC(N)     !COLUMN
        NN=(K-1)*NCOL*NROW+(I-1)*NCOL+J
        Q=0.
        Q=QSFGW(N)    !(-)VE MEANS GW TO SFR; (+)VE MEANS SFR TO GW
        IF(Q.LT.0.) THEN
C.......CONSIDER ONLY FLOW INTO STREAM
C          CONC=CNEW(J,I,K,ICOMP)
          IF(UPDLHS) A(NN)=A(NN)+Q
C
C--FILL RHS WITH SFR TO GW TERMS USING CALCULATED SFR CONCS
        ELSE
C.......CONSIDER ONLY FLOW OUT OF STREAM
C          CONC=CNEW(J,I,K,ICOMP)
          CONC=CNEWSF(N,ICOMP)
          RHS(NN)=RHS(NN)-Q*CONC
        ENDIF
      ENDDO
C
      RETURN
      END
C
C
      SUBROUTINE SFT5FM(ICOMP)
C***********************************************************************
C     THIS SUBROUTINE ASSEMBLES AND SOLVES MATRIX FOR SFR TRANSPORT
C***********************************************************************
      USE MT3DMS_MODULE, ONLY: IOUT,NCOMP,CNEW,
     &                         DTRANS,NLAY,NROW,NCOL,ICBUND,NODES
      USE SFRVARS
      USE LAKVARS, ONLY : CNEWLAK
      USE XMDMODULE
      IMPLICIT NONE
      INTEGER ICOMP
      REAL    DELT,DELTMIN
      INTEGER K,I,J,II,JJ,N,NN,IS,IR,NC,ICNT,ISIN,IRIN,III
      REAL    CONC,Q,VOL,COEFO,COEFN
      INTEGER numactive,KKITER,ITER,N_ITER,KITERSF,NSUBSTEPS,KSFSTP
      DOUBLE PRECISION ADV1,ADV2,ADV3
C
      DELT=DTRANS
      DELTMIN=DTRANS
C
C--DETERMINE DELTSF TO HONOR COURANT CONSTRAINT
CCC      DO I=1,NSTRM
CCC        IF(QOUTSF(I).GE.1.E-3) THEN
CCC          DELT=CRNTSF*SFLEN(I)*SFNAREA(I)/QOUTSF(I)
CCC          IF(DELT.LT.DELTMIN) DELTMIN=DELT
CCC        ENDIF
CCC      ENDDO
C
CCC      IF(DELTMIN.LE.1.E-5) THEN
CCC        WRITE(*,*) 'DELTMIN IS LESS THAN 1.E-5'
CCC        STOP
CCC      ENDIF
C
CCC      NSUBSTEPS=INT(DTRANS/DELTMIN)
CCC      NSUBSTEPS=NSUBSTEPS+1
CCC      DELT=DTRANS/REAL(NSUBSTEPS)
C
CCC      DO KSFSTP=1,NSUBSTEPS
CCC      COLDSF2(:,ICOMP)=CNEWSF(:,ICOMP)
C
      RHSSF=0.
      AMATSF=0.
C
C--FILL RHSSF---------------------------------------------------------
C
C.....INFLOW BOUNDARY CONDITIONS: PRECIP AND RUNOFF
      DO I=1,NSSSF
        IS=ISEGBC(I)
        IR=IRCHBC(I)
        CONC=CBCSF(I,ICOMP)
        N=ISTRM(IR,IS)
        IF(ISFBCTYP(I).EQ.0) THEN
          !BCTYPSF=' HEADWATER'
          DO II=IDXNIN(N),IDXNIN(N+1)-1
            ISIN=INSEG(II)
            IRIN=INRCH(II)
            IF(ISIN.LT.0.AND.IRIN.LT.0 .AND.
     1         IS.EQ.-ISIN.AND.IR.EQ.-IRIN) THEN
                Q=QINSF(II)
C                IF(ISFSOLV.EQ.2) THEN
                  RHSSF(N)=RHSSF(N)-Q*CONC
C                ELSE
C                ENDIF
                GOTO 105
            ENDIF
          ENDDO
104       WRITE (*,*) 'INVLID SFR BC-TYPE',IS,IR
          STOP
105       CONTINUE
        ELSEIF(ISFBCTYP(I).EQ.1) THEN
          !BCTYPSF='    PRECIP'
          Q=QPRECSF(N)
C          IF(ISFSOLV.EQ.2) THEN
            RHSSF(N)=RHSSF(N)-Q*CONC
C          ELSE
C          ENDIF
        ELSEIF(ISFBCTYP(I).EQ.2) THEN
          !BCTYPSF='    RUNOFF'
          Q=QRUNOFSF(N)
C          IF(ISFSOLV.EQ.2) THEN
            RHSSF(N)=RHSSF(N)-Q*CONC
C          ELSE
C          ENDIF
        ENDIF
      ENDDO
C
      ICNT=0
      DO N=1,NSTRM
        K=ISFL(N)     !LAYER
        I=ISFR(N)     !ROW
        J=ISFC(N)     !COLUMN
C
C.......VOLUME/TIME: ASSUME VOLUME DOES NOT CHANGE
        VOL=SFLEN(N)*SFNAREA(N)
        VOL=VOL/DELT
C        IF(ISFSOLV.EQ.2) THEN
          RHSSF(N)=RHSSF(N)-VOL*COLDSF(N,ICOMP)
C        ELSE
C          RHSSF(N)=RHSSF(N)+COLDSF(N,ICOMP)/DELT
C        ENDIF
C
C.......INFLOW/OUTFLOW GW
        Q=QSFGW(N)
        IF(Q.LT.0.0) THEN
C          IF(ISFSOLV.EQ.2) THEN
            RHSSF(N)=RHSSF(N)+Q*CNEW(J,I,K,ICOMP)
C          ELSE
C          ENDIF
        ENDIF
C
C.......CHECK INFLOW FROM LAKE
        DO NC=1,NIN(N)
          ICNT=ICNT+1
          IS=INSEG(ICNT)
          IR=INRCH(ICNT)
          IF(IS.GT.0.AND.IR.EQ.0) THEN
            Q=QINSF(ICNT)
            CONC=CNEWLAK(IS,ICOMP)
C            IF(ISFSOLV.EQ.2) THEN
              RHSSF(N)=RHSSF(N)-Q*CONC
C            ELSE
C            ENDIF
          ENDIF
        ENDDO
      ENDDO
C--FILL RHSSF COMPLETE------------------------------------------------
C
C--FILL AMATSF--------------------------------------------------------
      ICNT=0
      DO N=1,NSTRM
        II=IASF(N)
C
C.......VOLUME/TIME: ASSUME VOLUME DOES NOT CHANGE
        VOL=SFLEN(N)*SFNAREA(N)
        VOL=VOL/DELT
C        IF(ISFSOLV.EQ.2) THEN
          AMATSF(II)=AMATSF(II)-VOL
C        ELSE
C          AMATSF(II)=AMATSF(II)+1.0D0/DELT
C        ENDIF
C
C.......TOTAL FLOW OUT INCLUDING ET
        IF(IEXIT(N).EQ.1) THEN
          IF(IETSFR.EQ.0) THEN
            Q=QOUTSF(N)-QETSF(N)
            IF(QETSF(N).GE.QOUTSF(N)) Q=0.
          ELSE
            Q=QOUTSF(N)
          ENDIF
C        IF(ISFSOLV.EQ.2) THEN
          AMATSF(II)=AMATSF(II)-Q*WIMP
          RHSSF(N)=RHSSF(N)+(1.0D0-WIMP)*Q*COLDSF(N,ICOMP)
C        ELSE
C        ENDIF
        ENDIF
C
C.......INFLOW/OUTFLOW GW
        Q=QSFGW(N)
        IF(Q.GE.0.0) THEN
C          IF(ISFSOLV.EQ.2) THEN
            AMATSF(II)=AMATSF(II)-Q*WIMP
            RHSSF(N)=RHSSF(N)+(1.0D0-WIMP)*Q*COLDSF(N,ICOMP)
C          ELSE
C          ENDIF
        ENDIF
C
C.......INFLOW FROM UPSTREAM REACHES, LAKES, FIRST REACH (IS=0,IR=0)
        DO NC=1,NIN(N)
          ICNT=ICNT+1
          IS=INSEG(ICNT)
          IR=INRCH(ICNT)
          IF(IS.GT.0.AND.IR.GT.0) THEN
C...........INFLOW FROM STREAM
            NN=ISTRM(IR,IS)
            Q=QINSF(ICNT)
            DO II=IASF(N)+1,IASF(N+1)-1
              IF(NN.EQ.JASF(II)) GOTO 110
            ENDDO
100         WRITE(*,*) 'ERROR IN JASF MATRIX'
            STOP
110         CONTINUE
C            IF(ISFSOLV.EQ.2) THEN
C            AMATSF(II)=AMATSF(II)+Q*WIMP
C            RHSSF(N)=RHSSF(N)-(1.0D0-WIMP)*Q*COLDSF(NN,ICOMP)
            III=IASF(N)
            Q=Q/(SFLEN(NN)+SFLEN(N))
            ADV1=Q*(WUPS*SFLEN(NN)+SFLEN(N))
            ADV2=Q*(1.0D0-WUPS)*SFLEN(NN)
            AMATSF(II)=AMATSF(II)+ADV1*WIMP
            RHSSF(N)=RHSSF(N)-(1.0D0-WIMP)*ADV1*COLDSF(NN,ICOMP)
            AMATSF(III)=AMATSF(III)+ADV2*WIMP
            RHSSF(N)=RHSSF(N)-(1.0D0-WIMP)*ADV2*COLDSF(N,ICOMP)
C            ELSE
C            ENDIF
C
            IF(IDSPFLG(ICNT).NE.0) THEN
C--DISPERSION
            !i=N=>AMATSF(III) and i-1=NN=>AMATSF(II) terms
C...........DISPERSION TERMS i-1,i
              COEFN= (  SFNAREA(N)*DISPSF(N,ICOMP)*SFLEN(NN)
     1                +SFNAREA(NN)*DISPSF(NN,ICOMP)*SFLEN(N))/
     1                  (SFLEN(NN)+SFLEN(N))
              COEFO= (  SFOAREA(N)*DISPSF(N,ICOMP)*SFLEN(NN)
     1                +SFOAREA(NN)*DISPSF(NN,ICOMP)*SFLEN(N))/
     1                  (SFLEN(NN)+SFLEN(N))
              III=IASF(N)
              AMATSF(III)=AMATSF(III) 
     1          - COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
              AMATSF(II)=AMATSF(II) 
     1          + COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
              RHSSF(N)=RHSSF(N)
     1   + COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(N,ICOMP)/(SFLEN(NN)+SFLEN(N))
     1  - COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(NN,ICOMP)/(SFLEN(NN)+SFLEN(N))
C              RHSSF(N)=RHSSF(N)
C     1    +COEFO*(COLDSF(NN,ICOMP)-COLDSF(N,ICOMP))/(SFLEN(NN)+SFLEN(N))
            ENDIF
C
C...........LOOK FOR i-1 ROW IN THE MATRIX
              DO II=IASF(NN)+1,IASF(NN+1)-1
                IF(N.EQ.JASF(II)) GOTO 210
              ENDDO
200           WRITE(*,*) 'ERROR IN JASF MATRIX'
              STOP
210           CONTINUE
C
C.............ADVECTION TERMS ON i,i+1
              III=IASF(NN)
              ADV2=Q*(WUPS*SFLEN(NN)+SFLEN(N))
              ADV3=Q*(1.0D0-WUPS)*SFLEN(NN)
              AMATSF(III)=AMATSF(III)-ADV2*WIMP
              RHSSF(NN)=RHSSF(NN)+(1.0D0-WIMP)*ADV2*COLDSF(NN,ICOMP)
              AMATSF(II)=AMATSF(II)-ADV3*WIMP
              RHSSF(NN)=RHSSF(NN)+(1.0D0-WIMP)*ADV3*COLDSF(N,ICOMP)
C
            !i=NN=>AMATSF(III) and i+1=N=>AMATSF(II) terms
            IF(IDSPFLG(ICNT).NE.0) THEN
C--DISPERSION
C...........DISPERSION TERMS i,i+1
              III=IASF(NN)
              AMATSF(III)=AMATSF(III) 
     1          - COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
              AMATSF(II)=AMATSF(II) 
     1          + COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
              RHSSF(NN)=RHSSF(NN)
     1  + COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(NN,ICOMP)/(SFLEN(NN)+SFLEN(N))
     1  - COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(N,ICOMP)/(SFLEN(NN)+SFLEN(N))
C              RHSSF(N)=RHSSF(N)
C     1    +COEFO*(COLDSF(N,ICOMP)-COLDSF(NN,ICOMP))/(SFLEN(NN)+SFLEN(N))
            ENDIF
          ENDIF
        ENDDO
      ENDDO
C
C--CONSTANT CONCENTRATION BOUNDARY
CVSB      DO I=1,NSSSF
CVSB        IS=ISEGBC(I)
CVSB        IR=IRCHBC(I)
CVSB        CONC=CBCSF(I,ICOMP)
CVSB        N=ISTRM(IR,IS)
CVSB        IF(ISFBCTYP(I).EQ.3) THEN 
CVSB        !CONSTANT CONCENTRATION
CVSB          !SET OFF-DIAGONAL TO ZEROES
CVSB          DO II=IASF(N)+1,IASF(N+1)-1
CVSB            AMATSF(II)=0.0D0
CVSB          ENDDO
CVSB          !DIAGONAL
CVSB          II=IASF(N)
CVSB          AMATSF(II)=-1.0D0
CVSB          RHSSF(N)=-CONC
CVSB        ENDIF
CVSB      ENDDO
      DO N=1,NSTRM
        IF(IBNDSF(N).EQ.-1) THEN
          !SET OFF-DIAGONAL TO ZEROES
          DO II=IASF(N)+1,IASF(N+1)-1
            AMATSF(II)=0.0D0
          ENDDO
          !DIAGONAL
          II=IASF(N)
          AMATSF(II)=-1.0D0
          RHSSF(N)=-CONC
        ENDIF
      ENDDO
C
C--FILL AMATSF COMPLETE-----------------------------------------------
C
CCC      ENDDO !KSFSTP
C
      RETURN
      END
C
C
      SUBROUTINE SFT5AD(N)
C***********************************************************************
C     RESET STREAM CONCENTRATIONS
C***********************************************************************
      USE SFRVARS
      INTEGER N
C
C--RESET STREAM CONCENTRATION
      COLDSF=CNEWSF
      COLDSF2=CNEWSF
C
      RETURN
      END
C
C
      SUBROUTINE SFT5AD2(N)
C***********************************************************************
C     SAVE OLD STREAM FLOW PARAMETERS
C***********************************************************************
      USE SFRVARS
      INTEGER N
C
C--SAVE OLD FLOW PARAMETERS
      QPRECSFO=QPRECSF
      QRUNOFSFO=QRUNOFSF
      QOUTSFO=QOUTSF
      QINSFO=QINSF
      SFOAREA=SFNAREA
C
      RETURN
      END
C
C
      SUBROUTINE SFT5BD(ICOMP,KPER,KSTP,DTRANS,NTRANS)
C***********************************************************************
C     THIS SUBROUTINE CALCULATES BUDGETS FOR STREAMS
C     THIS SUBROUTINE CALCULATES GROUNDWATER BUDGETS RELATED TO STREAMS
C     THIS SUBROUTINE WRITES STREAM CONCENTRATIONS AT OBSERVATION LOCATIONS
C***********************************************************************
      USE LAKVARS
      USE SFRVARS
      USE MT3DMS_MODULE, ONLY: IOUT,NCOMP,UPDLHS,CNEW,TIME2,PRTOUT,
     &                         NLAY,NROW,NCOL,ICBUND,NODES,
     &                         MIXELM,INLKT,RMASIO,iUnitTRNOP
      IMPLICIT  NONE
      INTEGER IS,IR
      INTEGER ICOMP
      INTEGER K,I,J,N,NUM,II,ICCNODE
      INTEGER KPER,KSTP,NTRANS
      INTEGER ISIN,IRIN,ICNT,NC,NN,III
      REAL COEFN,COEFO,DTRANS,QX
      REAL CONC,Q,VO,CO,VOL,QC,Q1,Q2,DELV,QDIFF,VOLN,VOLO,ADV1,ADV2,ADV3
      REAL GW2SFR,GWFROMSFR,LAKFROMSFR,LAK2SFR,PRECSF,RUNOFSF,WDRLSF,
     1  ETSF,TOTINSF,TOTOUTSF,CTOTINSF,CTOTOUTSF,DIFF,CDIFF,PERC,CPERC,
     1  STORINSF,STOROTSF,TOTMASOLD,TOTMASNEW,STORDIFF,CCINSF,CCOUTSF
      REAL FLOINSF,FLOOUTSF
C
C--ZERO OUT TERMS
      CONC=0.
      Q=0.
      RMASLAK=0.
      VOUTLAK=0.
C
      FLOINSF=0.
      FLOOUTSF=0.
      GW2SFR=0.
      GWFROMSFR=0.
      LAKFROMSFR=0.
      LAK2SFR=0.
      PRECSF=0.
      RUNOFSF=0.
      WDRLSF=0.
      ETSF=0.
      STORINSF=0.
      STOROTSF=0.
      CCINSF=0.
      CCOUTSF=0.
      TOTINSF=0.
      TOTOUTSF=0.
      Q1=0.
      Q2=0.
      DELV=0.
C
C--WRITE HEADER TO ICBCSF FILE
      IF(KPER.EQ.1 .AND. KSTP.EQ.1.AND.NTRANS.EQ.1.AND.NOBSSF.GT.0)THEN
      ENDIF
C
C--WRITE OBSERVATIONS
      DO I=1,NOBSSF
        IS=ISOBS(I)
        IR=IROBS(I)
        N=ISTRM(IR,IS)
        CONC=CNEWSF(N,ICOMP)
        WRITE(IOUTOBS,*) TIME2,IS,IR,CONC
      ENDDO
C
C-- CALCULATE INFLOW, STORAGE, AND OUTFLOW TERMS
C
C.....INFLOW BOUNDARY CONDITIONS: PRECIP AND RUNOFF
      DO I=1,NSSSF
        IS=ISEGBC(I)
        IR=IRCHBC(I)
        CONC=CBCSF(I,ICOMP)
        N=ISTRM(IR,IS)
C.......NO BOUNDARY ALLOWED ON CONST. CONC
        IF(IBNDSF(N).EQ.-1) THEN
          CYCLE
        ENDIF
C
        IF(ISFBCTYP(I).EQ.3) THEN
          !BCTYPSF='CNST. CONC'
          !SKIP IF CONST. CONC
        ELSEIF(ISFBCTYP(I).EQ.0) THEN
          !BCTYPSF=' HEADWATER'
          DO II=IDXNIN(N),IDXNIN(N+1)-1
            ISIN=INSEG(II)
            IRIN=INRCH(II)
            IF(ISIN.LT.0.AND.IRIN.LT.0 .AND.
     1         IS.EQ.-ISIN.AND.IR.EQ.-IRIN) THEN
              Q=QINSF(II)
              Q1=Q1+Q*DTRANS
              FLOINSF=FLOINSF+Q*CONC*DTRANS
            ENDIF
          ENDDO
        ELSEIF(ISFBCTYP(I).EQ.1) THEN
          !BCTYPSF='    PRECIP'
          Q=QPRECSF(N)
          Q1=Q1+Q*DTRANS
          PRECSF=PRECSF+Q*CONC*DTRANS
        ELSEIF(ISFBCTYP(I).EQ.2) THEN
          !BCTYPSF='    RUNOFF'
          Q=QRUNOFSF(N)
          Q1=Q1+Q*DTRANS
          RUNOFSF=RUNOFSF+Q*CONC*DTRANS
        ENDIF
      ENDDO
C
      ICNT=0
      DO N=1,NSTRM
        K=ISFL(N)     !LAYER
        I=ISFR(N)     !ROW
        J=ISFC(N)     !COLUMN
C
C.......VOLUME/TIME: ASSUME VOLUME DOES NOT CHANGE
        VOLN=SFLEN(N)*SFNAREA(N)
        VOLO=SFLEN(N)*SFOAREA(N)
        DELV=DELV+VOLN-VOLO
        IF(IBNDSF(N).NE.-1) THEN
CCC        STORDIFF=VOLN*CNEWSF(N,ICOMP)-VOLO*COLDSF(N,ICOMP)
        STORDIFF=VOLN*(CNEWSF(N,ICOMP)-COLDSF(N,ICOMP))
        IF(STORDIFF.LT.0) THEN
          STORINSF=STORINSF-STORDIFF
        ELSE
          STOROTSF=STOROTSF+STORDIFF
        ENDIF
        ENDIF

      if(n.eq.100)then
      continue
      endif

C
C.......INFLOW/OUTFLOW GW
        Q=QSFGW(N)
        IF(Q.LT.0.0) THEN
          Q1=Q1+ABS(Q)*DTRANS
          CONC=CNEW(J,I,K,ICOMP)
          IF(IBNDSF(N).EQ.-1) THEN
C            CCOUTSF=CCOUTSF-Q*CONC*DTRANS
          ELSE
            GW2SFR=GW2SFR-Q*CONC*DTRANS
          ENDIF
          RMASIO(52,2,ICOMP)=RMASIO(52,2,ICOMP)+Q*CONC*DTRANS
        ELSE
          Q2=Q2+ABS(Q)*DTRANS
          CONC=CNEWSF(N,ICOMP)
          IF(IBNDSF(N).EQ.-1) THEN
C            CCINSF=CCINSF+Q*CONC*DTRANS
          ELSE
            GWFROMSFR=GWFROMSFR+Q*CONC*DTRANS
          ENDIF
          RMASIO(52,1,ICOMP)=RMASIO(52,1,ICOMP)+Q*CONC*DTRANS
        ENDIF
C
C.......TOTAL FLOW OUT INCLUDING/EXCLUDING ET
        IF(IETSFR.EQ.0) THEN
          Q=QOUTSF(N)-QETSF(N)
          IF(QETSF(N).GE.QOUTSF(N)) Q=0.
          Q2=Q2+ABS(Q)*DTRANS
        ELSE
          Q=QOUTSF(N)
          ETSF=ETSF+QETSF(N)*CNEWSF(N,ICOMP)*DTRANS
          Q=MAX(0.0,QOUTSF(N)-QETSF(N))
          Q2=Q2+ABS(Q)*DTRANS
        ENDIF
        IF(IEXIT(N).EQ.1) THEN
          IF(IBNDSF(N).EQ.-1) THEN
            CCOUTSF=CCOUTSF+Q*CNEWSF(N,ICOMP)*DTRANS
          ELSE
            FLOOUTSF=FLOOUTSF+Q*CNEWSF(N,ICOMP)*DTRANS
          ENDIF
        ENDIF
C
C.......LAK, ADVECTION, DISPERSION
        II=IASF(N)
        DO NC=1,NIN(N)
          ICNT=ICNT+1
          IS=INSEG(ICNT)
          IR=INRCH(ICNT)
          IF(IS.GT.0.AND.IR.EQ.0) THEN
C...........INFLOW FROM LAKE
            Q=QINSF(ICNT)
            Q1=Q1+ABS(Q)*DTRANS
            CONC=CNEWLAK(IS,ICOMP)
            IF(IBNDSF(N).EQ.-1) THEN
            ELSE
              LAK2SFR=LAK2SFR+Q*CONC*DTRANS
            ENDIF
          ELSEIF(IS.GT.0.AND.IR.GT.0) THEN
C...........INFLOW FROM STREAM
            NN=ISTRM(IR,IS)
            Q=QINSF(ICNT)
            DO II=IASF(N)+1,IASF(N+1)-1
              IF(NN.EQ.JASF(II)) GOTO 110
            ENDDO
100         WRITE(*,*) 'ERROR IN JASF MATRIX'
            STOP
110         CONTINUE
            IF(IBNDSF(NN).EQ.-1) THEN
              QX=Q/(SFLEN(NN)+SFLEN(N))
              ADV1=QX*(WUPS*SFLEN(NN)+SFLEN(N))
              ADV2=QX*(1.0D0-WUPS)*SFLEN(NN)
              CCINSF=CCINSF+
     1  ADV1*WIMP*CNEWSF(NN,ICOMP)*DTRANS
     1  +ADV1*(1.0D0-WIMP)*COLDSF(NN,ICOMP)*DTRANS
     1  +ADV2*WIMP*CNEWSF(N,ICOMP)*DTRANS
     1  +ADV2*(1.0D0-WIMP)*COLDSF(N,ICOMP)*DTRANS
            ENDIF
C            FLOINSF=FLOINSF+Q*CNEWSF(NN,ICOMP)*DTRANS
            Q1=Q1+ABS(Q)*DTRANS
C            AMATSF(II)=AMATSF(II)+Q*WIMP
C            RHSSF(N)=RHSSF(N)-(1.0D0-WIMP)*Q*COLDSF(NN,ICOMP)
C
            IF(IDSPFLG(ICNT).NE.0) THEN
C--DISPERSION
            !i=N and i-1=NN terms
C...........DISPERSION TERMS i-1,i
              COEFN= (  SFNAREA(N)*DISPSF(N,ICOMP)*SFLEN(NN)
     1                +SFNAREA(NN)*DISPSF(NN,ICOMP)*SFLEN(N))/
     1                  (SFLEN(NN)+SFLEN(N))
              COEFO= (  SFOAREA(N)*DISPSF(N,ICOMP)*SFLEN(NN)
     1                +SFOAREA(NN)*DISPSF(NN,ICOMP)*SFLEN(N))/
     1                  (SFLEN(NN)+SFLEN(N))
              III=IASF(N)
              IF(IBNDSF(NN).EQ.-1) THEN
                CCINSF=CCINSF+COEFN*2.0D0*DTRANS
     1  *(WIMP*CNEWSF(NN,ICOMP)+(1.0D0-WIMP)*COLDSF(NN,ICOMP))
     1  /(SFLEN(NN)+SFLEN(N))
                CCINSF=CCINSF+COEFN*2.0D0*DTRANS
     1  *(-WIMP*CNEWSF(N,ICOMP)-(1.0D0-WIMP)*COLDSF(N,ICOMP))
     1  /(SFLEN(NN)+SFLEN(N))


ccc              AMATSF(III)=AMATSF(III) 
ccc     1          - COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
ccc              AMATSF(II)=AMATSF(II) 
ccc     1          + COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
ccc              RHSSF(N)=RHSSF(N)
ccc     1   + COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(N,ICOMP)/(SFLEN(NN)+SFLEN(N))
ccc     1  - COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(NN,ICOMP)/(SFLEN(NN)+SFLEN(N))


              ENDIF
C              FLOINSF=FLOINSF+COEFN*2.0D0
C     1        *(COLDSF(NN,ICOMP)-COLDSF(N,ICOMP))/(SFLEN(NN)+SFLEN(N))
C              FLOOUTSF=FLOOUTSF+COEFN*2.0D0
C     1        *(COLDSF(NN,ICOMP)-COLDSF(N,ICOMP))/(SFLEN(NN)+SFLEN(N))
C              AMATSF(III)=AMATSF(III) 
C     1          - COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
C              AMATSF(II)=AMATSF(II) 
C     1          + COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
C              RHSSF(N)=RHSSF(N)
C     1+ COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(N,ICOMP)/(SFLEN(NN)+SFLEN(N))
C     1- COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(NN,ICOMP)/(SFLEN(NN)+SFLEN(N))
C              RHSSF(N)=RHSSF(N)
C     1    +COEFO*(COLDSF(NN,ICOMP)-COLDSF(N,ICOMP))/(SFLEN(NN)+SFLEN(N))
C
            ENDIF
C
C...........LOOK FOR i-1 ROW IN THE MATRIX
              DO II=IASF(NN)+1,IASF(NN+1)-1
                IF(N.EQ.JASF(II)) GOTO 210
              ENDDO
200           WRITE(*,*) 'ERROR IN JASF MATRIX'
              STOP
210           CONTINUE

C
C.............ADVECTION TERMS ON i,i+1
              IF(IBNDSF(N).EQ.-1) THEN
                ADV2=QX*(WUPS*SFLEN(NN)+SFLEN(N))
                ADV3=QX*(1.0D0-WUPS)*SFLEN(NN)
                CCOUTSF=CCOUTSF+
     1  ADV2*WIMP*CNEWSF(NN,ICOMP)*DTRANS
     1  +(1.0D0-WIMP)*ADV2*COLDSF(NN,ICOMP)*DTRANS
     1  +ADV3*WIMP*CNEWSF(N,ICOMP)*DTRANS
     1  +(1.0D0-WIMP)*ADV3*COLDSF(N,ICOMP)*DTRANS
              ENDIF
C
            IF(IDSPFLG(ICNT).NE.0) THEN
            !i=NN and i+1=N terms
C...........DISPERSION TERMS i,i+1
              III=IASF(NN)
              IF(IBNDSF(N).EQ.-1) THEN
                CCOUTSF=CCOUTSF+COEFN*2.0D0*DTRANS
     1        *(WIMP*CNEWSF(NN,ICOMP)+(1.0D0-WIMP)*COLDSF(NN,ICOMP))
     1        /(SFLEN(NN)+SFLEN(N))
                CCOUTSF=CCOUTSF+COEFN*2.0D0*DTRANS
     1        *(-WIMP*CNEWSF(N,ICOMP)-(1.0D0-WIMP)*COLDSF(N,ICOMP))
     1        /(SFLEN(NN)+SFLEN(N))
              ENDIF
C              FLOINSF=FLOINSF+COEFN*2.0D0
C     1        *(COLDSF(NN,ICOMP)-COLDSF(N,ICOMP))/(SFLEN(NN)+SFLEN(N))
C              FLOOUTSF=FLOOUTSF+COEFN*2.0D0
C     1        *(COLDSF(NN,ICOMP)-COLDSF(N,ICOMP))/(SFLEN(NN)+SFLEN(N))
C              AMATSF(III)=AMATSF(III) 
C     1          - COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
C              AMATSF(II)=AMATSF(II) 
C     1          + COEFN*2.0D0*WIMP/(SFLEN(NN)+SFLEN(N))
C              RHSSF(NN)=RHSSF(NN)
C     1+ COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(NN,ICOMP)/(SFLEN(NN)+SFLEN(N))
C     1- COEFN*2.0D0*(1.0D0-WIMP)*COLDSF(N,ICOMP)/(SFLEN(NN)+SFLEN(N))
C              RHSSF(N)=RHSSF(N)
C     1    +COEFO*(COLDSF(N,ICOMP)-COLDSF(NN,ICOMP))/(SFLEN(NN)+SFLEN(N))
            ENDIF
          ENDIF
        ENDDO
      ENDDO
C
C--CUMULATIVE TERMS
      CFLOINSF(ICOMP)=CFLOINSF(ICOMP)+FLOINSF
      CFLOOUTSF(ICOMP)=CFLOOUTSF(ICOMP)+FLOOUTSF
      CGW2SFR(ICOMP)=CGW2SFR(ICOMP)+GW2SFR
      CGWFROMSFR(ICOMP)=CGWFROMSFR(ICOMP)+GWFROMSFR
      CLAKFROMSFR(ICOMP)=CLAKFROMSFR(ICOMP)+LAKFROMSFR
      CLAK2SFR(ICOMP)=CLAK2SFR(ICOMP)+LAK2SFR
      CPRECSF(ICOMP)=CPRECSF(ICOMP)+PRECSF
      CRUNOFSF(ICOMP)=CRUNOFSF(ICOMP)+RUNOFSF
      CETSF(ICOMP)=CETSF(ICOMP)+ETSF
      CSTORINSF(ICOMP)=CSTORINSF(ICOMP)+STORINSF
      CSTOROTSF(ICOMP)=CSTOROTSF(ICOMP)+STOROTSF
      CCCOUTSF(ICOMP)=CCCOUTSF(ICOMP)+CCOUTSF
      CCCINSF(ICOMP)=CCCINSF(ICOMP)+CCINSF
C
C--CALCULATE TOTAL
      TOTINSF=GW2SFR+LAK2SFR+PRECSF+RUNOFSF+STORINSF+FLOINSF+CCINSF
      TOTOUTSF=GWFROMSFR+LAKFROMSFR+ETSF+STOROTSF+FLOOUTSF+CCOUTSF
      CTOTINSF=CGW2SFR(ICOMP)+CLAK2SFR(ICOMP)+CPRECSF(ICOMP)+
     1  CRUNOFSF(ICOMP)+CSTORINSF(ICOMP)+CFLOINSF(ICOMP)+CCCINSF(ICOMP)
      CTOTOUTSF=CGWFROMSFR(ICOMP)+CLAKFROMSFR(ICOMP)+CETSF(ICOMP)+
     1  CSTOROTSF(ICOMP)+CFLOOUTSF(ICOMP)+CCCOUTSF(ICOMP)
C
      DIFF=TOTINSF-TOTOUTSF
      CDIFF=CTOTINSF-CTOTOUTSF
      IF(TOTINSF+TOTOUTSF.LE.1.0E-10) TOTINSF=1.0E-10
      PERC=DIFF*100/((TOTINSF+TOTOUTSF)/2.0E0)
      IF(CTOTINSF+CTOTOUTSF.LE.1.0E-10) CTOTINSF=1.0E-10
      CPERC=CDIFF*100/((CTOTINSF+CTOTOUTSF)/2.0E0)
C
C--FLOW BALANCE TERM
      QDIFF=Q1-Q2-DELV
C
C--WRITE SFR MASS BALANCE TO OUTPUT FILE
      IF(PRTOUT) THEN
        WRITE(IOUT,10) NTRANS,KSTP,KPER,ICOMP
        WRITE(IOUT,20) 
        WRITE(IOUT,30) CSTORINSF(ICOMP),STORINSF
        WRITE(IOUT,35) CFLOINSF(ICOMP),FLOINSF
        WRITE(IOUT,40) CGW2SFR(ICOMP),GW2SFR
        IF(iUnitTRNOP(18).GT.0) WRITE(IOUT,45) CLAK2SFR(ICOMP),LAK2SFR
        WRITE(IOUT,50) CPRECSF(ICOMP),PRECSF
        WRITE(IOUT,55) CRUNOFSF(ICOMP),RUNOFSF
        WRITE(IOUT,56) CCCINSF(ICOMP),CCINSF
        WRITE(IOUT,60)
        WRITE(IOUT,65) CTOTINSF,TOTINSF
        WRITE(IOUT,70) CSTOROTSF(ICOMP),STOROTSF
        WRITE(IOUT,75) CFLOOUTSF(ICOMP),FLOOUTSF
        WRITE(IOUT,80) CGWFROMSFR(ICOMP),GWFROMSFR
        IF(iUnitTRNOP(18).GT.0) 
     1  WRITE(IOUT,85) CLAKFROMSFR(ICOMP),LAKFROMSFR
        WRITE(IOUT,56) CCCOUTSF(ICOMP),CCOUTSF
        IF(IETSFR.GT.0) WRITE(IOUT,90) CETSF(ICOMP),ETSF
        WRITE(IOUT,60)
        WRITE(IOUT,95) CTOTOUTSF,TOTOUTSF
        WRITE(IOUT,97) CDIFF,DIFF
        WRITE(IOUT,98) CPERC,PERC
        WRITE(IOUT,99) QDIFF
      ENDIF
10    FORMAT(//21X,'STREAM MASS BUDGETS AT END OF TRANSPORT STEP',
     & I5,', TIME STEP',I5,', STRESS PERIOD',I5,' FOR COMPONENT',I4,
     & /21X,103('-'))
20    FORMAT(/33X,7X,1X,'CUMULATIVE MASS [M]',
     &         8X,13X,15X,' MASS FOR THIS TIME STEP [M]',
     &       /41X,19('-'),36X,14('-'))
30    FORMAT(16X,'      STREAM DEPLETION =',G15.7,
     &       16X,'      STREAM DEPLETION =',G15.7)
35    FORMAT(16X,'      INFLOW TO STREAM =',G15.7,
     &       16X,'      INFLOW TO STREAM =',G15.7)
40    FORMAT(16X,'          GW TO STREAM =',G15.7,
     &       16X,'          GW TO STREAM =',G15.7)
45    FORMAT(16X,'         LAK TO STREAM =',G15.7,
     &       16X,'         LAK TO STREAM =',G15.7)
50    FORMAT(16X,'         PRECIPITATION =',G15.7,
     &       16X,'         PRECIPITATION =',G15.7)
55    FORMAT(16X,'                RUNOFF =',G15.7,
     &       16X,'                RUNOFF =',G15.7)
56    FORMAT(16X,'CONSTANT CONCENTRATION =',G15.7,
     &       16X,'CONSTANT CONCENTRATION =',G15.7)
60    FORMAT(41X,19('-'),36X,14('-'))
65    FORMAT(16X,'              TOTAL IN =',G15.7,
     &       16X,'              TOTAL IN =',G15.7)
70    FORMAT(/16X,'   STREAM ACCUMULATION =',G15.7,
     &       16X,'   STREAM ACCUMULATION =',G15.7)
75    FORMAT(16X,'        STREAM OUTFLOW =',G15.7,
     &       16X,'        STREAM OUTFLOW =',G15.7)
80    FORMAT(16X,'          STREAM TO GW =',G15.7,
     &       16X,'          STREAM TO GW =',G15.7)
85    FORMAT(16X,'         STREAM TO LAK =',G15.7,
     &       16X,'         STREAM TO LAK =',G15.7)
90    FORMAT(16X,'                    ET =',G15.7,
     &       16X,'                    ET =',G15.7)
95    FORMAT(16X,'             TOTAL OUT =',G15.7,
     &       16X,'             TOTAL OUT =',G15.7)
97    FORMAT(/16X,'        NET (IN - OUT) =',G15.7,
     &        16X,'        NET (IN - OUT) =',G15.7)
98    FORMAT(16X,' DISCREPANCY (PERCENT) =',G15.7,
     &       16X,' DISCREPANCY (PERCENT) =',G15.7)
99    FORMAT(46X,'FLOW ERR (QIN-QOUT-DV) =',G15.7,' [L3/T]',/)
C
      RETURN
      END
C
