import { useNavigate, useLocation, Link } from 'react-router-dom';

import { Outlet } from 'react-router-dom';

import { clearAuth, getUserRole } from '../lib/auth-storage';

const navItems = [
  { path: '/app', label: 'Пользователи' },
  { path: '/app/products', label: 'Товары' },
  { path: '/app/orders', label: 'Заказы' },
  { path: '/app/deliveries', label: 'Доставки' },
];

export function DashboardLayout() {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    clearAuth();
    navigate('/');
  };

  const role = getUserRole();

  return (
    <div className="min-h-screen bg-slate-100">
      <header className="bg-white border-b border-slate-200">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-6">
          <h1 className="text-lg font-semibold text-slate-800">Farm Admin</h1>
          <div className="flex items-center gap-4">
            <span className="text-sm text-slate-600 capitalize">{role || 'admin'}</span>
            <button
              onClick={handleLogout}
              className="rounded-md border border-slate-300 px-3 py-1 text-sm hover:bg-slate-200"
            >
              Logout
            </button>
          </div>
        </div>
        <nav className="mx-auto max-w-7xl border-t border-slate-200 bg-white px-6">
          <div className="flex gap-1">
            {navItems.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                className={`px-4 py-3 text-sm font-medium transition-colors ${
                  location.pathname === item.path
                    ? 'border-b-2 border-primary text-primary'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {item.label}
              </Link>
            ))}
          </div>
        </nav>
      </header>
      <main className="mx-auto mt-6 max-w-7xl px-6">
        <Outlet />
      </main>
    </div>
  );
}
