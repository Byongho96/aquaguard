import { useEffect } from 'react';
import { useStompClientContext } from '../api/stompClient';

export function useStompSubscription(topic: string, callback: (payload: unknown) => void) {
  const { client, connected } = useStompClientContext();

  useEffect(() => {
    if (!client || !connected) {
      return;
    }

    const subscription = client.subscribe(topic, (message) => {
      try {
        const payload = JSON.parse(message.body);
        callback(payload);
      } catch {
        // ignore invalid payload
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [client, connected, topic, callback]);
}
