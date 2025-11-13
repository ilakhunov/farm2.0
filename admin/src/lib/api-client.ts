import axios, { AxiosError } from 'axios';

import { clearAuth, getAccessToken } from './auth-storage';

export const apiClient = axios.create({
  baseURL: __API_BASE_URL__,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: false,
});

// Add token to requests
apiClient.interceptors.request.use(
  (config) => {
    const token = getAccessToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Handle 401 errors
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      clearAuth();
      if (window.location.pathname !== '/') {
        window.location.href = '/';
      }
    }
    return Promise.reject(error);
  },
);

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  refresh_expires_in: number;
}

export interface AuthUser {
  id: string;
  phone_number: string;
  role: 'farmer' | 'shop' | 'admin';
  entity_type?: string | null;
  tax_id?: string | null;
  legal_name?: string | null;
  is_verified: boolean;
}

export interface AuthResponse {
  token: AuthTokens;
  user: AuthUser;
}

export interface SendOtpPayload {
  phone_number: string;
  role?: string;
  entity_type?: string;
}

export interface VerifyOtpPayload extends SendOtpPayload {
  code: string;
  tax_id?: string;
  legal_name?: string;
  legal_address?: string;
  bank_account?: string;
  email?: string;
}

export interface LoginPayload {
  username: string;
  password: string;
}

export const authApi = {
  async login(payload: LoginPayload) {
    const response = await apiClient.post<AuthResponse>('/auth/login', payload);
    return response.data;
  },
  async sendOtp(payload: SendOtpPayload) {
    const response = await apiClient.post<{ message: string; debug?: { otp?: string } }>(
      '/auth/send-otp',
      payload,
    );
    return response.data;
  },
  async verifyOtp(payload: VerifyOtpPayload) {
    const response = await apiClient.post<AuthResponse>('/auth/verify-otp', payload);
    return response.data;
  },
};

// Products API
export interface Product {
  id: string;
  farmer_id: string;
  name: string;
  description?: string | null;
  category: string;
  price: number;
  quantity: number;
  unit: string;
  image_url?: string | null;
  is_active: boolean;
  is_available?: boolean; // Legacy field
  created_at: string;
  updated_at: string;
}

export interface ProductsResponse {
  items: Product[];
  total: number;
  limit: number;
  offset: number;
}

export interface ProductCreate {
  name: string;
  description?: string;
  category: string;
  price: number;
  quantity: number;
  unit: string;
  image_url?: string;
}

export interface ProductUpdate {
  name?: string;
  description?: string;
  category?: string;
  price?: number;
  quantity?: number;
  unit?: string;
  image_url?: string;
  is_active?: boolean;
}

export const productsApi = {
  async list(params?: { limit?: number; offset?: number; category?: string; farmer_id?: string; search?: string }) {
    const response = await apiClient.get<ProductsResponse>('/products', { params });
    return response.data;
  },
  async get(id: string) {
    const response = await apiClient.get<Product>(`/products/${id}`);
    return response.data;
  },
  async create(data: ProductCreate) {
    const response = await apiClient.post<Product>('/products', data);
    return response.data;
  },
  async update(id: string, data: ProductUpdate) {
    const response = await apiClient.patch<Product>(`/products/${id}`, data);
    return response.data;
  },
  async delete(id: string) {
    await apiClient.delete(`/products/${id}`);
  },
};

// Orders API
export interface OrderItem {
  id: string;
  product_id: string;
  quantity: number;
  price: number;
  product?: Product;
}

export interface Order {
  id: string;
  shop_id: string;
  farmer_id: string;
  status: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  total_amount: number;
  delivery_address?: string | null;
  notes?: string | null;
  created_at: string;
  updated_at: string;
  items: OrderItem[];
}

export interface OrdersResponse {
  items: Order[];
  total: number;
  limit: number;
  offset: number;
}

export const ordersApi = {
  async list(params?: { limit?: number; offset?: number; status?: string; farmer_id?: string; shop_id?: string }) {
    const response = await apiClient.get<OrdersResponse>('/orders', { params });
    return response.data;
  },
  async get(id: string) {
    const response = await apiClient.get<Order>(`/orders/${id}`);
    return response.data;
  },
  async updateStatus(id: string, status: Order['status']) {
    const response = await apiClient.patch<Order>(`/orders/${id}`, { status });
    return response.data;
  },
};

// Deliveries API
export interface Delivery {
  id: string;
  order_id: string;
  status: 'pending' | 'assigned' | 'in_transit' | 'delivered' | 'failed' | 'cancelled';
  delivery_address: string;
  courier_name?: string | null;
  courier_phone?: string | null;
  tracking_number?: string | null;
  estimated_delivery?: string | null;
  delivered_at?: string | null;
  notes?: string | null;
  created_at: string;
  updated_at: string;
  order?: Order;
}

export const deliveriesApi = {
  async getByOrder(orderId: string) {
    const response = await apiClient.get<Delivery>(`/deliveries/order/${orderId}`);
    return response.data;
  },
  async update(orderId: string, data: Partial<Pick<Delivery, 'status' | 'courier_name' | 'courier_phone' | 'estimated_delivery' | 'tracking_number' | 'notes'>>) {
    const response = await apiClient.patch<Delivery>(`/deliveries/order/${orderId}`, data);
    return response.data;
  },
};

// Users API
export interface User {
  id: string;
  phone_number: string;
  role: 'farmer' | 'shop' | 'admin';
  entity_type?: string | null;
  tax_id?: string | null;
  legal_name?: string | null;
  legal_address?: string | null;
  bank_account?: string | null;
  email?: string | null;
  is_verified: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export const usersApi = {
  async getMe() {
    const response = await apiClient.get<User>('/users/me');
    return response.data;
  },
  async updateMe(data: Partial<Pick<User, 'legal_name' | 'legal_address' | 'bank_account' | 'email'>>) {
    const response = await apiClient.patch<User>('/users/me', data);
    return response.data;
  },
  async list(params?: { role?: 'farmer' | 'shop' | 'admin'; limit?: number; offset?: number }) {
    try {
      const response = await apiClient.get<User[]>('/users', { params });
      return response.data;
    } catch (error: any) {
      // If endpoint doesn't exist or user is not admin, return empty list
      if (error.response?.status === 403 || error.response?.status === 404) {
        return [];
      }
      throw error;
    }
  },
};
