import { Link, useLocation } from 'react-router-dom';

interface BreadcrumbItem {
  label: string;
  path?: string;
}

export function Breadcrumbs() {
  const location = useLocation();
  const pathnames = location.pathname.split('/').filter((x) => x);

  const breadcrumbMap: Record<string, string> = {
    app: 'Главная',
    products: 'Товары',
    orders: 'Заказы',
    deliveries: 'Доставки',
    users: 'Пользователи',
  };

  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Главная', path: '/app' },
  ];

  let currentPath = '';
  pathnames.forEach((name) => {
    currentPath += `/${name}`;
    if (breadcrumbMap[name]) {
      breadcrumbs.push({
        label: breadcrumbMap[name],
        path: pathnames[pathnames.length - 1] === name ? undefined : currentPath,
      });
    }
  });

  return (
    <nav className="flex mb-4" aria-label="Breadcrumb">
      <ol className="inline-flex items-center space-x-1 md:space-x-3">
        {breadcrumbs.map((crumb, index) => (
          <li key={index} className="inline-flex items-center">
            {index > 0 && (
              <svg
                className="w-6 h-6 text-slate-400"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fillRule="evenodd"
                  d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                  clipRule="evenodd"
                />
              </svg>
            )}
            {crumb.path ? (
              <Link
                to={crumb.path}
                className="inline-flex items-center text-sm font-medium text-slate-700 hover:text-primary transition-colors"
              >
                {crumb.label}
              </Link>
            ) : (
              <span className="ml-1 text-sm font-medium text-slate-500 md:ml-2">
                {crumb.label}
              </span>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}

