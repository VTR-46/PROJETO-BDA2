-- F5 como dono. Sem COMMIT: as alterações abaixo são revertidas, inclusive em erro.
SET DEFINE OFF
SET SERVEROUTPUT ON
DECLARE
    v_id NUMBER;
    v_versao NUMBER;
    v_i tab_indicador_municipio%ROWTYPE;
    v_logs NUMBER;
    v_novos NUMBER;
BEGIN
    SAVEPOINT sp_demonstracao;
    SELECT id_programa INTO v_id FROM tab_programa WHERE codigo='PBA';
    SELECT versao INTO v_versao FROM tab_municipio_programa
    WHERE id_municipio=1500800 AND id_programa=v_id AND ano_referencia=2025;
    -- Somente retifica a justificativa para demonstrar o controle de versão.
    pr_registrar_oferta(1500800,v_id,2025,13,NULL,NULL,
        'https://www.ananindeua.pa.gov.br/secdh/noticia/8608/programa-brasil-alfabetizado-em-ananindeua-o-conhecimento-e-um-direito-para-todos',
        DATE '2025-02-12',DATE '2026-11-24',v_versao,'Demonstração temporária, será revertida.',v_versao);
    DBMS_OUTPUT.PUT_LINE('Versão da oferta temporária: ' || v_versao);
    SELECT * INTO v_i FROM tab_indicador_municipio WHERE id_municipio=1500800;
    SELECT COUNT(*) INTO v_logs FROM tab_auditoria_indicador;
    -- Todos os valores originais são preservados, exceto uma renda temporária.
    pr_atualizar_indicadores(v_i.id_municipio,v_i.total_alfabetizacao,v_i.nao_alfabetizados,
        v_i.total_escolaridade,v_i.baixa_escolaridade,NVL(v_i.renda_media,0)+1,v_i.versao,v_versao);
    SELECT COUNT(*) INTO v_novos FROM tab_auditoria_indicador;
    IF v_novos <> v_logs+1 THEN RAISE_APPLICATION_ERROR(-20012,'Auditoria não registrada.'); END IF;
    DBMS_OUTPUT.PUT_LINE('Auditoria transacional registrada. Testando versão antiga...');
    BEGIN
        pr_atualizar_indicadores(v_i.id_municipio,v_i.total_alfabetizacao,v_i.nao_alfabetizados,
            v_i.total_escolaridade,v_i.baixa_escolaridade,v_i.renda_media,v_i.versao,v_versao);
        RAISE_APPLICATION_ERROR(-20012,'Conflito não detectado.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE <> -20005 THEN RAISE; END IF;
        DBMS_OUTPUT.PUT_LINE('Conflito rejeitado corretamente (-20005).');
    END;
    ROLLBACK TO sp_demonstracao;
    SELECT COUNT(*) INTO v_novos FROM tab_auditoria_indicador;
    IF v_novos <> v_logs THEN RAISE_APPLICATION_ERROR(-20012,'Log não revertido.'); END IF;
    DBMS_OUTPUT.PUT_LINE('Demonstração concluída; dados e logs temporários revertidos.');
EXCEPTION WHEN OTHERS THEN ROLLBACK TO sp_demonstracao; RAISE;
END;
/
