// Testes de comportamento do painel, com DOM e rede simulados, sem dependências.
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { test } = require('node:test');
const vm = require('node:vm');

class Element {
  constructor(tag = 'div') {
    this.tagName = tag; this.children = []; this.events = {}; this.attributes = {};
    this.textContent = ''; this.value = ''; this.hidden = false; this.style = {};
  }
  append(...children) { this.children.push(...children); }
  replaceChildren(...children) { this.children = children; }
  setAttribute(name, value) { this.attributes[name] = value; }
  addEventListener(event, fn) { this.events[event] = fn; }
  scrollIntoView() {}
  querySelector() { return this.button ||= new Element('button'); }
  get childElementCount() { return this.children.length; }
}

function interfaceSimulada() {
  const elements = new Map();
  const document = {
    getElementById(id) { if (!elements.has(id)) elements.set(id, new Element()); return elements.get(id); },
    createElement(tag) { return new Element(tag); }
  };
  const context = vm.createContext({ document, URL, L: {
    map: () => ({ events: {}, on(event, fn) { this.events[event] = fn; }, fitBounds() {}, removeLayer() {} }),
    geoJSON: (geo, opts = {}) => {
      const layers = (geo?.features || []).map(feature => {
        const layer = {
          events: {}, style: opts.style ? opts.style(feature) : {}, frontCount: 0,
          setStyle(s) { this.style = s; },
          on(ev, fn) { this.events[ev] = fn; },
          bindTooltip() {},
          closeTooltip() { this.tooltipOpen = false; },
          bringToFront() { this.frontCount++; },
          getBounds: () => []
        };
        opts.onEachFeature?.(feature, layer);
        return layer;
      });
      return { layers, addTo() { return this; }, getBounds: () => [], eachLayer(fn) { layers.forEach(fn); } };
    }
  }, fetch: () => new Promise(() => {}) });
  vm.runInContext(readFileSync(join(__dirname, '../static/app.js'), 'utf8'), context);
  return { context, elements, run: code => vm.runInContext(code, context) };
}

const cityA = { id_municipio: 3550308, nome: 'São Paulo', uf: 'SP' };
const cityB = { id_municipio: 5101837, nome: 'Boa Esperança do Norte', uf: 'MT' };
function resposta(city, texto = 'Contexto histórico e hipóteses.') {
  return { municipio: city, indicadores: { taxa_analfabetismo: null, renda_media: 1500, percentual_baixa_escolaridade: 60 },
    resposta: texto, fontes: [], sugestoes_busca: [], gerado_em: '2026-11-17T12:00:00+00:00' };
}
const http = data => ({ ok: true, json: async () => data });
const flush = () => new Promise(resolve => setImmediate(resolve));
function selecionar(ui, city) { ui.context.city = city; ui.run('selectCity(city)'); }
function clicarPesquisa(ui) { ui.elements.get('details').children.at(-1).events.click(); }
function todos(element) { return [element, ...element.children.flatMap(todos)]; }

test('PNAD mostra rótulos do banco, fonte única e somente links seguros', async () => {
  for (const [url, year, links] of [[null, null, 0], ['javascript:alert(1)', null, 0], ['https://example.org/pnad', 2020, 1]]) {
    const ui = interfaceSimulada();
    const source = { fonte: 'Amostra PNAD do projeto', ano_fonte: year, fonte_url: url };
    ui.context.fetch = async () => http([
      { escolaridade: 'Nome no catálogo', renda_media: null, total_amostra: 3, amostra_com_renda: 0, ...source },
      { escolaridade: 'Outro nível', renda_media: 100, total_amostra: 4, amostra_com_renda: 1, ...source }
    ]);
    await ui.run('loadPnad()');
    const chart = ui.elements.get('pnad-chart');
    assert.equal(chart.children[0].children[0].textContent, 'Nome no catálogo');
    assert.equal(chart.children[0].children[1].children[0].style.width, '0%');
    const note = ui.elements.get('pnad-note');
    assert.equal(note.children.length, 1);
    assert.match(note.children[0].textContent, /Amostra PNAD do projeto/);
    assert.ok(note.children[0].textContent.includes(year == null ? 'Ano não informado' : 'Ano: 2020'));
    assert.equal(todos(note).filter(node => node.tagName === 'a').length, links);
  }
});

