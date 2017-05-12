/******************************************************************************
  MOSFET CALLBACK FUNCTIONS
     ${template_libName}_mosCB
     ${template_libName}_mosDisplaySet
     ${template_libName}_mosCalcAreaPerim
     ${template_libName}_calcCap  
     ${template_libName}_calcMet   
*****************************************************************************/

procedure(${template_libName}_mosCB(param "s")                  ;_Dec  5 04 amir 8107
  let(
     (
        cdfId paramId dpt grid scale sGrid
        mode norm min max value
        numFinger totalWidth fingerWidth maxFingerWidth
        fingerLength (holdFingerLength nil)
        designLibName IncreaseDevLimits CustomDig_NR vxl_multiplier
        capacitance ca cf minL minW maxL maxW minC maxC
        leftDummies rightDummies sourceFirst sourceLast
        SCref scTop scBot scRight l w gt_contSpan  
        scLeft SCMatchEnc SCMinEnc SCA SCB SCC SC wstr SCAd SCARL SCATB SCANL SCANR
        saVal sbVal
        meDiffConty meM1Cont M1ContEnc msContPoly mwCont msCont
        contSpan deeDiffPoly neeDiffPoly fwMeeDiffCont
        maxGCwSp maxMetalWidthSD
        numContCols numContRows msContWide BSDContSp
        meDiffPoly meTapCont metalWidthSD msDiffPoly
        capMaxLW capMinLW crates meItimpCont msItimpCont
        newV oldV msPoly dceDiffPoly nceDiffPoly
        area perim fingersQuotient stepWidth numConts
        bsim_multiplier previous_dogbone dogbone diffContEnc 
        location floatSlop totFinger metalList meePolyCont
        primDpt polyCutContRows polyCutContCols polyCutContSp mePolyCutCont meePolyCutCont
        polyCutX polyCutY polyCutArea polyCutPerim
        diffCutContRows diffCutContCols diffCutContSp meDiffCutCont meeDiffCutCont
        diffCutX diffCutY diffCutArea diffCutPerim devHoles
        discreteLengthList discreteWidthList
        perimCalc perimLengthCoef perimWidthCoef 
        wellStretch toggleDimEntryMode dboxText metCap 
        (diffCutCols nil) (diffCutRows nil) (polyCutCols nil) (polyCutRows nil)
        ( funName        getCallingFunction(0) )
     )
;(printf "*** %s is being called with param %s\n" funName param)

    cdfId = cdfgData   

    unless( paramId = get(cdfId  param)
       PasError("%s: parameter not found in CDF - %s" funName param)
       error("\tCallback aborted abnormally!")
    )
    
    unless( dpt = PasGetObjCellProps(cdfId )
       PasError("%s: unable to get the device property table!" funName)
       error("\tCallback aborted abnormally!")
    )
        
    designLibName = or( cdfId->id->instHeader->cellView->libName
                   cdfgForm->cellViewId->libName
                    )

    ; allows mosfets to be placed with 1 contact on the SD
    when( designLibName
        CustomDig_NR = ddGetObj( designLibName)~>CustomDig_NR=="TRUE"
    )

    ; Turns off minW * minL (min is now grid size)
    when( designLibName
      IncreaseDevLimits = ddGetObj( designLibName)~>IncreaseDevLimits=="TRUE"
    ) ; when designLibName
    
    when( IncreaseDevLimits
        PasWarn( "Min & max device values for library %s are turned OFF"
            designLibName)
    ) ; when IncreaseDevLimits

    location = or(cdfId->location->value "")
    
        
                        
 
 
    grid = dpt->grid
    scale = dpt->scale || 1e-6
    sGrid = grid * scale
    norm = t
    floatSlop = 0
    
    SCMinEnc = dpt->SCMinEnc
    SCMatchEnc = dpt->SCMatchEnc
    meDiffPoly = dpt->meDiffPoly
    meTapCont = dpt->meTapCont
    msDiffPoly = dpt->msDiffPoly
    meItimpCont = dpt->meItimpCont
    msItimpCont = dpt->msItimpCont
    
    meM1Cont = dpt->meM1Cont 
    mwCont = dpt->mwCont
    msCont = dpt->msCont( 1 1)
    meePolyCont = dpt->meePolyCont( 1)
    fwMeeDiffCont = dpt->fwMeeDiffCont
    maxGCwSp = or(dpt->maxGCwSp 100.0)
    maxMetalWidthSD = or(dpt->maxMetalWidthSD 100.0)

    discreteLengthList = dpt->discreteLengthList
    discreteWidthList = dpt->discreteWidthList
    discreteNumOnly = dpt->discreteNumOnly

    perimCalc = evalstring(strcat("dpt->perimCalc_" location))
    when(perimCalc
       perimCalc = car(linereadstring(perimCalc))
       );when
    perimLengthCoef = perimCalc->length
    perimWidthCoef = perimCalc->width

    if( cdfId->ignoreLimits->value then
       mode = 'passive
    else
       mode = 'extreme
    )

;check for blank string entries
foreach(param setof(p cdfId->parameters p->paramType=="string")
   when(blankstrp(param->value)
      param->value = param->defValue
      );when
   );foreach

;keep the maxFingerWidth at default
;when(cdfId->maxFingerWidth
   ;cdfId->maxFingerWidth->value = cdfId->maxFingerWidth->defValue
   ;);when

;maintain values between netset params and their displayed string params
foreach(param list("B" "DNW" "PSUB")
   when(evalstring(strcat("cdfId->" param)) && evalstring(strcat("cdfId->" param "display"))
      evalstring(strcat("cdfId->" param "display->value = cdfId->" param "->value"))
      );when
   );foreach

         minL = if( CustomDig_NR then or(evalstring(strcat("dpt->minFingerLength_" location)) dpt->minFingerLengthNR dpt->minFingerLength) else or(evalstring(strcat("dpt->minFingerLength_" location)) dpt->minFingerLength)) * 1e-6
         minW = if( CustomDig_NR then 
            or(evalstring(strcat("dpt->minFingerWidthNR_" location))
               evalstring(strcat("dpt->minFingerWidth_" location))
               dpt->minFingerWidthNR dpt->minFingerWidth) 
            else 
               max( or(evalstring(strcat("dpt->minFingerWidth_" location)) dpt->minFingerWidth)
                    or(evalstring(strcat("dpt->minFingerWidthNR_" location)) dpt->minFingerWidthNR)
               );max
            ) * 1e-6
         if(location == "no_min_dim" then
            minL = sGrid
            minW = sGrid
            maxL = 999999.9
	        maxW = 999999.9
         else
            maxL = or(evalstring(strcat("dpt->maxFingerLength_" location)) dpt->maxFingerLength) * 1e-6
            maxW = or(evalstring(strcat("dpt->maxFingerWidth_" location)) dpt->maxFingerWidth) * 1e-6
         );if
         
         capMinLW = max( minL minW)

         ;maxL = or(evalstring(strcat("dpt->maxFingerLength_" location)) dpt->maxFingerLength) * 1e-6
         ;maxW = or(evalstring(strcat("dpt->maxFingerWidth_" location)) dpt->maxFingerWidth) * 1e-6

         capMaxLW= (max maxL maxW)

         ;numFinger = ${template_libName}_numOnly(cdfId->numFinger)
                        
          ;         numFinger = PasCdfValidateInt(cdfId->numFinger ?min dpt->minNumFinger || 1 
           ;        ?max dpt->maxNumFinger
            ;       ?mode mode ?numOnly nil)
                                                 
        ;############ if numFinger are a variable
         
if( numberp(cdfId->numFinger) then 
                 numFinger = PasCdfValidateInt(cdfId->numFinger ?min dpt->minNumFinger || 1 
                           ?max dpt->maxNumFinger
                            ?mode mode ?numOnly nil)
else 

      numFinger = cdfParseFloatString( cdfId->numFinger->value)
)         
 
;add for test 
; if( numberp(cdfId->fingerLength) then 
;                 fingerLength = PasCdfValidateInt(cdfId->fingerLength ?min minL ?max maxL ?mode mode ?numOnly nil)
;else 
;     fingerLength = cdfParseFloatString( cdfId->fingerLength->value)
;)         
                                                   
                                                 
                                                 
                                                 
                                                 
   ;;;;;;;;;;;;;;;;;;HV;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
                        
   when(and(cdfId->metalFingers cdfId->metalFingers->value != "None")
        cdfId->metalFingersUsed->value = "1"
        when(cdfId->metalFingers->value != "None"
            ;;for metal fingers these options should be set as
            cdfgData~>connectGates~>value = "None"
            cdfgData~>gateMetal~>value = "None"
            cdfgData~>strongConnectHVcaps~>value = "None"
        )
                  
        cdfId->metalFingers_str->value = cdfId->metalFingers->value         
                                                                
	when(cdfId->metalCaps
                
                                         
	if(cdfId->doneProc != "cs239ls_capMosDoneProc" then                
		metCap=${template_libName}_calcMetCap(cdfParseFloatString(cdfId->fingerWidth->value) cdfParseFloatString(cdfId->fingerLength->value) cdfId->metalFingers->value)        
		cdfId->metalCaps->value= sprintf(nil "%L" numFinger * cdfParseFloatString(metCap))
	else
		metCap=${template_libName}_calcMetCap2(cdfParseFloatString(cdfId->fingerWidth->value) cdfParseFloatString(cdfId->fingerLength->value) cdfId->metalFingers->value)        
		cdfId->metalCaps->value= sprintf(nil "%L" numFinger * cdfParseFloatString(metCap))
                                        
	);if
                                     
        );when(cdfId->metalCaps
    )   
              
    when(and(cdfId->metalFingers cdfId->metalFingers->value == "None")
         
	cdfId->metalFingers_str->value = cdfId->metalFingers->value   
                                         
              when(cdfId->metalCaps
						cdfId->metalCaps->value="0"
              );when(cdfId->metalCaps

    )   
     
    ;;when switching to metalFingers OFF
    when(and(cdfId->metalFingers cdfId->metalFingers->value == "None" cdfId->metalFingersUsed cdfId->metalFingersUsed->value == "1")

            cdfId->metalFingersUsed->value = "0"
            ;;cdfId->connectGates->value = cdfId->connectGates->defValue   
            ;;cdfId~>gateMetal~>value = cdfId~>gateMetal~>defValue
 
            cdfId->connectGates->value ="None" 
            cdfId~>gateMetal~>value = "None"



    )
    ;;when switching to strongConnectHVcaps ON make connectGates, gateMetal "None"
     when(and(cdfId->strongConnectHVcaps cdfId->strongConnectHVcaps->value != "None")

            cdfgData~>connectGates~>value = "None"
            cdfgData~>gateMetal~>value = "None"

     )
    
    
   ;;;;;;;;;;;;;;;;;;LV;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
   ;;when switching to metalFingersLV ON
    when(and(cdfId->metalFingersLV cdfId->metalFingersLV->value != "None")
    
        cdfId->metalFingersUsedLV->value = "1"
        when(cdfId->metalFingersLV->value != "None"
            ;;for metal fingers these options should be set as
            cdfgData~>connectGates~>value = "Both"
            cdfgData~>gateMetal~>value = "None"
        )
                  
   )   
   ;;when switching to metalFingersLV OFF
    when(and(cdfId->metalFingersLV cdfId->metalFingersLV->value == "None" cdfId->metalFingersUsedLV cdfId->metalFingersUsedLV->value == "1")

            cdfId->metalFingersUsedLV->value = "0"
            ;;for metal fingers these options should be set as
            cdfId->connectGates->value = cdfId->connectGates->defValue   
            cdfId~>gateMetal~>value = cdfId~>gateMetal~>defValue

                  
   )   
   ;;;;;;;;;;;;;;;;;;LV;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                     
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
/* no longer needed as caps can not be specified by c

                  if( cdfId->c->value then
            minC = ${template_libName}_calcCap( 
                        if( cdfId->calculatedParam->value == "Capacitance" then capMinLW else minW)
                        if( cdfId->calculatedParam->value == "Capacitance" then capMinLW else minL)
                        cdfId->numFinger->value dpt->ca dpt->cf dpt 
                      )
            maxC = ${template_libName}_calcCap( 
                        if( cdfId->calculatedParam->value == "Capacitance" then capMaxLW else maxW)
                        if( cdfId->calculatedParam->value == "Capacitance" then capMaxLW else maxL)
                        cdfId->numFinger->value dpt->ca dpt->cf dpt 
                      )
;            ${template_libName}_numOnly(cdfId->c)
            PasCdfValidateFloat(cdfId->c ?min minC ?max maxC ?mode mode ?norm norm ?numOnly nil )
            if(numberp(car( errsetstring( cdfId->simM->value))) then
              cdfId->mfactorC->value = aelSuffixNotation(car(errsetstring(cdfId->c->value)) * car(errsetstring(cdfId->simM->value)))
              else
              cdfId->mfactorC->value = "0"
              );if
         ) ; if c
           
*/                 
        if( dpt->aggregateFingers then   fingersQuotient = 1
        else
            fingersQuotient = cdfParseFloatString( cdfId->numFinger->value)
        ) ; ** if dpt **

         if( IncreaseDevLimits then
             ${template_libName}_numOnly(cdfId->maxFingerWidth)
             PasCdfValidateFloat(cdfId->maxFingerWidth ?min sGrid ?max nil ?grid sGrid  ?mode mode ?norm norm ?numOnly nil)
         else
             ${template_libName}_numOnly(cdfId->maxFingerWidth)
             PasCdfValidateFloat(cdfId->maxFingerWidth 
                    ?min if( cdfId->calculatedParam->value == "Capacitance" then capMinLW else minW) 
                    ?max if( cdfId->calculatedParam->value == "Capacitance" then capMaxLW else maxW)
                    ?grid sGrid ?mode mode ?norm norm ?numOnly nil)
         ) ; else if IncreaseDevLimits
/* this check is being removed by request
; check for variable entries which start with a number
             unless(cdfParseFloatString(cdfId->fingerLength->value)
                when(numberp(atof(substring(cdfId->fingerLength->value 1 1)))
                   PasError("fingerLength illegal syntax! Reverting to Default.")
                   cdfId->fingerLength->value = cdfId->fingerLength->defValue
                   );when
                );unless
             unless(cdfParseFloatString(cdfId->fingerWidth->value)
                when(numberp(atof(substring(cdfId->fingerWidth->value 1 1)))
                   PasError("fingerWidth illegal syntax! Reverting to Default.")
                   cdfId->fingerWidth->value = cdfId->fingerWidth->defValue
                   );when
                );unless
*/
         unless(location=="page_buffer"
         if( IncreaseDevLimits then
;             when(cdfId->c->value
;                ${template_libName}_numOnly(cdfId->fingerLength)
;                ${template_libName}_numOnly(cdfId->fingerWidth)
;                );when

             PasCdfValidateFloat(cdfId->fingerLength ?min sGrid ?max nil ?grid sGrid  ?mode mode ?norm norm ?numOnly nil)
             PasCdfValidateFloat(cdfId->fingerWidth ?min sGrid ?max nil ?grid sGrid  ?mode mode ?norm norm ?numOnly nil )
         else
;             when(cdfId->c->value
;                ${template_libName}_numOnly(cdfId->fingerLength)
;                ${template_libName}_numOnly(cdfId->fingerWidth)
;                );when

            if(numberp(cdfParseFloatString(cdfId->fingerLength->value)) && (apply('or mapcar(lambda((x) abs(cdfParseFloatString(cdfId->fingerLength->value)/scale - evalstring(x)) < grid/2) discreteLengthList)) || apply('or mapcar(lambda((x) abs(cdfParseFloatString(cdfId->fingerLength->value) - evalstring(x)) < grid/2) discreteLengthList))) then
               when(cdfParseFloatString(cdfId->fingerLength->value) > maxL-floatSlop
                  cdfId->fingerLength->value = aelSuffixNotation(cdfParseFloatString(cdfId->fingerLength->value)*scale)
                  );when
               else
               
;disable to fix L variable			   
/*               when(discreteLengthList && discreteNumOnly==t
		  maxL = apply('min mapcar('evalstring discreteLengthList)) * scale
		  warn("Length (%s) parameter: Only discrete value %L * %L allowed" cdfId->fingerLength->name discreteLengthList scale)
               );when

               when(PasCdfValidateFloat(cdfId->fingerLength ?min minL-floatSlop ?max PasRound(maxL sGrid) ?mode mode ?norm norm ?numOnly nil ?grid sGrid) 
               PasCdfSetValue(cdfId->fingerLength PasCdfValidateFloat(cdfId->fingerLength ?min minL-floatSlop ?max PasRound(maxL sGrid) ?mode mode ?norm norm ?numOnly nil ?grid sGrid))
               );when
      );if
            when(procedurep(discreteWidthList) && numberp(cdfParseFloatString(cdfId->fingerLength->value))
               discreteWidthList = funcall(discreteWidthList cdfParseFloatString(cdfId->fingerLength->value)/scale)
               when(dpt->discreteWidthOnly && apply('or mapcar(lambda((x) abs(cdfParseFloatString(cdfId->fingerLength->value)/scale - evalstring(x)) < grid/2) dpt->discreteWidthOnly)) 
                  minW = maxW = apply('max mapcar('evalstring discreteWidthList)) * scale
                  );when
               );when
            when(procedurep(discreteWidthList)
               discreteWidthList = nil
               );
*/
;add to try
            when(PasCdfValidateFloat(cdfId->fingerLength ?min minL-floatSlop ?max maxL ?mode mode ?norm norm ?numOnly nil ?grid sGrid)
            PasCdfSetValue(cdfId->fingerLength PasCdfValidateFloat(cdfId->fingerLength ?min minL-floatSlop ?max maxL ?mode mode ?norm norm ?numOnly nil ?grid sGrid))
               );when
      );if
;add to try
			   if(numberp(cdfParseFloatString(cdfId->fingerWidth->value)) && (apply('or mapcar(lambda((x) abs(cdfParseFloatString(cdfId->fingerWidth->value)/scale - evalstring(x)) < grid/2) discreteWidthList)) || apply('or mapcar(lambda((x) abs(cdfParseFloatString(cdfId->fingerWidth->value) - evalstring(x)) < grid/2) discreteWidthList))) then
               when(cdfParseFloatString(cdfId->fingerWidth->value) > maxW-floatSlop
                  cdfId->fingerWidth->value = aelSuffixNotation(cdfParseFloatString(cdfId->fingerWidth->value)*scale)
                  );when
               else
            when(PasCdfValidateFloat(cdfId->fingerWidth ?min minW-floatSlop ?max maxW ?mode mode ?norm norm ?numOnly nil ?grid sGrid)
            PasCdfSetValue(cdfId->fingerWidth PasCdfValidateFloat(cdfId->fingerWidth ?min minW-floatSlop ?max maxW ?mode mode ?norm norm ?numOnly nil ?grid sGrid))
      );when
   );if
         ) ; else if IncreaseDevLimits
         );unless

         ; limits on total width
         ; used to calculate finger width and number of fingers.
         totalWidth = cdfParseFloatString(cdfId->totalWidth->value)   
         maxFingerWidth = cdfParseFloatString(cdfId->maxFingerWidth->value)
         if( cdfId->considerMaxWidth->value == t then
            if( numberp(totalWidth) && numberp(maxFingerWidth) then
                    min = dpt->minNumFinger || 1
                    when( min && minW
                        min = min * minW
                    )
                    max = dpt->maxNumFinger
                    when( max
                        max = max * maxFingerWidth
                    )
                    if( IncreaseDevLimits then
;                        totalWidth = ${template_libName}_numOnly(cdfId->totalWidth)
                        totalWidth = PasCdfValidateFloat(cdfId->totalWidth ?min sGrid ?max nil ?grid sGrid  ?mode mode ?norm norm ?numOnly nil)
                    else
;                        totalWidth = ${template_libName}_numOnly(cdfId->totalWidth)
                        totalWidth = PasCdfValidateFloat(cdfId->totalWidth ?min min ?max max  ?grid sGrid ?mode mode ?norm norm ?numOnly nil)
                    ) ; else if IncreaseDevLimits
            else
;              totalWidth = ${template_libName}_numOnly(cdfId->totalWidth)
              totalWidth = PasCdfValidateFloat(cdfId->totalWidth ?min nil ?max nil ?grid sGrid ?mode mode ?norm norm ?numOnly nil)
            ) ; ** if numberp **
        else
            numFinger = cdfParseFloatString(cdfId->numFinger->value)
            if( numberp(numFinger) && numberp(totalWidth) then
                numFinger = round(numFinger)
                when( minW
                    ;;check if after numFinger*minW will not increase totalWidth 
                                                  
                    when(totalWidth < minW * numFinger
                        numFinger = 1
                        PasCdfSetValue(cdfId->numFinger numFinger)
                    )
                                                  
                    min = minW * numFinger
                )
                when( maxW
                    max = maxW * numFinger
                )
                 when(cdfId->calculatedParam->value == "Number of Fingers"
                    if( IncreaseDevLimits then
;                        totalWidth = ${template_libName}_numOnly(cdfId->totalWidth)
                        totalWidth = PasCdfValidateFloat(cdfId->totalWidth ?min sGrid ?max nil ?grid sGrid  ?mode mode ?norm norm ?numOnly nil)
                    else
;                        totalWidth = ${template_libName}_numOnly(cdfId->totalWidth)
                        totalWidth = PasCdfValidateFloat(cdfId->totalWidth ?min min ?max max ?grid (sGrid * numFinger) ?mode mode ?norm norm ?numOnly nil)                
                    ) ; else if IncreaseDevLimits
                )
            else
;                totalWidth = ${template_libName}_numOnly(cdfId->totalWidth)
                totalWidth = PasCdfValidateFloat(cdfId->totalWidth ?min nil ?max nil ?grid sGrid ?mode mode ?numOnly nil)       
            ) ; ** if numberp **
        ) ; if cdfId->calculatedParam->value == "Number of Fingers"


;fix for L variable		
if( numberp(cdfId->fingerLength) then 
              cdfId->fingerLength->value = aelSuffixNotation(PasCdfValidateFloat(cdfId->fingerLength ?min minL ?max maxL ?norm norm ?numOnly nil))   
else 
      fingerLength = cdfParseFloatString( cdfId->fingerLength->value)
)         
        		

;cdfId->fingerLength->value = aelSuffixNotation(PasCdfValidateFloat(cdfId->fingerLength ?min minL ?max maxL ?norm norm ?numOnly nil))



; determine configuration of device depending of it's size and hole pitch
  when(cdfId->contactHoles
    if(cdfId->contactHoles->value == t then
      when(numberp(car(errsetstring(cdfId->fingerWidth->value))) && numberp(car(errsetstring(cdfId->fingerLength->value)))

; normalize w and l
  cdfId->fingerWidth->value = aelSuffixNotation(PasCdfValidateFloat(cdfId->fingerWidth ?min minW ?max maxW ?norm norm ?numOnly nil))
  cdfId->fingerLength->value = aelSuffixNotation(PasCdfValidateFloat(cdfId->fingerLength ?min minL ?max maxL ?norm norm ?numOnly nil))

; fingerLength should be larger than fingerWidth to allow the most poly contacts when a poly edge protrudes from the diffusion, but only when the poly does not protrude on both sides
         when(cdfParseFloatString(cdfId->fingerWidth->value) > cdfParseFloatString(cdfId->fingerLength->value) && cdfId->bridgeDiff->value
            holdFingerLength = cdfId->fingerLength->value
            cdfId->fingerLength->value = cdfId->fingerWidth->value
            cdfId->fingerWidth->value = holdFingerLength
            );when

; calc device holes
  devHoles = ${template_libName}_calcCapHoles(dpt cdfParseFloatString(cdfId->fingerWidth->value)/scale cdfParseFloatString(cdfId->fingerLength->value)/scale cdfId->frequency->value)
  cdfId->polyHoleList->value = sprintf(nil "%L" nth(0 devHoles))
  cdfId->diffHoleList->value = sprintf(nil "%L" nth(1 devHoles))
  cdfId->polyHoleCount->value = length(nth(0 devHoles))
  cdfId->diffHoleCount->value = length(nth(1 devHoles))

; configure diffusion
; Spansion would now like the bridgeDiff to control the ringDiff

  if(nth(0 linereadstring(cdfId->diffHoleList->value)) then
    cdfId->ringDiff->value = t
;    cdfId->bridgeDiff->value = t
    else
    cdfId->ringDiff->value = nil
    );if


when(cdfId->bridgeDiff->value == nil 
   cdfId->ringDiff->value = nil
   );when

  );when
  else
  cdfId->polyHoleList->value = "nil"
  cdfId->diffHoleList->value = "nil"
  cdfId->polyHoleCount->value = 0
  cdfId->diffHoleCount->value = 0
  cdfId->ringDiff->value = nil
  ));if, when



; limit connect Gates cyclic value based on ringDiff param
  when(cdfId->ringDiff->value == t
     when(cdfId->connectGates->value != "None"
          cdfId->connectGates->value = "None"
          PasWarn("Gate Connection must be None when ring diffusion is used")
          );when
       );when

; limit connect Gates cyclic value based on brigeDiff param
  when(cdfId->bridgeDiff->value == t
     when(cdfId->connectGates->value != "None" && cdfId->connectGates->value != "Bottom"
          cdfId->connectGates->value = cdfId->connectGates->defValue
          PasWarn("Gate Connection must be None or Bottom when diffusion is bridged")
          );when
       );when

    ${template_libName}_numOnly(cdfId->metalWidthSD)
    PasCdfValidateFloat(cdfId->metalWidthSD 
                ?min cdfId->metalWidthSD->defValue
                ?max maxMetalWidthSD*scale
                ?grid sGrid ?mode mode ?norm norm ?numOnly nil)
                
    metalWidthSD = cdfParseFloatString( cdfId->metalWidthSD->value) / scale

    if(param == 'leftTap || param == 'rightTap || (param == 'tap && cdfId->tap->value == "Integrated") then
        when( cdfId->tap->value == "Integrated" && cdfId->leftTap->value && !cdfId->leftCont->value
            PasCdfSetValue(cdfId->leftCont t)
                PasWarn( "Left contact must remain on when integrated tap is used. Turning on left contact")
        ) ; when left integrated tap is used.
        when( cdfId->tap->value == "Integrated" && cdfId->rightTap->value && !cdfId->rightCont->value
            PasCdfSetValue(cdfId->rightCont t)
             PasWarn( "Right contact must remain on when integrated tap is used. Turning on right contact")
        ) ; when right integrated tap is used.
    else
        when( cdfId->tap->value == "Integrated" && cdfId->leftTap->value && !cdfId->leftCont->value 
            PasCdfSetValue(cdfId->leftTap nil)
            PasWarn("Left integrated tap must be off due to abutment.  Turning off left tap"  )
        )
        when( cdfId->tap->value == "Integrated" && cdfId->rightTap->value && ! cdfId->rightCont->value 
               PasCdfSetValue(cdfId->rightTap nil)
               PasWarn("Right integrated tap must be off due to abutment.  Turning off right tap"  )
        )
    ) ; else if

    if(!cdfId->leftCont->value && cdfId->leftTap->value then
        if(param == 'leftTap then
            PasCdfSetValue(cdfId->leftCont t)
            PasWarn( "Left contact must remain on when tap is used. Turning on left contact")
        else
            PasCdfSetValue(cdfId->leftTap nil)
            PasWarn("Left tap must be off when shared SD is used.  Turning off left tap"  )
        )
    )
        
    if(!cdfId->rightCont->value && cdfId->rightTap->value && cdfId->tap->value then
        if(param == 'rightTap then
            PasCdfSetValue(cdfId->rightCont t)
            PasWarn( "Right contact must remain on when tap is used. Turning on right contact")
        else
            PasCdfSetValue(cdfId->rightTap nil)
            PasWarn("Right tap must be off when shared SD is used.  Turning off right tap"  )
        )
    )

    PasCdfValidateInt(cdfId->simM ?min dpt->minSimM || 1 ?max dpt->maxSimM ?mode mode ?numOnly nil)

    when(cdfId->tapCntRows
        ${template_libName}_numOnly(cdfId->tapCntRows)
        PasCdfValidateInt(cdfId->tapCntRows ?min dpt->minTapCntRows || 1 ?max dpt->maxTapCntRows
                ?mode mode ?numOnly nil)
    );when

    numFinger = cdfParseFloatString( cdfId->numFinger->value)
    crates = ${template_libName}_numOnly(cdfId->crates)
    crates = PasCdfValidateInt(cdfId->crates ?min 1 ?max nil ?mode mode ?numOnly nil)
    
         if(numberp(numFinger) then
          unless( abs( round( float( numFinger) / crates) - float( numFinger) / crates ) < 0.01
        PasWarn( "Fingers / Crates must be an integer value. Setting Crates to 1" )
        crates = 1
        PasCdfSetValue(cdfId->crates crates)
     );unless
         );if  
         
    PasCdfSetValue(cdfId->crates crates)

    (when cdfId->tap
        oldV = evalstring(sprintf(nil "'( nil %s )" cdfId->tapExtension->value))
        newV = ""
        foreach( s list('left 'right 'bottom 'top)
            value = get(oldV s)
       
            if( numberp(value) then
                value = max(PasRound(float(value) grid) 0.0)
                value = min(value 100.0)
            else
                value = 0.0
            )
            newV = strcat(newV sprintf(nil "%s %L " s value ))
        ) ; ** foreach side **

        PasCdfSetValue(cdfId->tapExtension newV)
    )

    (when cdfId->rightAbutExt 
        ${template_libName}_numOnly(cdfId->rightAbutExt)
        PasCdfValidateFloat(cdfId->rightAbutExt ?min sGrid ?max nil ?grid nil ?mode mode ?numOnly nil)
    )
    (when cdfId->leftAbutExt 
        ${template_libName}_numOnly(cdfId->leftAbutExt)
        PasCdfValidateFloat(cdfId->leftAbutExt ?min sGrid ?max nil ?grid nil ?mode mode ?numOnly nil)
    ) 

    (when cdfId->tap &&   cdfId->tap->value == "Integrated"        
         leftDummies = cdfId->leftDummies->value
         rightDummies = cdfId->rightDummies->value
         numFinger = round( cdfParseFloatString(cdfId->numFinger->value))
         sourceFirst = cdfId->sourceFirst->value
         sourceLast = PasXor( sourceFirst oddp( numFinger ) ) || rightDummies >= 1

        
         when( cdfId->rightTap->value && !sourceLast && param == 'sourceFirst
                PasCdfSetValue(cdfId->rightTap nil)
                PasWarn( "Integrated tap may only abut source diffusion or right dummy. Turning off right tap")
         ) ; when
         when( cdfId->rightTap->value && !sourceLast && param != sourceFirst
                PasCdfSetValue(cdfId->sourceFirst !cdfId->sourceFirst->value)
                PasWarn( "Integrated tap may only abut source diffusion or right dummy. Changing Source First")
                (when cdfId->leftTap->value && !(cdfId->sourceFirst->value || leftDummies >= 1)
                  PasCdfSetValue(cdfId->leftTap nil)
                  PasWarn( "Integrated tap may only abut source diffusion or left dummy. Turning off left tap")
                ); when
         ) ; when
         
         
            when( cdfId->leftTap->value && !(cdfId->sourceFirst->value || cdfId->leftDummies->value >= 1) && param == 'sourceFirst
                  PasCdfSetValue(cdfId->leftTap nil)
                  PasWarn( "Integrated tap may only abut source diffusion or left dummy. Turning off left tap")
            ) ; when dfId->leftTap->value && cdfId->tap->value == "Integrated"
            when( cdfId->leftTap->value && !(cdfId->sourceFirst->value || cdfId->leftDummies->value >= 1) && param != 'sourceFirst
                  PasCdfSetValue(cdfId->sourceFirst !cdfId->sourceFirst->value)
                  PasWarn( "Integrated tap may only abut source diffusion or left dummy. Changing Source First")
                  sourceLast = PasXor( cdfId->sourceFirst->value oddp( numFinger ) ) || cdfId->rightDummies->value >= 1
                  when( cdfId->rightTap->value && !sourceLast
                    PasCdfSetValue(cdfId->rightTap nil)
                    PasWarn( "Integrated tap may only abut source diffusion or right dummy. Turning off right tap")
                  ) ; when
            ) ; when dfId->leftTap->value && cdfId->tap->value == "Integrated"

    ) ; cdfId->tap

    ;; set value for m
    if(numberp(car( errsetstring( cdfId->simM->value))) then

       vxl_multiplier = cdfId->crates->value * or( round( car( errsetstring( cdfId->simM->value))) 1)
       PasCdfSetValue( cdfId->m vxl_multiplier )  
     
       bsim_multiplier = if( dpt->aggregateFingers then 
                             or( round( car( errsetstring( cdfId->simM->value))) 1)
                         else
                            
                          if(numberp(numFinger) then                                                                                                                        
                               numFinger * or( round( car( errsetstring( cdfId->simM->value))) 1)
                           else
                              strcat(sprintf(nil "%d" or( round( car( errsetstring( cdfId->simM->value))) 1)) " * iPar(\"numFinger\")")
                           );if 
                                                                 
                                                                 
                                                                 
                                                                 )
       PasCdfSetValue( cdfId->bsimM bsim_multiplier )   
       else
       vxl_multiplier = strcat(sprintf(nil "%d" cdfId->crates->value) " * iPar(\"simM\")")
       PasCdfSetValue( cdfId->m vxl_multiplier )  
     
       bsim_multiplier = if( dpt->aggregateFingers then 
                             "iPar(\"simM\")"
                         else
                             "iPar(\"numFinger\") * iPar(\"simM\")"
                         )
       PasCdfSetValue( cdfId->bsimM bsim_multiplier )   
       );if

    if(cdfId->DFM->value then
         PasCdfSetValue( cdfId->diffContEnc dpt->meDiffContDFM * 1e-6 )
    else
         PasCdfSetValue( cdfId->diffContEnc dpt->meDiffCont * 1e-6 ) 
    )

    fingerLength =  cdfParseFloatString( cdfId->fingerLength->value)         
    fingerWidth =  cdfParseFloatString( cdfId->fingerWidth->value)   
    
    diffContEnc = cdfParseFloatString( cdfId->diffContEnc->value) / scale 
    meDiffConty = (max diffContEnc dpt->meeDiffCont)
    contSpan  = metalWidthSD - ( 2 * meM1Cont )
        
    if( numberp(fingerWidth) then 
       (when fingerWidth <= (fwMeeDiffCont - grid / 10.0) * 1e-6
;         diffContEnc = dpt->meeDiffCont
        diffContEnc = cdfParseFloatString( cdfId->diffContEnc->value) / scale 
        ) ; when fingerwidth
    else
        diffContEnc = cdfParseFloatString( cdfId->diffContEnc->value) / scale 
    ) ; numberp fingerwith

;    contSpan  = metalWidthSD - ( 2 * meM1Cont )
/*    
    ;new dogbone section
    when( numberp( fingerWidth) && cdfId->calculatedParam->value != "Finger Width"
        previous_dogbone = cdfId->dogbone->value
        dogbone = cdfId->dogbone->value = (fingerWidth*1e6 + grid/10.0) < (mwCont + 2 * meDiffConty  )
    )
    when( numberp( totalWidth) && numberp( numFinger) && cdfId->calculatedParam->value != "Total Width"
        previous_dogbone = cdfId->dogbone->value
        dogbone = cdfId->dogbone->value = ((totalWidth/numFinger)*1e6 + grid/10.0) < (mwCont + 2 * meDiffConty  )
    )
*/    
    numConts = metalWidthSD >= 2 * mwCont + msCont + 2 * meM1Cont 
    if( numConts then 
        M1ContEnc = meM1Cont
    else
        M1ContEnc = PasRound( (metalWidthSD - mwCont)/2 grid)
    )  
    numContCols = (ceiling contSpan / (mwCont + msCont))

    if( dogbone then
            ${template_libName}_numOnly(cdfId->GCwSp)
            PasCdfValidateFloat(cdfId->GCwSp 
                ?min PasRound( msDiffPoly + diffContEnc - M1ContEnc grid) * scale ?grid sGrid 
                ?max maxGCwSp*scale ?norm norm ?mode mode ?grid sGrid ?numOnly nil)
    else
            ${template_libName}_numOnly(cdfId->GCwSp)
            if(numContCols == 1 then
               PasCdfValidateFloat(cdfId->GCwSp ?min PasRound(cdfParseFloatString(cdfId->GCwSp->defValue) - (metalWidthSD*scale - cdfParseFloatString(cdfId->metalWidthSD->defValue))/2 sGrid) ?max maxGCwSp*scale ?norm norm ?mode mode ?grid sGrid ?numOnly nil)
               else
               PasCdfValidateFloat(cdfId->GCwSp ?min dpt->msContPoly*scale + dpt->meM1Cont*scale ?max maxGCwSp*scale ?norm norm ?mode mode ?grid sGrid ?numOnly nil)
               );if
    ) ; dogbone
        
    when( numberp( fingerWidth)
        unless( previous_dogbone == dogbone  || dogbone && param == 'DFM
            if( dogbone then
                cdfId->GCwSp->value = (sprintf nil "%.6g" 
                    PasRound( msDiffPoly + diffContEnc - M1ContEnc grid) * scale )
            else
                cdfId->GCwSp->value = cdfId->GCwSp->defValue
                artWarn( "Resetting Gate to Metal Space to default for non-dogbone")
            ) ; if else dogbone
        ) ; unless dogbone    
        ${template_libName}_numOnly(cdfId->GCwSp)
        if(numContCols == 1 then
           PasCdfValidateFloat(cdfId->GCwSp ?min PasRound(cdfParseFloatString(cdfId->GCwSp->defValue) - (metalWidthSD*scale - cdfParseFloatString(cdfId->metalWidthSD->defValue))/2 sGrid) ?max maxGCwSp*scale ?norm norm ?grid sGrid ?mode mode ?numOnly nil)
           else
           PasCdfValidateFloat(cdfId->GCwSp ?min dpt->msContPoly*scale + dpt->meM1Cont*scale ?max maxGCwSp*scale ?norm norm ?mode mode ?grid sGrid ?numOnly nil)
           );if
    ) ; fingerWidth
    ; end new dogbone section 
    

    cdfId->contSpan->value     = (sprintf nil "%.6g" contSpan * 1e-6)
        
         
 
         
         
         if(numberp(numFinger) then         
                    cdfId->totFinger->value    = (sprintf nil "%d" round( cdfId->leftDummies->value)                                                                                                                         + round( numFinger) + round( cdfId->rightDummies->value))
                   totFinger = evalstring( cdfId->totFinger->value)
         else
                 cdfId->totFinger->value    = (sprintf nil "%d + round(iPar(\"numFinger\"))" round( cdfId->leftDummies->value) + round( cdfId->rightDummies->value))
                        
                 totFinger = cdfId->totFinger->value
                                          
                 
         )
         
         
         
         
         

        
    ;totFinger = evalstring( cdfId->totFinger->value)
    metalList = evalstring(sprintf(nil "'%s" cdfId->metalList->value))
   
/*    unless( length( metalList) == 1
        when( member( cdfId->connectGates->value (list "Both" "Top"))
            for( c 0 totFinger
                metalList = ${template_libName}_mosSetStretchList(
                        metalList 
                        c totFinger
                        grid ?ury 0.0) 
            ) ; for totFinger
            unless( metalList == evalstring(sprintf(nil "'%s" cdfId->metalList->value))
                 PasWarn( "source-drain metal can't be stretched when gate connection is on")
            )
            cdfId->metalList->value = sprintf( nil "%L" metalList)
        ) ; when connectGates
    ) ; when metalList                   
        
    unless( length( metalList) == 1
        when( member( cdfId->connectGates->value (list "Both" "Bottom"))
            for( c 0 totFinger
                metalList = ${template_libName}_mosSetStretchList(
                        metalList 
                        c totFinger
                        grid ?lly 0.0) 
            ) ; for totFinger
            unless( metalList == evalstring(sprintf(nil "'%s" cdfId->metalList->value))
                PasWarn( "source-drain metal can't be stretched when gate connection is on")
            )
            cdfId->metalList->value = sprintf( nil "%L" metalList)
        ) ; when connectGates
    ) ; when metalList                   
*/    
    ; if fingerLength or fingerWidth are a variable, default msPoly is assumed
    if( procedurep( dpt->msPoly) then
        msPoly = dpt->msPoly( if( numberp(fingerLength) then fingerLength/scale else 
                                cdfParseFloatString( cdfId->fingerLength->defValue)/scale)
                  if( numberp(fingerWidth) then  fingerWidth/scale else
                                cdfParseFloatString( cdfId->fingerWidth->defValue)/scale)
                                !dpt->thoxLayer dpt->amsBestPractice)
    else 
        msPoly = dpt->msPoly
    )

     unless( numConts ; num of contact = 1
        contSpan = mwCont
    )  

    msContPoly = cdfParseFloatString( cdfId->GCwSp->value) * 1e6 + M1ContEnc
    cdfId->msContPoly->value = sprintf( nil "%.6g" msContPoly * scale)

    ; these variables were originally in the config file.  They are used by the pcell.
    stepWidth = max( ( msContPoly - diffContEnc ) msDiffPoly grid )
    cdfId->dsDiffPoly->value   = (sprintf nil "%.6g" stepWidth * 1e-6)
    
    ; active enclosure of poly (with contact) for dogbone on left & right hand sides.
    deeDiffPoly = max(meDiffPoly (2 *  diffContEnc + contSpan + stepWidth))
    cdfId->deeDiffPoly->value   = (sprintf nil "%.6g" deeDiffPoly * 1e-6)

    ; active enclosure of poly (with contact) for non dogbone on left & right hand sides.
    neeDiffPoly = max( meDiffPoly (diffContEnc + contSpan + msContPoly)) 
    cdfId->neeDiffPoly->value  = (sprintf nil "%.6g" neeDiffPoly * 1e-6)

    ; dogbone gate spacing
    dceDiffPoly = max( msPoly (2 * diffContEnc + contSpan + 2 * stepWidth))
    cdfId->dceDiffPoly->value  = (sprintf nil "%.6g" dceDiffPoly * 1e-6)
    
    ; non-dogbone gate spacing
    nceDiffPoly = max( msPoly ( 2 * msContPoly + contSpan))

    cdfId->nceDiffPoly->value   = (sprintf nil "%.6g" nceDiffPoly * 1e-6) 
    
    ; half gate spacings.
    cdfId->hdceDiffPoly->value = (sprintf nil "%.6g" PasCeiling( dceDiffPoly / 2.0 grid t) * 1e-6)
    cdfId->hnceDiffPoly->value = (sprintf nil "%.6g" PasCeiling( nceDiffPoly / 2.0 grid t) * 1e-6)

    ; calculate contact spacing to be used in BSDContSp calculation    
    if( numberp(fingerWidth) then 
        numContCols = (ceiling contSpan / (mwCont + msCont))
        numContRows = (ceiling (fingerWidth * 1e6) / (mwCont + msCont))
        msContWide = dpt->msCont( numContRows (numContCols + 1)) 
    else
        msContWide = msCont
    )

    BSDContSp =  max( ( max(meItimpCont meTapCont) + max(msItimpCont dpt->meDiffCont) ) msContWide)
    
    cdfId->BSDContSp->value = (sprintf nil "%.6g" BSDContSp * 1e-6 )

    case( cdfId->calculatedParam->value
	;added for variable finger length		
/*        ("Length"
            fingerLength = cdfParseFloatString(cdfId->fingerWidth->value)
            if( numberp(fingerLength)  then
               fingerLength = fingerLength
               PasCdfSetValue(cdfId->fingerLength fingerLength)
               fingerLength = PasCdfValidateFloat(cdfId->fingerLength ?min minL-floatSlop ?max maxL ?mode mode ?norm norm ?numOnly nil ?grid sGrid)			   
            else
              ; fingerLength = "iPar(\"fingerLength\")"
			  fingerLength = fingerLength
            )
            PasCdfSetValue(cdfId->fingerLength fingerLength)
        ) ; Finger Length		
*/
	
        ("Total Width"
            fingerWidth = cdfParseFloatString(cdfId->fingerWidth->value)
            numFinger = cdfParseFloatString(cdfId->numFinger->value)
            if( numberp(fingerWidth) && numberp(numFinger) then
               totalWidth = fingerWidth * round(numFinger)
            else
               totalWidth = "iPar(\"fingerWidth\") * iPar(\"numFinger\")"
            )
            PasCdfSetValue(cdfId->totalWidth totalWidth)
        ) ; Total Width
		

		
		
        ( "Finger Width"
            totalWidth = cdfParseFloatString(cdfId->totalWidth->value)
            numFinger = cdfParseFloatString(cdfId->numFinger->value)
            if( numberp(totalWidth) && numberp(numFinger) then
               fingerWidth = PasCeiling(totalWidth/round(numFinger) sGrid t)
               PasCdfSetValue(cdfId->fingerWidth fingerWidth)
               fingerWidth = PasCdfValidateFloat(cdfId->fingerWidth ?min minW-floatSlop ?max maxW ?mode mode ?norm norm ?numOnly nil ?grid sGrid)
               totalWidth = fingerWidth * numFinger
               PasCdfSetValue(cdfId->totalWidth totalWidth)
            else
               fingerWidth = "iPar(\"totalWidth\") / iPar(\"numFinger\")"
            )
            PasCdfSetValue(cdfId->fingerWidth fingerWidth)
            if(cdfId->considerMaxWidth->value == t then
               totalWidth = cdfParseFloatString(cdfId->totalWidth->value)
               maxFingerWidth = cdfParseFloatString(cdfId->maxFingerWidth->value)
               if( numberp(totalWidth) && numberp(maxFingerWidth) && numberp(fingerWidth) then
                 if(fingerWidth > maxFingerWidth then
                  numFinger = PasCalcMosFingers(totalWidth maxFingerWidth sGrid)
                  PasCdfSetValue(cdfId->numFinger numFinger)
                  fingerWidth = PasCeiling(totalWidth/numFinger sGrid t)
                  PasCdfSetValue(cdfId->fingerWidth fingerWidth )
                  PasCdfSetValue(cdfId->totalWidth (fingerWidth * numFinger) )
                  );if
               else
;                  numFinger = sprintf(nil "ceiling((iPar(\"totalWidth\") - %s) / iPar(\"maxFingerWidth\"))"
;                                   aelSuffixNotation(sGrid * 1e-3 6))
                  numFinger = "1"
                                                
                  PasCdfSetValue(cdfId->numFinger numFinger)
              ) ; ** if numberp **
            );if
        ) ; Finger Width
        ("Number of Fingers"
            totalWidth = cdfParseFloatString(cdfId->totalWidth->value)
            totalWidth2 = cdfParseFloatString(cdfId->totalWidth2->value)
            if(cdfId->considerMaxWidth->value == t || !numberp(totalWidth) then
               maxFingerWidth = cdfParseFloatString(cdfId->maxFingerWidth->value)
               else
               maxFingerWidth = min(maxW cdfParseFloatString(cdfId->totalWidth->value)/cdfParseFloatString(cdfId->numFinger->value))
               );if
            if( numberp(totalWidth) && numberp(maxFingerWidth) then
               fingerWidth = PasRound(totalWidth/numFinger sGrid)
               when(fingerWidth < minW
                  fingerWidth = totalWidth
                  numFinger = 1
                  PasCdfSetValue(cdfId->numFinger numFinger)
                  );when
               when(fingerWidth > maxFingerWidth || abs(totalWidth - totalWidth2) > grid/4
                  numFinger = PasCalcMosFingers(totalWidth maxFingerWidth sGrid)
                  PasCdfSetValue(cdfId->numFinger numFinger)
                  fingerWidth = PasCeiling(totalWidth/numFinger sGrid t)
                  PasCdfSetValue(cdfId->totalWidth2 (fingerWidth * numFinger))
                  );when
               PasCdfSetValue(cdfId->fingerWidth fingerWidth )
               PasCdfSetValue(cdfId->totalWidth (fingerWidth * numFinger) )
            else
;               numFinger = sprintf(nil "ceiling((iPar(\"totalWidth\") - %s) / iPar(\"maxFingerWidth\"))"
;                                   aelSuffixNotation(sGrid * 1e-3 6))
               numFinger = 1
               PasCdfSetValue(cdfId->numFinger numFinger)
               PasCdfSetValue(cdfId->fingerWidth totalWidth)
            ) ; ** if numberp **
/*        ) ; Number Of Fingers
        ( ( "Capacitance" "cap & l" )

            numFinger = cdfParseFloatString(cdfId->numFinger->value)
            when(cdfId->c->value && atof(cdfId->c->value)
               capacitance  = cdfParseFloatString(cdfId->c->value) / numFinger
               )
            ca = dpt->ca
            cf = dpt->cf
            
            if( cdfId->calculatedParam->value == "Capacitance" then
                fingerLength = PasRound( (-4*cf + ((4*cf)**2 - 4*ca*(-capacitance))**0.5)/
                    (2*ca) sGrid )
                PasCdfSetValue(cdfId->fingerLength fingerLength)
                if( IncreaseDevLimits then
                    when(cdfId->c->value
                       ${template_libName}_numOnly(cdfId->fingerLength)
                       );when
                    PasCdfValidateFloat(cdfId->fingerLength ?min sGrid ?max nil ?grid sGrid 
                                            ?mode mode ?norm norm ?numOnly nil)
                else
                    when(cdfId->c->value
                       ${template_libName}_numOnly(cdfId->fingerLength)
                       );when
                    PasCdfSetValue(cdfId->fingerLength PasCdfValidateFloat(cdfId->fingerLength ?min minL-floatSlop ?max maxL+floatSlop ?mode mode ?norm norm ?numOnly nil))
                ) ; if else
            ) ; if Capacitance
            fingerLength = cdfParseFloatString(cdfId->fingerLength->value)
            fingerWidth = PasRound( (capacitance - 2 * fingerLength * cf) / (fingerLength * ca + 2 * cf) sGrid)
            PasCdfSetValue(cdfId->fingerWidth fingerWidth )
            if( IncreaseDevLimits then
                    when(cdfId->c->value
                       ${template_libName}_numOnly(cdfId->fingerLength)
                       );when
                PasCdfValidateFloat(cdfId->fingerWidth ?min sGrid ?max nil ?grid sGrid 
                                            ?mode mode ?norm norm ?numOnly nil )
            else
                    when(cdfId->c->value
                       ${template_libName}_numOnly(cdfId->fingerLength)
                       );when
                PasCdfSetValue(cdfId->fingerWidth PasCdfValidateFloat(cdfId->fingerWidth ?min minW-floatSlop ?max maxW+floatSlop ?mode mode ?norm norm ?numOnly nil))
            )
            fingerWidth = cdfParseFloatString(cdfId->fingerWidth->value)
            numFinger = cdfParseFloatString(cdfId->numFinger->value)
       ) ; Capacitance, cap & l
        ("l & w" */
            numFinger = cdfParseFloatString(cdfId->numFinger->value)
            fingerWidth = cdfParseFloatString(cdfId->fingerWidth->value)
            fingerLength = cdfParseFloatString(cdfId->fingerLength->value)
            ca = dpt->ca
            cf = dpt->cf
        ) ; l & w
        (t
            (printf "mos callback: unknown calculatedParam value %s\n" cdfId->calculatedParam->value)
        )
    ) ; case calculatedParam

;    when(member(cdfId->calculatedParam->value list("Capacitance" "cap & l" "l & w"))

    ;new dogbone section
    when( numberp( fingerWidth) && cdfId->calculatedParam->value != "Finger Width"
        previous_dogbone = cdfId->dogbone->value
        dogbone = cdfId->dogbone->value = (fingerWidth*1e6 + grid/10.0) < (mwCont + 2 * meDiffConty  )
    )
    when( numberp( totalWidth) && numberp( numFinger) && cdfId->calculatedParam->value != "Total Width"
        previous_dogbone = cdfId->dogbone->value
        dogbone = cdfId->dogbone->value = ((totalWidth/numFinger)*1e6 + grid/10.0) < (mwCont + 2 * meDiffConty  )
    )

    ;; calculate parasitic values
    value = ${template_libName}_mosCalcAreaPerim(
                     cdfId->fingerWidth->value
                     cdfId->fingerLength->value
                     cdfId->numFinger->value
                     cdfId->sourceFirst->value
                     cdfId->metalWidthSD->value
                     dpt 
                 )
   ; gt_contSpan  = (fingerLength * numFinger) + (value->sd * (numFinger - 1)) - ( 2 * meePolyCont*scale )

   ; cdfId->gt_contSpan->value  = (sprintf nil "%.6g" gt_contSpan)

    unless(cdfId->userWell == "Edit"
        PasCdfSetValue(cdfId->wellArea value->wellArea)
        PasCdfSetValue(cdfId->wellPerim value->wellPerim)
        );unless
    unless(cdfId->userDNW == "Edit"
        PasCdfSetValue(cdfId->dnwArea value->dnwArea)
        PasCdfSetValue(cdfId->dnwPerim value->dnwPerim)
        );unless

    unless( cdfId->editSourceAreaPerim->value == "Edit"
        PasCdfSetValue(cdfId->as value->as )
        PasCdfSetValue(cdfId->ps value->ps )
        PasCdfSetValue(cdfId->nrs value->nrs )
    )  ; ** unless editSourceAreaPerim *
    unless( cdfId->editDrainAreaPerim->value == "Edit"
        PasCdfSetValue(cdfId->ad value->ad )
        PasCdfSetValue(cdfId->pd value->pd )
        PasCdfSetValue(cdfId->nrd value->nrd )
    )  ; ** unless editDrainAreaPerim *
    unless(cdfId->editSDAreaPerim->value == "Edit"
       PasCdfSetValue(cdfId->asd value->asd )
       PasCdfSetValue(cdfId->psd value->psd )
       );unless
    unless( cdfId->userLod->value == "Edit"
      case(cdfId->userLod->value
        ("View Typ"
          saVal = if(dpt->TypSa then dpt->TypSa*scale else value->sa)
          sbVal = if(dpt->TypSb then dpt->TypSb*scale else value->sb)
          );typ
        ("View Bcs"
          if(dpt->BcsSa == "calculate" then
            saVal = value->sa
            else
            saVal = if(dpt->BcsSa then dpt->BcsSa*scale else value->sa)
            );if
          if(dpt->BcsSb == "calculate" then
            sbVal = value->sb
            else
            sbVal = if(dpt->BcsSb then dpt->BcsSb*scale else value->sb)
            );if
          );bcs
        ("View Wcs"
          if(dpt->WcsSa == "calculate" then
            saVal = value->sa
            else
            saVal = if(dpt->WcsSa then dpt->WcsSa*scale else value->sa)
            );if
          if(dpt->WcsSb == "calculate" then
            sbVal = value->sb
            else
            sbVal = if(dpt->WcsSb then dpt->WcsSb*scale else value->sb)
            );if
          );wcs
        (t
          saVal = value->sa
          sbVal = value->sb
          )
        );case
        PasCdfSetValue(cdfId->sa saVal )
        PasCdfSetValue(cdfId->sb sbVal )
        PasCdfSetValue(cdfId->sd value->sd )
    ) ; ** unless userLod **
/*  Saifun did not like this behavior
    when( and( cdfId->userLod->value == "Edit" !cdfId->match->value)
        PasWarn( "LOD params can only be edited when the Matched Device button is enabled.")
        PasCdfSetValue(cdfId->userLod "View")    
    ) ; when
    
    when( cdfId->editSourceAreaPerim->value == "Edit"
      PasWarn( "User Source parasitics button is ON.  Source parasitics not updated with callback.")
    )
    when( cdfId->editDrainAreaPerim->value == "Edit"
      PasWarn( "User Drain parasitics button is ON.  Drain parasitics not updated with callback.")
    )
*/
    w = cdfParseFloatString(cdfId->fingerWidth->value)
    l = cdfParseFloatString(cdfId->fingerLength->value)

    unless( (scTop = cdfParseFloatString(cdfId->scTop->value)) && typep( scTop ) == 'flonum &&
           scTop >= 0
        artWarn("scTop value must be a positive integer - set to default" )
        scTop = cdfParseFloatString(cdfId->scTop->defValue)
    )
    when( scTop < (SCMinEnc - grid/2 ) / 1e6
        artWarn("scTop Enclosure value < SCMinEnc - setting to SCMinEnc")
        scTop = SCMinEnc / 1e6
    )
    
    unless( (scBot = cdfParseFloatString(cdfId->scBot->value)) && typep( scBot ) == 'flonum &&
           scBot >= 0
        artWarn("scBot value must be a positive integer - set to default" )
        scBot = cdfParseFloatString(cdfId->scBot->defValue)
    )
    when( scBot < (SCMinEnc - grid/2 ) / 1e6
        artWarn("scBot Enclosure value < SCMinEnc - setting to SCMinEnc")
        scBot = SCMinEnc / 1e6
    )
    
    unless( (scRight = cdfParseFloatString(cdfId->scRight->value)) && typep( scRight ) == 'flonum &&
           scRight >= 0
        artWarn("scRight value must be a positive integer - set to default" )
        scRight = cdfParseFloatString(cdfId->scRight->defValue)
    )
    when( scRight < ( (SCMinEnc + msContPoly + mwCont + diffContEnc ) - grid/2 ) / 1e6
        artWarn("scRight Enclosure value < SCMinEnc - setting to SCMinEnc")
        scRight =  (SCMinEnc + msContPoly + mwCont + diffContEnc) / 1e6
    )
    
    unless( (scLeft = cdfParseFloatString(cdfId->scLeft->value)) && typep( scLeft ) == 'flonum &&
           scLeft >= 0
        artWarn("scLeft value must be a positive integer - set to default" )
        scLeft = cdfParseFloatString(cdfId->scLeft->defValue)
    )
    when( scLeft < ( (SCMinEnc + msContPoly + mwCont + diffContEnc ) - grid/2 ) / 1e6
        artWarn("scLeft Enclosure value < SCMinEnc - setting to SCMinEnc")
        scLeft = (SCMinEnc + msContPoly + mwCont + diffContEnc) / 1e6
    )

    if( cdfId->userWPE->value != "Edit" && !cdfId->match->value then
        scTop = SCMinEnc / 1e6
        scBot = SCMatchEnc / 1e6
        if( typep( l ) == 'flonum 
                && type( cdfParseFloatString(cdfId->sa->value)) == 'flonum 
                && type( cdfParseFloatString(cdfId->sb->value)) == 'flonum then
            scRight = max( SCMatchEnc/1e6 cdfParseFloatString(cdfId->sb->value)+(SCMinEnc/1e6))
            scLeft = max( SCMatchEnc/1e6 cdfParseFloatString(cdfId->sa->value)+(SCMinEnc/1e6))
        else
            scRight = SCMatchEnc / 1e6
            scLeft = SCMatchEnc / 1e6
        )
    ) ; if !match
    if( cdfId->userWPE->value != "Edit" && cdfId->match->value then
        scTop = SCMatchEnc / 1e6
        scBot = SCMatchEnc / 1e6
        if( typep( l ) == 'flonum 
                && type( cdfParseFloatString(cdfId->sa->value)) == 'flonum 
                && type( cdfParseFloatString(cdfId->sb->value)) == 'flonum then
            scRight = max( SCMatchEnc/1e6 cdfParseFloatString(cdfId->sb->value)+(SCMinEnc/1e6))
            scLeft = max( SCMatchEnc/1e6 cdfParseFloatString(cdfId->sa->value)+(SCMinEnc/1e6))
        else
            scRight = 3u + SCMinEnc/1e6
            scLeft = 3u + SCMinEnc/1e6
        )
    ) ; if match

    cdfId->scTop->value = sprintf(nil "%.6g" scTop)
    cdfId->scBot->value = sprintf(nil "%.6g" scBot)
    cdfId->scRight->value = sprintf(nil "%.6g" scRight)
    cdfId->scLeft->value = sprintf(nil "%.6g" scLeft)
    SCref = 1e-6 ; taken out of models

    if( typep( w ) == 'flonum && typep( l ) == 'flonum then
        
        ; Top and Bottom
        SCATB = (1/scTop - 1/(scTop + w ) + 1/scBot - 1/(scBot + w ))/w*SCref**2 
        ; Right and Left (1st term)
        SCARL = (1/scRight - 1/(scRight + l ) + 1/scLeft - 1/(scLeft + l ))/l*SCref**2 
        if( numberp(numFinger) && numFinger > 1 then ; Right and Left (numFinger-1 terms)
            SCAd = l + cdfParseFloatString(cdfId->sd->value)
            SCANR = scRight + (numFinger - 0.45)*SCAd
            SCANL = scLeft + (numFinger - 0.45)*SCAd
            SCARL = SCARL + (log( SCANR*(scRight+0.55*SCAd+l)/(scRight+0.55*SCAd)/(SCANR+l)) +
             log( SCANL*(scLeft+0.55*SCAd+l)/(scLeft+0.55*SCAd)/(SCANL+l)))/SCAd/l*SCref**2
        ) ; if fingers > 1
     if(numberp(numFinger) then
        SCA = SCATB + SCARL/numFinger
        
        SCB = ((scTop/10 + SCref/100)*exp(-10*scTop/SCref) -  
                ((scTop + w)/10+SCref/100)*exp(-10*(scTop+w)/SCref) +
                (scBot/10 + SCref/100)*exp(-10*scBot/1e-6) - 
                ((scBot + w)/10+SCref/100)*exp(-10*(scBot+w)/SCref))/w +
                ((scRight/10 + SCref/100)*exp(-10*scRight/SCref) - 
                ((scRight + l)/10+SCref/100)*exp(-10*(scRight+l)/SCref) +
                (scLeft/10 + SCref/100)*exp(-10*scLeft/SCref) - 
                ((scLeft + l)/10+SCref/100)*exp(-10*(scLeft+l)/SCref))/l/numFinger
        SCC = ((scTop/20 + SCref/400)*exp(-20*scTop/SCref) - 
                ((scTop + w)/20+SCref/400)*exp(-20*(scTop+w)/SCref) +
                (scBot/20 + SCref/400)*exp(-20*scBot/SCref) - 
                ((scBot + w)/20+SCref/400)*exp(-20*(scBot+w)/SCref))/w +
                ((scRight/20 + SCref/400)*exp(-20*scRight/SCref) - 
                ((scRight + l)/20+SCref/400)*exp(-20*(scRight+l)/SCref) +
                (scLeft/20 + SCref/400)*exp(-20*scLeft/SCref) - 
                ((scLeft + l)/20+SCref/400)*exp(-20*(scLeft+l)/SCref))/l/numFinger
        cdfId->sca->value = sprintf(nil "%.6g" SCA)
        cdfId->scb->value = sprintf(nil "%.6g" SCB)
        cdfId->scc->value = sprintf(nil "%.6g" SCC)
    );if
    else
        ; single ended solution l or w are variable
        SC = min( scTop scBot scRight scLeft )
        if( typep( w ) == 'flonum then
            cdfId->sca->value = sprintf(nil "%.6g" (1/SC - 1/(SC + w))/w*SCref**2 )
            cdfId->scb->value = sprintf(nil "%.6g" 1/(w*SCref)*( SCref/10*SC*exp(-10*SC/SCref) + 
                                               SCref**2/100*exp(-10*SC/SCref) -
                                               SCref/10*(SC + w)*exp(-10*(SC + w)/SCref) -
                                               SCref**2/100*exp(-10*(SC + w)/SCref)
                                               ))
            cdfId->scc->value = sprintf(nil "%.6g" 1/(w*SCref)*( SCref/20*SC*exp(-20*SC/SCref) + 
                                               SCref**2/400*exp(-20*SC/SCref) -
                                               SCref/20*(SC + w)*exp(-20*(SC + w)/SCref) -
                                               SCref**2/400*exp(-20*(SC + w)/SCref)
                                               ))

        else
            wstr = "iPar(\"fingerWidth\")"
            cdfId->sca->value = sprintf(nil "%.6g/%s*(1/%.6g - 1/(%.6g + %s))"
                                    SCref**2 wstr SC SC wstr)
            cdfId->scb->value = sprintf(nil
                      "1/%s*((%.6g+%.6g)*exp(%.6g)-(%.6g*(%.6g+%s)+%.6g)*exp(%.6g*(%.6g+%s)))"
                      wstr SC/10 SCref/100 -10*SC/SCref SCref/10 SC wstr SCref/100 -10/SCref SC wstr)
            cdfId->scc->value = sprintf(nil
                      "1/%s*((%.6g+%.6g)*exp(%.6g)-(%.6g*(%.6g+%s)+%.6g)*exp(%.6g*(%.6g+%s)))"
                         wstr SC/20 SCref/400 -20*SC/SCref SCref/20 SC wstr SCref/400 -20/SCref SC wstr)
        ) ; else if w is flonum
    ) ; else if l is flonum

   if( numberp(cdfParseFloatString(cdfId->fingerWidth->value)) 
            && numberp( cdfParseFloatString(cdfId->as->value))
            && numberp( cdfParseFloatString(cdfId->ad->value))
            && numberp( cdfParseFloatString(cdfId->ps->value))
            && numberp( cdfParseFloatString(cdfId->pd->value)) then 
        PasCdfSetValue(cdfId->fingerWidthMicron cdfParseFloatString(cdfId->fingerWidth->value)*1e6)
        (when cdfId->asMicron && cdfId->adMicron && cdfId->psMicron && cdfId->pdMicron
            PasCdfSetValue(cdfId->asMicron cdfParseFloatString(cdfId->as->value)*1e12)
            PasCdfSetValue(cdfId->adMicron cdfParseFloatString(cdfId->ad->value)*1e12)
            PasCdfSetValue(cdfId->psMicron cdfParseFloatString(cdfId->ps->value)*1e6)
            PasCdfSetValue(cdfId->pdMicron cdfParseFloatString(cdfId->pd->value)*1e6)
        ) ; when parasitic micron vals
   else
        PasCdfSetValue(cdfId->fingerWidthMicron sprintf(nil "%s * %s" cdfId->fingerWidth->value "1e6") )
        (when cdfId->asMicron && cdfId->adMicron && cdfId->psMicron && cdfId->pdMicron
            PasCdfSetValue(cdfId->asMicron sprintf(nil "%s * %s" "1e12" cdfId->as->value ))
            PasCdfSetValue(cdfId->adMicron sprintf(nil "%s * %s" "1e12" cdfId->ad->value ))
            PasCdfSetValue(cdfId->psMicron sprintf(nil "%s * %s" "1e6" cdfId->ps->value ))
            PasCdfSetValue(cdfId->pdMicron sprintf(nil "%s * %s" "1e6" cdfId->pd->value ))
        )
   )  
   if( numberp(cdfParseFloatString( cdfId->totalWidth->value)) then 
        PasCdfSetValue(cdfId->totalWidthMicron cdfParseFloatString(cdfId->totalWidth->value)*1e6)
   else
        PasCdfSetValue(cdfId->totalWidthMicron sprintf(nil "%s * %s" cdfId->totalWidth->value "1e6"))
   )
   if( numberp(cdfParseFloatString( cdfId->fingerLength->value)) then 
        PasCdfSetValue(cdfId->fingerLengthMicron cdfParseFloatString(cdfId->fingerLength->value)*1e6)
   else
        PasCdfSetValue(cdfId->fingerLengthMicron sprintf(nil "%s * %s" cdfId->fingerLength->value "1e6"))
   )
   if(cdfId->dimEntryMode->value != "A/P" then
      when(cdfId->dimEntryMode2 && cdfId->dimEntryMode2->value != cdfId->dimEntryMode->value
      dboxText = "Warning!!\nThis instance was previously fine tuned for LVS purposes!\nYou are changing the dimensional entry mode from A/P to W/L\nNote that continuing with this action will undo this fine tuning, and LVS mismatches may result.\nDo you want to continue?"
      toggleDimEntryMode = hiDisplayAppDBox(?name 'toggleDimEntryModeAppDBox
                                ?dboxBanner "Removal of LVS Fine Tuning Edits"
                                ?dboxText dboxText
                                ?dialogStyle 'modal
                                ?buttonLayout 'YesNo
                                )
      if(toggleDimEntryMode then
         cdfId->dimEntryMode2->value = cdfId->dimEntryMode->value
         else
         cdfId->dimEntryMode->value = cdfId->dimEntryMode2->value
         );if
      );when
when(cdfId->dimEntryMode->value != "A/P"
   when(cdfId->areamicron
        if( dpt->micron then
          if(cdfId->contactHoles->value then 
;cap has holes
; need to restrict the w and l vals to numbers, for now
    unless(atof(cdfId->fingerLength->value)
      PasWarn("finger length needs to be a number when contact holes is on")
      cdfId->fingerLength->value = cdfId->fingerLength->defValue
      cdfId->fingerLengthMicron->value =  cdfId->fingerLengthMicron->defValue
      );unless
    unless(atof(cdfId->fingerWidth->value)
      PasWarn("finger width needs to be a number when contact holes is on")
      cdfId->fingerWidth->value = cdfId->fingerWidth->defValue
      cdfId->fingerWidthMicron->value =  cdfId->fingerWidthMicron->defValue
      cdfId->totalWidth->value = cdfId->totalWidth->defValue
      );unless

            primDpt = PasGetPdkParams("${template_libName}" dpt->mosCell)
            polyCutContRows = primDpt->polyCutContRows
            polyCutContCols = primDpt->polyCutContCols
            polyCutContSp = primDpt->msCont(polyCutContCols polyCutContRows)
            mePolyCutCont = primDpt->mePolyCutCont
            meePolyCutCont = primDpt->meePolyCutCont
            polyCutX = mePolyCutCont*2 + (primDpt->mwCont * polyCutContCols) + (polyCutContSp * (polyCutContCols - 1))
            polyCutY = meePolyCutCont*2 + (primDpt->mwCont * polyCutContRows) + (polyCutContSp * (polyCutContRows - 1))
            polyCutArea = polyCutX*polyCutY
            polyCutPerim = 2*polyCutX + 2*polyCutY

            diffCutContRows = primDpt->diffCutContRows
            diffCutContCols = primDpt->diffCutContCols
            diffCutContSp = primDpt->msCont(diffCutContCols diffCutContRows)
            meDiffCutCont = primDpt->meDiffCutCont
            meeDiffCutCont = primDpt->meeDiffCutCont
            diffCutX = meDiffCutCont*2 + (primDpt->mwCont * diffCutContCols) + (diffCutContSp * (diffCutContCols - 1))
            diffCutY = meeDiffCutCont*2 + (primDpt->mwCont * diffCutContRows) + (diffCutContSp * (diffCutContRows - 1))
            diffCutArea = diffCutX*diffCutY
            diffCutPerim = 2*diffCutX + 2*diffCutY

            if( numberp(cdfParseFloatString( cdfId->fingerLengthMicron->value)) &&
                    numberp(cdfParseFloatString(cdfId->fingerWidthMicron->value)) then 
                area =  cdfParseFloatString(cdfId->fingerLengthMicron->value) *
                        cdfParseFloatString(cdfId->fingerWidthMicron->value) - 
                        (length(car(linereadstring(cdfId->polyHoleList->value))) * polyCutArea + length(car(linereadstring(cdfId->diffHoleList->value))) * diffCutArea)
                if(cdfId->ringDiff->value then 
                   perim = cdfParseFloatString(cdfId->fingerLengthMicron->value) * or(perimLengthCoef 2) + cdfParseFloatString(cdfId->fingerWidthMicron->value) * or(perimWidthCoef 2) + length(car(linereadstring(cdfId->polyHoleList->value))) * polyCutPerim
                   else
                   if(cdfId->bridgeDiff->value then
                      perim = cdfParseFloatString(cdfId->fingerLengthMicron->value) * or(perimLengthCoef 1) + cdfParseFloatString(cdfId->fingerWidthMicron->value) * or(perimWidthCoef 2) + length(car(linereadstring(cdfId->polyHoleList->value))) * polyCutPerim
                      else
                      perim = cdfParseFloatString(cdfId->fingerWidthMicron->value) * or(perimWidthCoef 2)  + length(car(linereadstring(cdfId->polyHoleList->value))) * polyCutPerim
                      );if
                   );if
            else
                area =  sprintf( nil "%s * %s" cdfId->fingerLengthMicron->value
                                                    cdfId->fingerWidthMicron->value)
                perim = 0
            ) ; else if numberp fingerLengthMicron and fingerWidthMicron
            else
;cap does not have holes
            if( numberp(cdfParseFloatString( cdfId->fingerLengthMicron->value)) &&
                    numberp(cdfParseFloatString(cdfId->fingerWidthMicron->value)) then 
                area =  cdfParseFloatString(cdfId->fingerLengthMicron->value) *
                        cdfParseFloatString(cdfId->fingerWidthMicron->value) 
                                                                
                                                                                                     
                if(cdfId->bridgeDiff->value then
                  perim = cdfParseFloatString(cdfId->fingerLengthMicron->value) * or(perimLengthCoef 1) + cdfParseFloatString(cdfId->fingerWidthMicron->value) * or(perimWidthCoef 2)
                                           else
                  perim = cdfParseFloatString(cdfId->fingerWidthMicron->value) * or(perimWidthCoef 2) + cdfParseFloatString(cdfId->fingerLengthMicron->value) * or(perimLengthCoef 0)
                                           );if
            else
                area =  sprintf( nil "%s * %s" cdfId->fingerLengthMicron->value
                                                    cdfId->fingerWidthMicron->value)
                                                                                                                                         
                                                                                                        
                if(cdfId->bridgeDiff->value then
                  perim = sprintf( nil "%s * %f + %s * %f" cdfId->fingerLengthMicron->value or(perimLengthCoef 1.0) cdfId->fingerWidthMicron->value or(perimWidthCoef 2.0))
                  else
                  perim = sprintf( nil "%s * %f + %s * %f" cdfId->fingerLengthMicron->value or(perimLengthCoef 0.0) cdfId->fingerWidthMicron->value or(perimWidthCoef 2.0))
                  );if

            ) ; else if numberp fingerLengthMicron and fingerWidthMicron
          );if
        else
; not micron
            if( numberp(cdfParseFloatString(cdfId->fingerLength->value)) &&  numberp(cdfParseFloatString(cdfId->fingerWidth->value)) then 
                area =  cdfParseFloatString(cdfId->fingerLength->value) *
                        cdfParseFloatString(cdfId->fingerWidth->value)
                if(cdfId->bridgeDiff->value then
                  perim = cdfParseFloatString(cdfId->fingerLength->value) * or(perimLengthCoef 1) + cdfParseFloatString(cdfId->fingerWidth->value) * or(perimWidthCoef 2)
                  else
                  perim = cdfParseFloatString(cdfId->fingerLength->value) * or(perimLengthCoef 0.0) + cdfParseFloatString(cdfId->fingerWidth->value) * or(perimWidthCoef 2)
                  );if
            else
                area =  sprintf( nil "%s * %s" cdfId->fingerLength->value cdfId->fingerWidth->value)
                if(cdfId->bridgeDiff->value then
                  perim = sprintf( nil "%s * %f + %s * %f" cdfId->fingerLength->value or(perimLengthCoef 1.0) cdfId->fingerWidth->value or(perimWidthCoef 2.0))
                  else
                  perim = sprintf( nil "%s * %f + %s * %f" cdfId->fingerLength->value or(perimLengthCoef 0.0) cdfId->fingerWidth->value or(perimWidthCoef 2.0))
                  );if

            ) ; else if numberp fingerLength and fingerWidth
        ) ; else if micron
       PasCdfSetValue(cdfId->areamicron area)
       when(cdfId->perimmicron
         PasCdfSetValue(cdfId->perimmicron perim)
         );when
      when(cdfId->perim
         if(numberp(perim) then
            PasCdfSetValue(cdfId->perim perim*1e-6)
            else
            PasCdfSetValue(cdfId->perim strcat(perim "*1e-6"))
            );if
         );when
      when(cdfId->area
         if(numberp(area) then
            PasCdfSetValue(cdfId->area area*1e-12)
            else
            PasCdfSetValue(cdfId->area strcat(area "*1e-12"))
            );if
                                
                
         );when
   );when

   when(cdfId->c
      if(numberp(area) && numberp(perim) && numberp(numFinger) then
           
	       capacitance = (area * 1e-12 * ca + perim * 1e-6 * cf)*numFinger
	    
               when(cdfId~>id~>name=="uhvnecap4_hvpw2" || cdfId~>id~>master~>cellName=="uhvnecap4_hvpw2" || cdfId~>id~>name=="uhvnecapsb3_psub" || cdfId~>id~>master~>cellName=="uhvnecapsb3_psub" || cdfId~>id~>name=="uhvnecap3_psub" || cdfId~>id~>master~>cellName=="uhvnecap3_psub"
                   capacitance = (area * ca + perim * cf)*numFinger
               );when
           else
               capacitance = 0.0
           );if
        PasCdfSetValue(cdfId->c capacitance)
            if(numberp(car( errsetstring( cdfId->simM->value))) then
                      cdfId->mfactorC->value = aelSuffixNotation(car(errsetstring(cdfId->c->value)) * car(errsetstring(cdfId->simM->value)))

                when(cdfId->metalCaps
                      cdfId->mfactorMC->value = aelSuffixNotation(car(errsetstring(cdfId->metalCaps->value)) * car(errsetstring(cdfId->simM->value)))
                )
                                else
                      cdfId->mfactorC->value = "0"
                when(cdfId->metalCaps
                      cdfId->mfactorMC->value = "0"
                )
                                );if

    ) ; when device is a moscap

when(dpt->userEntry == "Area&Perim"
;normalize area and perim
   ;if(numberp(cdfParseFloatString(cdfId->area->value)) && cdfParseFloatString(cdfId->area->value) > maxL*maxW then
   ;   cdfId->area->value = aelSuffixNotation(cdfParseFloatString(cdfId->area->value)*1e-12)
  ; );if
   if(numberp(cdfParseFloatString(cdfId->perim->value)) then
      cdfId->perim->value = aelSuffixNotation(PasCdfValidateFloat(cdfId->perim ?min 2*minW ?max 2*maxW ?norm norm ?numOnly nil))
                

      );if
   area = cdfParseFloatString(cdfId->area->value)
   perim = cdfParseFloatString(cdfId->perim->value)
        

;set c and micron params
   if(numberp(area) && numberp(perim) then
      cdfId->c->value = aelSuffixNotation(perim*cdfParseFloatString(cdfId->cf->value) + area*cdfParseFloatString(cdfId->ca->value))
      cdfId->areamicron->value = pcExprToString(area*1e12)
      cdfId->perimmicron->value = pcExprToString(perim*1e6)
            if(numberp(car( errsetstring( cdfId->simM->value))) then
              cdfId->mfactorC->value = aelSuffixNotation(car(errsetstring(cdfId->c->value)) * car(errsetstring(cdfId->simM->value)))
              else
              cdfId->mfactorC->value = "0"
              );if
      else
      cdfId->c->value = strcat("iPar(\"perim\") * iPar(\"cf\") + iPar(\"area\") * iPar(\"ca\")")
      cdfId->areamicron->value = strcat("iPar(\"area\") * 1e12")
      cdfId->perimmicron->value =  strcat("iPar(\"perim\") * 1e6")
            if(numberp(car( errsetstring( cdfId->simM->value))) then
              cdfId->mfactorC->value = srtcat("iPar(\"c\") * iPar(\"simM\")")
              else
              cdfId->mfactorC->value = "0"
              );if
      );if
   );when
);when

                         
   else
   when(cdfId->dimEntryMode2 && cdfId->dimEntryMode2->value != cdfId->dimEntryMode->value
      dboxText = "Warning!!\nYou are changing the dimensional entry mode from W/L to A/P\nThis option is reserved for LVS fine tuning only!\nDo you want to continue?"
      toggleDimEntryMode = hiDisplayAppDBox(?name 'toggleDimEntryModeAppDBox
                                ?dboxBanner "Functionality Reserved for LVS Edits"
                                ?dboxText dboxText
                                ?dialogStyle 'modal
                                ?buttonLayout 'YesNo
                                )
      if(toggleDimEntryMode then
         cdfId->dimEntryMode2->value = cdfId->dimEntryMode->value
         else
         cdfId->dimEntryMode->value = cdfId->dimEntryMode2->value
         );if
      );when
      
   );if dimEntryMode

/* this has been requested to be removed
   when(cdfId->drawDnw2
      when(cdfId->drawDnw2->value != cdfId->drawDnw->value
         cdfId->drawDnw2->value = cdfId->drawDnw->value
         if(cdfId->drawDnw->value then
            cdfId->wellList->value = "(nil)"
            else
            when(dpt->deWellDiff && dpt->meWellDiff
               stretch = pcExprToString(max(0 dpt->deWellDiff-dpt->meWellDiff))
               cdfId->wellList->value = strcat("(nil \\0 ((" stretch " " stretch ") (" stretch " " stretch ")))")
               );when
            );when
         );when
      );when
*/

    t
    
  ) ; ** let **
) ; ** procedure ${template_libName}_mosCB **


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( ${template_libName}_mosDisplaySet( param "s")

prog( (excludeList displaySet display dpt)

    display = t
    dpt = PasCdfGetDpt(cdfgData->displaySet)
    ; list parameters to be switched off for the front and back ends.
    excludeList = ncons(nil)
    if(dpt->feDisplayExclude then
      excludeList->Front\-End = dpt->feDisplayExclude
      else
      excludeList->Front\-End = 
                 '( connectGates connectSD
                    leftCont rightCont leftAbutExt rightAbutExt
                    tap leftTap rightTap bottomTap topTap
                    tapExtension tapCntRows
                  )
      );if
    if(dpt->beDisplayExclude then
      excludeList->Back\-End = dpt->beDisplayExclude
      else
      excludeList->Back\-End = 
                '( ad as pd ps nrd nrs ld ls off Vds Vgs Vbs trise
                   region degradation geo rdc rsc sa sb sd dtemp
                   editSourceAreaPerim editDrainAreaPerim
                 )
      );if
    when( (displaySet = cdfgData->displaySet->value)
       when( (excludeList = get(excludeList displaySet))
          display = !memq(param excludeList)
       )
    )
    
    return( display)
)
) ; procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(${template_libName}_mosCalcAreaPerim( fingerWidth fingerLength numFinger sourceFirst metalWidthSD dpt @optional cdfId )
prog((scale grid wellEff old_vals
      meWellTap meTapCont mwCont msTapDiff meDiffCont msContPoly msDiff mwTap
      wellLength wellWidth wellArea wellPerim dnwArea dnwPerim meWellDiff
      returnList as ad ps pd nrs nrd sa sb sd asd psd perim_ratio dnwWellTap
   )

unless(cdfId cdfId = cdfgData)

; pull values from dpt
scale = or(dpt->scale 1e-6)
grid = dpt->grid
wellEff = or(dpt->wellEff 0.85)

meWellTap = dpt->meWellTap*scale
meWellDiff = dpt->meWellDiff*scale
meTapCont = dpt->meTapCont*scale
mwCont = dpt->mwCont*scale
msTapDiff = dpt->msTapDiff*scale
meDiffCont = dpt->meDiffCont*scale
msContPoly = dpt->msContPoly*scale
msContPolyS = or(dpt->msContPolyS dpt->msContPoly)*scale
msContPolyD = or(dpt->msContPolyD dpt->msContPoly)*scale
msDiff = dpt->msDiff*scale
mwTap = dpt->mwTap*scale




perim_ratio=1

foreach(s list('fingerWidth 'fingerLength 'numFinger)
   value = symeval(s)
   caseq(type(value)
      (string
         set(s cdfParseFloatString(value))
          );string
      (( flonum fixnum ) t)
      (t error("%s: invalid value for '%s' - %L" funName s value))
   );caseq
); foreach


if(and(dpt->ca dpt->cf) then
; this is a cap device
; it is assumed that there is one cap per well

if(dpt->wellCap then
; this is a well cap device
        if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
                wellLength = 
                numFinger * (fingerLength + mwCont + 2*msContPoly) + 
                2*meDiffCont + mwCont + 2*meWellDiff
                                        
        else
                wellLength = sprintf(nil "iPar(\"numFinger\") + (iPar(\"fingerLength\") + %s) + %s"
                aelSuffixNotation(mwCont + 2*msContPoly 6)
                  aelSuffixNotation(2*meDiffCont + mwCont + 2*meWellDiff 6))
                                               
                                                
   );if

        if(numberp(fingerLength) && numberp(fingerWidth) then
                wellWidth = 
                fingerWidth + 2 * meWellDiff
        else
                wellWidth = sprintf(nil "iPar(\"fingerWidth\") + %s"
                aelSuffixNotation(2 * meWellDiff 6))
        );if

;;gennadyg
if(cdfId->userWell->value != "Edit" then

        if(numberp(wellWidth) && numberp(wellLength) then
           wellArea = wellWidth * wellLength
           wellPerim = 2 * (wellWidth + wellArea)
                         
   else
           wellArea = strcat("(" wellWidth ")*(" wellLength ")")
           wellPerim = strcat("2*(" wellLength "+" wellWidth ")")
   );if

;;gennadyg
else
    ;; keep up current values
    wellArea  = cdfId->wellArea->value
    wellPerim = cdfId->wellPerim->value
)

else
        ; this is a mos cap device, adding additional well area for a tap
        if(numberp(fingerWidth) && numberp(fingerLength) then
                wellLength = 
                numFinger * (fingerLength + mwCont + 2*msContPoly) + 
                2*meDiffCont + mwCont + 2*(msTapDiff + max(mwTap 2*meTapCont + mwCont) + meWellTap)
        else
                wellLength = sprintf(nil "iPar(\"numFinger\") * (iPar(\"fingerLength\") + %s) + %s"
                  aelSuffixNotation(mwCont + 2*msContPoly 6)
                  aelSuffixNotation(2*meDiffCont + mwCont + 2*(msTapDiff + max(mwTap 2*meTapCont + mwCont) + meWellTap) 6))
        );if

        if(numberp(fingerWidth) && numberp(fingerLength) then
                wellWidth = 
                fingerWidth + 2 * (msTapDiff + max(mwTap 2*meTapCont + mwCont) + meWellTap)
        else
                wellWidth = sprintf(nil "iPar(\"fingerWidth\") + %s"
          aelSuffixNotation(2 * (msTapDiff + max(mwTap 2*meTapCont + mwCont) + meWellTap) 6))
   );if

;;gennadyg
if(cdfId->userWell->value != "Edit" then

        if(numberp(wellWidth) && numberp(wellLength) then
           wellArea = wellWidth * wellLength
           wellPerim = 2 * (wellWidth + wellArea)
   else
           wellArea = strcat("(" wellWidth ")*(" wellLength ")")
           wellPerim = strcat("2*(" wellLength "+" wellWidth ")")
   );if

;;gennadyg
else
    ;; keep up current values
    wellArea  = cdfId->wellArea->value
    wellPerim = cdfId->wellPerim->value
)

);if dpt->wellCap then

else



; this is a fet device
; calculate the well dimensions
; length is measured the same direction as the transistor gate length
; it is assumed that 2 transistors are sharing one well
; it is assumed that wells are tapped with a diffusion ring



if(cdfId->custom_well_wl~>value then

       case(cdfId->custom_well_wl~>value
                  
                                  ("well_wl_hvmos5"

                                   dnwWellTap = dpt->dnwWellTap*scale
                                   
                               if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
                                                                                              
                                        wellLength = meWellTap + max(mwTap 2*meTapCont + mwCont) + msTapDiff 
                                                       + 2 *(meDiffCont + mwCont + msContPoly)  + numFinger * fingerLength 
                                                               + (numFinger - 1) * (mwCont + 2 * msContPoly)  + msDiff/2
                                                                                
                                        wellWidth = 1/wellEff * (fingerWidth 
                                                              + 2 * msTapDiff 
                                                              + 2 * max(mwTap 2*meTapCont + mwCont) 
                                                              + 2 * meWellTap)
                                                                          
                                  else
                                   
                                                                                          
                   wellLength = sprintf(nil "%s + %s + iPar(\"numFinger\") * iPar(\"fingerLength\") + ( iPar(\"numFinger\") - 1) * %s"
                                                                                                                                                 aelSuffixNotation(meWellTap + max(mwTap 2*meTapCont + mwCont) 
                                                                                                                                                                                  + msTapDiff 6)
                                                                                                                                                 aelSuffixNotation(2 *(meDiffCont + mwCont + msContPoly) 6)
                                                                                                                                                 aelSuffixNotation((mwCont + 2 * msContPoly) + msDiff/2 6))
                                                                                                                                                 
                                                                                
                                         wellWidth = sprintf(nil "%s * (iPar(\"fingerWidth\") + %s + %s)"
                                                                                                                                        aelSuffixNotation(1/wellEff 6)
                                                                                                                                        aelSuffixNotation(2 * msTapDiff + 2 * max(mwTap 2*meTapCont + mwCont) 6)
                                                                                                                                        aelSuffixNotation(2 * meWellTap 6))
                
                                                                                          );numberp                                         
                                 
                                                                                        
                                                                                         );well_wl_hvmos5
                                ("well_wl_lvmos4"
                                    
            if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then                                  
                                        wellLength = meWellTap + 2 * meDiffCont + mwCont + msTapDiff
                                                                                                                                                                         + 2 *(meDiffCont + mwCont + msContPoly)
                                                               + numFinger * fingerLength 
                                                               + (numFinger - 1) * (mwCont 
                                                               + 2 * msContPoly) + msDiff/2
                                                                                
                                        wellWidth = 1/wellEff * (fingerWidth 
                                                              + 2 * msTapDiff 
                                                                                                                                                                  + 2 * (mwCont + (2 * meDiffCont)) 
                                                              + 2 * meWellTap)
                                                                                                                                                                  
             else
                wellLength = sprintf(nil "%s + %s + iPar(\"numFinger\") * iPar(\"fingerLength\")
                                                                                                                                                                 + (iPar(\"numFinger\") - 1) * %s"
                                                                                                                                                                 aelSuffixNotation(meWellTap + 2 * meDiffCont + mwCont + msTapDiff 6)
                                                                                                                                                                 aelSuffixNotation(2*(meDiffCont + mwCont + msContPoly) 6)
                                                                                                                                                            aelSuffixNotation((mwCont + 2 * msContPoly) + msDiff/2 6))
                                                                                                                                                                 
                   wellWidth = sprintf(nil "%s * (iPar(\"fingerWidth\") + %s)" 
                                     aelSuffixNotation(1/wellEff 6)
                                     aelSuffixNotation(2 * (mwCont + (2 * meDiffCont)) + 2 * meWellTap 6))                                                         
       );if
        
                                                                                        ); well_wl_lvmos4
                                                                
                                ("well_wl_lhvmos4"
                                                                        
                                                                                  
                                   if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then                                  
                                        wellLength = meWellTap + max(mwTap 2*meTapCont + mwCont) + msTapDiff 
                                                               + 2 *(meDiffCont + mwCont + msContPoly) 
                                                               + numFinger * fingerLength 
                                                               + (numFinger - 1) * (mwCont 
                                                               + 2 * msContPoly) + msDiff/2
                                                                                
                                        wellWidth = 1/wellEff * (fingerWidth 
                                                              + 2 * msTapDiff 
                                                              + 2 * max(mwTap 2*meTapCont + mwCont) 
                                                              + 2 * meWellTap)
                                   else
                                        
                                        wellLength = sprintf(nil "%s + %s + iPar(\"numFinger\") * iPar(\"fingerLength\")
                                                                     + (iPar(\"numFinger\") - 1) * %s"
                                                                     aelSuffixNotation(meWellTap + max(mwTap 2*meTapCont + mwCont) + msTapDiff 6)
                                                                     aelSuffixNotation(2 *(meDiffCont + mwCont + msContPoly) 6)
                                                                     aelSuffixNotation((mwCont + 2 * msContPoly) + msDiff/2 6))
                                                                                        
                                        wellWidth = sprintf(nil "%s * (iPar(\"fingerWidth\") + %s)" 
                                                                                                                                        aelSuffixNotation(1/wellEff 6)
                                                                                                                                        aelSuffixNotation(2 * msTapDiff + 2 * max(mwTap 2*meTapCont + mwCont) 
                                                                     + 2 * meWellTap 6)
                                                                                                                                   )
                                        
                                  );if numberp
                                
                                          );well_wl_lhvmos4
                  
                  
                              ("well_wl_hvmos5sd"
                                    perim_ratio=15 ;for use in perimeter calculation (found in MT formula)
                                    if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then

                                                wellLength = fingerLength + dpt->ms_cont_gate_s*scale+(mwCont/2)
                                                        + dpt->ms_cont_gate_d*scale+(mwCont/2)
                                                        + 2*((mwCont/2)+ dpt->avg_edg_c1_nhv_edg*scale 
                                                                                                                                                  + dpt->avg_nhv_phv_sp*scale
                                                        + dpt->avg_phv_w*scale+dpt->avg_hvpw_ov_phv*scale)/30
                                
                                                wellWidth = fingerWidth + 2 * (dpt->ms_gate_poly_ov_sd*scale 
                                                                                                                                                    + dpt->mw_gate_poly*scale 
                                                        + dpt->avg_nhv_phv_top_bot_sp*scale 
                                                                                                                                                  + dpt->avg_phv_w*scale + dpt->avg_hvpw_ov_phv*scale)
                                
                                                                                  else
                                                                                                  
                             wellLength = sprintf(nil "iPar(\"fingerLength\") + %s"
                                                                                                                                        aelSuffixNotation(dpt->ms_cont_gate_s*scale+(mwCont/2)
                                                        + dpt->ms_cont_gate_d*scale+(mwCont/2)
                                                        + 2*((mwCont/2)+ dpt->avg_edg_c1_nhv_edg*scale 
                                                                                                                                                  + dpt->avg_nhv_phv_sp*scale
                                                        + dpt->avg_phv_w*scale+dpt->avg_hvpw_ov_phv*scale)/30 6))
                                                                                                
                                                                                                wellWidth = sprintf(nil "iPar(\"fingerWidth\") + %s"
                                                                                                                                        aelSuffixNotation(2 * (dpt->ms_gate_poly_ov_sd*scale 
                                                                                                                                                    + dpt->mw_gate_poly*scale 
                                                        + dpt->avg_nhv_phv_top_bot_sp*scale 
                                                                                                                                                  + dpt->avg_phv_w*scale + dpt->avg_hvpw_ov_phv*scale) 6))                                                          
                                
                                                                                  
                                                                                  );if numberp
                                                                                  
                                                    );well_wl_hvmos5sd
                                                                        
                        
                                                 ("well_wl_lhvmos4sd"
                                
                                perim_ratio=15
                                
             if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
                                                
                         wellLength = fingerLength + dpt->ms_cont_gate_s*scale+(mwCont/2) 
                                                              + dpt->ms_cont_gate_d*scale+(mwCont/2)
                                                              + 2*((mwCont/2)+ dpt->avg_edg_c1_phv_edg*scale
                                                              + dpt->avg_phv_nhv_leftright_sp*scale
                                                                                                                                                                  + dpt->avg_nhv_w*scale+dpt->avg_hvpw_ov_phv*scale)/30
                                                                
                                                wellWidth = fingerWidth + 2 * (dpt->ms_gate_poly_ov_sd*scale 
                                                                                                                        + dpt->mw_gate_poly*scale 
                                                                             + dpt->avg_phv_nhv_top_bot_sp*scale 
                                                                                                                                                                + dpt->avg_nhv_w*scale + dpt->avg_hvpw_ov_phv*scale)
                        
                          
              else
                                                                                                
                   wellLength = sprintf(nil "iPar(\"fingerLength\") + %s"
                                                                                                                                                                aelSuffixNotation(dpt->ms_cont_gate_s*scale+(mwCont/2) 
                                                              + dpt->ms_cont_gate_d*scale+(mwCont/2)
                                                              + 2*((mwCont/2)+ dpt->avg_edg_c1_phv_edg*scale
                                                              + dpt->avg_phv_nhv_leftright_sp*scale
                                                                                                                                                                  + dpt->avg_nhv_w*scale+dpt->avg_hvpw_ov_phv*scale)/30 6))
                                                                                                
                   wellWidth = sprintf(nil "iPar(\"fingerWidth\") + %s"
                                                                                                                                                                aelSuffixNotation(2 * (dpt->ms_gate_poly_ov_sd*scale 
                                                                                                                        + dpt->mw_gate_poly*scale 
                                                                             + dpt->avg_phv_nhv_top_bot_sp*scale 
                                                                                                                                                                + dpt->avg_nhv_w*scale + dpt->avg_hvpw_ov_phv*scale) 6))                                                                  
                                                                                        );if numberp
                                                                  
                                                                  
                                                                  );well_wl_lhvmos4sd
                                                                  
                 
                 ("well_wl_hvmos5afsd"
                                
                                perim_ratio=6 ;for use in perimeter calculation (found in MT formula)
                                
                                
       if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
                                                                                  
                                                                   wellLength = dpt->ms_c1_to_gate_edg*scale
                                                        + fingerLength
                                                        + dpt->ms_c1_to_sal_hole_edg_sp*scale
                                                        + mwCont + ((dpt->ms_c1_to_c1*scale)/2)
                                                        + dpt->ms_p2_to_p2*scale/2
                                                        + 2*(dpt->avg_edg_hole_to_nhv_edg*scale + dpt->nhv_phv_sp*scale
                                                        + dpt->phv_well_pu_width*scale+dpt->avg_hvpw_ov_phv*scale)/12
                                                                                        
                                                        wellWidth = fingerWidth + 2 * (dpt->exact_donut_ring_ov_sd*scale 
                                                        + dpt->ts_nhv_phv_topbot*scale
                                                        + dpt->typ_phv_well_pu_width*scale        
                                                        + dpt->avg_hvpw_ov_phv*scale)
         else
                                                                                        
               wellLength = sprintf(nil "%s + iPar(\"fingerLength\") + %s"
                                                   aelSuffixNotation(dpt->ms_c1_to_gate_edg*scale 6)
                                                                                                                                        aelSuffixNotation(dpt->ms_c1_to_sal_hole_edg_sp*scale
                                                        + mwCont + ((dpt->ms_c1_to_c1*scale)/2)
                                                        + dpt->ms_p2_to_p2*scale/2
                                                        + 2*(dpt->avg_edg_hole_to_nhv_edg*scale + dpt->nhv_phv_sp*scale
                                                        + dpt->phv_well_pu_width*scale+dpt->avg_hvpw_ov_phv*scale)/12 6))
                                                                                                                                                  
                                                                                                        
                                                                                                        wellWidth = sprintf(nil "iPar(\"fingerWidth\") + %s"
                                                                                                                                                  aelSuffixNotation(2 * (dpt->exact_donut_ring_ov_sd*scale 
                                                        + dpt->ts_nhv_phv_topbot*scale
                                                        + dpt->typ_phv_well_pu_width*scale        
                                                        + dpt->avg_hvpw_ov_phv*scale) 6))
                                                                                                                                                                                        
                                                                                        
                                                                                        );if numberp
                                                                        
                 );well_wl_hvmos5afsd
                 
                         
                 ("well_wl_hvmos5f"
                                
                                perim_ratio=5 ;for use in perimeter calculation (found in MT formula)
                                
                                                                                  
                                                                        if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
                                                                                                        
                                wellLength = fingerLength+2*(dpt->ms_c1_to_gate_salicide_hole*scale
                                                                + dpt->ms_c1_to_sal_hole_edg_sp*scale
                                                                + mwCont + (dpt->ms_c1_to_c1*scale/2))
                                                                + 2*(mwCont/2
                                                                + dpt->edg_c1_nhv_edg*scale
                                                                + dpt->nhv_phv_sp*scale
                                                                + dpt->phv_well_pu_width*scale
                                                                + dpt->avg_hvpw_ov_phv*scale)/10
                                
                                wellWidth = fingerWidth + 2 * (dpt->ts_nhv_phv_topbot*scale
                                                        + dpt->typ_phv_well_pu_width*scale        
                                                        + dpt->avg_hvpw_ov_phv*scale)
                           else
                                                                        
                                                                             wellLength = sprintf(nil "iPar(\"fingerLength\") + %s" 
                                                                                                                                          aelSuffixNotation(2*(dpt->ms_c1_to_gate_salicide_hole*scale
                                                                + dpt->ms_c1_to_sal_hole_edg_sp*scale
                                                                + mwCont + (dpt->ms_c1_to_c1*scale/2))
                                                                + 2*(mwCont/2
                                                                + dpt->edg_c1_nhv_edg*scale
                                                                + dpt->nhv_phv_sp*scale
                                                                + dpt->phv_well_pu_width*scale
                                                                + dpt->avg_hvpw_ov_phv*scale)/10 6))
                                   
                                                                                wellWidth = sprintf(nil "iPar(\"fingerWidth\") + %s"
                                                                                                                                        aelSuffixNotation(2 * (dpt->ts_nhv_phv_topbot*scale
                                                        + dpt->typ_phv_well_pu_width*scale        
                                                        + dpt->avg_hvpw_ov_phv*scale) 6))
                                                                        
                                                                        );if numberp                                             
                 );well_wl_hvmos5f
                 
                 
           ("well_wl_hvmos5fdd"
                             
                              if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
                                                                                  
                                                                                  
                                                                                  wellLength = fingerLength + 4*(dpt->ms_c1_to_gate_edg*scale
                                                          + dpt->ms_c1_to_sal_hole_edg_sp*scale
                                                          + (mwCont/2))
                                                          + 2*(dpt->nhv_phv_sp*scale
                                                          + dpt->phv_well_pu_width*scale
                                                          + dpt->avg_hvpw_ov_phv*scale)/1
                                
                                wellWidth = fingerWidth + 2 * (dpt->exact_donut_ring_ov_sd*scale
                                                        + dpt->ts_nhv_phv_topbot*scale 
                                                        + dpt->typ_phv_well_pu_width*scale        
                                                        + dpt->avg_hvpw_ov_phv*scale)
                                                                                else
                                                                                
                                                                                  wellLength = sprintf(nil "iPar(\"fingerLength\") + %s"
                                                                                                                                          aelSuffixNotation(4*(dpt->ms_c1_to_gate_edg*scale
                                                          + dpt->ms_c1_to_sal_hole_edg_sp*scale
                                                          + (mwCont/2))
                                                          + 2*(dpt->nhv_phv_sp*scale
                                                          + dpt->phv_well_pu_width*scale
                                                          + dpt->avg_hvpw_ov_phv*scale)/1 6))
                                                                                                                                                         
                                wellWidth = sprintf(nil "iPar(\"fingerWidth\") + %s"
                                                                                                                                          aelSuffixNotation(2 * (dpt->exact_donut_ring_ov_sd*scale
                                                        + dpt->ts_nhv_phv_topbot*scale 
                                                        + dpt->typ_phv_well_pu_width*scale        
                                                        + dpt->avg_hvpw_ov_phv*scale) 6))
                                                                                
                                                                                );if numberp
                                                                        
                 );well_wl_hvmos5fdd
                        
        
        );end case                          
                
                               
else

if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
wellLength = 
; well edge to transistor s/d edge
  meWellTap + max(mwTap 2*meTapCont + mwCont) + msTapDiff +
; transistor s/d edge to opposite transistor s/d edge
  2 *(meDiffCont + mwCont + msContPoly) + numFinger * fingerLength + 
  (numFinger - 1) * (mwCont + 2 * msContPoly) + 
; half transistor s/d edge to next transistor s/d edge
  msDiff/2
  

else

wellLength = sprintf(nil "%s + iPar(\"numFinger\") * iPar(\"fingerLength\") + (iPar(\"numFinger\") - 1) * %s + %s"
  aelSuffixNotation(meWellTap + max(mwTap 2*meTapCont + mwCont) + msTapDiff + 2 *(meDiffCont + mwCont + msContPoly) 6)
  aelSuffixNotation(mwCont + 2 * msContPoly 6)
  aelSuffixNotation(msDiff/2 6))
  

);if




if(numberp(fingerWidth) && numberp(fingerLength) && numberp(numFinger) then
        wellWidth = 
        ; well efficiency factor - (well used)/(well available)
          1/wellEff * (
        ; transistor width plus top and bottom well edge to transistor s/d edge
        fingerWidth + 2 * msTapDiff + 2 * max(mwTap 2*meTapCont + mwCont) + 2 * meWellTap
   )
  
else 

wellWidth = sprintf(nil "%s * (iPar(\"fingerWidth\") + %s)"
  aelSuffixNotation(1/wellEff 6)
  aelSuffixNotation(2 * msTapDiff + 2 * max(mwTap 2*meTapCont + mwCont) + 2 * meWellTap 6))
  
);if

);ifcdfId->custom_well_wl~>value 

