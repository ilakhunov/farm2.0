import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';

import { ordersApi, Order } from '../lib/api-client';

const STATUS_COLORS: Record<Order['status'], string> = {
  pending: 'bg-amber-100 text-amber-700',
  confirmed: 'bg-blue-100 text-blue-700',
  processing: 'bg-purple-100 text-purple-700',
  shipped: 'bg-cyan-100 text-cyan-700',
  delivered: 'bg-emerald-100 text-emerald-700',
  cancelled: 'bg-red-100 text-red-700',
};

const STATUS_LABELS: Record<Order['status'], string> = {
  pending: 'Ожидает',
  confirmed: 'Подтверждён',
  processing: 'Обрабатывается',
  shipped: 'Отправлен',
  delivered: 'Доставлен',
  cancelled: 'Отменён',
};

export function OrdersPage() {
  const queryClient = useQueryClient();
  const [filter, setFilter] = useState<{ status?: string; farmer_id?: string; shop_id?: string }>({});

  const { data, isLoading, error } = useQuery({
    queryKey: ['orders', filter],
    queryFn: () => ordersApi.list({ limit: 50, ...filter }),
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: Order['status'] }) =>
      ordersApi.updateStatus(id, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
    },
  });

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('ru-RU', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('ru-RU').format(price);
  };

  return (
    <section className="space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-slate-900">Заказы</h2>
          <p className="text-sm text-slate-500">Управление заказами магазинов</p>
        </div>
      </header>

      {/* Filters */}
      <div className="flex gap-4 rounded-lg border border-slate-200 bg-white p-4">
        <div className="flex-1">
          <label className="mb-1 block text-xs font-medium text-slate-700">Статус</label>
          <select
            className="w-full rounded-md border border-slate-300 px-3 py-1.5 text-sm"
            value={filter.status || ''}
            onChange={(e) => setFilter({ ...filter, status: e.target.value || undefined })}
          >
            <option value="">Все</option>
            {Object.keys(STATUS_LABELS).map((status) => (
              <option key={status} value={status}>
                {STATUS_LABELS[status as Order['status']]}
              </option>
            ))}
          </select>
        </div>
        <div className="flex-1">
          <label className="mb-1 block text-xs font-medium text-slate-700">ID Фермера</label>
          <input
            type="text"
            placeholder="Фильтр по фермеру"
            className="w-full rounded-md border border-slate-300 px-3 py-1.5 text-sm"
            value={filter.farmer_id || ''}
            onChange={(e) => setFilter({ ...filter, farmer_id: e.target.value || undefined })}
          />
        </div>
        <div className="flex-1">
          <label className="mb-1 block text-xs font-medium text-slate-700">ID Магазина</label>
          <input
            type="text"
            placeholder="Фильтр по магазину"
            className="w-full rounded-md border border-slate-300 px-3 py-1.5 text-sm"
            value={filter.shop_id || ''}
            onChange={(e) => setFilter({ ...filter, shop_id: e.target.value || undefined })}
          />
        </div>
      </div>

      {/* Table */}
      {isLoading && <div className="text-center text-slate-500">Загрузка...</div>}
      {error && <div className="rounded-lg bg-red-50 p-4 text-sm text-red-700">Ошибка загрузки данных</div>}
      {data && (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">ID</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Фермер</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Магазин</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Сумма</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Статус</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Создан</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Действия</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
              {data.items.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-slate-500">
                    Заказы не найдены
                  </td>
                </tr>
              ) : (
                data.items.map((order) => (
                  <tr key={order.id}>
                    <td className="px-4 py-3 font-mono text-xs">{order.id.substring(0, 8)}...</td>
                    <td className="px-4 py-3 font-mono text-xs">{order.farmer_id.substring(0, 8)}...</td>
                    <td className="px-4 py-3 font-mono text-xs">{order.shop_id.substring(0, 8)}...</td>
                    <td className="px-4 py-3 font-medium">{formatPrice(order.total_amount)} сум</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${STATUS_COLORS[order.status]}`}>
                        {STATUS_LABELS[order.status]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-500">{formatDate(order.created_at)}</td>
                    <td className="px-4 py-3">
                      <select
                        value={order.status}
                        onChange={(e) => {
                          updateStatusMutation.mutate({
                            id: order.id,
                            status: e.target.value as Order['status'],
                          });
                        }}
                        className="rounded-md border border-slate-300 px-2 py-1 text-xs"
                        disabled={updateStatusMutation.isPending}
                      >
                        {Object.entries(STATUS_LABELS).map(([value, label]) => (
                          <option key={value} value={value}>
                            {label}
                          </option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {data && data.total > 0 && (
        <div className="text-sm text-slate-600">
          Всего: {data.total} заказов
        </div>
      )}
    </section>
  );
}

