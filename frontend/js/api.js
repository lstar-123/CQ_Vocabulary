// ==================== API LAYER ====================
// All HTTP communication goes through this module.

let _showAuth = null;
export function setAuthHandler(fn) { _showAuth = fn; }

export async function apiFetch(path, options = {}) {
  const res = await fetch(path, {
    credentials: 'same-origin',
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options
  });
  const data = await res.json();
  if (!res.ok) {
    if (res.status === 401) {
      if (_showAuth) _showAuth();
      throw new Error(data.error || '请先登录');
    }
    throw new Error(data.error || '请求失败');
  }
  return data;
}
