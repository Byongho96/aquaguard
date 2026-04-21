import { Link, useLocation } from 'react-router-dom';
import { LayoutGrid, Map, FileText, Truck, Activity, Settings, User } from 'lucide-react';

const items = [
  { label: 'Dashboard', icon: LayoutGrid, path: '/dashboard' },
  { label: 'Live Map', icon: Map, path: '/live-map' },
  { label: 'Event Log', icon: FileText, path: '/event-log' }
];

export default function Sidebar() {
  const location = useLocation();

  return (
    <aside className="fixed left-0 top-0 z-50 flex h-full w-20 flex-col bg-white border-r border-slate-100 py-6">
      <div className="mb-10 flex flex-col items-center gap-1 px-4">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-black">
          <div className="h-4 w-4 rounded-full bg-white" />
        </div>
        <div className="flex h-4 w-4 rounded-full bg-black -mt-2 ml-4 border-2 border-white" />
      </div>
      
      <div className="flex flex-1 flex-col items-center gap-4 px-3">
        {items.map((item) => {
          const Icon = item.icon;
          const active = location.pathname === item.path;
          return (
            <Link
              key={item.label}
              to={item.path}
              className={`flex h-12 w-12 items-center justify-center rounded-2xl transition-all duration-200 ${
                active ? 'bg-slate-900 text-white shadow-md' : 'text-slate-400 hover:bg-slate-50 hover:text-slate-600'
              }`}
            >
              <Icon size={20} strokeWidth={active ? 2.5 : 2} />
            </Link>
          );
        })}
      </div>

      <div className="flex flex-col items-center gap-4 px-3">
        <button className="flex h-12 w-12 items-center justify-center rounded-2xl text-slate-400 hover:bg-slate-50 hover:text-slate-600">
          <Settings size={20} />
        </button>
        <button className="flex h-12 w-12 items-center justify-center rounded-2xl text-slate-400 hover:bg-slate-50 hover:text-slate-600">
          <User size={20} />
        </button>
      </div>
    </aside>
  );
}