;;gennadyg
if(cdfId->userWell->value != "Edit" then

if(numberp(wellWidth) && numberp(wellLength) then
   wellArea = wellWidth * wellLength
   wellPerim = 2 * wellLength + wellWidth/perim_ratio
        
else
   wellArea = strcat("(" wellWidth ")*(" wellLength ")")
   wellPerim = strcat("2*(" wellLength ")+" wellWidth)
);if
 
;;gennadyg
else
    ;; keep up current values
    wellArea  = cdfId->wellArea->value
    wellPerim = cdfId->wellPerim->value
)
     

);if

 
; calculate the dnw dimensions based on the well dimensions

;;gennadyg
if(cdfId->userDNW->value != "Edit" then

if(numberp(wellArea) && numberp(wellPerim) then
  
  if(dpt->typ_hv_gr_well_pu_width then
        

                dnwArea = wellArea + (wellPerim * (2 * meWellTap 
                + dpt->typ_hv_gr_well_pu_width*scale))
                + 4*(2* meWellTap + dpt->typ_hv_gr_well_pu_width*scale)**2
   
                dnwPerim = wellPerim + 8 * (2 * meWellTap + dpt->typ_hv_gr_well_pu_width*scale)

        

 else ;If Non-ESD dev then use regular formula
                
        if(dnwWellTap then ;hvmos5
                dnwArea = wellArea + wellPerim * (2 * dnwWellTap + max(mwTap 2*meTapCont + mwCont)) 
               + 4 * (2 * dnwWellTap + max(mwTap 2*meTapCont + mwCont))**2
                                
                dnwPerim = wellPerim + 8 * (2 * dnwWellTap + max(mwTap 2*meTapCont + mwCont))
        
        else
                dnwArea = wellArea + wellPerim * (2 * meWellTap + max(mwTap 2*meTapCont + mwCont)) 
               + 4 * (2 * meWellTap + max(mwTap 2*meTapCont + mwCont))**2
                                
                dnwPerim = wellPerim + 8 * (2 * meWellTap + max(mwTap 2*meTapCont + mwCont))
        
        
        );if dnwWellTap                
                        
        
 );if
  
else

 
dnwArea = sprintf(nil "iPar(\"wellArea\") + iPar(\"wellPerim\") * %s + %s"
  aelSuffixNotation((2 * meWellTap + max(mwTap 2*meTapCont + mwCont)) 6)
  aelSuffixNotation(4 * (2 * meWellTap + max(mwTap 2*meTapCont + mwCont))**2 6))
dnwPerim = sprintf(nil "iPar(\"wellPerim\") + %s"
  aelSuffixNotation(8 * (2 * meWellTap + max(mwTap 2*meTapCont + mwCont)) 6))
   );if

;;gennadyg
else
    ;; keep up current values
    dnwArea  = cdfId->dnwArea->value
    dnwPerim = cdfId->dnwPerim->value
)


