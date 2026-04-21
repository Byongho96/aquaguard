export type SensorType = 'temperature' | 'do' | 'salt' | 'ntu';

export interface SensorDataRealtime {
  temperature: number;
  do: number;
  salt: number;
  ntu: number;
}

export interface GpsPosition {
  truckId: string;
  latitude: number;
  longitude: number;
  altitude?: number;
  updatedAt: string;
}

export interface ControlState {
  state: boolean;
}

export interface SensorRange {
  min: number;
  max: number;
}

export interface EventLogEntry {
  id: string;
  title: string;
  subtitle: string;
  status: 'warning' | 'danger' | 'normal';
  timestamp: string;
  affected: string;
}

export interface TankStatus {
  tankId: string;
  data: SensorDataRealtime;
  ranges: Record<SensorType, SensorRange>;
  isAbnormal: boolean;
}

export interface TankSummary {
  tankId: string;
  sensors: {
    sensorId: string;
    state: boolean;
  }[];
}