test('bloqueia duplicação e exibe texto seguro, fontes e sugestões isoladas', async () => {
  const ui = interfaceSimulada();
  let resolve, calls = 0;
  ui.context.fetch = () => { calls++; return new Promise(done => { resolve = done; }); };
  selecionar(ui, cityA); clicarPesquisa(ui); clicarPesquisa(ui);
  assert.equal(calls, 1);
  assert.equal(ui.elements.get('research-form').querySelector().disabled, true);
  const data = resposta(cityA, '<script>alert(1)</script> Educação: São Paulo');
  data.fontes = [{ titulo: 'Fonte', url: 'https://www.ibge.gov.br/', trecho: 'Educação: São Paulo' },
    { titulo: 'Inválida', url: 'javascript:alert(1)', trecho: 'Ignorar' }];
  data.sugestoes_busca = ['<div>Pesquisa Google</div>'];
  resolve(http(data)); await flush();
  const nodes = todos(ui.elements.get('research-conversation'));
  assert.equal(nodes.find(n => n.className === 'research-text').textContent, data.resposta);
  assert.equal(nodes.filter(n => n.tagName === 'a').length, 1);
  assert.equal(nodes.find(n => n.tagName === 'a').rel, 'noopener noreferrer');
  const frame = nodes.find(n => n.tagName === 'iframe');
  assert.equal(frame.attributes.sandbox, 'allow-popups allow-popups-to-escape-sandbox');
  assert.equal(frame.srcdoc, '<base target="_blank">' + data.sugestoes_busca[0]);
  assert.match(nodes.find(n => n.className === 'source-note').textContent, /Sem dados/);
  assert.equal(ui.elements.get('research-form').hidden, false);
});

test('resposta atrasada fica no município correto e o retorno usa o relatório salvo', async () => {
  const ui = interfaceSimulada(), pending = [];
  ui.context.fetch = () => new Promise(resolve => pending.push(resolve));
  selecionar(ui, cityA); clicarPesquisa(ui);
  selecionar(ui, cityB);
  assert.equal(ui.elements.get('research-panel').hidden, true);
  pending[0](http(resposta(cityA, 'Relatório A'))); await flush();
  assert.equal(ui.elements.get('research-panel').hidden, true);
  clicarPesquisa(ui);
  pending[1](http(resposta(cityB, 'Relatório B'))); await flush();
  assert.match(ui.elements.get('research-heading').textContent, /Boa Esperança/);
  selecionar(ui, cityA); clicarPesquisa(ui);
  assert.equal(pending.length, 2);
  assert.match(ui.elements.get('research-heading').textContent, /São Paulo/);
  assert.equal(todos(ui.elements.get('research-conversation')).find(n => n.className === 'research-text').textContent, 'Relatório A');
  ui.run('resetMap()');
  assert.equal(ui.elements.get('research-panel').hidden, true);
});

test('perguntas enviam o relatório e apenas as últimas cinco trocas do município', async () => {
  const ui = interfaceSimulada(), requests = [];
  ui.context.fetch = async (url, options) => {
    requests.push({ url, ...JSON.parse(options.body) });
    return http(resposta(url.includes(String(cityB.id_municipio)) ? cityB : cityA,
      requests.length === 1 ? 'Relatório original' : 'Resposta ' + requests.length));
  };
  selecionar(ui, cityA); clicarPesquisa(ui); await flush();
  for (let i = 0; i < 7; i++) await ui.run(`runResearch(selectedCity, 'Pergunta ${i}')`);
  const last = requests.at(-1);
  assert.equal(last.url, '/api/municipios/3550308/pesquisa');
  assert.equal(last.historico.length, 11);
  assert.deepEqual(last.historico[0], { role: 'assistant', content: 'Relatório original' });
  assert.deepEqual(last.historico[1], { role: 'user', content: 'Pergunta 1' });
  assert.equal(last.pergunta, 'Pergunta 6');
  selecionar(ui, cityB); clicarPesquisa(ui); await flush();
  assert.equal(requests.at(-1).historico, undefined);
});

test('carregar outra UF limpa uma seleção feita no mapa antigo durante a espera', async () => {
  const ui = interfaceSimulada(), pending = [];
  ui.context.fetch = async () => http(resposta(cityA));
  selecionar(ui, cityA); clicarPesquisa(ui); await flush();
  ui.context.fetch = () => new Promise(resolve => pending.push(resolve));
  const loading = ui.run("loadUf('MT')");
  assert.equal(ui.elements.get('research-panel').hidden, true);
  selecionar(ui, cityA);
  assert.equal(ui.elements.get('research-panel').hidden, false);
  pending[0](http({ features: [] })); pending[1](http([]));
  await loading;
  assert.equal(ui.elements.get('research-panel').hidden, true);
  assert.equal(ui.run('selectedCity'), null);
});

test('falhas permitem tentar de novo e preservam a pergunta sem fontes inventadas', async () => {
  const ui = interfaceSimulada();
  ui.context.fetch = async () => ({ ok: false, json: async () => ({ erro: 'Configure GEMINI_API_KEY' }) });
  selecionar(ui, cityA); clicarPesquisa(ui); await flush();
  assert.equal(ui.elements.get('research-retry').hidden, false);
  assert.match(ui.elements.get('research-status').textContent, /GEMINI_API_KEY/);
  ui.context.fetch = async () => http(resposta(cityA));
  ui.elements.get('research-retry').events.click(); await flush();
  assert.equal(ui.elements.get('research-retry').hidden, true);
  assert.match(todos(ui.elements.get('research-conversation')).find(n => n.className === 'research-warning').textContent, /não trouxe fontes/);
  ui.context.fetch = async () => ({ ok: false, json: async () => ({ erro: 'Limite de uso atingido' }) });
  const question = ui.elements.get('research-question');
  question.value = 'E a renda?'; question.events.input();
  ui.elements.get('research-form').events.submit({ preventDefault() {} }); await flush();
  assert.equal(question.value, 'E a renda?');
  assert.equal(question.disabled, false);
  assert.match(ui.elements.get('research-status').textContent, /Limite de uso/);
  assert.equal(ui.run('researchStates.get(selectedCity.id_municipio).entries.length'), 1);
});

