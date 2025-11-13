import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';

import { usersApi, User } from '../lib/api-client';

// Use users API endpoint
function useUsers(role?: string) {
  const { data: usersData } = useQuery({
    queryKey: ['users', role],
    queryFn: () => usersApi.list({ role: role as 'farmer' | 'shop' | 'admin' | undefined }),
    retry: false, // Don't retry if endpoint doesn't exist (fallback to empty list)
  });

  return usersData || [];
}

export function UsersPage() {
  const [filter, setFilter] = useState<{ role?: string }>({});
  const users = useUsers(filter.role);

  const filteredUsers = users;

  const formatDate = (dateStr: string | undefined) => {
    if (!dateStr) return 'N/A';
    return new Date(dateStr).toLocaleDateString('ru-RU');
  };

  return (
    <section className="space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-slate-900">Пользователи</h2>
          <p className="text-sm text-slate-500">
            Пользователи из заказов и товаров (всего: {filteredUsers.length})
          </p>
        </div>
        <div className="text-sm text-slate-500">
          <p>Пользователи создаются через OTP авторизацию</p>
        </div>
      </header>

      {/* Filters */}
      <div className="flex gap-4 rounded-lg border border-slate-200 bg-white p-4">
        <div className="flex-1">
          <label className="mb-1 block text-xs font-medium text-slate-700">Роль</label>
          <select
            className="w-full rounded-md border border-slate-300 px-3 py-1.5 text-sm"
            value={filter.role || ''}
            onChange={(e) => setFilter({ ...filter, role: e.target.value || undefined })}
          >
            <option value="">Все роли</option>
            <option value="farmer">Фермер</option>
            <option value="shop">Магазин</option>
            <option value="admin">Админ</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">ID</th>
              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Роль</th>
              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Телефон</th>
              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Статус</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
            {filteredUsers.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-4 py-8 text-center text-slate-500">
                  Пользователи не найдены
                </td>
              </tr>
            ) : (
              filteredUsers.map((user) => (
                <tr key={user.id}>
                  <td className="px-4 py-3 font-mono text-xs">{user.id?.substring(0, 8)}...</td>
                  <td className="px-4 py-3 capitalize">{user.role}</td>
                  <td className="px-4 py-3">{user.phone_number || 'N/A'}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                        user.is_verified
                          ? 'bg-emerald-100 text-emerald-700'
                          : 'bg-amber-100 text-amber-700'
                      }`}
                    >
                      {user.is_verified ? 'Подтверждён' : 'Ожидает'}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {filteredUsers.length > 0 && (
        <div className="text-sm text-slate-600">Всего: {filteredUsers.length} пользователей</div>
      )}
    </section>
  );
}
