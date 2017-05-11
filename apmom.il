procedure(PREFIX_mopCB(param)                          ;_Feb  8 06 quoc 1194
  let((procName cdfId libName cellName dpt grid scale sGrid epsilon
       minW maxW minL maxL minF maxF minM maxM todo paramId w l m fingers botlevMx toplevMx botlev toplev dwCap dlCap minArea maxArea
       )

    procName = "PREFIX_mopCB"
    cdfId = cdfgData
    caseq( concat(cdfId~>type)
       ((cellData baseCellData userCellData)
        libName = cdfId~>id~>lib~>name
        cellName = cdfId~>id~>name
       )
       (instData
        libName = cdfId~>id~>master~>libName
        cellName = cdfId~>id~>master~>cellName
       )
       (t
        PasAttention()
        error("%s: unexpected CDF data type - %L" procName cdfId~>type)
       )
    ) ; ** caseq concat **

    dpt = PasGetPdkParams(libName cellName)
    grid = dpt->grid
    scale = dpt->scale
    sGrid = grid*scale
    epsilon = sGrid/10.0
    minL = PREFIX_mopValue('l ?dpt dpt ?type 'min)
    maxL = PREFIX_mopValue('l ?dpt dpt ?type 'max)
    minF = PREFIX_mopValue('fingers ?dpt dpt ?type 'min)
    maxF = PREFIX_mopValue('fingers ?dpt dpt ?type 'max) 
    minM = PREFIX_mopValue('m ?dpt dpt ?type 'min)
    maxM = PREFIX_mopValue('m ?dpt dpt ?type 'max)
    minW = PREFIX_mopValue('w ?dpt dpt ?type 'min)
    maxW = PREFIX_mopValue('w ?dpt dpt ?type 'max)

    ;; process param argument
    todo = list(nil)
    caseq( param
       (l
        paramId = cdfId->l
        PasCdfValidateFloat(cdfId->l ?min minL ?max maxL ?grid sGrid ?mode 'extreme)
       )

       (fingers
        paramId = cdfId->fingers       
        PasCdfValidateInt(cdfId->fingers ?min minF ?max maxF ?mode 'extreme)
       )

       (w 
        paramId = cdfId->w 
        PasCdfValidateFloat(cdfId->w ?min minW ?max maxW ?mode 'extreme)
       )

       (m 
        paramId = cdfId->m     
        PasCdfValidateInt(cdfId->m ?min minM ?max maxM ?mode 'extreme)
       )
;add for momcap
       ( (botlev toplev)
        PasCdfValidateInt(paramId ?min 1 ?max 3 ?mode 'extreme)
      )

      ( (botlevMx toplevMx)
         botlevMx=cdfId->botlevMx->value
         toplevMx=cdfId->toplevMx->value
        case(botlevMx
                 ("M1" botlev=1)
                 ("M2" botlev=2)
                 ("M3" botlev=3)
                );case
        case(toplevMx
                 ("M1" toplev=1)
                 ("M2" toplev=2)
                 ("M3" toplev=3)
                );case
    if(botlev>toplev then 
     botlev=toplev 
     botlevMx=toplevMx
     );if
     PasCdfSetValue(cdfId->botlev botlev t)
     PasCdfSetValue(cdfId->toplev toplev t)
     PasCdfSetValue(cdfId->botlevMx botlevMx t)
     PasCdfSetValue(cdfId->toplevMx toplevMx t)
;PasCdfCommitValue(paramId)
      )

    ) ; ** caseq param **
    todo = reverse(todo)

;try to fix min area of apmom
    w = cdfParseFloatString(cdfId->w->value)
    l = cdfParseFloatString(cdfId->l->value)
    if( (cdfId~>id~>master~>cellName =="mom" ||cdfId~>id~>name=="mom") && numberp(w) && numberp(l) then
     dw = dpt->dwCap * scale
     dl = dpt->dlCap * scale
	 calculated_area = w * l
	 minA = dpt->minArea * scale * scale
	 maxA = dpt->maxArea * scale * scale
	  if(calculated_area >maxA || calculated_area<minA then
			w = dw
			l = dl
			PasWarn("Area of APMOM invalid, set to default value !")
	    )
	) 
     PasCdfSetValue(cdfId->w w) 
     PasCdfSetValue(cdfId->l l) 
	 
  ) ; ** let **
) ; ** procedure PREFIX_mopCB **


procedure(PREFIX_mopValue(           ;_Feb 18 03 quoc 1759
param 
@key 
(dpt nil) 
(id nil)       
(type 'default) 
(returnString nil)
(fingers nil)

)

  prog((procName libName cellName scale error_msg retValue)

    procName = "PREFIX_mopValue"

    ;; check required arguments
    cond(
       (dpt
        if( !tablep(dpt) then
           PasAttention()
           error("%s: ?dpt argument must be a table - %L" procName dpt)
        )
        libName = dpt->libName
        if( !libName then
           libName = "Unknown_Lib"
        )
        cellName = dpt->cellName
        if( !cellName then
           cellName = "Unknown_Cell"
        )
       )

       (id
        if( cdfIsId(id) then
           caseq( concat(id~>type)
              ((cellData baseCellData userCellData)
               libName = id~>id~>lib~>name
               cellName = id~>id~>name
              )
              (instData
               libName = id~>id~>master~>libName
               cellName = id~>id~>master~>cellName
              )
              (t
               PasAttention()
               error("%s: unexpected ?id argument - %L" procName id)
              )
           ) ; ** caseq concat **
           dpt = PasGetPdkParams(libName cellName)
        else
           PasAttention()
           error("%s: unexpected ?id argument - %L" procName id)
        ) ; ** if cdfIsId **
       )

       (t
        PasAttention()
        error("%s: either ?dpt or ?id argument must be specified" procName)
       )
    ) ; ** cond dpt **

    scale = dpt->scale
    if( numberp(scale) then
       scale = float(scale)
    else
       PasAttention()
       error("%s: scale property must be a number - %L" procName scale)
    ) ; ** if numberp **

    error_msg = "%s: '%s' value is not applicable to the '%s' parameter"

    ;; process param argument
    caseq( param
       (model
        caseq( type
           (default
            retValue = dpt->model
            if( !stringp(retValue) then
               retValue = ""
            )
           )
           (t
            PasAttention()
            error(error_msg procName type param)
           )
        ) ; ** caseq type **
       )


       (w
        caseq( type
           ((min minimum)
            retValue = dpt->mwCap
           )
           ((max maximum)
            retValue = dpt->xwCap
           )
           (default
            retValue = dpt->dwCap || dpt->mwCap
           )
           (t
            PasAttention()
            error(error_msg procName type param)
           )
        ) ; ** caseq type **
        if( retValue then
           if( numberp(retValue) then
              retValue = float(retValue)*scale
           else
              PasAttention()
              error("%s: %s width value for %s is not a number - %L"
                    procName type cellName retValue)
           ) ; ** if numberp **
        else
           PasAttention()
           error("%s: unable to determine the %s width for '%s/%s'"
                 procName type libName cellName)
        ) ; ** if retValue **
       )

       (l
        caseq( type
           ((min minimum)
            retValue = dpt->mlCap
           )
           ((max maximum)
            retValue = dpt->xlCap
           )
           (default
            retValue = dpt->dlCap || dpt->mlCap
           )
           (t
            PasAttention()
            error(error_msg procName type param)
           )
        ) ; ** caseq type **
        if( retValue then
           if( numberp(retValue) then
              retValue = float(retValue)*scale
           else
              PasAttention()
              error("%s: %s length value for %s is not a number - %L"
                    procName type cellName retValue)
           ) ; ** if numberp **
        else
           PasAttention()
           error("%s: unable to determine the %s length for '%s/%s'"
                 procName type libName cellName)
        ) ; ** if retValue **
       )



       (m
        caseq( type
           ((min minimum)
            retValue = 1
           )
           ((max maximum)
            retValue = dpt->maxM
           )
           (default
            retValue = 1
           )
           (t
            PasAttention()
            error(error_msg procName type param)
           )
        ) ; ** caseq type **
        if( retValue then
           if( numberp(retValue) then
              retValue = float(retValue)
           else
              PasAttention()
              error("%s: %s multiplier value for %s is not a number - %L"
                    procName type cellName retValue)
           ) ; ** if numberp **
        else
           PasAttention()
           error("%s: unable to determine the %s multiplier for '%s/%s'"
                 procName type libName cellName)
        ) ; ** if retValue **
       )

       (fingers
        caseq( type
           ((min minimum)
            retValue = 1
           )
           ((max maximum)
            retValue = dpt->maxFingers
           )
           (default
            retValue = 1
           )
           (t
            PasAttention()
            error(error_msg procName type param)
           )
        ) ; ** caseq type **
        if( retValue then
           if( numberp(retValue) then
              retValue = float(retValue)
           else
              PasAttention()
              error("%s: %s finger value for %s is not a number - %L"
                    procName type cellName retValue)
           ) ; ** if numberp **
        else
           PasAttention()
           error("%s: unable to determine the %s finger for '%s/%s'"
                 procName type libName cellName)
        ) ; ** if retValue **
       )


    ) ; ** caseq param **

    ;; format retValue
    if( returnString then
       caseq( type(retValue)
          (string
           ;; nothing to do
          )
          (flonum
           retValue = aelSuffixNotation(retValue 6)
           ;; retValue = sprintf(nil "%g" retValue)
          )
          (fixnum
           retValue = sprintf(nil "%d" retValue)
          )
          (t     ;; list, table, etc.
           retValue = sprintf(nil "%L" retValue)
          )
       ) ; ** caseq type **
    ) ; ** if returnString **

    return(retValue)
  ) ; ** prog **
) ; ** procedure PREFIX_mopValue **


procedure(PREFIX_mopDisplay(param)                  ;_Feb 18 03 quoc 668
  prog((retValue cdfId cv)

    retValue = nil
    cdfId = cdfgData
    cv = geGetEditCellView()

    caseq( param
       (showSimParams
        if( cv~>cellViewType == "maskLayout" then
           retValue = t
        )
       )

       ( model 
        if( cv~>cellViewType != "maskLayout" || cdfId~>showSimParams~>value then
           retValue = t
        )
       )


    ) ; ** caseq param **

    return(retValue)
  ) ; ** prog **
) ; ** procedure PREFIX_mopDisplay **

