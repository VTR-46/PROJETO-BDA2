const map = L.map('map', { zoomControl: true, scrollWheelZoom: false, attributionControl: false });
const ufSelect = document.getElementById('uf-select');
const search = document.getElementById('city-search');
const options = document.getElementById('city-options');
const status = document.getElementById('status');
const details = document.getElementById('details');
const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 2 });
const integer = new Intl.NumberFormat('pt-BR');
const percent = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 2 });
let countryLayer, cityLayer, cities = [], catalog = [], cityLayers = new Map(), requestId = 0;
let selectedSearchCode = null;

async function getJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Falha ao carregar ${url} (${response.status})`);
  return response.json();
}

function color(rate) {
  if (rate == null) return '#cbd2d4';
  if (rate <= 10) return '#b9d8c5';
  if (rate <= 20) return '#7cae91';
  if (rate <= 30) return '#e6aa68';
  return '#c86a55';
}

function emptyValue(value, formatter) {
  return value == null ? 'Sem dados' : formatter(value);
}

function searchKey(value) {
  return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('pt-BR').trim();
}

function cityLabel(city) {
  return `${city.nome} (${city.uf})`;
}

function updateSuggestions() {
  const typed = searchKey(search.value);
  options.replaceChildren();
  if (!typed) return;
  const matches = catalog.filter(city => searchKey(city.nome).includes(typed)).slice(0, 20);
  for (const city of matches) {
    const label = cityLabel(city);
    const option = document.createElement('option'); option.value = label;
    options.append(option);
    const plain = label.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    if (plain !== label) {
      const alias = document.createElement('option'); alias.value = plain; alias.label = label;
      options.append(alias);
    }
  }
  if (!matches.length) status.textContent = 'Nenhum município encontrado. Confira o nome digitado.';
}

function commitSearch() {
  const typed = searchKey(search.value);
  if (!typed) return;
  const exact = catalog.filter(city => searchKey(cityLabel(city)) === typed || searchKey(city.nome) === typed);
  if (exact.length !== 1) {
    status.textContent = exact.length ? 'Há municípios com esse nome em mais de uma UF. Escolha uma sugestão com a sigla.'
      : 'Município não encontrado. Escolha uma sugestão ou digite o nome completo.';
    return;
  }
  const city = exact[0];
  if (selectedSearchCode === city.id_municipio) return;
  selectedSearchCode = city.id_municipio;
  if (ufSelect.value === city.uf && cityLayers.has(city.id_municipio)) selectCity(cities.find(item => item.id_municipio === city.id_municipio));
  else loadUf(city.uf, city.id_municipio);
}

function metric(label, value, note) {
  const box = document.createElement('div');
  box.className = 'metric';
  const small = document.createElement('span'); small.textContent = label;
  const strong = document.createElement('strong'); strong.textContent = value;
  box.append(small, strong);
  if (note) { const caption = document.createElement('small'); caption.textContent = note; box.append(caption); }
  return box;
}

function selectCity(city) {
  search.value = cityLabel(city);
  selectedSearchCode = city.id_municipio;
  details.replaceChildren();
  const eyebrow = document.createElement('p'); eyebrow.className = 'eyebrow'; eyebrow.textContent = 'MUNICÍPIO SELECIONADO';
  const title = document.createElement('h3'); title.textContent = `${city.nome} · ${city.uf}`;
  const grid = document.createElement('div'); grid.className = 'metrics';
  grid.append(
    metric('Taxa de analfabetismo', emptyValue(city.taxa_analfabetismo, v => `${percent.format(v)}%`),
      city.total_alfabetizacao == null ? '' : `${integer.format(city.nao_alfabetizados)} de ${integer.format(city.total_alfabetizacao)} idosos`),
    metric('Renda nominal média', emptyValue(city.renda_media, v => money.format(v)), 'Média mensal dos grupos de 60 a 64 e 65+ anos'),
    metric('Sem instrução ou fundamental incompleto', emptyValue(city.percentual_baixa_escolaridade, v => `${percent.format(v)}%`),
      city.total_escolaridade == null ? '' : `${integer.format(city.baixa_escolaridade)} de ${integer.format(city.total_escolaridade)} idosos`)
  );
  details.append(eyebrow, title, grid);
  const layer = cityLayers.get(city.id_municipio);
  if (layer) { layer.bringToFront(); map.fitBounds(layer.getBounds(), { padding: [50, 50], maxZoom: 10 }); }
}

function makeSvg(name, attributes, text) {
  const node = document.createElementNS('http://www.w3.org/2000/svg', name);
  for (const [key, value] of Object.entries(attributes)) node.setAttribute(key, value);
  if (text != null) node.textContent = text;
  return node;
}

function drawScatter() {
  const target = document.getElementById('scatter');
  target.replaceChildren();
  const points = cities.filter(city => city.taxa_analfabetismo != null && city.renda_media != null);
  document.getElementById('scatter-count').textContent = `${integer.format(points.length)} municípios com ambos os indicadores nesta UF.`;
  if (!points.length) { target.textContent = 'Sem municípios com os dois indicadores disponíveis.'; return; }
  const svg = makeSvg('svg', { viewBox: '0 0 600 320', 'aria-hidden': 'true' });
  const left = 55, top = 16, width = 520, height = 250;
  const maxIncome = Math.max(...points.map(p => p.renda_media)) * 1.05;
  const maxRate = Math.max(10, Math.ceil(Math.max(...points.map(p => p.taxa_analfabetismo)) / 10) * 10);
  for (let i = 0; i <= 4; i++) {
    const y = top + height - i * height / 4;
    svg.append(makeSvg('line', { x1: left, x2: left + width, y1: y, y2: y, class: 'gridline' }));
    svg.append(makeSvg('text', { x: left - 8, y: y + 4, 'text-anchor': 'end', class: 'tick' }, `${percent.format(maxRate * i / 4)}%`));
  }
  svg.append(makeSvg('text', { x: left, y: 305, class: 'axis-label' }, 'Renda média mensal (R$) →'));
  svg.append(makeSvg('text', { x: left + width, y: 305, 'text-anchor': 'end', class: 'tick' }, money.format(maxIncome)));
  for (const city of points) {
    const circle = makeSvg('circle', {
      cx: left + city.renda_media / maxIncome * width,
      cy: top + height - city.taxa_analfabetismo / maxRate * height,
      r: 4, class: 'point', tabindex: '0', role: 'button',
      'aria-label': `${city.nome}: ${percent.format(city.taxa_analfabetismo)}%, ${money.format(city.renda_media)}`
    });
    circle.append(makeSvg('title', {}, `${city.nome}: ${percent.format(city.taxa_analfabetismo)}% · ${money.format(city.renda_media)}`));
    circle.addEventListener('click', () => selectCity(city));
    circle.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); selectCity(city); } });
    svg.append(circle);
  }
  target.append(svg);
}

async function loadUf(sigla, selectedCode = null) {
  if (!sigla) return resetMap();
  const current = ++requestId;
  status.textContent = `Carregando municípios de ${sigla}…`;
  try {
    const [geo, rows] = await Promise.all([
      getJson(`/static/malhas/${sigla}.geojson`), getJson(`/api/municipios?uf=${sigla}`)
    ]);
    if (current !== requestId) return;
    cities = rows;
    const byCode = new Map(rows.map(city => [city.id_municipio, city]));
    if (cityLayer) map.removeLayer(cityLayer);
    if (countryLayer) map.removeLayer(countryLayer);
    cityLayers = new Map();
    cityLayer = L.geoJSON(geo, {
      style: feature => ({ color: '#ffffff', weight: 0.7, fillColor: color(byCode.get(Number(feature.properties.id_municipio))?.taxa_analfabetismo), fillOpacity: 0.95 }),
      onEachFeature: (feature, layer) => {
        const code = Number(feature.properties.id_municipio);
        cityLayers.set(code, layer);
        const city = byCode.get(code);
        if (city) {
          layer.bindTooltip(city.nome, { sticky: true });
          layer.on('click', () => selectCity(city));
        }
      }
    }).addTo(map);
    map.fitBounds(cityLayer.getBounds(), { padding: [24, 24] });
    ufSelect.value = sigla;
    search.value = ''; selectedSearchCode = null; options.replaceChildren();
    const available = rows.filter(city => city.taxa_analfabetismo != null).length;
    status.textContent = `${integer.format(available)} de ${integer.format(rows.length)} municípios com taxa disponível em ${sigla}.`;
    details.replaceChildren();
    const heading = document.createElement('h3'); heading.textContent = 'Selecione um município';
    const note = document.createElement('p'); note.textContent = 'Clique no mapa ou use a busca acima para ver seus indicadores.';
    details.append(heading, note);
    drawScatter();
    if (selectedCode != null && byCode.has(selectedCode)) selectCity(byCode.get(selectedCode));
  } catch (error) { status.textContent = error.message; }
}

function resetMap() {
  ++requestId;
  if (cityLayer) map.removeLayer(cityLayer);
  cityLayer = null; cities = []; cityLayers.clear();
  if (countryLayer) { countryLayer.addTo(map); map.fitBounds(countryLayer.getBounds(), { padding: [15, 15] }); }
  ufSelect.value = ''; search.value = ''; selectedSearchCode = null; options.replaceChildren();
  status.textContent = 'Selecione uma UF ou busque um município de qualquer estado.';
  document.getElementById('scatter').textContent = 'Selecione uma UF para ver a comparação.';
  document.getElementById('scatter-count').textContent = '';
  details.innerHTML = '<p class="eyebrow">MUNICÍPIO SELECIONADO</p><h3>Escolha um município no mapa</h3><p>Os indicadores disponíveis aparecerão aqui.</p>';
}

async function loadPnad() {
  const rows = await getJson('/api/pnad-escolaridade');
  const target = document.getElementById('pnad-chart');
  const max = Math.max(...rows.map(row => row.renda_media || 0));
  for (const row of rows) {
    const item = document.createElement('div'); item.className = 'bar-row';
    const label = document.createElement('span'); label.textContent = row.escolaridade;
    const track = document.createElement('div'); track.className = 'bar-track';
    const bar = document.createElement('div'); bar.className = 'bar'; bar.style.width = `${100 * row.renda_media / max}%`;
    track.append(bar);
    const value = document.createElement('strong'); value.textContent = emptyValue(row.renda_media, v => money.format(v));
    item.append(label, track, value); target.append(item);
  }
  const valid = rows.reduce((sum, row) => sum + row.amostra_com_renda, 0);
  const total = rows.reduce((sum, row) => sum + row.total_amostra, 0);
  document.getElementById('pnad-note').textContent = `${integer.format(valid)} de ${integer.format(total)} registros informaram renda. Médias sem pesos amostrais.`;
}

async function initialize() {
  try {
    const [ufs, geo, municipalities] = await Promise.all([
      getJson('/api/ufs'), getJson('/static/malhas/ufs.geojson'), getJson('/api/catalogo-municipios')
    ]);
    catalog = municipalities;
    search.disabled = false;
    document.getElementById('coverage').textContent = integer.format(ufs.reduce((sum, uf) => sum + uf.com_taxa, 0));
    for (const uf of ufs) {
      const option = document.createElement('option'); option.value = uf.sigla; option.textContent = `${uf.nome} (${uf.sigla})`;
      ufSelect.append(option);
    }
    const byUf = new Map(ufs.map(uf => [uf.id_uf, uf]));
    countryLayer = L.geoJSON(geo, {
      style: feature => ({ color: '#365965', weight: 1.2,
        fillColor: color(byUf.get(Number(feature.properties.id_uf))?.taxa_analfabetismo), fillOpacity: 0.9 }),
      onEachFeature: (feature, layer) => {
        const uf = byUf.get(Number(feature.properties.id_uf));
        if (uf) {
          layer.bindTooltip(`${uf.nome} · ${emptyValue(uf.taxa_analfabetismo, v => `${percent.format(v)}%`)} · ${uf.com_taxa}/${uf.municipios} municípios com taxa`, { sticky: true });
          layer.on('click', () => loadUf(uf.sigla));
        }
      }
    }).addTo(map);
    map.fitBounds(countryLayer.getBounds(), { padding: [15, 15] });
    status.textContent = 'Selecione uma UF ou busque um município de qualquer estado.';
    await loadPnad();
  } catch (error) { status.textContent = error.message; }
}

ufSelect.addEventListener('change', () => loadUf(ufSelect.value));
document.getElementById('reset-map').addEventListener('click', resetMap);
search.addEventListener('input', () => { selectedSearchCode = null; updateSuggestions(); });
search.addEventListener('change', commitSearch);
search.addEventListener('keydown', event => {
  if (event.key === 'Enter') { event.preventDefault(); commitSearch(); }
});
initialize();
