import axios from 'axios';
import { DEFAULT_API_URL } from '../constants';
import type { ControlState, SensorRange } from '../types';

export const apiClient = axios.create({
  baseURL: DEFAULT_API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

export async function getTanks() {
  const response = await apiClient.get<{ tanks: { tankId: string, sensors: { sensorId: string, state: boolean }[] }[] }>('/tanks');
  return response.data;
}

export async function getSensorRange(tankId: string, sensorId: string) {
  const response = await apiClient.get<SensorRange>(`/tanks/${tankId}/${sensorId}/range`);
  return response.data;
}

export async function getHistory(tankId: string) {
  const response = await apiClient.get<{ temperature: number[], do: number[], salt: number[], ntu: number[] }>(`/tanks/${tankId}/history`);
  return response.data;
}

export async function updateAiEnable(truckId: string, state: boolean) {
  const response = await apiClient.post<{ state: boolean }>(`/tanks/${truckId}/aienable`, { state });
  return response.data;
}

export async function updateSensorRange(tankId: string, sensorId: string, min: number, max: number) {
  const response = await apiClient.post<SensorRange>(`/tanks/${tankId}/${sensorId}/range`, { min, max });
  return response.data;
}

export async function getSensorControlState(tankId: string, sensorId: string) {
  const response = await apiClient.get<ControlState>(`/tanks/${tankId}/${sensorId}/control`);
  return response.data;
}
