'use client';

import { useSyncExternalStore } from 'react';
import { canStartDemo, isDemoMode } from './demoMode';

const subscribe = () => () => {};

/**
 * Demo mode for components. It only changes with a full page load, so there's nothing to
 * subscribe to; the server render is never the demo.
 */
export function useIsDemoMode(): boolean {
  return useSyncExternalStore(subscribe, isDemoMode, () => false);
}

/** Whether the demo can run in this browser (see canStartDemo); the server assumes it can */
export function useCanStartDemo(): boolean {
  return useSyncExternalStore(subscribe, canStartDemo, () => true);
}
