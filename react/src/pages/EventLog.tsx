import { useMemo, useState } from 'react';
import { Phone, Search, Edit3, Wind, Thermometer, Clock } from 'lucide-react';
import type { EventLogEntry } from '../types';
import { useAppContext } from '../context/AppContext';

const statusStyles = {
  warning: 'bg-amber-100 text-amber-600',
  danger: 'bg-red-100 text-red-600',
  normal: 'bg-slate-100 text-slate-400'
};

const statusLabels = {
  warning: '주의',
  danger: '위험',
  normal: '정상'
};

export default function EventLog() {
  const { eventLogs } = useAppContext();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [filter, setFilter] = useState<'yesterday' | 'today' | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const filteredEvents = useMemo(() => {
    let result = [...eventLogs];
    
    // Filter by date
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const yesterday = today - 24 * 60 * 60 * 1000;

    if (filter === 'today') {
      result = result.filter(e => new Date(e.timestamp).getTime() >= today);
    } else if (filter === 'yesterday') {
      result = result.filter(e => {
        const time = new Date(e.timestamp).getTime();
        return time >= yesterday && time < today;
      });
    }

    // Filter by search
    if (searchQuery) {
      result = result.filter(e => 
        e.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        e.affected.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    return result;
  }, [eventLogs, filter, searchQuery]);

  // Use the first filtered event if none selected or if selected is not in filtered results
  const effectiveSelectedId = selectedId && filteredEvents.find(e => `${e.id}-${e.timestamp}` === selectedId) 
    ? selectedId 
    : (filteredEvents.length > 0 ? `${filteredEvents[0].id}-${filteredEvents[0].timestamp}` : null);

  const selected = useMemo(() => 
    filteredEvents.find((item) => `${item.id}-${item.timestamp}` === effectiveSelectedId), 
    [filteredEvents, effectiveSelectedId]
  );

  const formatTimestamp = (iso: string) => {
    const d = new Date(iso);
    return `${d.getFullYear()}. ${String(d.getMonth() + 1).padStart(2, '0')}. ${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  };

  return (
    <div className="grid gap-8 lg:grid-cols-[1fr_440px]">
      <div className="flex flex-col gap-6">
        <div className="rounded-[2rem] bg-white border border-slate-100 shadow-sm overflow-hidden">
          <div className="p-8 border-b border-slate-50">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-slate-800">사건 로그</h2>
              <div className="flex items-center gap-2">
                <div className="flex rounded-lg bg-slate-100 p-1 text-[11px] font-bold">
                  <button 
                    onClick={() => setFilter('yesterday')}
                    className={`px-3 py-1 rounded-md transition-all ${filter === 'yesterday' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400'}`}
                  >
                    어제
                  </button>
                  <button 
                    onClick={() => setFilter('today')}
                    className={`px-3 py-1 rounded-md transition-all ${filter === 'today' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400'}`}
                  >
                    오늘
                  </button>
                  <button 
                    onClick={() => setFilter('all')}
                    className={`px-3 py-1 rounded-md transition-all ${filter === 'all' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400'}`}
                  >
                    전체
                  </button>
                </div>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-300" size={14} />
                  <input 
                    type="text" 
                    placeholder="검색..." 
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-9 pr-4 py-1.5 rounded-lg bg-slate-50 border border-slate-100 text-[11px] focus:outline-none w-48"
                  />
                </div>
              </div>
            </div>
          </div>

          <div className="divide-y divide-slate-50">
            {filteredEvents.length > 0 ? (
              filteredEvents.map((event) => {
                const uniqueId = `${event.id}-${event.timestamp}`;
                return (
                  <button
                    key={uniqueId}
                    onClick={() => setSelectedId(uniqueId)}
                    className={`w-full flex items-center justify-between p-8 transition-colors ${
                      effectiveSelectedId === uniqueId ? 'bg-slate-50/50' : 'hover:bg-slate-50/30'
                    }`}
                  >
                    <div className="flex items-center gap-8">
                      <span className={`px-3 py-1 rounded-full text-[10px] font-bold whitespace-nowrap ${statusStyles[event.status]}`}>
                        {statusLabels[event.status]}
                      </span>
                      <div className="text-left">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-sm font-bold text-slate-800">{event.id}</span>
                          <span className="text-[11px] text-slate-400 font-medium">{event.subtitle}</span>
                        </div>
                        <div className="text-sm font-bold text-slate-600">{event.title} - {event.affected}</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-[10px] text-slate-300 font-medium flex items-center gap-1 justify-end">
                        <Clock size={10} /> {formatTimestamp(event.timestamp)}
                      </div>
                    </div>
                  </button>
                );
              })
            ) : (
              <div className="p-20 text-center text-slate-400 text-sm">
                기록된 사건이 없습니다.
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="space-y-6">
        {selected ? (
          <div className="rounded-[2rem] bg-white border border-slate-100 p-8 shadow-sm">
            <div className="flex items-center justify-between mb-8">
              <div>
                <div className="text-xl font-bold text-slate-900">{selected.id}</div>
                <div className="text-sm font-bold text-slate-600 mt-2">{selected.title}</div>
                <div className="text-[11px] text-slate-400 font-medium mt-1">{selected.subtitle.split(' - ')[0]}</div>
              </div>
              <span className={`px-3 py-1 rounded-full text-[10px] font-bold ${statusStyles[selected.status]}`}>
                {statusLabels[selected.status]}
              </span>
            </div>

            <button className="w-full flex items-center justify-center gap-2 bg-slate-800 text-white py-4 rounded-[1.5rem] font-bold text-sm mb-10 hover:bg-slate-700 transition-colors">
              <Phone size={18} /> 전화하기
            </button>

            <div className="space-y-6">
              <h3 className="text-xs font-bold text-slate-400">이상 수조 실시간 ({selected.affected})</h3>
              
              <div className="relative h-28 rounded-2xl bg-orange-500 overflow-hidden p-4 text-white shadow-lg shadow-orange-100">
                <div className="relative z-10">
                  <div className="text-[10px] font-bold opacity-80 mb-1">[{selected.affected}]</div>
                  <div className="text-2xl font-black">경고<span className="text-sm font-normal ml-1">상태</span></div>
                </div>
                <Wind className="absolute right-4 top-4 opacity-20" size={32} />
                <div className="absolute bottom-0 left-0 w-full h-1/2 bg-gradient-to-t from-white/10 to-transparent" />
                <div className="absolute bottom-0 left-0 w-full h-12 flex items-end opacity-30">
                  {[40, 70, 45, 90, 65, 80, 50, 85, 45, 75].map((h, i) => (
                    <div key={i} className="flex-1 bg-white" style={{ height: `${h}%`, margin: '0 1px' }} />
                  ))}
                </div>
              </div>
            </div>

            <div className="mt-10 pt-8 border-t border-slate-50">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">메모</h3>
                <Edit3 size={14} className="text-slate-300" />
              </div>
              <textarea 
                placeholder="내용을 작성해주세요." 
                className="w-full bg-slate-50 rounded-xl p-4 text-xs text-slate-400 border-none focus:ring-0 resize-none h-24"
              />
            </div>
          </div>
        ) : (
          <div className="rounded-[2rem] bg-white border border-slate-100 p-8 shadow-sm flex items-center justify-center h-40 text-slate-400 text-sm">
            사건을 선택해주세요.
          </div>
        )}
      </div>
    </div>
  );
}
