import { Thermometer, Waves, Droplet, Wind } from 'lucide-react';
import type { SensorDataRealtime, SensorRange, SensorType } from '../types';

interface SensorGridProps {
  sensorData: SensorDataRealtime;
  ranges: Record<SensorType, SensorRange>;
  tankLabel: string;
}

const sensors = [
  { id: 'temperature' as const, label: '수온', icon: Thermometer, unit: '°C' },
  { id: 'do' as const, label: '용존산소량', icon: Waves, unit: 'mg/L' },
  { id: 'salt' as const, label: 'pH', icon: Droplet, unit: '' },
  { id: 'ntu' as const, label: '탁도', icon: Wind, unit: 'NTU' }
];

export default function SensorGrid({ sensorData, ranges, tankLabel }: SensorGridProps) {
  return (
    <div className="space-y-3">
      <div className="text-sm font-bold text-slate-400">{tankLabel}</div>
      <div className="grid grid-cols-4 gap-2">
        {sensors.map((s) => {
          const Icon = s.icon;
          const value = sensorData[s.id];
          const range = ranges[s.id];
          
          const isWarning = range ? (value < range.min || value > range.max) : false;
          
          return (
            <div 
              key={s.id} 
              className={`flex flex-col items-center justify-center p-3 rounded-2xl transition-all duration-300 ${
                isWarning 
                  ? 'bg-orange-500 text-white shadow-lg shadow-orange-100 scale-[1.02]' 
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              <Icon size={14} className={`mb-2 ${isWarning ? 'opacity-100' : 'opacity-70'}`} />
              <div className="text-[9px] font-bold opacity-70 mb-0.5 whitespace-nowrap">{s.label}</div>
              <div className="text-[11px] font-extrabold whitespace-nowrap">
                {value.toFixed(1)}{s.unit}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
