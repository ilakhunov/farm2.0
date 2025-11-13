import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';

import { productsApi, Product } from '../lib/api-client';
import { ProductModal } from '../components/product-modal';
import { useToast } from '../hooks/use-toast';

const STATUS_COLORS: Record<string, string> = {
  available: 'bg-emerald-100 text-emerald-700',
  unavailable: 'bg-slate-100 text-slate-700',
};

export function ProductsPage() {
  const queryClient = useQueryClient();
  const [filter, setFilter] = useState<{ category?: string; farmer_id?: string; search?: string }>({});
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [sortBy, setSortBy] = useState<'name' | 'price' | 'quantity' | 'created_at'>('created_at');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const { showToast, ToastComponent } = useToast();

  const { data, isLoading, error } = useQuery({
    queryKey: ['products', filter, sortBy, sortOrder],
    queryFn: () => productsApi.list({ limit: 50, ...filter }),
    select: (data) => {
      if (!data) return data;
      const sorted = [...data.items];
      sorted.sort((a, b) => {
        let comparison = 0;
        switch (sortBy) {
          case 'name':
            comparison = a.name.localeCompare(b.name);
            break;
          case 'price':
            comparison = a.price - b.price;
            break;
          case 'quantity':
            comparison = a.quantity - b.quantity;
            break;
          case 'created_at':
            comparison = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
            break;
        }
        return sortOrder === 'asc' ? comparison : -comparison;
      });
      return { ...data, items: sorted };
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => productsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      showToast('Товар успешно удален', 'success');
    },
    onError: (error: any) => {
      showToast(error.response?.data?.detail || 'Ошибка при удалении товара', 'error');
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
        <button
          onClick={() => {
            setEditingProduct(null);
            setIsModalOpen(true);
          }}
          className="flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90"
        >
          <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Создать товар
        </button>
      </header>

      {/* Filters */}
      <div className="flex gap-4 rounded-lg border border-slate-200 bg-white p-4">
        <div className="flex-1">
          <label className="mb-1 block text-xs font-medium text-slate-700">Поиск</label>
          <input
            type="text"
            placeholder="Поиск по названию..."
            className="w-full rounded-md border border-slate-300 px-3 py-1.5 text-sm"
            value={filter.search || ''}
            onChange={(e) => setFilter({ ...filter, search: e.target.value || undefined })}
          />
        </div>
        <div className="flex-1">
          <label className="mb-1 block text-xs font-medium text-slate-700">Категория</label>
          <select
            className="w-full rounded-md border border-slate-300 px-3 py-1.5 text-sm"
            value={filter.category || ''}
            onChange={(e) => setFilter({ ...filter, category: e.target.value || undefined })}
          >
            <option value="">Все категории</option>
            <option value="vegetables">Овощи</option>
            <option value="fruits">Фрукты</option>
            <option value="grains">Зерновые</option>
            <option value="dairy">Молочные продукты</option>
            <option value="meat">Мясо</option>
            <option value="other">Другое</option>
          </select>
        </div>
        <div className="flex items-end">
          <button
            onClick={() => setFilter({})}
            className="rounded-md border border-slate-300 px-4 py-1.5 text-sm text-slate-700 hover:bg-slate-50"
          >
            Сбросить
          </button>
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
                          STATUS_COLORS[(product.is_active ?? product.is_available) ? 'available' : 'unavailable']
                        }`}
                      >
                        <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${
                          (product.is_active ?? product.is_available) ? 'bg-emerald-500' : 'bg-slate-400'
                        }`}></span>
                        {(product.is_active ?? product.is_available) ? 'Доступен' : 'Недоступен'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-500">{formatDate(product.created_at)}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => {
                            setEditingProduct(product);
                            setIsModalOpen(true);
                          }}
                          className="text-xs text-blue-600 hover:text-blue-800"
                        >
                          Редактировать
                        </button>
                        <span className="text-slate-300">|</span>
                        <button
                          onClick={() => {
                            if (confirm('Удалить товар?')) {
                              deleteMutation.mutate(product.id);
                            }
                          }}
                          className="text-xs text-red-600 hover:text-red-800"
                          disabled={deleteMutation.isPending}
                        >
                          {deleteMutation.isPending ? 'Удаление...' : 'Удалить'}
                        </button>
                      </div>
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

      <ProductModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setEditingProduct(null);
        }}
        onSuccess={() => {
          queryClient.invalidateQueries({ queryKey: ['products'] });
          showToast(editingProduct ? 'Товар успешно обновлен' : 'Товар успешно создан', 'success');
        }}
        product={editingProduct}
      />
      {ToastComponent}
    </section>
  );
}

