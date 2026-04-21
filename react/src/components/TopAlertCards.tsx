import { FIXED_TRUCK_NAME } from '../constants';
import type { AlertCard } from '../types';

const badgeStyle = {
  warning: 'bg-amber-100 text-amber-600',
  danger: 'bg-red-100 text-red-600',
  info: 'bg-sky-100 text-sky-600'
};

const labels = {
  warning: '주의',
  danger: '위험',
  info: '정보'
};

export default function TopAlertCards({ alerts }: { alerts: AlertCard[] }) {
  return (
    <div className="flex gap-4 overflow-x-auto pb-2 scrollbar-hide">
      {alerts.map((alert, index) => (
        <div 
          key={alert.id} 
          className="min-w-[280px] max-w-[280px] rounded-[1.5rem] bg-slate-800/90 backdrop-blur-sm p-5 border border-slate-700 shadow-lg"
        >
          <div className="flex items-center justify-between mb-3">
            <span className={`rounded-full px-3 py-0.5 text-[10px] font-bold ${badgeStyle[alert.level]}`}>
              {labels[alert.level]}
            </span>
            <span className="text-[10px] text-slate-400 font-medium">방금 전</span>
          </div>
          <div className="text-[11px] font-bold text-slate-300 mb-1">{FIXED_TRUCK_NAME}</div>
          <h3 className="text-sm font-bold text-white leading-tight mb-4 line-clamp-1">{alert.title}</h3>
          <div className="text-[10px] text-slate-400 flex items-center gap-1">
            <span className="inline-block w-1 h-1 rounded-full bg-slate-500" />
            최근 위치 수신됨
          </div>
        </div>
      ))}
    </div>
  );
}
