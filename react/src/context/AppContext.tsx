import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import type { TankStatus, GpsPosition, EventLogEntry, SensorType, SensorRange, SensorDataRealtime } from '../types';
import { FIXED_TRUCK_ID, FIXED_TRUCK_NAME } from '../constants';

interface AppContextValue {
  tanks: Record<string, TankStatus>;
  gpsData: GpsPosition | null;
  eventLogs: EventLogEntry[];
  connected: boolean;
  isGpsValid: boolean;
  setTanks: React.Dispatch<React.SetStateAction<Record<string, TankStatus>>>;
  setGpsData: React.Dispatch<React.SetStateAction<GpsPosition | null>>;
  setConnected: React.Dispatch<React.SetStateAction<boolean>>;
  addEventLog: (entry: Omit<EventLogEntry, 'id' | 'subtitle' | 'timestamp'>) => void;
  updateTankData: (tankId: string, data: SensorDataRealtime) => void;
}

const AppContext = createContext<AppContextValue | undefined>(undefined);

const SENSOR_IDS: SensorType[] = ['temperature', 'do', 'salt', 'ntu'];
const SENSOR_LABELS: Record<SensorType, string> = {
  temperature: '수온',
  do: '용존산소량',
  salt: '염도',
  ntu: '탁도'
};

const GPS_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutes

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [tanks, setTanks] = useState<Record<string, TankStatus>>({});
  const [gpsData, setGpsData] = useState<GpsPosition | null>(null);
  const [connected, setConnected] = useState(false);
  const [eventLogs, setEventLogs] = useState<EventLogEntry[]>([]);
  const [isGpsValid, setIsGpsValid] = useState(false);

  // Check GPS validity every 10 seconds
  useEffect(() => {
    const checkGps = () => {
      if (!gpsData || !gpsData.updatedAt) {
        setIsGpsValid(false);
        return;
      }
      const lastUpdate = new Date(gpsData.updatedAt).getTime();
      const now = new Date().getTime();
      setIsGpsValid(now - lastUpdate < GPS_TIMEOUT_MS);
    };

    checkGps();
    const interval = setInterval(checkGps, 10000);
    return () => clearInterval(interval);
  }, [gpsData]);

  // Load event logs from localStorage on init
  useEffect(() => {
    const savedLogs = localStorage.getItem('eventLogs');
    if (savedLogs) {
      try {
        setEventLogs(JSON.parse(savedLogs));
      } catch (e) {
        console.error('Failed to parse saved event logs', e);
      }
    }
  }, []);

  // Save event logs to localStorage when they change
  useEffect(() => {
    localStorage.setItem('eventLogs', JSON.stringify(eventLogs));
  }, [eventLogs]);

  const addEventLog = useCallback((entry: Omit<EventLogEntry, 'id' | 'subtitle' | 'timestamp'>) => {
    const newEntry: EventLogEntry = {
      ...entry,
      id: 'YJ-2026-016', // Fixed UUID for the truck
      subtitle: `${FIXED_TRUCK_NAME} - 관리자`,
      timestamp: new Date().toISOString(),
    };
    setEventLogs(prev => [newEntry, ...prev]);
  }, []);

  const checkAbnormal = (data: SensorDataRealtime, ranges: Record<SensorType, SensorRange>) => {
    const abnormalSensors: SensorType[] = [];
    SENSOR_IDS.forEach(id => {
      const val = data[id];
      const range = ranges[id];
      if (range && (val < range.min || val > range.max)) {
        abnormalSensors.push(id);
      }
    });
    return abnormalSensors;
  };

  const updateTankData = useCallback((tankId: string, newData: SensorDataRealtime) => {
    setTanks(prev => {
      const currentTank = prev[tankId];
      if (!currentTank) return prev;

      const abnormalSensors = checkAbnormal(newData, currentTank.ranges);
      const isNowAbnormal = abnormalSensors.length > 0;
      
      // If it became abnormal, log it
      if (isNowAbnormal && !currentTank.isAbnormal) {
        const titles = abnormalSensors.map(s => SENSOR_LABELS[s]).join(', ') + ' 이상 감지';
        addEventLog({
          title: titles,
          status: 'danger',
          affected: `수조 ${tankId}`
        });
      }

      return {
        ...prev,
        [tankId]: {
          ...currentTank,
          data: { ...currentTank.data, ...newData },
          isAbnormal: isNowAbnormal
        }
      };
    });
  }, [addEventLog]);

  return (
    <AppContext.Provider value={{ 
      tanks, 
      gpsData, 
      eventLogs, 
      connected, 
      isGpsValid,
      setTanks, 
      setGpsData, 
      setConnected,
      addEventLog,
      updateTankData
    }}>
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useAppContext must be used within an AppProvider');
  }
  return context;
}
