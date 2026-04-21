import { Routes, Route, Navigate } from 'react-router-dom';
import { AppProvider } from './context/AppContext';
import { StompProvider } from './api/stompClient';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import LiveMap from './pages/LiveMap';
import EventLog from './pages/EventLog';

import { FIXED_TRUCK_NAME } from './constants';

function Header() {
  return (
    <header className="mb-6 overflow-hidden rounded-[2rem] bg-gradient-to-br from-slate-700 via-slate-800 to-slate-900 p-5 shadow-2xl relative">
      <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-10"></div>
      <div className="relative flex flex-col justify-between gap-3 sm:flex-row sm:items-center px-2">
        <div>
          <p className="text-[10px] font-medium text-slate-400 uppercase tracking-wider">Live Monitoring System</p>
          <h1 className="mt-1 text-sm font-normal text-slate-200">현재 {FIXED_TRUCK_NAME}가 안전하게 운행중입니다</h1>
        </div>
        <div className="text-right">
          <h2 className="text-xl font-black tracking-tighter text-white italic">AQUAGUARD LIVE</h2>
        </div>
      </div>
    </header>
  );
}

function App() {
  return (
    <AppProvider>
      <StompProvider>
        <div className="min-h-screen bg-[#F8F9FA] text-slate-900">
          <div className="flex min-h-screen">
            <Sidebar />
            <main className="flex-1 ml-20 p-4 sm:p-6 lg:p-8 max-w-[1600px] mx-auto w-full transition-all duration-300">
              <Header />
              <Routes>
                <Route path="/dashboard" element={<Dashboard />} />
                <Route path="/live-map" element={<LiveMap />} />
                <Route path="/event-log" element={<EventLog />} />
                <Route path="*" element={<Navigate to="/dashboard" replace />} />
              </Routes>
            </main>
          </div>
        </div>
      </StompProvider>
    </AppProvider>
  );
}

export default App;
