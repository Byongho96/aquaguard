import { useState } from 'react';
import { CheckCircle2, AlertTriangle, AlertCircle, MapPin } from 'lucide-react';
import { FIXED_TRUCK_NAME } from '../constants';

const statusConfig = {
  정상: { label: '정상', color: 'text-green-600 bg-green-50', icon: CheckCircle2 },
  주의: { label: '주의', color: 'text-amber-600 bg-amber-50', icon: AlertTriangle },
  위험: { label: '위험', color: 'text-red-600 bg-red-50', icon: AlertCircle }
};

interface VehicleListProps {
  status: '정상' | '주의' | '위험';
  position: string | null;
}

export default function VehicleList({ status, position }: VehicleListProps) {
  const [activeTab, setActiveTab] = useState<'all' | 'normal' | 'warning'>('all');
  const config = statusConfig[status];

  // Logic to determine if the vehicle should be shown in the current tab
  const shouldShow = () => {
    if (activeTab === 'all') return true;
    if (activeTab === 'normal' && status === '정상') return true;
    if (activeTab === 'warning' && (status === '주의' || status === '위험')) return true;
    return false;
  };
  
  return (
    <div className="flex flex-col h-[600px] rounded-[2rem] bg-white border border-slate-100 shadow-sm overflow-hidden">
      <div className="p-6 pb-2">
        <h2 className="text-lg font-bold text-slate-800 mb-4">차량 목록</h2>
        <div className="flex gap-2 overflow-x-auto pb-4 scrollbar-hide text-[11px] font-bold text-slate-400">
          <button 
            onClick={() => setActiveTab('all')}
            className={`px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap ${activeTab === 'all' ? 'bg-slate-50 text-slate-800' : 'hover:bg-slate-50'}`}
          >
            전체 차량
          </button>
          <button 
            onClick={() => setActiveTab('normal')}
            className={`px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap ${activeTab === 'normal' ? 'bg-slate-50 text-slate-800' : 'hover:bg-slate-50'}`}
          >
            정상 차량
          </button>
          <button 
            onClick={() => setActiveTab('warning')}
            className={`px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap ${activeTab === 'warning' ? 'bg-slate-50 text-slate-800' : 'hover:bg-slate-50'}`}
          >
            주의 차량
          </button>
        </div>
      </div>
      
      <div className="flex-1 overflow-y-auto px-6 py-2 space-y-4">
        {shouldShow() ? (
          <div className="p-6 rounded-[1.5rem] border border-slate-50 bg-slate-50/30">
            <div className="flex items-center justify-between mb-6">
              <div>
                <div className="text-base font-bold text-slate-800">{FIXED_TRUCK_NAME}</div>
                <div className="text-xs text-slate-400 font-medium italic mt-0.5 tracking-tight">Real-time tracking</div>
              </div>
              <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] font-bold ${config.color}`}>
                {config.label}
              </div>
            </div>
            
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-slate-500">
                <MapPin size={16} />
                <div className="text-xs font-medium tracking-tighter">
                  {position ? position : <span className="text-slate-300">GPS 정보 없음</span>}
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="h-full flex flex-col items-center justify-center text-slate-300 py-10">
            <div className="text-[11px] font-medium">해당하는 차량이 없습니다.</div>
          </div>
        )}
      </div>
      
      <div className="p-6 bg-slate-50/50 text-[11px] font-medium text-slate-400 border-t border-slate-50">
        총 {shouldShow() ? 1 : 0}대
      </div>
    </div>
  );
}
