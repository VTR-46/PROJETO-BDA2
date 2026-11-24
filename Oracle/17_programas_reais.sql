-- Recorte documental consultado em 24/11/2026. Repetir não desfaz retificações.
-- Não há estimativa de participantes idosos, orçamento ou efeito sobre o Censo.
DECLARE
    v_pba NUMBER;
    v_mux NUMBER;
    v_versao NUMBER;
    v_existe NUMBER;
    v_url_barra VARCHAR2(2000) := 'https://educacao.barradogarcas.mt.gov.br/Imprensa/Noticias/Secretaria-municipal-de-educacao-celebra-inicio-das-aulas-dos-programas-mais-mt-muxirum-e-brasil-alfabetizado-205/';
    v_url_anan VARCHAR2(2000) := 'https://www.ananindeua.pa.gov.br/secdh/noticia/8608/programa-brasil-alfabetizado-em-ananindeua-o-conhecimento-e-um-direito-para-todos';
    PROCEDURE carregar(p_municipio NUMBER,p_programa NUMBER,p_turmas NUMBER,p_url VARCHAR2,p_publicacao DATE) IS
        v_o tab_municipio_programa%ROWTYPE;
    BEGIN
        BEGIN
            SELECT * INTO v_o FROM tab_municipio_programa WHERE id_municipio=p_municipio
                AND id_programa=p_programa AND ano_referencia=2025;
            IF NVL(v_o.qtd_turmas,-1)<>NVL(p_turmas,-1) OR v_o.participantes_total IS NOT NULL
                OR v_o.participantes_60mais IS NOT NULL OR v_o.fonte_url<>p_url
                OR v_o.publicado_em<>p_publicacao THEN
                RAISE_APPLICATION_ERROR(-20011, 'Carga diverge de oferta existente; revise explicitamente antes de retificar.');
            END IF;
            RETURN;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL; END;
        pr_registrar_oferta(p_municipio,p_programa,2025,p_turmas,NULL,NULL,p_url,
            p_publicacao,DATE '2026-11-24',NULL,'Carga documental oficial; quantidades não publicadas permanecem NULL.',v_versao);
    END;
BEGIN
    SAVEPOINT sp_carga_programas;
    SELECT COUNT(*) INTO v_existe FROM tab_programa WHERE codigo='PBA';
    IF v_existe=0 THEN
        pr_salvar_programa('PBA','Programa Brasil Alfabetizado','MEC / FNDE',
            'Jovens de 15 anos ou mais, adultos e idosos não alfabetizados.','NACIONAL',NULL,
            'https://www.gov.br/fnde/pt-br/acesso-a-informacao/acoes-e-programas/programas/programas_suplementares/eja/pba',
            DATE '2026-11-24',v_pba);
    ELSE SELECT id_programa INTO v_pba FROM tab_programa WHERE codigo='PBA'; END IF;
    SELECT COUNT(*) INTO v_existe FROM tab_programa WHERE codigo='MAIS_MT_MUXIRUM';
    IF v_existe=0 THEN
        pr_salvar_programa('MAIS_MT_MUXIRUM','Mais MT Muxirum','Seduc-MT',
            'Jovens de 15 anos ou mais, adultos e idosos não alfabetizados.','ESTADUAL',51,
            'https://www5.sefaz.mt.gov.br/web/seduc/w/munic%C3%ADpios-participantes-do-programa-mais-mt-muxirum-devem-indicar-coordenadores-locais-e-selecionar-alfabetizadores',
            DATE '2026-11-24',v_mux);
    ELSE SELECT id_programa INTO v_mux FROM tab_programa WHERE codigo='MAIS_MT_MUXIRUM'; END IF;
    -- As 43 turmas da notícia de Barra do Garças são conjuntas, não por programa.
    carregar(5101803,v_pba,NULL,v_url_barra,DATE '2025-05-09');
    carregar(5101803,v_mux,NULL,v_url_barra,DATE '2025-05-09');
    carregar(1500800,v_pba,13,v_url_anan,DATE '2025-02-12');
EXCEPTION WHEN OTHERS THEN ROLLBACK TO sp_carga_programas; RAISE;
END;
/
