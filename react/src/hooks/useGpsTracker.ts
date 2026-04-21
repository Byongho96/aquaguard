import { useMemo } from 'react';
import { useStompClientContext } from '../api/stompClient';

export function useGpsTracker() {
  const { gpsData, connected, lastError } = useStompClientContext();

  return useMemo(() => {
    return {
      gpsData,
      connected,
      lastError,
      position: gpsData
        ? [gpsData.latitude, gpsData.longitude] as [number, number]
        : [35.1796, 129.0756] as [number, number]
    };
  }, [gpsData, connected, lastError]);
}
