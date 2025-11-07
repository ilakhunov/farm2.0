const ACCESS_TOKEN_KEY = 'farm_admin_access_token';
const REFRESH_TOKEN_KEY = 'farm_admin_refresh_token';
const USER_ROLE_KEY = 'farm_admin_role';

export function saveAuth(tokens: { access_token: string; refresh_token: string }, role: string) {
  localStorage.setItem(ACCESS_TOKEN_KEY, tokens.access_token);
  localStorage.setItem(REFRESH_TOKEN_KEY, tokens.refresh_token);
  localStorage.setItem(USER_ROLE_KEY, role);
}

export function clearAuth() {
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(USER_ROLE_KEY);
}

export function getAccessToken() {
  return localStorage.getItem(ACCESS_TOKEN_KEY);
}

export function getUserRole() {
  return localStorage.getItem(USER_ROLE_KEY);
}