; calculate as ad ps pd
; it is assumed that the device is in an abutted chain, so has no end caps
; these values are calculated as an average per finger
; added bypass for as ad ps pd values in esd (sd) devices ;;by gennadyg 18.07.2010


 
if(cdfId->custom_as_ad_ps_pd~>value then

        case(cdfId->custom_as_ad_ps_pd~>value
                  
                  
                    ("as_ad_ps_pd_lvmosesd"

                     if(numberp(wellArea) && numberp(wellPerim) then
                                                            
                                                                as=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6*(dpt->ms_c1_to_gate+dpt->mwCont+(dpt->ms_c1_to_c1/2))) "p")
  
                               ad=as

                                                                ps=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6+(2*(dpt->ms_c1_to_gate+dpt->mwCont+(dpt->ms_c1_to_c1/2)))) "u")
                                                                
                                                                pd=ps

                                                                                  
                    else
                       
                                                                  as=strcat(pcExprToString(1e6*(dpt->ms_c1_to_gate+dpt->mwCont+(dpt->ms_c1_to_c1/2))) "p")
                                                                ad=as
                                                                
                                                                  ps=strcat(pcExprToString(1e6*(2*(dpt->ms_c1_to_gate+dpt->mwCont+(dpt->ms_c1_to_c1/2)))) "u")
                                                                pd=ps                        
                                                             
                                                  );
                  
                  );as_ad_ps_pd_lvmosesd
                  
                 
                  
                  
             ("as_ad_ps_pd_mos_moshv"

                     if(numberp(wellArea) && numberp(wellPerim) then
                                                            
                        as=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6*(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                +2*(dpt->ms_gate_poly_ov_sd + dpt->mw_gate_poly)*(dpt->ms_cont_gate_s+(dpt->mwCont/2))) "p")
  
  
                                                                          ;strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6*($pcRule_ms_cont_gate_s+($pcRule_mwCont/2))
                                                                   ;+2*($pcRule_ms_gate_poly_ov_sd+$pcRule_mw_gate_poly)*($pcRule_ms_cont_gate_s+($pcRule_mwCont/2))) "p")
  
  
  
                        ad=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6*(dpt->ms_cont_gate_d+(dpt->mwCont/2))
                                +2*dpt->typ_drain_area_moshvlv) "p")

                        ps=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                +2*(dpt->ms_cont_gate_s+(dpt->mwCont/2))+ 2*(dpt->ms_gate_poly_ov_sd + dpt->mw_gate_poly)) "u")


                        pd=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                +2*dpt->typ_poly_step_peri_moshvlv) "u")
                                                                                  
                    else
                             as=strcat(pcExprToString(1e6*(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                +2*(dpt->ms_gate_poly_ov_sd + dpt->mw_gate_poly)*(dpt->ms_cont_gate_s+(dpt->mwCont/2))) "p")
                                                                  
                                                                
                                                                ad=strcat(pcExprToString(1e6*(dpt->ms_cont_gate_d+(dpt->mwCont/2))
                                +2*dpt->typ_drain_area_moshvlv) "p")

                        ps=strcat(pcExprToString(1e6
                                +2*(dpt->ms_cont_gate_s+(dpt->mwCont/2))+ 2*(dpt->ms_gate_poly_ov_sd + dpt->mw_gate_poly)) "u")


                        pd=strcat(pcExprToString(1e6
                                +2*dpt->typ_poly_step_peri_moshvlv) "u")
                                                        
                                                                as=strcat("iPar(\"totalWidth\") *" as)
                                                                ad=strcat("iPar(\"totalWidth\") *" ad)
                                                                ps=strcat("iPar(\"totalWidth\") *" ps)
                                                                pd=strcat("iPar(\"totalWidth\") *" pd)
                                                                
                                                                
                                                                
                                                  );if numberp                                                            
                                                                                                      
              )   
                
          ("as_ad_ps_pd_mos_hvscnemos5"
                 
                    if(numberp(wellArea) && numberp(wellPerim) then                     
                                                                as=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6*(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                 +2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)*(dpt->ms_cont_gate_s+(dpt->mwCont/2))) "p")

                        ad=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6*(dpt->ms_cont_gate_d+(dpt->mwCont/2))
                                +2*dpt->typ_drain_area_moshvsc5) "p")

                        ps=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                +2*(dpt->ms_cont_gate_s+(dpt->mwCont/2))+ 2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)) "u")

                        pd=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                            +2*dpt->typ_poly_step_peri_moshvsc5) "u")
                                        else
                                                        as=strcat(pcExprToString(1e6*(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                 +2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)*(dpt->ms_cont_gate_s+(dpt->mwCont/2))) "p")

                        ad=strcat(pcExprToString(1e6*(dpt->ms_cont_gate_d+(dpt->mwCont/2))
                                +2*dpt->typ_drain_area_moshvsc5) "p")

                        ps=strcat(pcExprToString(1e6
                                +2*(dpt->ms_cont_gate_s+(dpt->mwCont/2))+ 2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)) "u")

                        pd=strcat(pcExprToString(1e6
                                            +2*dpt->typ_poly_step_peri_moshvsc5) "u")
                                                        
                                                        as=strcat("iPar(\"totalWidth\") *" as)
                                                                ad=strcat("iPar(\"totalWidth\") *" ad)
                                                                ps=strcat("iPar(\"totalWidth\") *" ps)
                                                                pd=strcat("iPar(\"totalWidth\") *" pd)
                                                        
                                                        
                                        );if numberp
          )

          ("as_ad_ps_pd_mos_hvscpemos4"
                   
                                                 
                                                 if(numberp(wellArea) && numberp(wellPerim) then             
                        as=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                *(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                + 2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)*(dpt->ms_cont_gate_s+(dpt->mwCont/2))) "p")

                        ad=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                *(dpt->ms_cont_gate_d+(dpt->mwCont/2))
                                + 2*dpt->typ_drain_area_moshvsc4) "p")

                        ps=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                + 2*(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                + 2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)) "u")

                        pd=strcat(pcExprToString(evalstring(cdfId->totalWidth->value)*1e6
                                +2*dpt->typ_poly_step_peri_moshvsc4) "u")
                        else
                                                
                                                                as=strcat(pcExprToString(1e6
                                *(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                + 2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)*(dpt->ms_cont_gate_s+(dpt->mwCont/2))) "p")

                        ad=strcat(pcExprToString(1e6
                                *(dpt->ms_cont_gate_d+(dpt->mwCont/2))
                                + 2*dpt->typ_drain_area_moshvsc4) "p")

                        ps=strcat(pcExprToString(1e6
                                + 2*(dpt->ms_cont_gate_s+(dpt->mwCont/2))
                                + 2*(dpt->ms_gate_poly_ov_sd+dpt->mw_gate_poly)) "u")

                        pd=strcat(pcExprToString(1e6
                                +2*dpt->typ_poly_step_peri_moshvsc4) "u")
                                                                                  
                                                                                  
                                                                as=strcat("iPar(\"totalWidth\") *" as)
                                                                ad=strcat("iPar(\"totalWidth\") *" ad)
                                                                ps=strcat("iPar(\"totalWidth\") *" ps)
                                                                pd=strcat("iPar(\"totalWidth\") *" pd)
                                                
                                                
                                                );if numberp
          
                         
                         
                         )
           


        )
        ;end case


