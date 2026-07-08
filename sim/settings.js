/**
 * Settings Manager — Autograf-882 Debug Simulator
 *
 * Хранит конфигурацию в localStorage, предоставляет панель настроек.
 *
 * Секции:
 *   chips:   адреса загрузки ROM-чипов
 *   vars:    адреса отслеживаемых переменных (X, Y, перо, цвет)
 *   custom:  пользовательские watch-переменные
 */

const STORAGE_KEY = 'aftograf-settings';

export const DEFAULTS = {
  chips: [
    { label: 'Chip 1 (D2764A)', offset: 0x0000, size: 0x2000 },
    { label: 'Chip 2 (D2764A)', offset: 0x2000, size: 0x2000 },
    { label: 'Chip 3 (D2764A)', offset: 0x4000, size: 0x2000 },
  ],
  vars: {
    X_POS_LO:   { label: 'X position (LO)',  addr: 0x6180, size: 1 },
    X_POS_HI:   { label: 'X position (HI)',  addr: 0x6181, size: 1 },
    Y_POS_LO:   { label: 'Y position (LO)',  addr: 0x61ca, size: 1 },
    Y_POS_HI:   { label: 'Y position (HI)',  addr: 0x61cb, size: 1 },
    PEN_STATE:  { label: 'Pen state',        addr: 0x63f0, size: 1 },
    PEN_COLOR:  { label: 'Pen color / num',  addr: 0x61e8, size: 1 },
  },
  theme: 'dark',
  dip: [false, false, false, false],
  custom: [],
};

export class SettingsManager {
  constructor() {
    this.config = this._load();
  }

