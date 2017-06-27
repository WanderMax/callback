procedure( PREFIX_mosAbut( iA iB pA pB pASide connection event @optional (group nil) ) ;_Mar 11 04 amir 183 ;;InstA, instB, PinA, PinB
  let(
     (
        result apA apB avA avB delta
        ( epsilon 0.0001 )  ;;set local epsilon to 0.0001 let skill++ mode
     )
    
    cond(
       ( isCallable('_geIsQCell) && _geIsQCell(iA)
         result = PREFIX_QCellMosAbut(iA iB pA pB pASide connection event group)
       )
       ( isCallable('_geIsQCell) && _geIsQCell(iB)
         result = PREFIX_QCellMosAbut(iB iA pB pA pASide connection event group)
       )
       ( t
         case( event
            ( 1   ;; compute abutment offset
              result = 0.0
            )
            ( 2   ;; adjust pcell for abutment
              apA = pA~>abutParam
              apB = pB~>abutParam
              avA = get(get(get(iA 'master) 'parameters) apA)        ;; get value of a property from list, 'parameters-->symbol
              avB = get(get(get(iB 'master) 'parameters) apB)
              ;; save current state
              dbReplaceProp( group                                   ;; dbReplaceProp(
                             sprintf(nil "abutInfo_%s" iA~>name)     ;; g_object
                             "list"                                  ;; t_name
                             list(                                   ;; t_propType
                                list(concat(apA) avA)                ;; g_value
                             ))                                      ;; )
              dbReplaceProp( group                                   ;; => d_prop / nil
                             sprintf(nil "abutInfo_%s" iB~>name)     
                             "list"
                             list(
                                list(concat(apB) avB)
                             ))
              
              case( connection
                 ( 1   ;; no third connection, remove both contacts
                   delta = pB~>gateWidth - pA~>gateWidth
                   cond(
                      ( delta > epsilon
                        avA = 6
                        avB = 2
                      )
                      ( delta < -epsilon
                        avA = 2
                        avB = 6
                      )
                      ( t
                        avA = 4
                        avB = 4
                      )
                   ) ; ** cond delta **
                 )
                 ( 2   ;; third connection exists
                   delta = rodGetObj(pB)~>length - rodGetObj(pA)~>length
                   cond(
                      ( delta > epsilon
                        avA = 7
                        avB = 1
                      )
                      ( delta < -epsilon
                        avA = 1
                        avB = 7
                      )
                      ( t
                        delta = rodGetObj(pB)~>length - pA~>gateWidth
                        if( delta > epsilon then
                           avA = 7
                           avB = 1
                        else
                           avA = 5
                           avB = 3
                        )   ; ** if delta **
                      )
                   ) ; ** cond delta **
                 )
              ) ; ** case connection **
              when( PasXor(pA~>isSource == "TRUE" pB~>isSource == "TRUE")
                 avA = avA * -1
                 avB = avB * -1
              )
              PasSetInstParamValue(iA avA apA)
              PasSetInstParamValue(iB avB apB)
              result = t
            )
            ( 3   ;; adjust pcell for unabutment
              when( dbIsId(iA)
                 foreach( param get(group sprintf(nil "abutInfo_%s" iA~>name))
                    PasSetInstParamValue(iA cadr(param) car(param))
                 )
              )
              when( dbIsId(iB)        
                 foreach( param get(group sprintf(nil "abutInfo_%s" iB~>name))
                    PasSetInstParamValue(iB cadr(param) car(param))
                 )
              )
              result = nil
            )
         ) ; ** case event **
       )
    ) ; ** cond isCallable **
    
    result
    
  ) ; ** let **
) ; ** procedure PREFIX_mosAbut **

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


procedure(PREFIX_QCellGetOffset(iB pB connection qCellFingerWidth) ;_Mar 16 04 amir 35
  prog((epsilon grid diff dpt grid2)
    epsilon = 0.0001
    grid = 0.01
    grid2 = grid/2
    diff = pB~>gateWidth - qCellFingerWidth
    dpt=PasGetDeviceProps(iB~>master)
    when(connection == 1 && abs(diff) < epsilon  ;;; same width
       when(PasCeiling(dpt->msGate grid*2 t) > dpt->msGate
          return(-grid2)
       )
    )
    return(0.0)
  ) ; ** prog **
) ; ** procedure PREFIX_QCellGetOffset **
        
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       

;;; This procedure is used to abut QCell with PREFIX template cell.
;;; iA will always be QCell, and iB always PREFIX.
procedure( PREFIX_QCellMosAbut( iA iB pA pB pASide connection event @optional (group nil) ) ;_Mar 16 04 amir 3451
  let(
     (
        result (epsilon 0.0001 ) contactParam delta value apB avB
        paramsA fingerWidth diffStretchLTV diffStretchLBV diffStretchRTV diffStretchRBV
        ( ContactNone     0 )
        ( ContactOn       1 )
        ( ContactShoulder 2 )
        ( ContactSeries   3 )           
        ( ContactOff      4 )
     )
    
    pASide
    
    paramsA = iA->master->parameters
    fingerWidth = paramsA->fingerWidth
    diffStretchLTV = paramsA->diffStretchLTV
    diffStretchLBV = paramsA->diffStretchLBV
    diffStretchRTV = paramsA->diffStretchRTV
    diffStretchRBV = paramsA->diffStretchRBV
    
    
    
    case(event
       ( 1      ;; compute abutment offset
         delta = pB~>gateWidth - fingerWidth
         result = PREFIX_QCellGetOffset(iB pB connection fingerWidth)
       )
       ( 2
         contactParam = pA~>contactParam
         if(contactParam == "leftAbutmentState" then
            when(abs(diffStretchLTV) > epsilon
               dbReplaceProp(iA "diffStretchLTV" "float" 0.0)
               dbReplaceProp(group 
                             sprintf(nil "%s_diffStretchLTV" iA~>name)
                             "float" diffStretchLTV)
            ) ; ** when abs **
            when(abs(diffStretchLBV) > epsilon
               dbReplaceProp(iA "diffStretchLBV" "float" 0.0)
               dbReplaceProp(group 
                             sprintf(nil "%s_diffStretchLBV" iA~>name)
                             "float" diffStretchLBV)
            ) ; ** when abs **
         else
            when(abs(diffStretchRTV) > epsilon
               dbReplaceProp(iA "diffStretchRTV" "float" 0.0)
               dbReplaceProp(group 
                             sprintf(nil "%s_diffStretchRTV" iA~>name)
                             "float" diffStretchRTV)
            ) ; ** when abs **
            when(abs(diffStretchRBV) > epsilon
               dbReplaceProp(group 
                             sprintf(nil "%s_diffStretchRBV" iA~>name)
                             "float" diffStretchRBV)
               dbReplaceProp(iA "diffStretchRBV" "float" 0.0)
            ) ; ** when abs **
         ) ; ** if contactParam **
         
            ;;; Save old status for pasMos.
         apB = pB~>abutParam
         avB = get(iB apB) || 0
         dbReplaceProp(group sprintf(nil "abutInfo_%s" iB~>name)
                       "list" list(list(concat(apB) avB)))
         delta = pB~>gateWidth - fingerWidth
         
         
         
         case( connection
            ( 1      ;; No third connection, remove both contacts
              cond(
                 ( delta > epsilon       ;;; pasMos width > qCell
                   avB = 2
                   dbReplaceProp(iA contactParam "int" ContactShoulder)
                 )
                 ( delta < -epsilon      ;;; pasMos width < qCell
                   avB = 6
                   dbReplaceProp(iA contactParam "int" ContactOff)
                 )
                 ( t
                   avB = 4
                   dbReplaceProp(iA contactParam "int" ContactSeries)
                 )
              ) ; ** cond delta **
            )
            ( 2      ;;; Third connection, always keep contact of large side 
              cond(
                 ( delta > epsilon       ;;; pasMos width > qCell
                   avB = 1
                   dbReplaceProp(iA contactParam "int" ContactShoulder)
                 )
                 ( delta < -epsilon      ;;; pasMos width < qCell
                   avB = 7
                   dbReplaceProp(iA contactParam "int" ContactOn)
                 )
                 ( t
                   avB = 3
                   dbReplaceProp(iA contactParam "int" ContactNone)
                 )
              ) ; ** cond delta **
            )
         ) ; ** case connection **
         
         when(pB~>isSource == "TRUE" avB = avB * -1)
         
         PasSetInstParamValue(iB avB apB)
         dbReplaceProp(group iA~>name "string" contactParam)
         result = t
       )
       ( 3   ;; adjust pcell for unabutment
         when( dbIsId(iA)
            contactParam = get(group sprintf(nil "%s" iA~>name))
            dbReplaceProp(iA contactParam "int" ContactOn)
            if( contactParam == "leftAbutmentState" then
               value = get(group sprintf(nil "%s_diffStretchLTV" iA~>name))
               when(value 
                  dbReplaceProp(iA "diffStretchLTV" "float" value)
               )
               value = get(group sprintf(nil "%s_diffStretchLBV" iA~>name))
               when(value
                  dbReplaceProp(iA "diffStretchLBV" "float" value)
               )
            else
               value = get(group sprintf(nil "%s_diffStretchRTV" iA~>name))
               when(value
                  dbReplaceProp(iA "diffStretchRTV" "float" value)
               )
               value = get(group sprintf(nil "%s_diffStretchRBV" iA~>name))
               when(value
                  dbReplaceProp(iA "diffStretchRBV" "float" value)
               )
            ) ; ** if contactParam **
         ) ; ** when dbIsId **
         when( dbIsId(iB)        
            foreach( param get(group sprintf(nil "abutInfo_%s" iB~>name))
               dbReplaceProp(iB symbolToString(car(param)) "int"  cadr(param))
            )
         ) ; ** when dbIsId **
         result = nil
       )
    ) ; ** case event **
    
    result
    
  ) ; ** let **
) ; ** procedure PREFIX_QCellMosAbut **

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
