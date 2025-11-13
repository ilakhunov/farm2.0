import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { AxiosError } from 'axios';

import { authApi } from '../lib/api-client';
import { saveAuth } from '../lib/auth-storage';

interface LoginFormValues {
  username: string;
  password: string;
}

export function LoginPage() {
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const { register, handleSubmit, formState } = useForm<LoginFormValues>({
    defaultValues: { username: '', password: '' },
  });

  const extractErrorMessage = (error: unknown): string => {
    if (error instanceof AxiosError) {
      const detail = (error.response?.data as { detail?: string })?.detail;
      return detail ?? error.message;
    }
    if (error instanceof Error) {
      return error.message;
    }
    return 'Произошла ошибка';
  };

  const onSubmit = async (values: LoginFormValues) => {
    setIsSubmitting(true);
    setErrorMessage(null);
    try {
      const auth = await authApi.login({
        username: values.username.trim(),
        password: values.password,
      });
      saveAuth(auth.token, auth.user.role);
      navigate('/app');
    } catch (error) {
      const message = extractErrorMessage(error);
      setErrorMessage(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-12 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-bold tracking-tight text-slate-900">
            Вход в админ панель
          </h2>
          <p className="mt-2 text-center text-sm text-slate-600">
            Введите логин и пароль для доступа
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit(onSubmit)}>
          <div className="space-y-4 rounded-md shadow-sm">
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-slate-700">
                Логин
              </label>
              <input
                {...register('username', {
                  required: 'Введите логин',
                  minLength: { value: 3, message: 'Логин должен быть не менее 3 символов' },
                })}
                id="username"
                type="text"
                autoComplete="username"
                className="mt-1 block w-full rounded-md border border-slate-300 px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary sm:text-sm"
                placeholder="Введите логин"
                disabled={isSubmitting}
              />
              {formState.errors.username && (
                <p className="mt-1 text-sm text-red-600">{formState.errors.username.message}</p>
              )}
            </div>
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-slate-700">
                Пароль
              </label>
              <input
                {...register('password', {
                  required: 'Введите пароль',
                  minLength: { value: 6, message: 'Пароль должен быть не менее 6 символов' },
                })}
                id="password"
                type="password"
                autoComplete="current-password"
                className="mt-1 block w-full rounded-md border border-slate-300 px-3 py-2 text-slate-900 placeholder-slate-400 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary sm:text-sm"
                placeholder="Введите пароль"
                disabled={isSubmitting}
              />
              {formState.errors.password && (
                <p className="mt-1 text-sm text-red-600">{formState.errors.password.message}</p>
              )}
            </div>
          </div>

          {errorMessage && (
            <div className="rounded-md bg-red-50 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <svg className="h-5 w-5 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <div className="ml-3">
                  <p className="text-sm font-medium text-red-800">{errorMessage}</p>
                </div>
              </div>
            </div>
          )}

          <div>
            <button
              type="submit"
              disabled={isSubmitting}
              className="group relative flex w-full justify-center rounded-md border border-transparent bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? 'Вход...' : 'Войти'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
