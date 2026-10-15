(() => {
  'use strict';
  const tabs = [...document.querySelectorAll('[role="tab"][data-panel]')];
  const panels = [...document.querySelectorAll('[role="tabpanel"]')];
  function activateTab(tab, shouldFocus = false) {
    for (const item of tabs) {
      const active = item === tab;
      item.setAttribute('aria-selected', String(active));
      item.tabIndex = active ? 0 : -1;
    }
    for (const panel of panels) {
      panel.hidden = panel.id !== 'panel-' + tab.dataset.panel;
      panel.classList.toggle('active', !panel.hidden);
    }
    if (shouldFocus) tab.focus();
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => activateTab(tab));
    tab.addEventListener('keydown', event => {
      let next = -1;
      if (event.key === 'ArrowRight' || event.key === 'ArrowDown') next = (index + 1) % tabs.length;
      if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') next = (index - 1 + tabs.length) % tabs.length;
      if (event.key === 'Home') next = 0;
      if (event.key === 'End') next = tabs.length - 1;
      if (next >= 0) {
        event.preventDefault();
        activateTab(tabs[next], true);
      }
    });
  });
  const toggle = document.querySelector('.nav-toggle');
  const menu = document.getElementById('nav-links');
  const closeMenu = () => {
    if (!toggle || !menu) return;
    toggle.setAttribute('aria-expanded', 'false');
    toggle.setAttribute('aria-label', 'Open navigation');
    menu.classList.remove('is-open');
  };
  toggle?.addEventListener('click', () => {
    const open = toggle.getAttribute('aria-expanded') !== 'true';
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
    menu.classList.toggle('is-open', open);
  });
  menu?.querySelectorAll('a').forEach(link => link.addEventListener('click', closeMenu));
  document.addEventListener('keydown', event => { if (event.key === 'Escape') closeMenu(); });
  const copyButton = document.querySelector('[data-copy]');
  copyButton?.addEventListener('click', async () => {
    const text = copyButton.dataset.copy || '';
    const original = copyButton.textContent;
    try {
      if (!navigator.clipboard?.writeText) throw new Error('Clipboard unavailable');
      await navigator.clipboard.writeText(text);
      copyButton.textContent = 'Copied ✓';
    } catch {
      copyButton.textContent = 'Select commands above to copy';
    }
    window.setTimeout(() => { copyButton.textContent = original; }, 2400);
  });
  const year = document.getElementById('year');
  if (year) year.textContent = String(new Date().getFullYear());
})();