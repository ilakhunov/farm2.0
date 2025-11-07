import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';

import { productsApi } from '../lib/api-client';

const STATUS_COLORS: Record<string, string> = {
  available: 'bg-emerald-100 text-emerald-700',
  unavailable: 'bg-slate-100 text-slate-700',
};

export function ProductsPage() {
  const queryClient = useQueryClient();
  const [filter, setFilter] = useState<{ category?: string; farmer_id?: string }>({});

  const { data, isLoading, error } = useQuery({
    queryKey: ['products', filter],
    queryFn: () => productsApi.list({ limit: 50, ...filter }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => productsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
  });

  const formatDate = (dateStr: string) => {
    return new Date(dateStr).toLocaleDateString('ru-RU');
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('ru-RU').format(price);
  };

  return (
    <section className="space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-slate-900">Товары</h2>
          <p className="text-sm text-slate-500">Управление каталогом товаров фермеров</p>
        </div>
      </header>

      {/* Filters */}
      <div className="flex gap-4 rounded-lg border border-slate-200 bg-white p-4">
        <div className="flex-1">
          <label className="mb-1 block text-xs font-medium text-slate-700">Категория</label>
          <input
            type="text"
            placeholder="Фильтр по категории"
            className="w-full rounded-md border border-slate-300 px-3 py-1.5 text-sm"
            value={filter.category || ''}
            onChange={(e) => setFilter({ ...filter, category: e.target.value || undefined })}
          />
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
      </div>

      {/* Table */}
      {isLoading && <div className="text-center text-slate-500">Загрузка...</div>}
      {error && <div className="rounded-lg bg-red-50 p-4 text-sm text-red-700">Ошибка загрузки данных</div>}
      {data && (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Название</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Категория</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Цена</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Количество</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Статус</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Создан</th>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">Действия</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
              {data.items.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-slate-500">
                    Товары не найдены
                  </td>
                </tr>
              ) : (
                data.items.map((product) => (
                  <tr key={product.id}>
                    <td className="px-4 py-3 font-medium">{product.name}</td>
                    <td className="px-4 py-3">{product.category}</td>
                    <td className="px-4 py-3">{formatPrice(product.price)} сум / {product.unit}</td>
                    <td className="px-4 py-3">{product.quantity}</td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                          STATUS_COLORS[product.is_available ? 'available' : 'unavailable']
                        }`}
                      >
                        {product.is_available ? 'Доступен' : 'Недоступен'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-500">{formatDate(product.created_at)}</td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => {
                          if (confirm('Удалить товар?')) {
                            deleteMutation.mutate(product.id);
                          }
                        }}
                        className="text-xs text-red-600 hover:text-red-800"
                        disabled={deleteMutation.isPending}
                      >
                        Удалить
                      </button>
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
          Всего: {data.total} товаров
        </div>
      )}
    </section>
  );
}

