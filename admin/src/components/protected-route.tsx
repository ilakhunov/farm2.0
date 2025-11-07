import { Navigate } from 'react-router-dom';

import { getAccessToken } from '../lib/auth-storage';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const token = getAccessToken();
  if (!token) {
    return <Navigate to="/" replace />;
  }
  return <>{children}</>;
}
