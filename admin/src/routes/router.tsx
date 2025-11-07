import { createBrowserRouter } from 'react-router-dom';

import { ProtectedRoute } from '../components/protected-route';
import { AuthLayout } from '../layouts/auth-layout';
import { DashboardLayout } from '../layouts/dashboard-layout';
import { DeliveriesPage } from '../pages/deliveries-page';
import { LoginPage } from '../pages/login-page';
import { OrdersPage } from '../pages/orders-page';
import { ProductsPage } from '../pages/products-page';
import { UsersPage } from '../pages/users-page';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <AuthLayout />,
    children: [
      { index: true, element: <LoginPage /> },
    ],
  },
  {
    path: '/app',
    element: (
      <ProtectedRoute>
        <DashboardLayout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <UsersPage /> },
      { path: 'products', element: <ProductsPage /> },
      { path: 'orders', element: <OrdersPage /> },
      { path: 'deliveries', element: <DeliveriesPage /> },
    ],
  },
]);