  /** Загрузить из localStorage, смержить с дефолтами */
  _load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const saved = JSON.parse(raw);
        return this._merge(saved);
      }
    } catch (_) { /* corrupted — use defaults */ }
    return this._merge({});
  }

  _merge(saved) {
    const cfg = {
      theme: saved.theme === 'light' ? 'light' : 'dark',
      dip: Array.isArray(saved.dip) ? saved.dip.map(Boolean) : [false, false, false, false],
      chips: (saved.chips || []).length === 3
        ? saved.chips.map((c, i) => ({ ...DEFAULTS.chips[i], ...c }))
        : DEFAULTS.chips.map(c => ({ ...c })),
      vars: { ...DEFAULTS.vars },
      custom: Array.isArray(saved.custom) ? saved.custom.map(c => ({ ...c })) : [],
    };
    // Merge vars
    for (const key of Object.keys(DEFAULTS.vars)) {
      if (saved.vars && saved.vars[key]) {
        cfg.vars[key] = { ...DEFAULTS.vars[key], ...saved.vars[key] };
      }
    }
    return cfg;
  }

  /** Сохранить в localStorage */
  save() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.config));
    } catch (_) { /* storage full — ignore */ }
  }

  /** Получить адрес переменной по ключу */
  getAddr(key) {
    const v = this.config.vars[key];
    return v ? v.addr : 0;
  }

  /** Обновить адрес переменной */
  setAddr(key, addr) {
    if (this.config.vars[key]) {
      this.config.vars[key].addr = addr;
    }
  }

  /** Обновить offset чипа */
  setChipOffset(idx, offset) {
    if (idx >= 0 && idx < this.config.chips.length) {
      this.config.chips[idx].offset = offset;
    }
  }

  /** Добавить кастомную переменную */
  addCustom(name, addr, size = 1, type = 'uint8') {
    this.config.custom.push({ name, addr, size, type, id: Date.now() });
  }

  /** Удалить кастомную переменную */
  removeCustom(id) {
    this.config.custom = this.config.custom.filter(c => c.id !== id);
  }

  /** Сбросить на дефолты */
  reset() {
    this.config = this._merge({});
    this.save();
  }

  /** Построить HTML панели настроек */
  renderPanel() {
    const cfg = this.config;
    const chipRows = cfg.chips.map((c, i) => `
      <tr>
        <td>${c.label}</td>
        <td><input type="text" class="cfg-chip-offset" data-idx="${i}" value="$${c.offset.toString(16).padStart(4,'0').toUpperCase()}" size="6"></td>
        <td>${'0x' + c.size.toString(16).toUpperCase()} (${c.size})</td>
      </tr>`).join('');

    const varRows = Object.entries(cfg.vars).map(([key, v]) => `
      <tr>
        <td>${v.label}</td>
        <td><code>${key}</code></td>
        <td><input type="text" class="cfg-var-addr" data-key="${key}" value="$${v.addr.toString(16).padStart(4,'0').toUpperCase()}" size="6"></td>
        <td>${v.size}B</td>
      </tr>`).join('');

    const customRows = cfg.custom.length === 0
      ? '<tr><td colspan="4" style="color:#565f89;text-align:center">Нет пользовательских переменных</td></tr>'
      : cfg.custom.map((c, i) => `
      <tr>
        <td><input type="text" class="cfg-custom-name" data-id="${c.id}" value="${c.name}" size="12"></td>
        <td><input type="text" class="cfg-custom-addr" data-id="${c.id}" value="$${c.addr.toString(16).padStart(4,'0').toUpperCase()}" size="6"></td>
        <td>
          <select class="cfg-custom-size" data-id="${c.id}">
            <option value="1" ${c.size===1?'selected':''}>1B</option>
            <option value="2" ${c.size===2?'selected':''}>2B</option>
          </select>
        </td>
        <td><button class="small-btn cfg-custom-remove" data-id="${c.id}">✕</button></td>
      </tr>`).join('');

    return `
    <div id="settings-overlay" class="settings-overlay">
      <div class="settings-panel">
        <div class="settings-header">
          <h2>Настройки симулятора</h2>
          <button id="settings-close" class="ctrl-btn">✕ Закрыть</button>
        </div>

        <div class="settings-body">
          <!-- Загрузка прошивки -->
          <section class="settings-section">
            <h3>Загрузка прошивки</h3>
            <div class="settings-row">
              <button id="settings-load-rom" class="ctrl-btn">📂 Загрузить файл прошивки</button>
              <input type="file" id="settings-rom-input" accept=".bin,.rom" style="display:none">
              <span id="settings-load-status" class="load-status-info" style="display:none">—</span>
            </div>
            <div class="settings-row">
              <label>Адрес загрузки: <input type="text" id="settings-load-addr" value="$0000" size="6"></label>
              <label class="settings-hint">Hex, например $2000 для Chip 2</label>
            </div>
          </section>

          <!-- Карта чипов -->
          <section class="settings-section">
            <h3>Адреса чипов ROM</h3>
            <table class="settings-table">
              <thead><tr><th>Чип</th><th>Смещение</th><th>Размер</th></tr></thead>
              <tbody>${chipRows}</tbody>
            </table>
            <div class="settings-row">
              <label class="settings-hint">Изменения применяются при следующей загрузке ROM</label>
            </div>
          </section>

          <!-- Переменные плоттера -->
          <section class="settings-section">
            <h3>Переменные плоттера (RAM)</h3>
            <table class="settings-table">
              <thead><tr><th>Описание</th><th>Ключ</th><th>Адрес</th><th>Размер</th></tr></thead>
              <tbody>${varRows}</tbody>
            </table>
            <div class="settings-row">
              <label class="settings-hint">Изменения применяются сразу, после закрытия настроек</label>
            </div>
          </section>


          <!-- DIP-переключатели -->
          <section class="settings-section">
            <h3>Конфигурационные переключатели (DIP)</h3>
            <div class="settings-row">
              ${cfg.dip.map((v,i) => `
                <label style="display:flex;align-items:center;gap:4px;font-size:12px;font-family:var(--font-mono)">
                  <input type="checkbox" class="cfg-dip" data-idx="${i}" ${v?'checked':''}>
                  ComCfg${i+1}
                </label>
              `).join('')}
              <label class="settings-hint">Соответствуют PB4-PB7 на PIO1. Применяются сразу.</label>
            </div>
          </section>
          <!-- Тема оформления -->
          <section class="settings-section">
            <h3>Тема оформления</h3>
            <div class="settings-row">
              <label for="settings-theme">Режим:</label>
              <select id="settings-theme" class="cfg-theme-select" style="background:var(--bg-input);color:var(--text);border:1px solid var(--border);border-radius:3px;padding:2px 4px;font-family:var(--font-mono);font-size:12px">
                <option value="dark" ${cfg.theme==='dark'?'selected':''}>Тёмная (ночная)</option>
                <option value="light" ${cfg.theme==='light'?'selected':''}>Светлая (дневная)</option>
              </select>
              <label class="settings-hint">Применяется сразу после закрытия настроек</label>
            </div>
          </section>

          <!-- Пользовательские watcher'ы -->
          <section class="settings-section">
            <h3>Пользовательские переменные</h3>
            <table class="settings-table" id="custom-vars-table">
              <thead><tr><th>Имя</th><th>Адрес</th><th>Размер</th><th></th></tr></thead>
              <tbody>${customRows}</tbody>
            </table>
            <div class="settings-row">
              <button id="settings-custom-add" class="small-btn">+ Добавить</button>
              <button id="settings-custom-read" class="small-btn">⟳ Прочитать</button>
            </div>
            <div id="custom-readout" class="custom-readout"></div>
          </section>

          <!-- Управление -->
          <section class="settings-section">
            <h3>Управление настройками</h3>
            <div class="settings-row">
              <button id="settings-save" class="ctrl-btn">💾 Сохранить</button>
              <button id="settings-reset" class="ctrl-btn">↺ Сбросить</button>
              <span id="settings-save-status" style="display:none;color:var(--green)">✓ Сохранено</span>
            </div>
          </section>
        </div>
      </div>
    </div>`;
  }
}
