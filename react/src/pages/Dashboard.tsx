import { BellRing } from 'lucide-react';
import { useStompClientContext } from '../api/stompClient';
import { FIXED_TRUCK_ID, FIXED_TRUCK_NAME } from '../constants';
import TopAlertCards from '../components/TopAlertCards';
import VehicleList from '../components/VehicleList';
import TruckMapCard from '../components/TruckMapCard';
import type { AlertCard } from '../types';

export default function Dashboard() {
  const { gpsData, tanks } = useStompClientContext();

  const alerts: AlertCard[] = Object.values(tanks)
    .filter(tank => tank.isAbnormal)
    .map(tank => ({
      id: `TANK-${tank.tankId}`,
      title: `수조 ${tank.tankId} 이상 감지`,
      description: '센서 수치가 설정 범위를 벗어났습니다.',
      level: 'danger' as const
    }));

  const isAnyAbnormal = Object.values(tanks).some(t => t.isAbnormal);

  return (
    <div className="space-y-6">
      <section className="rounded-[2rem] bg-white border border-slate-100 p-6 shadow-sm overflow-hidden">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-slate-800">알림</h2>
          <div className="flex items-center gap-2 text-xs text-slate-400">
            <BellRing size={14} /> 실시간 알림 활성화
          </div>
        </div>
        <div className="w-full">
          <TopAlertCards alerts={alerts.length > 0 ? alerts : [{ id: 'OK', title: '모든 수조 정상', description: '현재 모든 센서가 정상 범위 내에 있습니다.', level: 'info' as const }]} />
        </div>
      </section>

      <div className="grid gap-8 lg:grid-cols-[440px_1fr]">
        <VehicleList status={isAnyAbnormal ? '위험' : '정상'} position={gpsData ? `${gpsData.latitude.toFixed(6)}, ${gpsData.longitude.toFixed(6)}` : null} />
        <TruckMapCard position={gpsData ? [gpsData.latitude, gpsData.longitude] : [35.1796, 129.0756]} isAbnormal={isAnyAbnormal} />
      </div>
    </div>
  );
}
