"""Integração Oracle opt-in, exclusivamente em esquema MAPA_TEST_* já instalado.

Defina PLSQL_TEST_USER, PLSQL_TEST_PASSWORD e PLSQL_TEST_DSN. Fixtures são
revertidas; concorrência usa somente um indicador de fixture confirmado.
"""
import json
import os
import unittest
from pathlib import Path
from threading import Event
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

import oracledb


@unittest.skipUnless(os.getenv('PLSQL_TEST_USER'), 'Requer esquema Oracle isolado PLSQL_TEST_*')
class PlsqlTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        user = os.environ['PLSQL_TEST_USER']
        if not user.upper().startswith('MAPA_TEST_'):
            raise ValueError('Testes de escrita exigem usuário MAPA_TEST_*; nunca use o esquema real.')
        cls.config = dict(user=user, password=os.environ['PLSQL_TEST_PASSWORD'],
                          dsn=os.environ['PLSQL_TEST_DSN'])

    def setUp(self):
        self.connection = oracledb.connect(**self.config)
        self.addCleanup(self.connection.close)
        self.cursor = self.connection.cursor()
        self.addCleanup(self.cursor.close)
        self.addCleanup(self.connection.rollback)
        self.cursor.execute('SAVEPOINT fixture')
        self.now = datetime(2026, 11, 24)

    def scalar(self, sql, binds=None):
        self.cursor.execute(sql, binds or {})
        return self.cursor.fetchone()[0]

    def error(self, code, operation):
        with self.assertRaises(oracledb.DatabaseError) as caught:
            operation()
        self.assertEqual(caught.exception.args[0].code, abs(code))

    def program(self, code='TESTE', uf=None):
        out = self.cursor.var(oracledb.NUMBER)
        self.cursor.callproc('pr_salvar_programa', [code, 'Fixture', 'Teste', 'Adultos e idosos',
            'ESTADUAL' if uf else 'NACIONAL', uf, 'https://example.org/fonte', self.now, out])
        return out.getvalue()

    def offer(self, program, municipality=1500800, version=None, turmas=2):
        out = self.cursor.var(oracledb.NUMBER)
        self.cursor.callproc('pr_registrar_oferta', [municipality, program, 2025, turmas,
            None, None, 'https://example.org/fonte', datetime(2025, 2, 12), self.now,
            version, 'Fixture revertida ao final do teste', out])
        return out.getvalue()

    def indicator(self, code=1500800, version=1, income=100):
        out = self.cursor.var(oracledb.NUMBER)
        self.cursor.callproc('pr_atualizar_indicadores', [code,100,25,200,120,income,version,out])
        return out.getvalue()

    def test_objects_and_seed(self):
        self.assertEqual(self.scalar('SELECT COUNT(*) FROM user_tables'),9)
        self.assertEqual(self.scalar("SELECT COUNT(*) FROM user_objects WHERE object_type IN ('FUNCTION','PROCEDURE','TRIGGER') AND status='VALID'"),7)
        self.assertEqual(self.scalar('SELECT COUNT(*) FROM user_errors'),0)
        self.assertEqual(self.scalar('SELECT COUNT(*) FROM tab_programa'),2)
        self.assertEqual(self.scalar('SELECT COUNT(*) FROM tab_municipio_programa'),3)
        self.assertEqual(self.scalar("SELECT qtd_turmas FROM vw_programas_municipio WHERE codigo='PBA' AND id_municipio=1500800"),13)
        self.assertIsNone(self.scalar("SELECT qtd_turmas FROM vw_programas_municipio WHERE codigo='PBA' AND id_municipio=5101803"))

    def test_seed_preserves_corrections(self):
        program = self.scalar("SELECT id_programa FROM tab_programa WHERE codigo='PBA'")
        self.offer(program,version=1,turmas=14)
        seed = (Path(__file__).resolve().parent.parent / 'Oracle' / '17_programas_reais.sql').read_text(encoding='utf-8')
        self.error(20011,lambda: self.cursor.execute(seed.rstrip().removesuffix('/').rstrip()))
        self.assertEqual(self.scalar('SELECT qtd_turmas FROM tab_municipio_programa WHERE id_municipio=1500800 AND id_programa=:p',{'p':program}),14)

    def test_functions(self):
        for part,total,expected in [(1,3,33.33),(0,10,0),(None,10,None),(0,0,None),(5,None,None)]:
            self.assertEqual(self.cursor.callfunc('fn_percentual',oracledb.NUMBER,[part,total]),expected)
        for part,total in [(-1,10),(11,10),(0,-1)]:
            self.error(20001,lambda: self.cursor.callfunc('fn_percentual',oracledb.NUMBER,[part,total]))
        self.assertEqual(self.cursor.callfunc('fn_validar_indicadores',oracledb.NUMBER,[None,None,100,None,None]),1)
        for args in [(100,None,100,10,0),(None,1,100,10,0),(100,101,100,10,0),
                     (100,1,None,1,0),(1.5,1,100,10,0),(100,1,100,10,-1)]:
            self.error(20002,lambda: self.cursor.callfunc('fn_validar_indicadores',oracledb.NUMBER,args))

    def test_program_and_offer_versions(self):
        p = self.program()
        self.assertEqual(self.program(),p)
        self.assertEqual(self.offer(p),1)
        self.assertEqual(self.offer(p,version=1),1)
        self.assertEqual(self.offer(p,version=1,turmas=3),2)
        self.error(20005,lambda: self.offer(p,version=1,turmas=4))
        self.error(20005,lambda: self.offer(p))
        self.error(20007,lambda: self.program(uf=51))

    def test_scope_and_direct_dml(self):
        p = self.program(uf=51)
        self.error(20009,lambda: self.offer(p))
        self.assertEqual(self.offer(p,municipality=5101803),1)
        self.error(20008,lambda: self.cursor.execute('UPDATE tab_municipio_programa SET ano_referencia=2024 WHERE id_programa=:p',p=p))
        self.error(20009,lambda: self.cursor.execute('''INSERT INTO tab_municipio_programa
            (id_municipio,id_programa,ano_referencia,fonte_url,publicado_em,consultado_em,justificativa)
            VALUES(1500800,:p,2025,'https://example.org',DATE '2025-01-01',DATE '2026-11-24','teste')''',p=p))
        self.error(20003,lambda: self.offer(p,municipality=9999999))

    def test_audit_noop_and_rollback(self):
        v = self.scalar('SELECT versao FROM tab_indicador_municipio WHERE id_municipio=1500800')
        before = self.scalar('SELECT COUNT(*) FROM tab_auditoria_indicador')
        self.assertEqual(self.indicator(version=v),v+1)
        self.assertEqual(self.indicator(version=v+1),v+1)
        self.assertEqual(self.scalar('SELECT COUNT(*) FROM tab_auditoria_indicador'),before+1)
        self.cursor.execute('SELECT anterior,novo,usuario FROM tab_auditoria_indicador ORDER BY id_auditoria DESC FETCH FIRST 1 ROW ONLY')
        old,new,user = self.cursor.fetchone()
        self.assertEqual(json.loads(new.read())['nao_alfabetizados'],25)
        self.assertEqual(json.loads(old.read())['versao'],v)
        self.assertEqual(user,self.config['user'].upper())
        self.error(20005,lambda: self.indicator(version=v,income=200))
        self.error(20002,lambda: self.cursor.execute('UPDATE tab_indicador_municipio SET nao_alfabetizados=NULL WHERE id_municipio=1500800'))
        self.cursor.execute('ROLLBACK TO fixture')
        self.assertEqual(self.scalar('SELECT COUNT(*) FROM tab_auditoria_indicador'),before)
        self.assertEqual(self.scalar('SELECT versao FROM tab_indicador_municipio WHERE id_municipio=1500800'),v)

    def test_audit_insert_delete(self):
        self.cursor.execute('DELETE FROM tab_indicador_municipio WHERE id_municipio=1500800')
        self.cursor.execute('INSERT INTO tab_indicador_municipio(id_municipio) VALUES(1500800)')
        self.cursor.execute("SELECT operacao FROM tab_auditoria_indicador WHERE id_municipio=1500800 ORDER BY id_auditoria DESC FETCH FIRST 2 ROWS ONLY")
        self.assertEqual([r[0] for r in self.cursor.fetchall()],['INSERT','DELETE'])

    def test_no_commit_and_savepoint(self):
        p = self.program()
        self.error(20009,lambda: self.offer(self.program(code='ESTADUAL',uf=51)))
        self.assertEqual(self.scalar('SELECT COUNT(*) FROM tab_programa WHERE id_programa=:p',{'p':p}),1)
        with oracledb.connect(**self.config) as other:
            with other.cursor() as q:
                q.execute("SELECT COUNT(*) FROM tab_programa WHERE codigo='TESTE'")
                self.assertEqual(q.fetchone()[0],0)

    def test_concurrent_stale_version(self):
        # Fixture isolada confirmada para que outra sessão possa vê-la.
        self.cursor.execute("INSERT INTO tab_municipio(id_municipio,nome,id_uf) VALUES(9999998,'Fixture concorrencia',15)")
        self.cursor.execute('INSERT INTO tab_indicador_municipio(id_municipio) VALUES(9999998)')
        self.connection.commit()
        try:
            self.assertEqual(self.indicator(code=9999998),2)
            started = Event()
            def competing_update():
                with oracledb.connect(**self.config) as other:
                    other.call_timeout=10000
                    with other.cursor() as q:
                        result=q.var(oracledb.NUMBER)
                        try:
                            started.set()
                            q.callproc('pr_atualizar_indicadores',[9999998,100,25,200,120,200,1,result])
                        except oracledb.DatabaseError as e:
                            return e.args[0].code
                        return 0
            with ThreadPoolExecutor(max_workers=1) as pool:
                future=pool.submit(competing_update)
                self.assertTrue(started.wait(timeout=5))
                # A segunda sessão deve aguardar o bloqueio da primeira.
                with self.assertRaises(TimeoutError):
                    future.result(timeout=0.2)
                self.connection.commit()
                self.assertEqual(future.result(timeout=15),20005)
        finally:
            self.connection.rollback()
            self.cursor.execute('DELETE FROM tab_indicador_municipio WHERE id_municipio=9999998')
            self.cursor.execute('DELETE FROM tab_municipio WHERE id_municipio=9999998')
            self.cursor.execute('DELETE FROM tab_auditoria_indicador WHERE id_municipio=9999998')
            self.connection.commit()


if __name__ == '__main__':
    unittest.main()
