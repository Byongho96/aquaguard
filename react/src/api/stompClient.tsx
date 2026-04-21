import { Client, IMessage, StompSubscription } from '@stomp/stompjs';
import React, { useEffect, useRef } from 'react';
import { DEFAULT_WS_URL } from '../constants';
import type { GpsPosition, SensorDataRealtime, TankStatus, SensorType, SensorRange } from '../types';
import { getTanks, getSensorRange } from './axios';
import { useAppContext } from '../context/AppContext';

const SENSOR_IDS: SensorType[] = ['temperature', 'do', 'salt', 'ntu'];

export function StompProvider({ children }: { children: React.ReactNode }) {
  const { tanks, setTanks, setGpsData, setConnected, updateTankData } = useAppContext();
  const clientRef = useRef<Client | null>(null);
  const subscriptionsRef = useRef<StompSubscription[]>([]);

  useEffect(() => {
    const initData = async () => {
      try {
        const { tanks: tankList } = await getTanks();
        const initialTanks: Record<string, TankStatus> = {};

        for (const t of tankList) {
          const ranges: Partial<Record<SensorType, SensorRange>> = {};
          for (const sId of SENSOR_IDS) {
            ranges[sId] = await getSensorRange(t.tankId, sId);
          }
          
          initialTanks[t.tankId] = {
            tankId: t.tankId,
            data: { temperature: 0, do: 0, salt: 0, ntu: 0 },
            ranges: ranges as Record<SensorType, SensorRange>,
            isAbnormal: false
          };
        }
        setTanks(initialTanks);
      } catch (error) {
        console.error('Failed to initialize tank data:', error);
      }
    };

    initData();
  }, [setTanks]);

  useEffect(() => {
    const client = new Client({
      brokerURL: DEFAULT_WS_URL,
      reconnectDelay: 5000,
      heartbeatIncoming: 10000,
      heartbeatOutgoing: 10000,
      debug: (message: string) => {
        if (message.startsWith('WebSocket connection closed')) {
          setConnected(false);
        }
      }
    });

    client.onConnect = () => {
      setConnected(true);

      const subs: StompSubscription[] = [];

      // Subscribe to GPS
      subs.push(
        client.subscribe('/topic/trucks/gps', (message: IMessage) => {
          try {
            const payload = JSON.parse(message.body) as GpsPosition;
            setGpsData({ ...payload, updatedAt: new Date().toISOString() });
          } catch (error) {
            console.error('Failed to parse GPS message:', error);
          }
        })
      );

      // Subscribe to each tank's realtime data
      Object.keys(tanks).forEach(tankId => {
        subs.push(
          client.subscribe(`/topic/tanks/${tankId}/realtime`, (message: IMessage) => {
            try {
              const payload = JSON.parse(message.body) as SensorDataRealtime;
              updateTankData(tankId, payload);
            } catch (error) {
              console.error(`Failed to parse realtime message for tank ${tankId}:`, error);
            }
          })
        );
      });

      subscriptionsRef.current = subs;
    };

    client.onStompError = (frame) => {
      console.error('STOMP error:', frame.headers['message']);
      setConnected(false);
    };

    client.onWebSocketError = (event) => {
      console.error('WebSocket error:', event);
      setConnected(false);
    };

    if (Object.keys(tanks).length > 0) {
      client.activate();
      clientRef.current = client;
    }

    return () => {
      subscriptionsRef.current.forEach((subscription) => subscription.unsubscribe());
      client.deactivate();
    };
  }, [Object.keys(tanks).length, setConnected, setGpsData, updateTankData]);

  return <>{children}</>;
}

// Keeping useStompClientContext for backward compatibility if needed, but it should be replaced by useAppContext
export function useStompClientContext() {
  const context = useAppContext();
  return {
    ...context,
    client: null // If direct client access is needed, we can add it to context, but instruction says use only for connection and subscription
  };
}
