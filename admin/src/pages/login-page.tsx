import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { AxiosError } from 'axios';

import { authApi } from '../lib/api-client';
import { saveAuth } from '../lib/auth-storage';

interface LoginFormValues {
  phone: string;
  code?: string;
}

export function LoginPage() {
  const navigate = useNavigate();
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [debugOtp, setDebugOtp] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const { register, handleSubmit, formState, setError } = useForm<LoginFormValues>({
    defaultValues: { phone: '+998' },
  });

  const normalizePhone = (value: string) => {
    const digits = value.replace(/\D/g, '');
    if (digits.length < 9) {
      return null;
    }
    if (digits.startsWith('998') && digits.length === 12) {
      return `+${digits}`;
    }
    if (digits.length === 9) {
      return `+998${digits}`;
    }
    return `+${digits}`;
  };

  const extractErrorMessage = (error: unknown) => {
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
      const phone = normalizePhone(values.phone);
      if (!phone) {
        setError('phone', { type: 'manual', message: 'Введите корректный номер' });
        return;
      }

      if (step === 'phone') {
        const response = await authApi.sendOtp({ phone_number: phone, role: 'admin' });
        setStep('otp');
        setDebugOtp(response.debug?.otp ?? null);
      } else {
        if (!values.code) {
          setError('code', { type: 'manual', message: 'Введите код' });
          return;
        }
        const auth = await authApi.verifyOtp({ phone_number: phone, code: values.code.trim(), role: 'admin' });
        saveAuth(auth.token, auth.user.role);
        navigate('/app');
      }
    } catch (error) {
      const message = extractErrorMessage(error);
      setErrorMessage(message);
      if (step === 'otp') {
        setError('code', { type: 'manual', message });
      } else {
        setError('phone', { type: 'manual', message });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="space-y-2 text-center">
        <h2 className="text-2xl font-semibold text-slate-900">Вход в админку</h2>
        <p className="text-sm text-slate-500">
          Используйте корпоративный номер телефона для входа.
        </p>
      </div>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div className="space-y-1">
          <label className="text-sm font-medium text-slate-700" htmlFor="phone">
            Номер телефона
          </label>
          <input
            id="phone"
            type="tel"
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm shadow-sm focus:border-primary focus:outline-none"
            {...register('phone', {
              required: 'Введите номер телефона',
              minLength: { value: 12, message: 'Минимум 12 символов' },
            })}
            disabled={step === 'otp'}
          />
          {formState.errors.phone && (
            <p className="text-sm text-red-500">{formState.errors.phone.message}</p>
          )}
          {debugOtp && step === 'otp' && (
            <p className="text-xs text-emerald-600">Отладочный код: {debugOtp}</p>
          )}
        </div>

        {step === 'otp' && (
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700" htmlFor="code">
              Код из SMS
            </label>
            <input
              id="code"
              type="text"
              maxLength={6}
              className="w-full rounded-md border border-slate-300 px-3 py-2 text-center text-lg tracking-[0.6em] focus:border-primary focus:outline-none"
              {...register('code', {
                required: 'Введите код',
                minLength: { value: 4, message: 'Некорректный код' },
              })}
            />
            {formState.errors.code && (
              <p className="text-sm text-red-500">{formState.errors.code.message}</p>
            )}
            <button
              type="button"
              className="text-sm text-primary hover:underline"
              onClick={() => setStep('phone')}
            >
              Изменить номер
            </button>
          </div>
        )}

        <button
          type="submit"
          className="flex w-full items-center justify-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary-dark disabled:opacity-60"
          disabled={isSubmitting}
        >
          {isSubmitting ? 'Обработка...' : step === 'phone' ? 'Получить код' : 'Подтвердить'}
        </button>
      </form>

      <div className="rounded-lg bg-slate-50 p-4 text-xs text-slate-500">
        <p className="font-medium text-slate-600">Справка:</p>
        <p>После подтверждения номера откроется панель управления (пользователи, заказы, транзакции).</p>
        <p>Код доступа направляется через GetSMS.
        </p>
        {errorMessage && <p className="mt-2 text-red-500">{errorMessage}</p>}
      </div>
    </div>
  );
}
