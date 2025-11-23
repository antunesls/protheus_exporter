#Include "totvs.ch"

// Função para ser chamada nas rotinas Protheus
// Parâmetros opcionais: se não passar, ele tenta descobrir do ambiente
User Function PromTrackRoutine( cRoutine, cEnv, cCompany, cBranch, cModule, cUser )

    Local cBody     := ""
    Local oJson     := JsonObject():New()
    Local cResult   := ""
    Local nTimeOut  := 30
    Local aHeadOut  := {}
    Local cHeadRet  := ""
    Local cNome     := ""

    Local cURL := GetMV("XZ_TELMURL",,"") 


    If Empty(cRoutine)
        Return .F.
    EndIf

	// Aqui você pode plugar functions nativas do Protheus, ex:
	if Empty(cEnv)
		cEnv := GetEnvServer()           // ou FWGetEnv(), conforme seu padrão
	endif

	if Empty(cCompany)
		cCompany := cEmpAnt  // ou a empresa atual; ajuste à sua realidade
	endif

	if Empty(cBranch)
		cBranch := cFilAnt   // ajuste conforme seu ambiente
	endif

	if Empty(cModule)
		cModule := cModulo // ou outra forma de obter o módulo
	endif

	if Empty(cUser)
		cUser := Alltrim( UsrRetName() )       // ou RetCodUsr(), FWGetUser(), etc.
	endif

	// Obter nome completo do usuário
	cNome := Alltrim( UsrFullName(RetCodUsr()) )       // Nome completo do usuário

    

    // Monta JSON
    oJson["routine"]     := Upper(cRoutine)
    oJson["environment"] := Upper(cEnv)
    oJson["company"]     := cCompany
    oJson["branch"]      := cBranch
    oJson["module"]      := Upper(cModule)
    oJson["user"]        := Upper(cUser)
    oJson["user_name"]   := cNome

    cBody := oJson:ToJson()

    // Configura headers para JSON
    AAdd(aHeadOut, 'User-Agent: Mozilla/4.0 (compatible; Protheus ' + GetBuild() + ')')
    AAdd(aHeadOut, 'Content-Type: application/json')

    // Envia HTTP POST usando função nativa do Protheus
    cResult := HttpPost(cUrl, "", cBody, nTimeOut, aHeadOut, @cHeadRet)

    // Verifica se houve erro
    If Empty(cResult)
        ConOut("Erro ao enviar telemetria Prometheus para: " + cUrl)
        ConOut("Headers retornados: " + cHeadRet)
        Return .F.
    EndIf

    ConOut("Telemetria enviada com sucesso: " + cRoutine)

Return .T.
