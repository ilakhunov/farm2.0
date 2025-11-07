import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';

import { ordersApi, deliveriesApi, Delivery } from '../lib/api-client';

const STATUS_LABELS: Record<Delivery['status'], string> = {
  pending: 'Ожидает',
  assigned: 'Назначен',
  picked_up: 'Забран',
  in_transit: 'В пути',
  delivered: 'Доставлен',
  failed: 'Не удалось',
};

export function DeliveriesPage() {
  const queryClient = useQueryClient();
  const [selectedOrderId, setSelectedOrderId] = useState<string>('');
  const [driverName, setDriverName] = useState('');
  const [driverPhone, setDriverPhone] = useState('');

  // Fetch orders to select from
  const { data: ordersData } = useQuery({
    queryKey: ['orders', {}],
    queryFn: () => ordersApi.list({ limit: 100 }),
  });

  // Fetch delivery for selected order
  const { data: deliveryData, isLoading, error } = useQuery({
    queryKey: ['delivery', selectedOrderId],
    queryFn: () => deliveriesApi.getByOrder(selectedOrderId),
    enabled: !!selectedOrderId,
  });

  const updateMutation = useMutation({
    mutationFn: (data: Parameters<typeof deliveriesApi.update>[1]) =>
      deliveriesApi.update(selectedOrderId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['delivery', selectedOrderId] });
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

  const handleUpdate = () => {
    if (!selectedOrderId) return;
    updateMutation.mutate({
      status: deliveryData?.status || 'pending',
      driver_name: driverName || undefined,
      driver_phone: driverPhone || undefined,
    });
  };

  return (
    <section className="space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-semibold text-slate-900">Доставки</h2>
          <p className="text-sm text-slate-500">Управление доставками заказов</p>
        </div>
      </header>

      {/* Order Selector */}
      <div className="rounded-lg border border-slate-200 bg-white p-4">
        <label className="mb-2 block text-sm font-medium text-slate-700">Выберите заказ</label>
        <select
          className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
          value={selectedOrderId}
          onChange={(e) => {
            setSelectedOrderId(e.target.value);
            setDriverName('');
            setDriverPhone('');
          }}
        >
          <option value="">-- Выберите заказ --</option>
          {ordersData?.items.map((order) => (
            <option key={order.id} value={order.id}>
              Заказ #{order.id.substring(0, 8)} - {formatPrice(order.total_amount)} сум - {order.status}
            </option>
          ))}
        </select>
      </div>

      {/* Delivery Info */}
      {isLoading && <div className="text-center text-slate-500">Загрузка...</div>}
      {error && <div className="rounded-lg bg-red-50 p-4 text-sm text-red-700">Ошибка загрузки данных</div>}
      {deliveryData && (
        <div className="space-y-4">
          <div className="rounded-lg border border-slate-200 bg-white p-6">
            <h3 className="mb-4 text-lg font-semibold">Информация о доставке</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-700">Статус</label>
                <select
                  className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                  value={deliveryData.status}
                  onChange={(e) => {
                    updateMutation.mutate({ status: e.target.value as Delivery['status'] });
                  }}
                  disabled={updateMutation.isPending}
                >
                  {Object.entries(STATUS_LABELS).map(([value, label]) => (
                    <option key={value} value={value}>
                      {label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-700">Адрес доставки</label>
                <div className="rounded-md border border-slate-300 bg-slate-50 px-3 py-2 text-sm">
                  {deliveryData.delivery_address || 'Не указан'}
                </div>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-700">Имя водителя</label>
                <input
                  type="text"
                  className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                  value={driverName || deliveryData.driver_name || ''}
                  onChange={(e) => setDriverName(e.target.value)}
                  placeholder="Введите имя водителя"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-700">Телефон водителя</label>
                <input
                  type="tel"
                  className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm"
                  value={driverPhone || deliveryData.driver_phone || ''}
                  onChange={(e) => setDriverPhone(e.target.value)}
                  placeholder="+998901234567"
                />
              </div>
              {deliveryData.estimated_delivery_at && (
                <div>
                  <label className="mb-1 block text-xs font-medium text-slate-700">Ожидаемая доставка</label>
                  <div className="rounded-md border border-slate-300 bg-slate-50 px-3 py-2 text-sm">
                    {formatDate(deliveryData.estimated_delivery_at)}
                  </div>
                </div>
              )}
              {deliveryData.delivered_at && (
                <div>
                  <label className="mb-1 block text-xs font-medium text-slate-700">Доставлен</label>
                  <div className="rounded-md border border-slate-300 bg-slate-50 px-3 py-2 text-sm">
                    {formatDate(deliveryData.delivered_at)}
                  </div>
                </div>
              )}
            </div>
            <div className="mt-4">
              <button
                onClick={handleUpdate}
                disabled={updateMutation.isPending}
                className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-primary-dark disabled:opacity-60"
              >
                {updateMutation.isPending ? 'Сохранение...' : 'Сохранить изменения'}
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}

