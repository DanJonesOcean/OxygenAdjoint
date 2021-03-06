C $Header: /u/gcmpack/MITgcm/pkg/dic/dic_biotic_forcing.F,v 1.28 2012/08/22 00:40:56 jmc Exp $
C $Name: checkpoint63s $

#include "DIC_OPTIONS.h"

CBOP
C !ROUTINE: DIC_BIOTIC_FORCING

C !INTERFACE: ==========================================================
      SUBROUTINE DIC_BIOTIC_FORCING( PTR_DIC, PTR_ALK, PTR_PO4,
     &                            PTR_DOP,
#ifdef ALLOW_O2
     &                            PTR_O2,
#endif
#ifdef ALLOW_FE
     &                            PTR_FE,
#endif
CTAKA
#ifdef ALLOW_PUMP
     &                            PTR_O2PRE,PTR_ALKPRE,PTR_DICPRE, 
#endif
CTAKA
     &                            bi,bj,imin,imax,jmin,jmax,
     &                             myIter,myTime,myThid)

C !DESCRIPTION:
C updates all the tracers for the effects of air-sea exchange, biological
c activity and remineralization

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "DYNVARS.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DIC_VARS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"

C !INPUT PARAMETERS: ===================================================
C  myThid               :: thread number
C  myIter               :: current timestep
C  myTime               :: current time
C  PTR_DIC              :: dissolced inorganic carbon
C  PTR_ALK              :: alkalinity
C  PTR_PO4              :: phosphate
c  PTR_DOP              :: dissolve organic phosphurous
c  PTR_O2               :: oxygen
C  PTR_FE               :: iron
      INTEGER myIter
      _RL myTime
      INTEGER myThid
      _RL  PTR_DIC(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  PTR_ALK(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  PTR_PO4(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  PTR_DOP(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
#ifdef ALLOW_O2
      _RL  PTR_O2(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
#endif
#ifdef ALLOW_FE
      _RL  PTR_FE(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
#endif
CTAKA
#ifdef ALLOW_PUMP
      _RL  PTR_O2PRE(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  PTR_ALKPRE(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  PTR_DICPRE(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
#endif
CTAKA
      INTEGER bi, bj, imin, imax, jmin, jmax

#ifdef ALLOW_PTRACERS
#ifdef DIC_BIOTIC

C !LOCAL VARIABLES: ====================================================
C  i,j,k                  :: loop indices
C  G*                     :: tendency term for the tracers
C  SURA                   :: tendency of alkalinity due to freshwater
C  SURC                   :: tendency of DIC due to air-sea exchange
C                            and virtual flux
C  SURO                   :: tendency of O2 due to air-sea exchange
C  GPO4                   :: tendency of PO4 due to biological productivity,
C                            exchange with DOP pool and reminerization
C  CAR                    :: carbonate changes due to biological
C                             productivity and remineralization
C  BIOac                  :: biological productivity
C  RDOP                   :: DOP sink due to remineralization
C  pflux                  :: changes to PO4 due to flux and remineralization
C  CAR_S                  :: carbonate sink
C  cflux                  :: carbonate changes due to flux and remineralization
C  freefe                 :: iron not bound to ligand
      _RL  GDIC(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  GALK(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  GPO4(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  GDOP(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  SURA(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL  SURC(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL  SURO(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL  CAR(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  BIOac(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  RDOP(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  pflux(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  exportflux(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  CAR_S(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  cflux(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
#ifdef ALLOW_O2
      _RL  GO2(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
#endif
#ifdef ALLOW_FE
      _RL  GFE(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
      _RL  freefe(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr)
#endif
       INTEGER i,j,k
#ifdef CAR_DISS
       INTEGER nCALCITEstep
#endif
CEOP

       DO k=1,Nr
         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
           RDOP(i,j,k) =0. _d 0
           GDIC(i,j,k) =0. _d 0
           GALK(i,j,k) =0. _d 0
           GPO4(i,j,k) =0. _d 0
           GDOP(i,j,k) =0. _d 0
           CAR(i,j,k)  =0. _d 0
           BIOac(i,j,k)   =0. _d 0
           pflux(i,j,k)   =0. _d 0
           exportflux(i,j,k)=0. _d 0
           cflux(i,j,k)   =0. _d 0
           CAR_S(i,j,k)   =0. _d 0
#ifdef ALLOW_O2
           GO2(i,j,k)     =0. _d 0
#endif
#ifdef ALLOW_FE
           GFE(i,j,k)     =0. _d 0
C  no longer needed after adding full initialisation of freefe in S/R FE_CHEM
c          freefe(i,j,k)  =0. _d 0
#endif
          ENDDO
         ENDDO
       ENDDO
         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
           SURA(i,j)   =0. _d 0
           SURC(i,j)   =0. _d 0
           SURO(i,j)   =0. _d 0
          ENDDO
         ENDDO

C carbon air-sea interaction
       CALL DIC_SURFFORCING( PTR_DIC, PTR_ALK, PTR_PO4, SURC,
     &                    bi,bj,imin,imax,jmin,jmax,
     &                    myIter,myTime,myThid)

C alkalinity air-sea interaction
       CALL ALK_SURFFORCING( PTR_ALK, SURA,
     &                    bi,bj,imin,imax,jmin,jmax,
     &                    myIter,myTime,myThid)

#ifdef ALLOW_O2
C oxygen air-sea interaction
       CALL O2_SURFFORCING( PTR_O2, SURO,
     &                    bi,bj,imin,imax,jmin,jmax,
     &                    myIter,myTime,myThid)
#endif

#ifdef ALLOW_FE
C find free iron
       CALL FE_CHEM( bi,bj,iMin,iMax,jMin,jMax, PTR_FE, freefe,
     &               myIter, myThid )
#endif


C biological activity
CTAKA - include external input option
      IF (DIC_ProdFile .NE. ' ') THEN
        DO k=1,Nr
         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
           bioac(i,j,k)=bioac_ext(i,j,k,bi,bj) 
     &                  *maskC(i,j,k,bi,bj)
          ENDDO
         ENDDO
        ENDDO
      ELSE     
       CALL BIO_EXPORT( PTR_PO4 ,
#ifdef ALLOW_FE
     I           PTR_FE,
#endif
     I           BIOac,
     I           bi,bj,imin,imax,jmin,jmax,
     I           myIter,myTime,myThid)
      ENDIF

C flux of po4 from layers with biological activity
       CALL PHOS_FLUX( BIOac, pflux, exportflux,
     &                    bi,bj,imin,imax,jmin,jmax,
     &                    myIter,myTime,myThid)

C- Carbonate sink
       DO k=1,Nr
         DO j=jmin,jmax
          DO i=imin,imax
             CAR_S(i,j,k)=BIOac(i,j,k)*R_CP*rain_ratio(i,j,bi,bj)*
     &                    (1. _d 0-DOPfraction)
          ENDDO
         ENDDO
       ENDDO

C carbonate
#ifdef CAR_DISS
C dissolution only below saturation horizon
C code following method by Karsten Friis
         nCALCITEstep = 3600
         IF(myIter .lt. (nIter0+5) .or.
     &               mod(myIter,nCALCITEstep) .eq. 0)THEN
           CALL CALCITE_SATURATION(PTR_DIC, PTR_ALK, PTR_PO4,
     I                    bi,bj,imin,imax,jmin,jmax,
     I                    myIter,myTime,myThid)
        ENDIF
c
        CALL CAR_FLUX_OMEGA_TOP( BIOac, cflux,
     &                    bi,bj,imin,imax,jmin,jmax,
     &                    myIter,myTime,myThid)
#else
C old OCMIP way
        CALL CAR_FLUX( CAR_S, cflux,
     &                    bi,bj,imin,imax,jmin,jmax,
     &                    myIter,myTime,myThid)
#endif

C add all tendencies for PO4, DOP, ALK, DIC
       DO k=1,Nr
         DO j=jmin,jmax
          DO i=imin,imax
#ifdef DIC_NO_NEG
           RDOP(i,j,k)= MAX(maskC(i,j,k,bi,bj)*KDOPRemin*PTR_DOP(i,j,k)
     &                     ,0. _d 0)
#else
           RDOP(i,j,k)= maskC(i,j,k,bi,bj)*KDOPRemin*PTR_DOP(i,j,k)
#endif
           GPO4(i,j,k)=-BIOac(i,j,k)+pflux(i,j,k) + RDOP(i,j,k)

           car(i,j,k) = cflux(i,j,k) - CAR_S(i,j,k)

           GDOP(i,j,k)=+BIOac(i,j,k)*DOPfraction - RDOP(i,j,k)

           GALK(i,j,k)=+2. _d 0 *car(i,j,k)-R_NP*GPO4(i,j,k)

           GDIC(i,j,k)=car(i,j,k)+R_CP*GPO4(i,j,k)

#ifdef ALLOW_O2
           if (PTR_O2(i,j,k).GT.O2crit) then
             GO2(i,j,k)= R_OP*GPO4(i,j,k)
           else
             GO2(i,j,k)= 0. _d 0
           endif
#endif
#ifdef ALLOW_FE
           GFE(i,j,k) = R_FeP*GPO4(i,j,k)
     &                 -Kscav*freefe(i,j,k)
#endif
          ENDDO
         ENDDO
       ENDDO

         DO j=jmin,jmax
          DO i=imin,imax
               GALK(i,j,1)=GALK(i,j,1)+SURA(i,j)
               GDIC(i,j,1)=GDIC(i,j,1)+SURC(i,j)
#ifdef ALLOW_O2
               GO2(i,j,1) =GO2(i,j,1)+SURO(i,j)
#endif
#ifdef ALLOW_FE
               GFE(i,j,1)=GFE(i,j,1)+alpfe*
     &                    InputFe(i,j,bi,bj)*recip_drF(1)
     &                       *recip_hFacC(i,j,1,bi,bj)
#endif
          ENDDO
         ENDDO


C update
       DO k=1,Nr
         DO j=jmin,jmax
          DO i=imin,imax
           PTR_DIC(i,j,k)=
     &      PTR_DIC(i,j,k)+GDIC(i,j,k)*PTRACERS_dTLev(k)
           PTR_ALK(i,j,k)=
     &      PTR_ALK(i,j,k)+GALK(i,j,k)*PTRACERS_dTLev(k)
           PTR_PO4(i,j,k)=
     &      PTR_PO4(i,j,k)+GPO4(i,j,k)*PTRACERS_dTLev(k)
           PTR_DOP(i,j,k)=
     &      PTR_DOP(i,j,k)+GDOP(i,j,k)*PTRACERS_dTLev(k)
#ifdef ALLOW_O2
           PTR_O2(i,j,k)=
     &      PTR_O2(i,j,k)+GO2(i,j,k)*PTRACERS_dTLev(k)
#endif
#ifdef ALLOW_FE
           PTR_FE(i,j,k)=
     &      PTR_FE(i,j,k)+GFE(i,j,k)*PTRACERS_dTLev(k)
#endif
CTAKA
#ifdef ALLOW_PUMP
           IF (k .EQ. 1) THEN
             PTR_O2PRE(i,j,1)=PTR_O2(i,j,1)
             PTR_ALKPRE(i,j,1)=PTR_ALK(i,j,1)
             PTR_DICPRE(i,j,1)=PTR_DIC(i,j,1)
           ENDIF
#endif
CTAKA
          ENDDO
         ENDDO
       ENDDO

#ifdef ALLOW_FE
#ifdef MINFE
c find free iron and get rid of insoluble part
       CALL FE_CHEM( bi,bj,iMin,iMax,jMin,jMax, PTR_FE, freefe,
     &               myIter, myThid )
#endif
#endif


#ifdef ALLOW_TIMEAVE
C save averages
       IF ( PTRACERS_taveFreq.GT.0. ) THEN
        DO k=1,Nr
         DO j=jmin,jmax
          DO i=imin,imax
            BIOave(i,j,k,bi,bj)   =BIOave(i,j,k,bi,bj)+
     &                             BIOac(i,j,k)*deltaTClock
            CARave(i,j,k,bi,bj)   =CARave(i,j,k,bi,bj)+
     &                             CAR(i,j,k)*deltaTClock
            OmegaCave(i,j,k,bi,bj)=OmegaCave(i,j,k,bi,bj)+
     &                             OmegaC(i,j,k,bi,bj)*deltaTClock
            pfluxave(i,j,k,bi,bj) =pfluxave(i,j,k,bi,bj) +
     &                             pflux(i,j,k)*deltaTClock
            epfluxave(i,j,k,bi,bj)=epfluxave(i,j,k,bi,bj) +
     &                             exportflux(i,j,k)*deltaTClock
            cfluxave(i,j,k,bi,bj) =cfluxave(i,j,k,bi,bj) +
     &                             cflux(i,j,k)*deltaTClock
          ENDDO
         ENDDO
        ENDDO
         DO j=jmin,jmax
          DO i=imin,imax
              SURave(i,j,bi,bj)    =SURave(i,j,bi,bj)+
     &                              SURC(i,j)*deltaTClock
#ifdef ALLOW_O2
              SUROave(i,j,bi,bj)   =SUROave(i,j,bi,bj)+
     &                              SURO(i,j)*deltaTClock
#endif
              pCO2ave(i,j,bi,bj)   =pCO2ave(i,j,bi,bj)+
     &                              pCO2(i,j,bi,bj)*deltaTClock
              pHave(i,j,bi,bj)     =pHave(i,j,bi,bj)+
     &                              pH(i,j,bi,bj)*deltaTClock
              fluxCO2ave(i,j,bi,bj)=fluxCO2ave(i,j,bi,bj)+
     &                           fluxCO2(i,j,bi,bj)*deltaTClock
          ENDDO
         ENDDO
         DIC_timeAve(bi,bj) = DIC_timeAve(bi,bj)+deltaTClock
       ENDIF
#endif /* ALLOW_TIMEAVE*/

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

#ifdef ALLOW_DIAGNOSTICS

      IF ( useDiagnostics ) THEN

        CALL DIAGNOSTICS_FILL(BIOac  ,'DICBIOA ',0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(CAR    ,'DICCARB ',0,Nr,2,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(pCO2   ,'DICPCO2 ',0,1 ,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(fluxCO2,'DICCFLX ',0,1 ,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(pH     ,'DICPHAV ',0,1 ,1,bi,bj,myThid)
        CALL DIAGNOSTICS_FILL(SURC   ,'DICTFLX ',0,1 ,2,bi,bj,myThid)
#ifdef ALLOW_O2
        CALL DIAGNOSTICS_FILL(SURO   ,'DICOFLX ',0,1 ,2,bi,bj,myThid)
#endif

      ENDIF

#endif /* ALLOW_DIAGNOSTICS */

#endif /* DIC_BIOTIC */
#endif /* ALLOW_PTRACERS */

       RETURN
       END
