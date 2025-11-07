import { Outlet } from 'react-router-dom';

export function AuthLayout() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-light to-primary">
      <div className="w-full max-w-md rounded-xl bg-white shadow-lg p-8">
        <Outlet />
      </div>
    </div>
  );
}
