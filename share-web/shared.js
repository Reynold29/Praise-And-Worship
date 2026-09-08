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

function storeButtons(container) {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
  const url = isIOS ? window.WC_CONFIG.appStoreUrl : window.WC_CONFIG.playStoreUrl;
  const label = isIOS ? "Get iOS app" : "Get Android app";
  container.innerHTML = `
    <p>Get Worship Companion for chords, transpose, and offline lyrics.</p>
    <a class="btn" href="${url}">${label}</a>
  `;
}

/** Try the installed app; if missing, stay on this page (Android intent fallback). */
function tryOpenApp() {
  if (!/Android/i.test(navigator.userAgent || "")) return;
  const fallback = location.href;
  const hostAndPath =
    location.host + location.pathname + location.search + location.hash;
  location.href =
    "intent://" +
    hostAndPath +
    "#Intent;scheme=https;package=com.reyzie.worshipcompanion;S.browser_fallback_url=" +
    encodeURIComponent(fallback) +
    ";end";
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