else
   if(numberp(fingerWidth) then
      as = fingerWidth * (msContPolyS + mwCont/2)
      ad = fingerWidth * (msContPolyD + mwCont/2)
      ps = 2*(msContPolyS + mwCont/2) + fingerWidth
      pd = 2*(msContPolyD + mwCont/2) + fingerWidth
   else
      as = ad = sprintf(nil "iPar(\"fingerWidth\") * %s"
        aelSuffixNotation(msContPoly + mwCont/2 6))
      ps = pd = sprintf(nil "%s + iPar(\"fingerWidth\")"
        aelSuffixNotation(2*(msContPoly + mwCont/2) 6)) 
   );if

);;if custom_as_ad_ps_pd

; calculate asd psd
; it is assumed that caps are not abutted
if(numberp(fingerWidth) && numberp(numFinger) then
   asd = 2 * fingerWidth * (mwCont/2 + msContPoly) + 
         2 * fingerWidth/numFinger * (meDiffCont + mwCont/2)
   psd = 2 * fingerWidth + 4 * (mwCont/2 + msContPoly) + 
         2/numFinger * (2 * meDiffCont + mwCont + fingerWidth)
   else
   asd = sprintf(nil "2*iPar(\"fingerWidth\") * %s + 2*iPar(\"fingerWidth\")/iPar(\"numFinger\") * %s"
      aelSuffixNotation(mwCont/2 + msContPoly 6)
      aelSuffixNotation(meDiffCont + mwCont/2 6))
   psd = sprintf(nil "2*iPar(\"fingerWidth\") + %s + 2/iPar(\"numFinger\") * (%s + iPar(\"fingerWidth\"))"
      aelSuffixNotation(4 * (mwCont/2 + msContPoly) 6)
      aelSuffixNotation(2 * meDiffCont + mwCont 6))
   );if

