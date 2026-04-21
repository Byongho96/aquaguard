import { MapContainer, TileLayer, Marker, useMap } from 'react-leaflet';
import { useEffect } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { MousePointer2, MapPinOff } from 'lucide-react';
import { FIXED_TRUCK_NAME } from '../constants';
import { useAppContext } from '../context/AppContext';

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

interface TruckMapCardProps {
  position: [number, number];
  isAbnormal: boolean;
}

export default function TruckMapCard({ position, isAbnormal }: TruckMapCardProps) {
  const { isGpsValid } = useAppContext();

  return (
    <div className="relative rounded-[2rem] bg-white border border-slate-100 shadow-sm overflow-hidden flex flex-col">
      <div className="p-6 flex items-center justify-between">
        <h2 className="text-lg font-bold text-slate-800">라이브 맵</h2>
      </div>
      
      <div className="flex-1 h-[500px] relative">
        <MapContainer center={position} zoom={13} zoomControl={false} scrollWheelZoom={false} className="h-full w-full">
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

        {/* Custom Overlay Popup */}
        {isGpsValid && (
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-[120%] z-[1000] pointer-events-none transition-all duration-500">
            <div className="bg-white/95 backdrop-blur shadow-2xl rounded-[1.5rem] p-4 w-48 border border-white">
              <div className="flex items-center justify-center mb-2">
                <span className={`${isAbnormal ? 'bg-red-500' : 'bg-green-500'} text-white text-[10px] font-bold px-2 py-0.5 rounded-full`}>
                  {isAbnormal ? '위험' : '정상'}
                </span>
              </div>
              <div className="text-center">
                <div className="text-xs font-bold text-slate-800 mb-0.5">{FIXED_TRUCK_NAME}</div>
                <div className={`text-[10px] font-bold ${isAbnormal ? 'text-red-500' : 'text-green-500'} mb-2`}>
                  {isAbnormal ? '수조 이상 감지' : '안전 운행 중'}
                </div>
                <button className="text-[9px] text-slate-400 underline decoration-slate-200">자세한 위치 보기</button>
              </div>
            </div>
            <div className="w-4 h-4 bg-white rotate-45 mx-auto -mt-2 shadow-xl" />
          </div>
        )}

        <div className="absolute bottom-6 right-6 z-[1000]">
          <div className="bg-slate-900 text-white p-2 rounded-full shadow-lg">
            <MousePointer2 size={16} />
          </div>
        </div>
      </div>
    </div>
  );
}