test('aplica borda azul escuro (#001cb8) ao selecionar município e hover azul claro (#73d5ff) em estados e municípios', async () => {
  const ui = interfaceSimulada();
  const geoUfs = { features: [{ properties: { id_uf: 35 } }] };
  const geoSp = { features: [{ properties: { id_municipio: cityA.id_municipio } }, { properties: { id_municipio: 3509502 } }] };
  const campinas = { id_municipio: 3509502, nome: 'Campinas', uf: 'SP', taxa_analfabetismo: 5 };
  ui.context.fetch = async url => {
    if (url === '/api/ufs') return http([{ id_uf: 35, sigla: 'SP', nome: 'São Paulo', taxa_analfabetismo: 8, com_taxa: 2, municipios: 2 }]);
    if (url === '/static/malhas/ufs.geojson') return http(geoUfs);
    if (url === '/api/catalogo-municipios' || url === '/api/pnad-escolaridade') return http([]);
    if (url === '/static/malhas/SP.geojson') return http(geoSp);
    if (url === '/api/municipios?uf=SP') return http([{ ...cityA, taxa_analfabetismo: 4 }, campinas]);
  };
  await ui.run('initialize()');
  const ufLayer = ui.run('countryLayer').layers[0];
  const ufOriginalFill = ufLayer.style.fillColor;
  ufLayer.events.mouseover();
  assert.equal(ufLayer.style.color, '#73d5ff');
  assert.equal(ufLayer.style.fillColor, ufOriginalFill);
  ufLayer.events.mouseout();
  assert.equal(ufLayer.style.color, '#365965');

  ufLayer.events.mouseover();
  await ui.run("loadUf('SP')");
  const layerA = ui.run(`cityLayers.get(${cityA.id_municipio})`);
  const layerB = ui.run('cityLayers.get(3509502)');
  const baseFillA = layerA.baseStyle.fillColor;

  layerA.events.mouseover();
  assert.equal(layerA.style.color, '#73d5ff');
  assert.equal(layerA.style.fillColor, baseFillA);
  layerA.events.mouseout();
  assert.equal(layerA.style.color, '#ffffff');
  assert.equal(layerA.style.fillColor, baseFillA);

  // Troca rápida de polígono, sem receber mouseout do anterior.
  layerA.events.mouseover(); layerA.tooltipOpen = true;
  layerB.events.mouseover(); layerB.tooltipOpen = true;
  assert.equal(layerA.style.color, '#ffffff');
  assert.equal(layerA.tooltipOpen, false);
  assert.equal(layerB.style.color, '#73d5ff');
  assert.equal(layerA.frontCount, 0);
  assert.equal(layerB.frontCount, 0);
  layerA.events.mouseout();
  assert.equal(layerB.style.color, '#73d5ff');
  assert.equal(layerB.tooltipOpen, true);
  ui.elements.get('map').events.mouseleave();
  assert.equal(layerB.style.color, '#ffffff');
  assert.equal(layerB.tooltipOpen, false);

  layerA.events.mouseover(); layerA.tooltipOpen = true;
  ui.run("map.events.movestart()");
  assert.equal(layerA.style.color, '#ffffff');
  assert.equal(layerA.tooltipOpen, false);

  layerA.events.click();
  assert.equal(layerA.style.color, '#001cb8');
  assert.equal(layerA.style.weight, 3);

  layerA.events.mouseover();
  assert.equal(layerA.style.color, '#001cb8');
  assert.equal(layerA.style.fillColor, baseFillA);
  layerA.events.mouseout();
  assert.equal(layerA.style.color, '#001cb8');
  assert.equal(layerA.style.fillColor, baseFillA);

  layerB.events.click();
  assert.equal(layerA.style.color, '#ffffff');
  assert.equal(layerA.style.weight, 0.7);
  assert.equal(layerB.style.color, '#001cb8');
  assert.equal(layerB.style.weight, 3);

  layerB.events.mouseover(); layerB.tooltipOpen = true;
  ui.run("map.events.zoomstart()");
  assert.equal(layerB.style.color, '#001cb8');
  assert.equal(layerB.tooltipOpen, false);
  assert.equal(ui.run('hoveredLayer'), null);

  ui.run('resetMap()');
  assert.equal(ui.run('selectedLayer'), null);
  assert.equal(ufLayer.style.color, '#365965');
});
