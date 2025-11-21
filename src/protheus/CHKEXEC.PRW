#Include 'TOTVS.CH'

User Function CHKEXEC()
    Local cRoutine := ""
    
    // Obtem o nome da rotina via ParamIXB
    cRoutine := ParamIXB
    
    // Se foi passado o nome da rotina, envia para metrics
    If !Empty(cRoutine)
        // Chama a função de incremento de métricas
        
        u_PromTrackRoutine(cRoutine)

    EndIf
    
return .T.
