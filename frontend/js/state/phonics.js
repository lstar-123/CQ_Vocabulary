// ==================== PHONICS CACHE ====================
import { apiFetch } from '../api.js';

export let phonicsCache = {};

export async function ensurePhonicsData(word) {
  if (!phonicsCache[word]) {
    try { phonicsCache[word] = await apiFetch('/api/words/phonics?word=' + encodeURIComponent(word)); }
    catch (e) { phonicsCache[word] = null; }
  }
  return phonicsCache[word];
}
