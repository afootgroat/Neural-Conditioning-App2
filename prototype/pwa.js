/* Rewire PWA — storage, service worker, first-launch onboarding */
(function () {
  "use strict";

  const STORE_KEY = "rewire-store-v1";
  const isMobileShell = window.matchMedia("(max-width: 768px), (display-mode: standalone)").matches;
  const debugMode = new URLSearchParams(location.search).has("debug");

  if (debugMode) document.body.classList.add("debug-on");

  window.RewirePWA = {
    isMobileShell,
    debugMode,
    loadStore,
    saveStore,
    scheduleSave,
    registerServiceWorker,
    maybeShowOnboarding,
  };

  let saveTimer = null;

  function loadStore() {
    try {
      const raw = localStorage.getItem(STORE_KEY);
      if (!raw) return null;
      const data = JSON.parse(raw);
      if (!data || !Array.isArray(data.pathways) || !Array.isArray(data.archived)) return null;
      return {
        pathways: data.pathways,
        archived: data.archived,
        hasCompletedOnboarding: !!data.hasCompletedOnboarding,
      };
    } catch {
      return null;
    }
  }

  function saveStore(pathways, archived, hasCompletedOnboarding) {
    try {
      localStorage.setItem(STORE_KEY, JSON.stringify({
        pathways,
        archived,
        hasCompletedOnboarding: !!hasCompletedOnboarding,
        savedAt: Date.now(),
      }));
    } catch (err) {
      console.warn("Rewire: could not persist store", err);
    }
  }

  function scheduleSave() {
    if (typeof window.__rewireGetStore !== "function") return;
    clearTimeout(saveTimer);
    saveTimer = setTimeout(() => {
      const snap = window.__rewireGetStore();
      saveStore(snap.pathways, snap.archived, snap.hasCompletedOnboarding);
    }, 200);
  }

  function registerServiceWorker() {
    if (!("serviceWorker" in navigator)) return;
    const secure = location.protocol === "https:" || location.hostname === "localhost";
    if (!secure) return;
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("./sw.js", { scope: "./" }).catch((err) => {
        console.warn("Rewire: service worker registration failed", err);
      });
    });
  }

  function maybeShowOnboarding() {
    if (typeof window.openOnboarding !== "function") return;
    const snap = window.__rewireGetStore?.();
    if (!snap) return;
    if (snap.hasCompletedOnboarding) return;
    if (snap.pathways.length > 0) return;
    window.openOnboarding();
  }

  registerServiceWorker();
})();
