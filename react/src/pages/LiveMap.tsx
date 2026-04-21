import { useMemo, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Phone, Battery, MapPinOff } from 'lucide-react';
import SensorGrid from '../components/SensorGrid';
import { useGpsTracker } from '../hooks/useGpsTracker';
import { useAppContext } from '../context/AppContext';
import { FIXED_TRUCK_NAME } from '../constants';

const markerIcon = new L.Icon({
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41]
});

function ChangeView({ center }: { center: [number, number] }) {
  const map = useMap();
  useEffect(() => {
    map.setView(center);
  }, [center, map]);
  return null;
}

export default function LiveMap() {
  const { position } = useGpsTracker();
  const { tanks, isGpsValid } = useAppContext();

  const center = useMemo(() => position, [position]);
  const isAnyAbnormal = Object.values(tanks).some(t => t.isAbnormal);

  return (
    <div className="grid gap-8 lg:grid-cols-[1fr_440px]">
      {/* Left Panel: Map */}
      <div className="rounded-[2rem] bg-white border border-slate-100 p-6 shadow-sm h-fit">
        <h2 className="text-lg font-bold text-slate-800 mb-6">라이브 맵</h2>
        <div className="relative h-[600px] overflow-hidden rounded-[1.5rem]">
          <MapContainer center={center} zoom={15} zoomControl={false} className="h-full w-full">
            <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" />
            {isGpsValid && (
              <>
                <ChangeView center={position} />
                <Marker position={position} icon={markerIcon} />
              </>
            )}
          </MapContainer>

          {/* GPS Invalid Overlay */}
          {!isGpsValid && (
            <div className="absolute inset-0 bg-slate-100/50 backdrop-blur-[2px] z-[1001] flex items-center justify-center">
              <div className="bg-white p-6 rounded-[1.5rem] shadow-xl text-center border border-slate-100">
                <MapPinOff size={40} className="mx-auto text-slate-300 mb-4" />
                <div className="text-sm font-bold text-slate-800 mb-1">GPS 신호 없음</div>
                <div className="text-xs text-slate-400">해당 차량의 실시간 위치를 확인할 수 없습니다.</div>
              </div>
            </div>
          )}

          {/* No GPS Trucks List (Top Left) */}
          {!isGpsValid && (
            <div className="absolute top-4 left-4 z-[1002] pointer-events-none">
              <div className="bg-slate-900/80 backdrop-blur-md p-4 rounded-2xl border border-white/10 shadow-2xl">
                <div className="text-[10px] font-bold text-white/40 uppercase tracking-widest mb-2">GPS 미수신 차량</div>
                <div className="flex items-center gap-2">
                  <div className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />
                  <div className="text-xs font-bold text-white">{FIXED_TRUCK_NAME}</div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Right Panel: Detailed Info Boxes */}
      <div className="flex flex-col gap-4">
        {/* Box 1: Truck Info */}
        <div className="rounded-[2rem] bg-white border border-slate-100 p-8 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-baseline gap-3">
              <h2 className="text-xl font-bold text-slate-900">{FIXED_TRUCK_NAME}</h2>
              <p className="text-[10px] text-slate-400 font-medium whitespace-nowrap">마지막 업데이트: 방금 전</p>
            </div>
            <div className="flex items-center gap-2">
              <span className={`${isAnyAbnormal ? 'bg-red-500' : 'bg-green-500'} text-white text-[10px] font-bold px-3 py-1 rounded-full`}>
                {isAnyAbnormal ? '위험' : '정상'}
              </span>
              <div className="text-slate-300"><Battery size={20} /></div>
            </div>
          </div>
        </div>

        {/* Box 2: Call Button */}
        <div className="px-0">
          <button className="w-full flex items-center justify-center gap-2 bg-slate-800 text-white py-4 rounded-[1.5rem] font-bold text-sm hover:bg-slate-700 transition-colors shadow-lg shadow-slate-200">
            <Phone size={18} /> 전화하기
          </button>
        </div>

        {/* Box 3: Tank Info (Sensor Grids) */}
        <div className="rounded-[2rem] bg-white border border-slate-100 p-8 shadow-sm flex-1">
          <div className="space-y-10">
            {Object.values(tanks).map(tank => (
              <SensorGrid 
                key={tank.tankId} 
                tankLabel={`수조 ${tank.tankId}`} 
                sensorData={tank.data} 
                ranges={tank.ranges}
              />
            ))}
          </div>
        </div>

        {/* Box 4: Vehicle List */}
        <div className="rounded-[2rem] bg-white border border-slate-100 p-8 shadow-sm">
          <h3 className="text-sm font-bold text-slate-800 mb-6 uppercase tracking-wider">전체 차량 목록</h3>
          <div className="grid grid-cols-1 gap-4">
            <div className="flex items-center justify-between p-4 rounded-2xl border border-slate-50 bg-slate-50/50">
              <div className="flex items-center gap-3">
                <div className={`w-2 h-2 rounded-full ${isAnyAbnormal ? 'bg-red-500' : 'bg-green-500'}`} />
                <div className="text-xs font-bold text-slate-700">{FIXED_TRUCK_NAME}</div>
              </div>
              <Battery size={16} className="text-slate-300" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
