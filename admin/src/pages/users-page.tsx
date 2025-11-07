const mockUsers = [
  {
    id: '1',
    role: 'farmer',
    phone: '+998900000001',
    status: 'pending',
    createdAt: '2024-05-01',
  },
  {
    id: '2',
    role: 'shop',
    phone: '+998900000002',
    status: 'verified',
    createdAt: '2024-05-02',
  },
];

export function UsersPage() {
  return (
    <section className="space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-slate-900">Пользователи</h2>
          <p className="text-sm text-slate-500">Управление регистрациями фермеров и магазинов</p>
        </div>
        <button className="rounded-md border border-slate-300 px-4 py-2 text-sm hover:bg-slate-200">Экспорт CSV</button>
      </header>
      <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50">
            <tr>
              <th className="px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">ID</th>
              <th className="px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Роль</th>
              <th className="px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Телефон</th>
              <th className="px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Статус</th>
              <th className="px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Создан</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
            {mockUsers.map((user) => (
              <tr key={user.id}>
                <td className="px-4 py-2 font-mono text-xs">{user.id}</td>
                <td className="px-4 py-2 capitalize">{user.role}</td>
                <td className="px-4 py-2">{user.phone}</td>
                <td className="px-4 py-2">
                  <span
                    className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                      user.status === 'verified'
                        ? 'bg-emerald-100 text-emerald-700'
                        : 'bg-amber-100 text-amber-700'
                    }`}
                  >
                    {user.status === 'verified' ? 'Подтверждён' : 'Ожидает'}
                  </span>
                </td>
                <td className="px-4 py-2 text-xs text-slate-500">{user.createdAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
