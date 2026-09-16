function tableForLang(lang) {
  if (lang === "english") return "english_data";
  if (lang === "kannada") return "kannada_data";
  return "other_data";
}

function langForCategory(category) {
  const c = (category || "").replace(/_data$/, "");
  if (c === "english" || c === "kannada") return c;
  return "other";
}

function createClient() {
  return window.supabase.createClient(
    window.WC_CONFIG.supabaseUrl,
    window.WC_CONFIG.supabaseAnonKey,
    { realtime: { params: { eventsPerSecond: 2 } } }
  );
}

function debounce(fn, ms) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[c]));
}

function langChip(lang) {
  if (lang === "english") return "EN";
  if (lang === "kannada") return "KN";
  return "OT";
}

function prefersReducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

function upsertMeta(attr, key, content) {
  if (!content) return;
  let el = document.head.querySelector(`meta[${attr}="${key}"]`);
  if (!el) {
    el = document.createElement("meta");
    el.setAttribute(attr, key);
    document.head.appendChild(el);
  }
  el.setAttribute("content", content);
}

function absoluteUrl(pathOrUrl) {
  try {
    return new URL(pathOrUrl, location.href).href;
  } catch (_) {
    return pathOrUrl;
  }
}

/**
 * Update share / preview metadata.
 * Note: WhatsApp/Facebook crawlers usually read the first HTML response and
 * do not execute JS, so perfect song-specific WhatsApp cards need SSR later.
 * This still helps Slack/Discord-ish clients, browser tabs, and in-app shares.
 */
function setShareMeta({ title, description, url, image, type }) {
  const pageTitle = title || "Worship Companion";
  const desc =
    description ||
    "Open lyrics, playlists, and worship songs with Worship Companion.";
  const pageUrl = absoluteUrl(url || location.href);
  const imageUrl = absoluteUrl(
    image || window.WC_CONFIG.ogImage || "../og-card.png"
  );

  document.title = pageTitle;
  upsertMeta("name", "description", desc);
  upsertMeta("property", "og:site_name", "Worship Companion");
  upsertMeta("property", "og:type", type || "website");
  upsertMeta("property", "og:title", pageTitle);
  upsertMeta("property", "og:description", desc);
  upsertMeta("property", "og:url", pageUrl);
  upsertMeta("property", "og:image", imageUrl);
  upsertMeta("name", "twitter:card", "summary_large_image");
  upsertMeta("name", "twitter:title", pageTitle);
  upsertMeta("name", "twitter:description", desc);
  upsertMeta("name", "twitter:image", imageUrl);

  let canonical = document.head.querySelector('link[rel="canonical"]');
  if (!canonical) {
    canonical = document.createElement("link");
    canonical.setAttribute("rel", "canonical");
    document.head.appendChild(canonical);
  }
  canonical.setAttribute("href", pageUrl);
}

function renderOpenAppBanner(container) {
  if (!container) return;
  container.innerHTML = `
    <div class="app-launch">
      <p>Open this in the app for chords, transpose, playlists, and offline lyrics.</p>
      <a href="#" class="btn tonal" id="openAppBtn">Open In App</a>
    </div>
  `;
  const btn = document.getElementById("openAppBtn");
  if (btn) {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      tryOpenApp({ userInitiated: true });
    });
  }
}

function storeButtons(container) {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
  const url = isIOS ? window.WC_CONFIG.appStoreUrl : window.WC_CONFIG.playStoreUrl;
  const label = isIOS ? "Get iOS app" : "Get Android app";
  container.innerHTML = `
    <p>Get Worship Companion for chords, transpose, and offline lyrics.</p>
    <a class="btn" href="${url}">${label}</a>
  `;
}

/**
 * Open the installed app. Call ONLY from a user tap — never on page load.
 * Auto intent redirects caused Chrome↔app bounce loops when the app was installed.
 */
function tryOpenApp(options = {}) {
  const { userInitiated = false } = options;
  if (!userInitiated) return;

  // One attempt per page session — prevents reload/visibility bounce loops.
  try {
    if (sessionStorage.getItem("wc_open_app_attempted") === "1") return;
    sessionStorage.setItem("wc_open_app_attempted", "1");
  } catch (_) {}

  const ua = navigator.userAgent || "";
  const isAndroid = /Android/i.test(ua);
  const isIOS = /iPad|iPhone|iPod/.test(ua);
  const params = new URLSearchParams(location.search);
  const path = location.pathname.toLowerCase();

  // Custom scheme used when Universal Links / App Links don't take over from the browser.
  let customUrl = "worshipcompanion://lyrics";
  if (path.includes("/playlist")) {
    customUrl =
      "worshipcompanion://playlist?id=" + encodeURIComponent(params.get("id") || "");
  } else {
    const lang = encodeURIComponent((params.get("l") || "english").toLowerCase());
    const id = encodeURIComponent(params.get("id") || "");
    customUrl = "worshipcompanion://lyrics?l=" + lang + "&id=" + id;
  }

  if (isAndroid || isIOS) {
    const started = Date.now();
    // Custom scheme opens the app without reloading this page (no intent fallback loop).
    location.href = customUrl;
    setTimeout(() => {
      if (document.hidden) return;
      if (Date.now() - started < 2200) {
        try {
          sessionStorage.removeItem("wc_open_app_attempted");
        } catch (_) {}
      }
    }, 1800);
    return;
  }

  // Desktop / other: stay on the web page.
}

function subscribeFiltered(client, channelName, table, filter, onChange) {
  const channel = client
    .channel(channelName)
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table, filter },
      onChange
    )
    .subscribe();
  return channel;
}