; place holder until the rest of the calculations are brought into this procedure
old_vals = ${template_libName}_mosCalcAreaPerim_old(fingerWidth fingerLength numFinger sourceFirst metalWidthSD dpt cdfId)

returnList =   list( nil
             'as as  
             'ad ad
             'ps ps
             'pd pd
             'nrs old_vals->nrs
             'nrd old_vals->nrd
             'sa old_vals->sa
             'sb old_vals->sb
             'sd old_vals->sd
             'asd asd
             'psd psd
             'wellArea wellArea
             'wellPerim wellPerim
             'dnwArea dnwArea
             'dnwPerim dnwPerim
       )
return(returnList)
));prog, procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


procedure(${template_libName}_mosCalcAreaPerim_old( fingerWidth fingerLength numFinger ;_Dec  4 04 amir 1160
             sourceFirst metalWidthSD dpt @optional cdfId )

  prog(
     (
        epsilon value stepWidth
        dogbone contSpan  returnList
        dbwLSD dbwRSD dbwCSD ndwLSD ndwRSD ndwCSD
        dbaCSD dbpCSD ndaCSD ndpCSD
        dbaLSD dbaRSD dbpLSD dbpRSD
        ndaLSD ndaRSD ndpLSD ndpRSD
        evnCntrs oddCntrs evnTest oddTest
        evnArea evnPerim oddArea oddPerim
        tmp1 tmp2 nrd nrs sa sb sd
        fingersQuotient fingersQuotientString
        scale grid mwCont meeDiffCont 
        leftCont rightCont leftAbutExt rightAbutExt
        leftDummies  rightDummies msContPoly msDiffPoly
        meDiffPoly meM1Cont funName
        meTapCont msCont BSDContSp iSD 
        stepWidth itapGateSep msPoly
        intTap leftITap rightITap leftDummyScale rightDummyScale
        msMetalPoly meItimpCont diffContEnc itapWidth
        dblCSD dblLSD dblRSD gateCwSp lSD mlSDx numConts timpContEnc mwItap
        oddTestInt evnTestInt evnAreaNoDb oddAreaNoDb evnPerimNoDb oddPerimNoDb
     )

    funName = getCallingFunction(0) 

     (unless cdfId cdfId = cdfgData)

     scale = (dpt->scale || 1e-6 )
     
     diffContEnc  = cdfParseFloatString( cdfId->diffContEnc->value)
     leftAbutExt  = cdfParseFloatString( cdfId->leftAbutExt->value)
     rightAbutExt = cdfParseFloatString( cdfId->rightAbutExt->value)
     leftDummies  = cdfId->leftDummies->value || 0
     rightDummies = cdfId->rightDummies->value || 0
     msMetalPoly  = cdfParseFloatString( cdfId->GCwSp->value)
 
     leftCont  = cdfId->leftCont->value
     rightCont = cdfId->rightCont->value
     dogbone   = cdfId->dogbone->value
     
     intTap    = cdfId->tap->value == "Integrated" || cdfId->tap->value == "Salicided Integrated"
     leftITap  = intTap && cdfId->leftTap->value
     rightITap = intTap && cdfId->rightTap->value

     leftDummyScale = 1.0
     rightDummyScale = 1.0

     grid = dpt->grid 
     mwCont = dpt->mwCont  
     meeDiffCont = dpt->meeDiffCont
     meM1Cont = dpt->meM1Cont 
     msDiffPoly = dpt->msDiffPoly  
     meDiffPoly = dpt->meDiffPoly 
     meTapCont = dpt->meTapCont 
     msCont = dpt->msCont( 1 1)
     meItimpCont = dpt->meItimpCont
     if(procedurep(dpt->msPoly) then
        msPoly = dpt->msPoly(if(numberp(fingerLength) then fingerLength/scale else dpt->maxFingerLength) if(numberp(fingerWidth) then  fingerWidth/scale else dpt->maxFingerWidth) !dpt->thoxLayer dpt->amsBestPractice)
        else
        msPoly = dpt->msPoly
        );if

     ; All calculations are done in meters.
     ; Convert params from microns to meters.
     foreach( s list('grid 'mwCont 'meeDiffCont 'msDiffPoly  'meItimpCont
                    'meDiffPoly 'meM1Cont 'meTapCont 'msCont)
       value = symeval(s)
       if( value then
          set(s value * scale)
       else
          error(
             "%s: invalid value for required device property '%s' - %L!"
             funName s value
          )
       ) ; ** if value **
     ) ; ** foreach s **

     msContPoly = cdfParseFloatString( cdfId->msContPoly->value)
     meeDiffCont = (max meeDiffCont diffContEnc)

     epsilon = grid / 10.0
     stepWidth = cdfParseFloatString( cdfId->dsDiffPoly->value) * 1e-6
     itapGateSep = max(dpt->msItapGate (dpt->meImplGate || 0)) * 1e-6
     BSDContSp = cdfParseFloatString( cdfId->BSDContSp->value)

    foreach( s list( 'fingerWidth 'fingerLength 'numFinger 'metalWidthSD)
       value = symeval(s)
       caseq( type(value)
          ( string
            set(s cdfParseFloatString( value ))
          )
          ( ( flonum fixnum ) t )
          ( t error("%s: invalid value for '%s' - %L" funName s value) )
       ) ; ** caseq type **
    ) ; ** foreach s **

    stepWidth = max( ( msContPoly - diffContEnc ) msDiffPoly grid )

    ;; this if statement is used to control if as/ad/ps/pd represent the
    ;; total width of the device, or the average per finger.
    if( dpt->aggregateFingers then
       fingersQuotient = 1
       fingersQuotientString = "1"
    else
       fingersQuotient = numFinger
       if( numberp( numFinger ) then
          fingersQuotientString = sprintf( nil "%d" round(numFinger) )
       else
          fingersQuotientString = sprintf( nil "%s" numFinger )
       )
    ) ; ** if dpt **

    ; assuming that metalWidthSD will always be a numerical value
    contSpan = cdfParseFloatString( cdfId->contSpan->value )
    mlSDx = contSpan + (2.0 * diffContEnc)
    
    numConts = metalWidthSD >= 2 * mwCont + msCont + 2 * meM1Cont   
    if( numConts  then  ; number of SD conts >= 2
        gateCwSp = msContPoly
    else ; number of SD conts = 1, but M1ContEnc can be larger than min
        gateCwSp = PasRound( (((metalWidthSD - mwCont) / 2) + msMetalPoly) grid)
        contSpan = contSpan - (metalWidthSD - mwCont)
    )

    if( numberp(fingerWidth) && numberp(metalWidthSD) && numberp(numFinger) then
       
       when( floatp(numFinger)
          numFinger = round(numFinger)
       )
       evnCntrs = (numFinger - 1) / 2
       oddCntrs = numFinger / 2
       
       ; dogbone width assumes only one contact
       dbwCSD = mwCont  + (2 * (max diffContEnc meeDiffCont)) ; dogbone center SD width
       dblCSD = mlSDx ; dogbone center SD width
       ndwCSD = contSpan  + (2 * msContPoly) ; non-dogbone center SD width

       dbwLSD = dbwCSD
       dbwRSD = dbwCSD

       if( leftCont then
            dblLSD = max(( meDiffPoly - stepWidth ) dblCSD )
            ndwLSD = max( meDiffPoly ( contSpan  + diffContEnc + msContPoly ))
        else
            dblLSD = ndwLSD = leftAbutExt
       ) ; else if leftCont
       if( rightCont then
            dblRSD = max(( meDiffPoly - stepWidth ) dblCSD )
            ndwRSD = max( meDiffPoly ( contSpan  + diffContEnc + msContPoly ))
        else
            dblRSD = ndwRSD =  rightAbutExt
       ) ; else if rightCont

       when( leftDummies >= 1 
            ndwLSD = ndwCSD
        )
       when( rightDummies >= 1 
            ndwRSD = ndwCSD
        )

       if( dogbone then
          ;; dogbone area
          dbaCSD = (dbwCSD * dblCSD) + (2 * fingerWidth * stepWidth)
          dbaLSD = if( (leftCont || leftDummies >= 1) then 
                        (dbwLSD * dblLSD) + (fingerWidth * stepWidth) 
                    else 
                        dblLSD * fingerWidth
                    ) 
                    + if( leftDummies >= 1 then (fingerWidth * stepWidth) - (dbwLSD * dblLSD) + (dbwLSD * dblCSD)
                       else 0.0)
          dbaRSD = if( (rightCont || rightDummies >= 1) then 
                        (dbwRSD * dblRSD) + (fingerWidth * stepWidth) 
                    else 
                        dblRSD * fingerWidth)
                    + if( rightDummies >= 1 then (fingerWidth * stepWidth) - (dbwRSD * dblRSD) + (dbwRSD * dblCSD)
                       else 0.0)

          ;; dogbone perimeter
          if( dpt->perimGateEdge then  ; count all four sides in perimeter
             dbpCSD = (2 * dbwCSD) + (2 * dblCSD) + (4 * stepWidth)
             dbpLSD =  if( (leftCont || leftDummies >= 1) then 
                        (2 * dbwLSD) + (2 * dblLSD) + (2 * stepWidth) 
                       else 
                        (2 * dblLSD) + 2 * fingerWidth
                       ) + if( leftDummies >= 1 then 2 * stepWidth - (2 * dblLSD) + (2 * dblCSD) else 0.0)
             dbpRSD =  if( (rightCont || rightDummies >= 1) then 
                          (2 * dbwRSD) + (2 * dblRSD) + (2 * stepWidth) 
                       else 
                          (2 * dblRSD) + 2 * fingerWidth
                       ) + if( rightDummies >= 1 then 2 * stepWidth - (2 * dblRSD) + (2 * dblCSD) else 0.0)
          else
             dbpCSD = (2 * dbwCSD) + (2 * dblCSD) + (4 * stepWidth) - (2 * fingerWidth)
             dbpLSD = (2 * dbwLSD) + if( leftCont  then (2 * dblLSD) + (2 * stepWidth) - fingerWidth else 0.0)
             dbpRSD = (2 * dbwRSD) + if( rightCont then (2 * dblRSD) + (2 * stepWidth) - fingerWidth else 0.0)
          ) ; ** if dpt->perimGateEdge **

       when(cdfId 
         when(cdfId->editSourceAreaPerim->value == "View Shared" && sourceFirst
           dbaLSD = dbaLSD/2
           dbpLSD = (dbpLSD - fingerWidth)/2
           when(evenp(numFinger)
              dbaRSD = dbaRSD/2
              dbpRSD = (dbpRSD - fingerWidth)/2
              );when
           );when
         when(cdfId->editSourceAreaPerim->value == "View Shared" && !sourceFirst && oddp(numFinger)
           dbaRSD = dbaRSD/2
           dbpRSD = (dbpRSD - fingerWidth)/2
           );when
         when(cdfId->editDrainAreaPerim->value == "View Shared" && !sourceFirst
           dbaLSD = dbaLSD/2
           dbpLSD = (dbpLSD - fingerWidth)/2
           when(evenp(numFinger)
              dbaRSD = dbaRSD/2
              dbpRSD = (dbpRSD - fingerWidth)/2
              );when
           );when
         when(cdfId->editDrainAreaPerim->value == "View Shared" && sourceFirst && oddp(numFinger)
           dbaRSD = dbaRSD/2
           dbpRSD = (dbpRSD - fingerWidth)/2
           );when

         when(cdfId->editSourceAreaPerim->value == "View Series" && sourceFirst
           dbaLSD = (fingerWidth * msPoly * scale)/2
           ndaLSD = (fingerWidth * msPoly * scale)/2
           dbpLSD = msPoly*scale
           ndpLSD = msPoly*scale
           when(evenp(numFinger)
              dbaRSD = (fingerWidth * msPoly * scale)/2
              ndaRSD = (fingerWidth * msPoly * scale)/2
              dbpRSD = msPoly*scale
              ndpRSD = msPoly*scale
              );when
           );when
         when(cdfId->editSourceAreaPerim->value == "View Series" && !sourceFirst && oddp(numFinger)
           dbaRSD = (fingerWidth * msPoly * scale)/2
           ndaRSD = (fingerWidth * msPoly * scale)/2
           dbpRSD = msPoly*scale
           ndpRSD = msPoly*scale
           );when
         when(cdfId->editDrainAreaPerim->value == "View Series" && sourceFirst
           dbaLSD = (fingerWidth * msPoly * scale)/2
           ndaLSD = (fingerWidth * msPoly * scale)/2
           dbpLSD = msPoly*scale
           ndpLSD = msPoly*scale
           when(evenp(numFinger)
              dbaRSD = (fingerWidth * msPoly * scale)/2
              ndaRSD = (fingerWidth * msPoly * scale)/2
              dbpRSD = msPoly*scale
              ndpRSD = msPoly*scale
              );when
           );when
         when(cdfId->editDrainAreaPerim->value == "View Series" && !sourceFirst && oddp(numFinger)
           dbaRSD = (fingerWidth * msPoly * scale)/2
           ndaRSD = (fingerWidth * msPoly * scale)/2
           dbpRSD = msPoly*scale
           ndpRSD = msPoly*scale
           );when
        );when

          evnArea =  (dbaLSD + (evnCntrs * dbaCSD) + if( evenp(numFinger) then dbaRSD else 0 )) 
                        / fingersQuotient
          oddArea =  (         (oddCntrs * dbaCSD) + if( oddp(numFinger)  then dbaRSD else 0 )) 
                        / fingersQuotient
          evnPerim = (dbpLSD + (evnCntrs * dbpCSD) + if( evenp(numFinger) then dbpRSD else 0 )) 
                        / fingersQuotient
          oddPerim = (         (oddCntrs * dbpCSD) + if( oddp(numFinger)  then dbpRSD else 0 )) 
                        / fingersQuotient

       else
          ;; no dogbone area
          ndaCSD = ndwCSD * fingerWidth
          ndaLSD = ndwLSD * fingerWidth
          ndaRSD = ndwRSD * fingerWidth
          ;; no dogbone perimeter
          if( dpt->perimGateEdge then
             ndpCSD = (2 * ndwCSD) + (2 * fingerWidth)
             ndpLSD = (2 * ndwLSD) + (2 * fingerWidth)
             ndpRSD = (2 * ndwRSD) + (2 * fingerWidth)
          else
             ndpCSD = (2 * ndwCSD)
             ndpLSD = (2 * ndwLSD) +  fingerWidth
             ndpRSD = (2 * ndwRSD) +  fingerWidth
          ) ; ** if dpt->perimGateEdge **

       when(cdfId 
         when(cdfId->editSourceAreaPerim->value == "View Shared" && sourceFirst
           ndaLSD = ndaLSD/2
           ndpLSD = (ndpLSD - fingerWidth)/2
           when(evenp(numFinger)
              ndaRSD = ndaRSD/2
              ndpRSD = (ndpRSD - fingerWidth)/2
              );when
           );when
         when(cdfId->editSourceAreaPerim->value == "View Shared" && !sourceFirst && oddp(numFinger)
           ndaRSD = ndaRSD/2
           ndpRSD = (ndpRSD - fingerWidth)/2
           );when
         when(cdfId->editDrainAreaPerim->value == "View Shared" && !sourceFirst
           ndaLSD = ndaLSD/2
           ndpLSD = (ndpLSD - fingerWidth)/2
           when(evenp(numFinger)
              ndaRSD = ndaRSD/2
              ndpRSD = (ndpRSD - fingerWidth)/2
              );when
           );when
         when(cdfId->editDrainAreaPerim->value == "View Shared" && sourceFirst && oddp(numFinger)
           ndaRSD = ndaRSD/2
           ndpRSD = (ndpRSD - fingerWidth)/2
           );when

         when(cdfId->editSourceAreaPerim->value == "View Series" && sourceFirst
           dbaLSD = (fingerWidth * msPoly * scale)/2
           ndaLSD = (fingerWidth * msPoly * scale)/2
           dbpLSD = msPoly*scale
           ndpLSD = msPoly*scale
           when(evenp(numFinger)
              dbaRSD = (fingerWidth * msPoly * scale)/2
              ndaRSD = (fingerWidth * msPoly * scale)/2
              dbpRSD = msPoly*scale
              ndpRSD = msPoly*scale
              );when
           );when
         when(cdfId->editSourceAreaPerim->value == "View Series" && !sourceFirst && oddp(numFinger)
           dbaRSD = (fingerWidth * msPoly * scale)/2
           ndaRSD = (fingerWidth * msPoly * scale)/2
           dbpRSD = msPoly*scale
           ndpRSD = msPoly*scale
           );when
         when(cdfId->editDrainAreaPerim->value == "View Series" && sourceFirst
           dbaLSD = (fingerWidth * msPoly * scale)/2
           ndaLSD = (fingerWidth * msPoly * scale)/2
           dbpLSD = msPoly*scale
           ndpLSD = msPoly*scale
           when(evenp(numFinger)
              dbaRSD = (fingerWidth * msPoly * scale)/2
              ndaRSD = (fingerWidth * msPoly * scale)/2
              dbpRSD = msPoly*scale
              ndpRSD = msPoly*scale
              );when
           );when
         when(cdfId->editDrainAreaPerim->value == "View Series" && !sourceFirst && oddp(numFinger)
           dbaRSD = (fingerWidth * msPoly * scale)/2
           ndaRSD = (fingerWidth * msPoly * scale)/2
           dbpRSD = msPoly*scale
           ndpRSD = msPoly*scale
           );when
         );when

          evnArea =  (ndaLSD + (evnCntrs * ndaCSD) + if( evenp(numFinger) then ndaRSD else 0 )) / fingersQuotient   
          oddArea =  (         (oddCntrs * ndaCSD) + if( oddp(numFinger)  then ndaRSD else 0 )) / fingersQuotient
          evnPerim = (ndpLSD + (evnCntrs * ndpCSD) + if( evenp(numFinger) then ndpRSD else 0 )) / fingersQuotient
          oddPerim = (         (oddCntrs * ndpCSD) + if( oddp(numFinger)  then ndpRSD else 0 )) / fingersQuotient
          
       ) ; ** if dogbone **
       
 
    nrd = nrs = gateCwSp / fingerWidth

    else
       ;; use AEL
       ;foreach( s list('fingerWidth 'numFinger 'metalWidthSD)
       foreach( s list('fingerWidth 'numFinger )
          set(s sprintf(nil "iPar(\"%s\")" s))
       ) ; ** foreach s **
       
       evnCntrs = sprintf( nil "floor((%s - 1) / 2.0)" numFinger)
       oddCntrs = sprintf( nil "floor(%s / 2.0)" numFinger)
       
       dbwCSD = sprintf( nil "(%.6g + %s)" mwCont  aelSuffixNotation((2 * (max diffContEnc meeDiffCont)) 6) )
       dblCSD = mlSDx ; dogbone center SD width
       ndwCSD = sprintf( nil "(%s + %s)" aelSuffixNotation( contSpan 6)  aelSuffixNotation((2 * msContPoly) 6) )
       
       dbwLSD = dbwCSD
       dbwRSD = dbwCSD

       if( leftCont then
            dblLSD = sprintf( nil "(%s > %s ? %s : %s)"
                         tmp1 = aelSuffixNotation((meDiffPoly - stepWidth) 6)
                         aelSuffixNotation( dblCSD 6) tmp1 aelSuffixNotation( dblCSD 6) )
       
            ndwLSD = sprintf( nil "(%s > %s ? %s : %s)"
                         tmp1 = aelSuffixNotation(meDiffPoly 6)
                         tmp2 = sprintf( nil "(%s + %s)" aelSuffixNotation(contSpan 6) 
                                         aelSuffixNotation((diffContEnc + msContPoly) 6) )
                         tmp1 tmp2 )
        else
            dblLSD = ndwLSD = sprintf( nil "%s" aelSuffixNotation( leftAbutExt) )
        ) ; if leftCont
        
        
       if( rightCont then
            dblRSD = sprintf( nil "(%s > %s ? %s : %s)"
                         tmp1 = aelSuffixNotation((meDiffPoly - stepWidth) 6)
                         aelSuffixNotation( dblCSD 6) tmp1 aelSuffixNotation( dblCSD 6) )
       
            ndwRSD = sprintf( nil "(%s > %s ? %s : %s)"
                         tmp1 = aelSuffixNotation(meDiffPoly 6)
                         tmp2 = sprintf( nil "(%s + %s)" aelSuffixNotation( contSpan 6) 
                                         aelSuffixNotation((diffContEnc + msContPoly) 6) )
                         tmp1 tmp2 )
        else
            dblRSD = ndwRSD = sprintf( nil "%s" aelSuffixNotation( rightAbutExt) )
        ) ; if rightCont

        when( leftDummies >= 1
            ndwLSD = ndwCSD
        ) ; when leftDummies
        
        when( rightDummies >= 1
            ndwRSD = ndwCSD
        ) ; when leftDummies
        
       ; both dogbone and non-dogbone parameters are calculated.
       dbaCSD = sprintf( nil "((%s * %s) + (%s * %s))"
                         dbwCSD  aelSuffixNotation( dblCSD 6) fingerWidth
                         aelSuffixNotation((2 * stepWidth) 6))
       dbaLSD = sprintf( nil "%s + %s"
                        if( (leftCont || leftDummies >= 1) then
                            sprintf( nil "(%s * %s) + (%s * %s)"
                                dbwLSD dblLSD 
                                fingerWidth aelSuffixNotation(stepWidth 6))
                         else   
                            sprintf( nil "%s * %s"  dblLSD fingerWidth)
                         ) ; else if leftCont
                         if( leftDummies >= 1 then 
                            sprintf( nil "%s * %.6g - (%s * %s) + (%s * %.6g)" fingerWidth stepWidth 
                            dbwLSD dblLSD dbwLSD dblCSD) 
                         else  
                            sprintf( nil "%.6g" 0.0) 
                         )
                ) ; sprintf
       dbaRSD = sprintf( nil "%s + %s"
                        if( (rightCont || rightDummies >= 1) then
                            sprintf( nil "(%s * %s) + (%s * %s)"
                                dbwRSD dblRSD 
                                fingerWidth aelSuffixNotation(stepWidth 6))
                         else   
                            sprintf( nil "%s * %s"  dblRSD fingerWidth)
                         ) ; else if rightCont
                         if( rightDummies >= 1 then 
                            sprintf( nil "%s * %.6g - (%s * %s) + (%s * %.6g)" fingerWidth stepWidth dbwRSD dblRSD dbwRSD dblCSD) 
                         else  
                            sprintf( nil "%.6g" 0.0) 
                         )
                ) ; sprintf
       
       
       ndaCSD = sprintf( nil "(%s * %s)" ndwCSD fingerWidth )
       ndaLSD = sprintf( nil "(%s * %s)" ndwLSD fingerWidth )
       ndaRSD = sprintf( nil "(%s * %s)" ndwRSD fingerWidth )


       ;; perimeter
       if( dpt->perimGateEdge then  ; count all four sides in perimeter
          dbpCSD = sprintf( nil "((2 * %s) + (2 * %s) + %s)"
                            dbwCSD aelSuffixNotation( dblCSD 6)
                            aelSuffixNotation((4 * stepWidth) 6) )
          if( (leftCont || leftDummies >= 1) then
            dbpLSD = sprintf( nil "%f * ((2 * %s) + (2 * %s) + %s + %s)"
                            leftDummyScale dbwLSD dblLSD
                            aelSuffixNotation((2 * stepWidth) 6) 
                            if( leftDummies >= 1 then 
                                sprintf( nil "%.6g - 2 * %s + 2 * %.6g" 2 * stepWidth dblLSD dblCSD) 
                            else "0.0"))
          else
            dbpLSD = sprintf( nil "%f * ((2 * %s) + 2 * %s)"
                            leftDummyScale dblLSD fingerWidth )
          ) ; if else leftCont

          if( (rightCont || rightDummies >= 1) then
            dbpRSD = sprintf( nil "%f * ((2 * %s) + (2 * %s) + %s + %s)"
                            rightDummyScale dbwRSD 
                            dblRSD
                            aelSuffixNotation((2 * stepWidth) 6) 
                            if( rightDummies >= 1 then 
                                sprintf( nil "%.6g - 2 * %s + 2 * %.6g" 2 * stepWidth dblRSD dblCSD) 
                            else "0.0"))
          else
            dbpRSD = sprintf( nil "%f * ((2 * %s) + 2 * %s)"
                            rightDummyScale dblRSD fingerWidth )
          ) ; if else rightCont

           ;; no dogbone perimeter
          ndpCSD = sprintf( nil "((2 * %s) + (2 * %s))" ndwCSD fingerWidth )
          ndpLSD = sprintf( nil "((2 * %s) + (2 * %s))" ndwLSD fingerWidth )
          ndpRSD = sprintf( nil "((2 * %s) + (2 * %s))" ndwRSD fingerWidth )
       else ; count only 2 sides in perimeter
          dbpCSD = sprintf( nil "((2 * %s) + %s - (2 * %s))"
                            dbwCSD
                            aelSuffixNotation(((2 * mlSDx) + (4 * stepWidth)) 6)
                            fingerWidth )
          
          dbpLSD = sprintf( nil "((2 * %s) + %s - %s)"
                            dbwLSD
                            if( leftCont then aelSuffixNotation(((2 * mlSDx) + (2 * stepWidth)) 6) else "0.0")
                            if( leftCont then fingerWidth else "0.0") )
          
          dbpRSD = sprintf( nil "((2 * %s) + %s - %s)"
                            dbwRSD
                            if( rightCont then aelSuffixNotation(((2 * mlSDx) + (2 * stepWidth)) 6) else "0.0")
                            if( rightCont then fingerWidth else "0.0") )
          
          ;; no dogbone perimeter
          ndpCSD = sprintf( nil "(2 * %s)" ndwCSD )
          ndpLSD = sprintf( nil "((2 * %s) + %s)" ndwLSD fingerWidth )
          ndpRSD = sprintf( nil "((2 * %s) + %s)" ndwRSD fingerWidth )
       ) ; ** if dpt->perimGateEdge **


       oddTest = sprintf( nil "((%s / 2) - floor(%s / 2) != 0)" numFinger numFinger)
       evnTest = sprintf( nil "((%s / 2) - floor(%s / 2) == 0)" numFinger numFinger)
       oddTestInt = if(oddTest then 1.0 else 0.0)
       evnTestInt = if(evnTest then 1.0 else 0.0)

       dogbone = sprintf( nil "(%s < %s - %s)" fingerWidth 
                    dbwCSD
                    aelSuffixNotation(epsilon 6) 
                    )
       when(cdfId 
         when(cdfId->editSourceAreaPerim->value == "View Shared" && sourceFirst
           dbaLSD = strcat("(" dbaLSD ")/2")
           ndaLSD = strcat("(" ndaLSD ")/2")
           dbpLSD = strcat("(" dbpLSD " - " pcExprToString(fingerWidth) ")/2")
           ndpLSD = strcat("(" ndpLSD " - " pcExprToString(fingerWidth) ")/2")
           when(evenp(numFinger)
              dbaRSD = strcat("(" dbaRSD ")/2")
              ndaRSD = strcat("(" ndaRSD ")/2")
              dbpRSD = strcat("(" dbpRSD " - " pcExprToString(fingerWidth) ")/2")
              ndpRSD = strcat("(" ndpRSD " - " pcExprToString(fingerWidth) ")/2")
              );when
           );when
         when(cdfId->editSourceAreaPerim->value == "View Shared" && !sourceFirst && oddp(numFinger)
           dbaRSD = strcat("(" dbaRSD ")/2")
           ndaRSD = strcat("(" ndaRSD ")/2")
           dbpRSD = strcat("(" dbpRSD " - " pcExprToString(fingerWidth) ")/2")
           ndpRSD = strcat("(" ndpRSD " - " pcExprToString(fingerWidth) ")/2")
           );when
         when(cdfId->editDrainAreaPerim->value == "View Shared" && !sourceFirst
           dbaLSD = strcat("(" dbaLSD ")/2")
           ndaLSD = strcat("(" ndaLSD ")/2")
           dbpLSD = strcat("(" dbpLSD " - " pcExprToString(fingerWidth) ")/2")
           ndpLSD = strcat("(" ndpLSD " - " pcExprToString(fingerWidth) ")/2")
           when(evenp(numFinger)
              dbaRSD = strcat("(" dbaRSD ")/2")
              ndaRSD = strcat("(" ndaRSD ")/2")
              dbpRSD = strcat("(" dbpRSD " - " pcExprToString(fingerWidth) ")/2")
              ndpRSD = strcat("(" ndpRSD " - " pcExprToString(fingerWidth) ")/2")
              );when
           );when
         when(cdfId->editDrainAreaPerim->value == "View Shared" && sourceFirst && oddp(numFinger)
           dbaRSD = strcat("(" dbaRSD ")/2")
           ndaRSD = strcat("(" ndaRSD ")/2")
           dbpRSD = strcat("(" dbpRSD " - " pcExprToString(fingerWidth) ")/2")
           ndpRSD = strcat("(" ndpRSD " - " pcExprToString(fingerWidth) ")/2")
           );when

         when(cdfId->editSourceAreaPerim->value == "View Series" && sourceFirst
           sprintf(dbaLSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(ndaLSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(dbpLSD "%f)" msPoly*scale)
           sprintf(ndpLSD "%f)" msPoly*scale)
           when(evenp(numFinger)
              sprintf(dbaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
              sprintf(ndaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
              sprintf(dbpRSD "%f" msPoly*scale)
              sprintf(ndpRSD "%f" msPoly*scale)
              );when
           );when
         when(cdfId->editSourceAreaPerim->value == "View Series" && !sourceFirst && oddp(numFinger)
           sprintf(dbaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(ndaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(dbpRSD "%f" msPoly*scale)
           sprintf(ndpRSD "%f" msPoly*scale)
           );when
         when(cdfId->editDrainAreaPerim->value == "View Series" && sourceFirst
           sprintf(dbaLSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(ndaLSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(dbpLSD "%f" msPoly*scale)
           sprintf(ndpLSD "%f" msPoly*scale)
           when(evenp(numFinger)
              sprintf(dbaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
              sprintf(ndaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
              sprintf(dbpRSD "%f" msPoly*scale)
              sprintf(ndpRSD "%f" msPoly*scale)
              );when
           );when
         when(cdfId->editDrainAreaPerim->value == "View Series" && !sourceFirst && oddp(numFinger)
           sprintf(dbaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(ndaRSD "(iPar(\"fingerWidth\") * %f)/2" msPoly*scale)
           sprintf(dbpRSD "%f" msPoly*scale)
           sprintf(ndpRSD "%f" msPoly*scale)
           );when
         );when

       evnArea =
       sprintf( nil "%s ? (%s + (%s * %s) + (%s ? %s : 0)) / %s : (%s + (%s * %s) + (%s ? %s : 0)) / %s"
                dogbone
                dbaLSD evnCntrs dbaCSD evnTest dbaRSD fingersQuotientString
                ndaLSD evnCntrs ndaCSD evnTest ndaRSD fingersQuotientString
       )

       oddArea =
       sprintf( nil "%s ? ((%s * %s) + (%s ? %s : 0)) / %s : ((%s * %s) + (%s ? %s : 0)) / %s"
                dogbone
                oddCntrs dbaCSD oddTest dbaRSD fingersQuotientString
                oddCntrs ndaCSD oddTest ndaRSD fingersQuotientString
       )
       
       evnPerim =
       sprintf( nil "%s ? (%s + (%s * %s) + (%s ? %s : 0)) / %s : (%s + (%s * %s) + (%s ? %s : 0)) / %s"
                dogbone
                dbpLSD evnCntrs dbpCSD evnTest dbpRSD fingersQuotientString
                ndpLSD evnCntrs ndpCSD evnTest ndpRSD fingersQuotientString
       )
       
       oddPerim =
       sprintf( nil "%s ? ((%s * %s) + (%s ? %s : 0)) / %s : ((%s * %s) + (%s ? %s : 0)) / %s"
                dogbone
                oddCntrs dbpCSD oddTest dbpRSD fingersQuotientString
                oddCntrs ndpCSD oddTest ndpRSD fingersQuotientString
       )
       evnAreaNoDb =
       sprintf( nil "(%s * %s) "
                tmp2 fingerWidth 
       )

       oddAreaNoDb =
       sprintf( nil "%s * %s"
                  tmp2 fingerWidth
       )
       
       evnPerimNoDb =
       sprintf( nil "2 * %s + %s"
                tmp2 fingerWidth  
       )

       oddPerimNoDb =
       sprintf( nil "2 * %s + %s"
                tmp2 fingerWidth  
       )
       

       nrd = nrs = sprintf( nil "%s / %s" aelSuffixNotation(gateCwSp 6) fingerWidth)

    ) ; ** if numberp **

    ; assuming that metalWidthSD will always be a numerical value
    ; calculate itapWidth
    mwItap = dpt->mwItap *scale
        cond( 
            ((itapGateSep >= msContPoly + contSpan + BSDContSp/2)
                ; DRC rule implant enc of gate is larger than sum of contact rules
                timpContEnc = meItimpCont
                lSD = itapGateSep
            )
            ((itapGateSep >= msContPoly + contSpan + meItimpCont)

                ; DRC rule implant enc of gate is larger than contact rules where a shared diffusion enc
                ; of contact is larger than contSp/2
                timpContEnc = BSDContSp - (itapGateSep 
                                        - msMetalPoly - metalWidthSD + (metalWidthSD - contSpan)/2) 
                lSD = itapGateSep
            )
            ((meItimpCont + (metalWidthSD - contSpan)/2 >= BSDContSp)
                ; contact spacing with large metalWidthSD
                timpContEnc = meItimpCont
                lSD = msMetalPoly
                      + metalWidthSD - (metalWidthSD - contSpan)/2 
                      + BSDContSp/2
            )
            ( t
                ; Contact spacing is all we have to worry about 
                timpContEnc = BSDContSp - meItimpCont
                lSD = msMetalPoly + metalWidthSD - (metalWidthSD - contSpan)/2  + meItimpCont
            )
        ) ; cond

       itapWidth = (max (timpContEnc + mwCont + meTapCont) mwItap)
       cdfId->itapWidth->value = sprintf( nil "%.6g" itapWidth)
       if( (timpContEnc + mwCont + meTapCont) >= mwItap then
            cdfId->timpContEnc->value = sprintf( nil "%.6g" timpContEnc)
       else
            cdfId->timpContEnc->value = sprintf( nil "%.6g" (mwItap - mwCont)/2.0)
       )
       iSD = lSD + itapWidth
       
    ; sa and sb are set to 3u when either match is set
    ; or if the contact is shared.
         cond( 
            ( cdfId->userLod->value == "Edit" t)
            ( and( cdfId->leftDummies->value == 0  
              or( cdfId->match->value !cdfId->leftCont->value))
                   sa = "3u"
            ) ; and
            ( !leftITap ; tap value isn't Integrated or Salicided integrated
                if( numberp( fingerLength) then
                     sa = sprintf( nil "%.6g" msContPoly + contSpan + diffContEnc 
                             + leftDummies * (fingerLength + 2 * msContPoly + contSpan))
                 else 
                     sa = sprintf( nil "%.6g + %d * ( %s + %.6g)" msContPoly + contSpan + diffContEnc 
                             leftDummies  "iPar(\"fingerLength\")" 2 * msContPoly + contSpan)
                ) ; when l is not a number
            ) ; tap not integrated
            ( t  ; shared SB
                if( numberp( fingerLength) then
                     sa = sprintf( nil "%.6g"  
                            iSD + leftDummies * (fingerLength + 2 * msContPoly + contSpan)) 
                else 
                    sa = sprintf( nil "%.6g + %d * ( %s + %.6g)" 
                            iSD  leftDummies "iPar(\"fingerLength\")"  2 * msContPoly + contSpan)  
                ) ; else if numberp fingerLength
           ) ; t
         ) ; cond sa
         cond( 
            ( cdfId->userLod->value == "Edit" t)
            ( and( cdfId->rightDummies->value == 0  
              or( cdfId->match->value !cdfId->rightCont->value))
                   sb = "3u"
            ) ; and
            ; rightDummies >= 1
            ( !rightITap ; tap value isn't Integrated or Salicided integrated
                if( numberp( fingerLength) then
                     sb = sprintf( nil "%.6g" msContPoly + contSpan + diffContEnc 
                             + rightDummies * (fingerLength + 2 * msContPoly + contSpan))
                 else 
                     sb = sprintf( nil "%.6g + %d * ( %s + %.6g)" msContPoly + contSpan + diffContEnc 
                             rightDummies  "iPar(\"fingerLength\")" 2 * msContPoly + contSpan)
                ) ; when l is not a number
            ) ; tap not integrated
            ; shared SB
            ( t  
                if( numberp( fingerLength) then
                     sb = sprintf( nil "%.6g"  
                            iSD + rightDummies * (fingerLength + 2 * msContPoly + contSpan)) 
                else 
                     sb = sprintf( nil "%.6g + %d * ( %s + %.6g)" 
                            iSD  rightDummies "iPar(\"fingerLength\")" 2 * msContPoly + contSpan)  
                ) ; else if numberp fingerLength
           ) ; t
         ) ; cond sb

         ;; sd
         sd = 2 * msContPoly + contSpan

    unless(evnAreaNoDb evnAreaNoDb = evnArea)
    unless(oddAreaNoDb oddAreaNoDb = oddArea)
    unless(evnPerimNoDb evnPerimNoDb = evnPerim)
    unless(oddPerimNoDb oddPerimNoDb = oddPerim)

    if( sourceFirst then
    returnList =   list( nil
             'as        evnArea
             'ad        oddArea
             'ps        evnPerim
             'pd        oddPerim
             'asCdl        evnAreaNoDb
             'adCdl        oddAreaNoDb
             'psCdl        evnPerimNoDb
             'pdCdl        oddPerimNoDb
             'nrs       nrs
             'nrd       nrd
             'sa        sa
             'sb        sb
             'sd        sd
             'asd       if(numberp(evnArea) && numberp(oddArea) then evnArea+oddArea else strcat(evnArea "+" oddArea))
             'psd       if(numberp(evnPerim) && numberp(oddPerim) then evnPerim+oddPerim else strcat(evnPerim "+" oddPerim))
       )
    else
      returnList = list( nil
             'as        oddArea
             'ad        evnArea
             'ps        oddPerim
             'pd        evnPerim
             'asCdl        oddAreaNoDb
             'adCdl        evnAreaNoDb
             'psCdl        oddPerimNoDb
             'pdCdl        evnPerimNoDb
             'nrs       nrs
             'nrd       nrd
             'sa        sa
             'sb        sb
             'sd        sd
             'asd       if(numberp(evnArea) && numberp(oddArea) then evnArea+oddArea else strcat(evnArea "+" oddArea))
             'psd       if(numberp(evnPerim) && numberp(oddPerim) then evnPerim+oddPerim else strcat(evnPerim "+" oddPerim))
       )
    ) ; ** if sourceFirst **
   
    return( returnList)
    
  ) ; ** let **
) ; ** procedure ${template_libName}_mosCalcAreaPerim **

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


procedure(${template_libName}_calcCap( fingerWidth fingerLength numFinger 
                                ca cf dpt "gggggo" )

    prog( (capacitance area perim scale grid
          s value funName)
    
        scale = (dpt->scale || 1e-6 )
        grid = dpt->grid 
        funName = getCallingFunction(0) 

        foreach( s list('grid )
            value = symeval(s)
            if( value then
                set(s value * scale)
            else
                error(
                    "%s: invalid value for required device property '%s' - %L!"
                    funName s value
                )
            ) ; ** if value **
         ) ; ** foreach s **
    
        foreach( s list('fingerWidth 'numFinger 'fingerLength 'ca 'cf)
            value = symeval(s)
            caseq( type(value)
                ( string
                    set(s cdfParseFloatString( value ))
                )
                ( ( flonum fixnum ) t )
                ( t error("%s: invalid value for '%s' - %L" funName s value) )
            ) ; ** caseq type **
        ) ; ** foreach s **
    
        area = fingerWidth * fingerLength
        perim = 2 * (fingerWidth + fingerLength)
        capacitance = sprintf( nil "%.6g" numFinger * (ca * area + cf * perim))

        return( capacitance)
   ) ; prog

) ; procedure



procedure(${template_libName}_calcMetCap2(fingerWidth fingerLength nL)
        prog( (Wm1 Wm2 Wm3 Wm4 Wbus
          Sm1 Sm2 Sm3 Sm4 Sbus
                         Pm1 Pm2 Pm3 Pm4 Cm1gap Cm1p2
                         Cm1ep2e Sm1busmin gM1tobus
                         deltaC dWm2 Sbus2m2 Wbus2
                         SwideM2a SPab SwideM2b W L nx
                         Cm3gap Cm3m2 nm2 nm1 Weffm1 Lm1g16 Sgvar)
                
    L=fingerLength*1e06
    W=fingerWidth*1e06
         

         Wm1 = 0.14; 
         Sm1 = 0.15; 
         Pm1 = Wm1+Sm1;
    
         Wm2 = 0.18; 
         Sm2 = 0.15; 
         Pm2 = Wm2+Sm2;
    
         Wm3 = 0.21; 
         Sm3 = 0.18; 
         Pm3 = Wm3+Sm3;
         
    Wm4 = 0.21; 
         Sm4 = 0.18; 
         Pm4 = Wm4+Sm4;
    
         Wbus= 0.31; 
         Sbus=0.24;
         Sm1busmin=0.16; 
         dWm1=0.005
     
         case( nL ;cdfId->metalFingers->value
            ("M1"
                         Cm1gap = 1.178783e-15/(7*(5*Pm2));
                        Cm1p2 = 1.376538e-16/((Pm1*7)*(5*Pm2));
                        
            );M1
                 
            ("M1-M2"
            
                                Cm1gap = 1.058032e-15/(7*(5*Pm2));
                        Cm1p2 = 1.378616e-16/((Pm1*7)*(5*Pm2));
                  
        );M1-M2
         
                 ("M1-M3"
        Cm1gap = 1.038227e-15/(7*(5*Pm2));
        Cm1p2 = 1.390732e-16/((5*Pm3)*(5*Pm2));
       );M1-M3
                  
       ("M1-M4"
                 
          Cm1gap = 1.044735e-15/(7*(5*Pm2));
          Cm1p2 = 1.390562e-16/((5*Pm3)*(5*Pm2));
                  
       );M1-M4
         );case
         
         
         nM1 = int((L+2*dWm1-2*Sbus-Wbus-Sm1busmin-Wm1+0.0001)/Pm1);
                        Weffm1 = W-Wbus-2*Sm1+2*(Wm1+Sm1*2);
                        Lm1gvar = 0;    
                        Sm1gvar = 1;
            if(modulo(nM1 2) > 0 then
        Lm1gvar = W;
        
                  Sm1gvar = (L+2*dWm1-2*Sbus-Wbus-Wm1-nM1*Pm1);
                  
        if(Sm1gvar-Sbus > 0 then Sm1gvar = Sbus );
                  
            );if
         
         
    deltaC = Cm1gap * ((nM1*Weffm1) + W*2*Sm1/(Sm1+dWm1) + Lm1gvar*(Sm1/Sm1gvar)) + Cm1p2 * W*(nM1*Pm1);
       
    if(nL=="M1" then  return(sprintf(nil "%L" deltaC)))
                
                
         case( nL ;cdfId->metalFingers->value
                 
                  ("M1-M2"
                        
                      Cm2gap = 1.039242e-15/(5*(7*Pm1));
                      Cm2m1 = 1.321127e-16/((Pm1*7)*(5*Pm2));
                  
                  );M1-M2
                  
                  ("M1-M3"
                       Cm2gap = 9.657502e-16/(5*(5*Pm3));
                       Cm2m1 = 1.327659e-16/((5*Pm3)*(5*Pm2));
                  );M1-M3
                  
                  ("M1-M4"
                       Cm2gap = 9.624996e-16/(5*(5*Pm3));
                       Cm2m1 = 1.327135e-16/((5*Pm3)*(5*Pm2));
                  );M1-M4
    );case( nL         
     
          
          
         dWm2 = 0.17;        # M2 bus // L, outside S/D by this much
    Sbus2m2 = 0.24;     # M2 bus // L, usually this far from regular fingers;
    Sbusmm2 = 0.155;    # M2 bus // L, can be this close to regular fingers;
    Sbusme2 = 0.17;     # M2 bus // W, this far from end of fingers;
    Wwmax = 0.3201;   
         S2bwmax = 0.3401;
    Wemin = 2*dWm2+5*Pm2;
            
     
         nga3 = int((W+2*dWm2-Sbus2m2-Wm2-Sbusmm2)/Pm2+0.001);
    nga3w = int((W+2*dWm2-Sbus2m2-Wm2-Pm2-Sbus2m2)/Pm2+0.001);
    nga2 = int((W+2*dWm2-2*Sbus2m2-Wm2)/Pm2+0.001);
    nga2w = int((W+2*dWm2-2*Sbus2m2-Wm2-Pm2)/Pm2+0.001);
    if(W < Wemin then
        nga3 = int((Wemin+2*dWm2-Sbus2m2-Wm2-Sbusmm2)/Pm2+0.001);
        nga3w = int((Wemin+2*dWm2-Sbus2m2-Pm2-Sbus2m2)/Pm2+0.001);
        nga2 = int((Wemin+2*dWm2-2*Sbus2m2-Wm2)/Pm2+0.001);
        nga2w = 4;
    )
          
          
         nga3_m6 = modulo(nga3 6);     
         nga3_m5 = modulo(nga3_m6 5);
    nga2_m6 = modulo(nga2 6);      
         nga2_m3 = modulo(nga2_m6 3);
    nga3w_m6 = modulo(nga3w 6);   
         nga3w_m5 = modulo(nga3w_m6 5);
    nga2w_m6 = modulo(nga2w 6);    
         nga2w_m3 = modulo(nga2w_m6 3);
    Lwide = 0; 
         S2wide = 10; 
         S2bwide = S2wide;   
         Wwide = 0;  
         wa33 = 0;
                    
         if(nga3w_m5 == 0 then
        nM2 = nga3w;
        if(nga3w <= 6 then
            nM2 = 5;
        else 
                     if(nga3w_m6 == 0 then
            nM2 = nM2 - 1;
                  );if
                 );if
        
                  wa33 = 1;
    else 
         
            if(nga3_m5 == 0 then
        nM2 = nga3;
                  
        if(nga3-6 <= 0 then
            nM2 = 5;
        else 
                  
                          if(nga3_m6 == 0 then
            nM2 = nM2 - 1;
         );if
                 );if
                 
                 else
                          
                    if(nga2_m3 == 0 then
                        nM2 = nga2;
                  
                     else
                        
                         if(nga2w_m3 == 0 then
                  nM2 = nga2w;    
                          Lwide = L-Sbus-Sbusme2+0.5*Pm2;
          S2wide = Sm2;   
                         S2bwide = Sbus2m2;
          Wwide = W+2*dWm2-2*Sbus2m2-nM2*Pm2-Wm2-Sm2;
          if(Wwide > Wwmax then
            S2wide = Sbus2m2;   
                                Wwide = Wwide + (Sm2 - Sbus2m2);
          )
                         
                    else 
                                if(nga3w_m5-nga2w_m3 <= 0 then
                        nM2 = nga3w;
                if(nga3w-nga3w_m5 <= 6 then
            nM2 = 5;
                  else 
                           if(nga3w_m5 == nga3w_m6 then
            nM2 = nM2 - (nga3w_m5+1);
                                )
          );
        wa33 = 1;
                  
      else 
                 if(ga3_m5-nga2_m3 < 0 then
        nM2 = nga3-2;
       else
        nM2 = nga2;
      );if
                
)))));if        
                
                                
                if(wa33 > 0 then
        Lwide = L-Sbus-Sbusme2+0.5*Pm2;
        S2wide = Sm2;   S2bwide = Sbus2m2;
        Wwide = W+2*dWm2-2*Sbus2m2-nM2*Pm2-Wm2-Sm2;
        if(Wwide-Wwmax > 0 then
            S2bwide = S2bwide+Wwide-Wbus;   Wwide = Wbus;
                                
            if(S2bwide > S2bwmax then
                Wwide = S2bwide+Wwide+S2wide-2*Sbus2m2;
                S2wide = Sbus2m2;   S2bwide = Sbus2m2;
            )
                        )
                )

         Leffm2 = L-Wbus-Sbus+(Wm2+2*Sm2);
    ng6M2 = 2*int(nM2/6);
    deltaC = deltaC + Cm2gap * ((nM2-ng6M2)*Leffm2 + L*(ng6M2 + Sm2/Sbus2m2) + Lwide*(Sm2/S2wide + Sm2/S2bwide) + (nM2-ng6M2)*Pm2*Sm2/Sbus2m2);
    deltaC = deltaC + L*(W+Wwide) * Cm2m1;

         if(nL=="M1-M2" then  return(sprintf(nil "%L" deltaC)))
         
         
         if(nL=="M1-M3" then
        Cm3gap = 7.821431e-16/(5*(5*Pm2));
        Cm3m2 = 9.190076e-17/((5*Pm3)*(5*Pm2));
    else
                  if(nL=="M1-M4" then
        Cm3gap = 6.949190e-16/(5*(5*Pm2));
        Cm3m2 = 9.190285e-17/((5*Pm3)*(5*Pm2));
             );
        );
        
        
        dLm3 = 0.005; 
        dWm3=0.17;
   nM3 = int((L+2*dLm3-2*Sbus-Pm3-Wbus+0.0001)/Pm3);
   nM3b = int(nM3/3);
   Weffm3 = W+2*dWm3-2*Sbus-Wbus-2*Sm3+2*(Wm3+1.5*Sm3);
   Weffm3b = W+2*dWm3+2*Wbus-(Wbus+2*Sm3)+2*(Wm3+1.5*Sm3);
   Lm3gvar = 0;    
        Sm3gvar = 1;
        
        if(modulo(nM3 2) == 1 then
        Lm3gvar = W+2*dWm3-2*Sbus;
        Sm3gvar = (L+2*dLm3-2*Sbus-Wm3-nM3*Pm3-Wbus);
                  
        if(Sm3gvar > Sbus then Sm3gvar = Sbus)
    );
         
    deltaC = deltaC + Cm3gap * ((nM3-nM3b)*Weffm3+nM3b*Weffm3b + 2*(W+(nM3b+1)*Wm3)*(Sm3/Sbus) + Lm3gvar*(Sm3/Sm3gvar)) + Cm3m2 * W*(nM3*Pm3);
         
         if(nL=="M1-M3" then  return(sprintf(nil "%L" deltaC)))
         
         Cm4gap = 7.835351e-16/(4*(5*Pm3));
    Cm4m3 = 9.093581e-17/((5*Pm3)*(5*Pm2));
         
         dWm4 = 0.17;        # M4 bus // L, outside S/D by this much
    Sbus2m4 = 0.24;     # M4 bus // L, usually this far from regular fingers;

    Sbusmm4 = 0.185;    # M4 bus // L, can be this close to regular fingers;
    Sbusme4 = 0.17;     # M4 bus // W, this far from end of fingers;
    W4wmax = 0.3201;   
         S2bw4max = 0.3101;
    W4emin = 2*dWm4+5*Pm4;
         
         ng4a3 = int((W+2*dWm4-Sbus2m4-Wm4-Sbusmm4)/Pm4+0.001);
    ng4a3w = int((W+2*dWm4-Sbus2m4-Wm4-Pm4-Sbus2m4)/Pm4+0.001);
    ng4a2 = int((W+2*dWm4-2*Sbus2m4-Wm4)/Pm4+0.001);
    ng4a2w = int((W+2*dWm4-2*Sbus2m4-Wm4-Pm4)/Pm4+0.001);
         
         
         if(W < W4emin then
        ng4a3 = int((W4emin+2*dWm4-Sbus2m4-Wm4-Sbusmm4)/Pm4+0.001);
        ng4a3w = int((W4emin+2*dWm4-Sbus2m4-Pm4-Sbus2m4)/Pm4+0.001);
        ng4a2 = int((W4emin+2*dWm4-2*Sbus2m4-Wm4)/Pm4+0.001);
        ng4a2w = 4;
    )
         
         ng4a3_m6 = modulo(ng4a3 6);     
         ng4a3_m5 = modulo(ng4a3_m6 5);
    ng4a2_m6 = modulo(ng4a2 6);      
         ng4a2_m3 = modulo(ng4a2_m6 3);
    ng4a3w_m6 = modulo(ng4a3w  6);   
         ng4a3w_m5 = modulo(ng4a3w_m6 5);
    ng4a2w_m6 = modulo(ng4a2w 6);    
         ng4a2w_m3 = modulo(ng4a2w_m6 3);
         
         Lwide4 = 0; 
         S2wide4 = 10; 
         S2bwide4 = S2wide4;  
         Wwide4 = 0;  
         w4a33 = 0;
         
         if(ng4a3w_m5 == 0 then
        nM4 = ng4a3w;
        if(ng4a3w <= 6 then
            nM4 = 5;
        else 
                                  if(ng4a3w_m6 == 0 then
                    nM4 = nM4 - 1;
                                );if
        )
                  
        w4a33 = 1;
                  
    else 
         
                 if(ng4a3_m5 == 0 then
        nM4 = ng4a3;
        if(ng4a3-6 <= 0 then
            nM4 = 5;
        else 
                                  if(ng4a3_m6 == 0 then
            nM4 = nM4 - 1;
                       )
                  )
                  
      else
                        if(ng4a2_m3 == 0 then
           nM4 = ng4a2;
                   else
                          if(ng4a2w_m3 == 0 then
                          
                        nM4 = ng4a2w;   
                                  Lwide4 = L;
                        S2wide4 = Sm4;  
                                  S2bwide4 = Sbus2m4;
                        Wwide4 = W+2*dWm4-2*Sbus2m4-nM4*Pm4-Wm4-Sm4;
        
                if(Wwide4-W4wmax > 0 then
            S2wide4 = Sbus2m4;   
                                Wwide4 = Wwide4 + (Sm4 - Sbus2m4);
                  )
                    else 
                                if(ng4a3w_m5-ng4a2w_m3 <= 0 then
                        nM4 = ng4a3w;
                        if(ng4a3w-ng4a3w_m5 <= 6 then
                    nM4 = 5;
                        else 
                                          if (ng4a3w_m5 == ng4a3w_m6 then
                            nM4 = nM4 - (ng4a3w_m5+1);
                                         );if
                                 );if
        
                w4a33 = 1;
     else 
                  if(ng4a3_m5-ng4a2_m3 < 0 then
        nM4 = ng4a3-2;
                else 
              nM4 = ng4a2;
                )
        )))))
        
        if(w4a33 > 0 then
        Lwide4 = L;
        S2wide4 = Sm4;   
                  S2bwide4 = Sbus2m4;
        Wwide4 = W+2*dWm4-2*Sbus2m4-nM4*Pm4-Wm4-Sm4;
                  
        if(Wwide4 > W4wmax then
            S2bwide4 = S2bwide4+Wwide4-Wbus;   
                                Wwide4 = Wbus;
            
                                if(S2bwide4-S2bw4max > 0 then
                Wwide4 = S2bwide4+Wwide4+S2wide4-2*Sbus2m4;
                S2wide4 = Sbus2m4;   
                                         S2bwide4 = Sbus2m4;
            )
        )
    )
         
         
     Leffm4 = L-Wbus-Sbus+2*(Wm4+Sm4);
          
        
          
    ng6M4 = 2*int(nM4/6);
    deltaC = deltaC + Cm4gap * ((nM4-ng6M4)*Leffm4 + L*(ng6M4 + Sm4/Sbus2m4) + Lwide4*(Sm4/S2wide4 + Sm4/S2bwide4) + (nM4-ng6M4)*Pm4*Sm4/Sbus);
    
         deltaC = deltaC + L*(W+2*dWm4) * Cm4m3;
    
    return(sprintf(nil "%L" deltaC))        
                
        );prog         
);proc

procedure(${template_libName}_calcMetCap( fingerWidth fingerLength nL)
        prog( (Wm1 Wm2 Wm3 Wm4 Wbus
          Sm1 Sm2 Sm3 Sm4 Sbus
                         Pm1 Pm2 Pm3 Pm4 Cm1gap Cm1p2
                         Cm1ep2e Sm1busmin gM1tobus
                         deltaC dWm2 Sbus2m2 Wbus2
                         SwideM2a SPab SwideM2b W L nx
                         Cm3gap Cm3m2 nm2 nm1 Weffm1 Lm1g16 Sgvar)
                
         L=fingerLength*1e06
    W=fingerWidth*1e06

        Wm1 = 0.10; 
        Sm1 = 0.15; 
        Pm1 = Wm1+Sm1;
    Wm2 = 0.12; 
         Sm2 = 0.15; 
         Pm2 = Wm2+Sm2;
    Wm3 = 0.16; 
         Sm3 = 0.18; 
         Pm3 = Wm3+Sm3;
    Wm4 = 0.16; 
         Sm4 = 0.20; 
         Pm4 = Wm4+Sm4;
    Wbus1 = 0.22;   
         Wbus2 = 0.22;   
         Wbus3 = 0.32;   
         Wbus4 = 0.32;   
         Sbus=0.24;  
    Sm1busmin=0.18; 
         dWm1 = 0.035;


    case( nL ;cdfId->metalFingers->value
        ("M1"
                                  
                            Cm1gap = 9.831064e-16/(7*(5*Pm2));
            Cm1p2 = 1.029937e-16/((Pm1*7)*(5*Pm2));
                  );M1
                  
                  ("M1-M2"
                                  Cm1gap = 8.759779e-16/(7*(5*Pm2));
            Cm1p2 = 1.031920e-16/((Pm1*7)*(5*Pm2));
                  );M1-M2
                                    
                  ("M1-M3"
                                  Cm1gap = 8.765589e-16/(7*(5*Pm2));
            Cm1p2 = 1.030549e-16/((5*Pm3)*(5*Pm2));
                        );M1-M3
                  
                  ("M1-M4"
                                  
                                Cm1gap = 8.861890e-16/(7*(5*Pm2));
            Cm1p2 = 1.040743e-16/((5*Pm3)*(5*Pm2));
                  
                  );M1-M4
                  
          );case
        
      
         nM1 = int((L+2*dWm1-Sm1busmin-Sm1-Wm1-Sbus-Wbus1+0.0001)/Pm1);
    Weffm1 = W-Wbus1-2*Sm1+2*(Wm1+Sm1*2);
    Lm1gvar = 0;    
         Sm1gvar = 1;
    
         if(modulo(nM1 2) > 0 then
        Lm1gvar = W;
        Sm1gvar = (L+2*dWm1-Sm1busmin-Wm1-nM1*Pm1-Sbus-Wbus1);
        if(Sm1gvar-Sbus > 0 then Sm1gvar = Sbus)
    )
         
    deltaC = Cm1gap * ((nM1*Weffm1) + W*(Sm1/(Sm1+dWm1)+Sm1/Sbus) + Lm1gvar*(Sm1/Sm1gvar)) + Cm1p2 * W*(nM1*Pm1)
    
         if(nL=="M1" then  return(sprintf(nil "%L" deltaC)))
   
                          
         case( nL ;cdfId->metalFingers->value
                 
                  ("M1-M2"
                         Cm2gap = 8.701234e-16/(5*(7*Pm1));
                        Cm2m1 = 1.156624e-16/((Pm1*7)*(5*Pm2));
                  );M1-M2
                  
                  ("M1-M3"
                        Cm2gap = 8.094812e-16/(5*(5*Pm3));
                       Cm2m1 = 1.147361e-16/((5*Pm3)*(5*Pm2));
                  );M1-M3
                  
                  ("M1-M4"
                        Cm2gap = 7.986361e-16/(5*(5*Pm3));
                        Cm2m1 = 1.154241e-16/((5*Pm3)*(5*Pm2));
                  );M1-M4
                );case 
   
        
         
    dWm2 = 0.13;        # M2 bus // L, outside S/D by this much
    Sbus2m2 = 0.24;     # M2 bus // L, usually this far from regular fingers;
    Sbusmm2 = 0.155;    # M2 bus // L, can be this close to regular fingers;
    Sbusme2 = 0.16;     # M2 bus // W, this far from end of fingers;
    Wwmax = 0.3201;   
         S2bwmax = 0.3321; 
         Wwfix = 0.318;
    Wemin = 2*dWm2+5*Pm2;
    
    nga3 = int((W+2*dWm2-Sbus2m2-Wm2-Sbusmm2)/Pm2+0.001);
    nga3w = int((W+2*dWm2-Sbus2m2-Wm2-Pm2-Sbus2m2)/Pm2+0.001);
    nga2 = int((W+2*dWm2-2*Sbus2m2-Wm2)/Pm2+0.001);
    nga2w = int((W+2*dWm2-2*Sbus2m2-Wm2-Pm2)/Pm2+0.001);
    if(W < Wemin then
        nga3 = int((Wemin+2*dWm2-Sbus2m2-Wm2-Sbusmm2)/Pm2+0.001);
        nga3w = int((Wemin+2*dWm2-Sbus2m2-Pm2-Sbus2m2)/Pm2+0.001);
        nga2 = int((Wemin+2*dWm2-2*Sbus2m2-Wm2)/Pm2+0.001);
        nga2w = 4;
    )
    nga3_m6 = modulo(nga3 6);     
         nga3_m5 = modulo(nga3_m6 5);
    nga2_m6 = modulo(nga2 6);
         nga2_m3 = modulo(nga2_m6 3);
         
    nga3w_m6 = modulo(nga3w 6); 
         nga3w_m5 = modulo(nga3w_m6 5);
    nga2w_m6 = modulo(nga2w 6);    
         nga2w_m3 = modulo(nga2w_m6 3);
         Lwide = 0; 
         S2wide = 10; 
         S2bwide = S2wide;   
         Wwide = 0;  
         wa33 = 0;
    
         if(nga3w_m5 == 0 then
                 nM2 = nga3w;
        if(nga3w <= 6 then
            nM2 = 5;
        else 
                    if(nga3w_m6 == 0 then
            nM2 = nM2 - 1;
        ))
                  
        wa33 = 1;
                  
    else 
         
                 if(nga3_m5 == 0 then
        nM2 = nga3;
        if(nga3-6 <= 0 then
            nM2 = 5;
        else 
                     if(nga3_m6 == 0 then
            nM2 = nM2 - 1;
                        )
                        )
                        
                else
                   if(nga2_m3 == 0 then
           nM2 = nga2;
                          
                        else 
                          if(nga2w_m3 == 0 then
                        nM2 = nga2w;    
                        Lwide = L-Sbus-Sbusme2+0.5*Pm2;
                        S2wide = Sm2;   
                                S2bwide = Sbus2m2;
                        Wwide = W+2*dWm2-2*Sbus2m2-nM2*Pm2-Wm2-Sm2;
                                if(Wwide > Wwmax then
                            S2wide = Sbus2m2;   
                                                Wwide = Wwide + (Sm2 - Sbus2m2);
                                )
                                
                         else 
                           if(nga3w_m5-nga2w_m3 <= 0 then
                                nM2 = nga3w;
                                if(nga3w-nga3w_m5 <= 6 then
                 nM2 = 5;
                         )
                                        if(nga3w_m5 == nga3w_m6 then
                            nM2 = nM2 - (nga3w_m5+1);
                                         )
                                        
                                    wa33 = 1;                                        
            else
                                  if(nga3_m5-nga2_m3 < 0 then
                nM2 = nga3-2;
                             else
                                   nM2 = nga2;
                                 )
                                )
                         )
                        )
                  )
                 )
    
        
        if(wa33 > 0 then
        Lwide = L-Sbus-Sbusme2+0.5*Pm2;
        S2wide = Sm2;   
                  S2bwide = Sbus2m2;
        Wwide = W+2*dWm2-2*Sbus2m2-nM2*Pm2-Wm2-Sm2;
        if(Wwide-Wwmax > 0 then
            S2bwide = S2bwide+Wwide-Wwfix;   
                                Wwide = Wwfix;
            if(S2bwide > S2bwmax then
                Wwide = S2bwide+Wwide+S2wide-2*Sbus2m2;
                S2wide = Sbus2m2;   
                                         S2bwide = Sbus2m2;
            )
        )
    )
        
        Leffm2 = L-Wbus2-Sbus+(Wm2+2*Sm2);
    ng6M2 = 2*int(nM2/6);
    deltaC = deltaC + Cm2gap * ((nM2-ng6M2)*Leffm2 + L*(ng6M2 + Sm2/Sbus2m2) + Lwide*(Sm2/S2wide + Sm2/S2bwide));
    deltaC = deltaC + L*(W+Wwide) * Cm2m1;
         
    if(nL=="M1-M2" then  return(sprintf(nil "%L" deltaC)))
         
    
    if(nL=="M1-M3" then
        Cm3gap = 7.391130e-16/(5*(5*Pm2));
        Cm3m2 = 6.320570e-17/((5*Pm3)*(5*Pm2));
    else 
           if(nL=="M1-M4" then
        Cm3gap = 6.834739e-16/(5*(5*Pm2));
        Cm3m2 = 6.366357e-17/((5*Pm3)*(5*Pm2));
            )
         )
    
         dWm3 = 0.035;
         nM3 = int((L+2*dWm3+0.5*Wm3-Sbus-Wbus3-Sm3-0.5*Wm3+0.0001)/Pm3);
    Weffm3 = W-Wbus3-2*Sm3+2*(Wm3+Sm3*2);
    Lm3gvar = 0;    
         Sm3gvar = 1;
    
         if(modulo(nM3 2) == 0 then
        Lm3gvar = W;
        Sm3gvar = (L+2*dWm3-nM3*Pm3-Sbus-Wbus3);
        if(Sm3gvar-Sbus > 0 then Sm3gvar = Sbus);
    )
         
    deltaC = deltaC + Cm3gap * ((nM3*Weffm3) + W*(Sm3/Sbus) + Lm3gvar*(Sm3/Sm3gvar)) + Cm3m2 * W*(nM3*Pm3);
         
    if(nL=="M1-M3" then return(sprintf(nil "%L" deltaC)))
        
        
         Cm4gap = 7.862427e-16/(4*(5*Pm3));
    Cm4m3 = 6.329882e-17/((5*Pm3)*(5*Pm2));
  
    dWm4 = 0.13;        # M4 bus // L, outside S/D by this much
    Sbus2m4 = 0.24;     # M4 bus // L, usually this far from regular fingers;
    Sbusmm4 = 0.205;    # M4 bus // L, can be this close to regular fingers;
    Sbusme4 = 0.18;     # M4 bus // W, this far from end of fingers;
    W4wmax = 0.3201;   
         S2bw4max = 0.2821;
    ;# looks like a layout bug that requires this to be non-zero:
    dS22m4=0.14;
    W4emin = 2*dWm4+5*Pm4;
        
         ng4a3 = int((W+2*dWm4-Sbus2m4-Wm4-Sbusmm4)/Pm4+0.001);
    ng4a3w = int((W+2*dWm4-dS22m4-Sbus2m4-Wm4-Pm4-Sbus2m4)/Pm4+0.001);
    ng4a2 = int((W+2*dWm4-dS22m4-2*Sbus2m4-Wm4)/Pm4+0.001);
    ng4a2w = int((W+2*dWm4-2*Sbus2m4-Wm4-Pm4)/Pm4+0.001);
    if(W < W4emin then
        ng4a3 = int((W4emin+2*dWm4-Sbus2m4-Wm4-Sbusmm4)/Pm4+0.001);
        ng4a3w = int((W4emin+2*dWm4-Sbus2m4-Pm4-Sbus2m4)/Pm4+0.001);
        ng4a2 = 5;
        ng4a2w = 4;
    )
         
    ng4a3_m6 = modulo(ng4a3  6);
         ng4a3_m5 = modulo(ng4a3_m6 5)
    ng4a2_m6 = modulo(ng4a2 6);      
         ng4a2_m3 = modulo(ng4a2_m6 3);
    ng4a3w_m6 = modulo(ng4a3w 6);   
         ng4a3w_m5 = modulo(ng4a3w_m6 5);
    ng4a2w_m6 = modulo(ng4a2w 6);   
         ng4a2w_m3 = modulo(ng4a2w_m6 3);
         
    Lwide4 = 0; 
         S2wide4 = 10; 
         S2bwide4 = S2wide4;   
         Wwide4 = 0;  
         w4a33 = 0;
        
        
         if(ng4a3w_m5 == 0 then
        nM4 = ng4a3w;
        if(ng4a3w <= 6 then
            nM4 = 5;
        else 
                     if(ng4a3w_m6 == 0 then
            nM4 = nM4 - 1;
                  )
                        )
        w4a33 = 1;
    else 
         
                 if(ng4a3_m5 == 0 then
        nM4 = ng4a3;
        if(ng4a3-6 <= 0 then
            nM4 = 5;
        else 
                    if(ng4a3_m6 == 0 then
            nM4 =nM4 - 1;
          )
                        )
                        
            else 
                        if(ng4a2_m3 == 0 then
                          nM4 = ng4a2;
                        else
                          if(ng4a2w_m3 == 0 then
                                  nM4 = ng4a2w;   
                                Lwide4 = L-Sbus-Sbusme4+0.5*Pm4;
            S2wide4 = Sm4;  
                                S2bwide4 = Sbus2m4;
                                Wwide4 = W+2*dWm4-2*Sbus2m4-nM4*Pm4-Wm4-Sm4;
                                
                        if(Wwide4-W4wmax > 0 then
                            S2wide4 = Sbus2m4;   
                                                Wwide4 = Wwide4 + (Sm4 - Sbus2m4);
                        )
                         else        
                                if(ng4a3w_m5-ng4a2w_m3 <= 0 then        
                                nM4 = ng4a3w;
                              if(ng4a3w-ng4a3w_m5 <= 6 then
                            nM4 = 5;
                         else 
                                                if(ng4a3w_m5 == ng4a3w_m6 then
                                    nM4 = nM4 - (ng4a3w_m5+1);
                                                )
                                        )
        
                        w4a33 = 1;
                                
                                else
                                        if(ng4a3_m5-ng4a2_m3 <= 0 then
                                                nM4 = ng4a3-2;
                                    else
                                                nM4 = ng4a2;
                               )
                                 )
                           )         
                          )
                         )
                        )
        
                if(w4a33 > 0 then
        Lwide4 = L-Sbus-Sbusme4+0.5*Pm4;
        S2wide4 = Sm4;   
                  S2bwide4 = Sbus2m4;
        Wwide4 = W+2*dWm4-2*Sbus2m4-nM4*Pm4-Wm4-Sm4;
        if(Wwide4 > W4wmax then
            S2bwide4 = S2bwide4+Wwide4-Wbus4;   
                                Wwide4 = Wbus4;
            if(S2bwide4-S2bw4max > 0 then
                Wwide4 = S2bwide4+Wwide4+S2wide4-2*Sbus2m4;
                S2wide4 = Sbus2m4;   
                                         S2bwide4 = Sbus2m4;
            )
        )
     )

    Leffm4 = L-Wbus4-Sbus+(Wm4+2*Sm4);
    ng6M4 = 2*int(nM4/6);
    deltaC = deltaC + Cm4gap * ((nM4-ng6M4)*Leffm4 + L*(ng6M4 + Sm4/Sbus2m4) + Lwide4*(Sm4/S2wide4 + Sm4/S2bwide4));
    deltaC = deltaC + L*(W+Wwide4) * Cm4m3;
        
             
        return(sprintf(nil "%L" deltaC))
        );prog
);procedure(${template_libName}_calcMetCap
;#####
