'use client';

import { useEffect, type ReactNode } from 'react';
import { useAgentSettingsStore } from '@/hooks/useAgentSettingsStore';
import { SignInExpired } from '@/components/layout/SignInExpired';
import { NotApprovedPage } from './NotApprovedPage';
import { useTenantAccess } from './useTenantAccess';

/**
 * Only organisations KnowAll has approved can use Timmie. Wraps everything a signed-in
 * user sees under a company, so nothing loads from Business Central (not even the
 * company list) until their organisation (the `tid` claim) is approved. Everyone else
 * gets the "not set up yet" page. Per-user rules (company access, permissions) still
 * apply inside it.
 */
export function TenantGate({ children }: { children: ReactNode }) {
  const { status, tenantId, email, retry } = useTenantAccess();

  if (status === 'approved') return <AgentSettingsLoader>{children}</AgentSettingsLoader>;

  if (status === 'denied' || status === 'signed-out') {
    return <NotApprovedPage tenantId={tenantId} email={email} />;
  }

  if (status === 'reauth') return <SignInExpired />;

  if (status === 'error') {
    return <NotApprovedPage tenantId={tenantId} email={email} onRetry={retry} />;
  }

  return (
    <div className="bg-dark-950 flex min-h-screen items-center justify-center" role="status">
      <div className="border-brand h-8 w-8 animate-spin rounded-full border-b-2" />
      <span className="text-dark-400 ml-3 text-sm">Checking your organisation...</span>
    </div>
  );
}

/** How long to wait before each retry of a failed settings load (then it gives up) */
export const AGENT_SETTINGS_RETRY_DELAYS_MS = [5_000, 15_000, 45_000];

/**
 * Loads the organisation's agent settings once it's approved; renders its children at once.
 * A failed load (a blip at start-up) is retried a few times, spaced out, so people who never
 * open Settings don't stay on Timmie's agent for the session. After that, Settings has Try again.
 */
export function AgentSettingsLoader({ children }: { children: ReactNode }) {
  const load = useAgentSettingsStore((state) => state.load);
  useEffect(() => {
    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const attempt = (retry: number) => {
      void load().then(() => {
        if (cancelled || useAgentSettingsStore.getState().loaded) return;
        const delay = AGENT_SETTINGS_RETRY_DELAYS_MS[retry];
        if (delay !== undefined) timer = setTimeout(() => attempt(retry + 1), delay);
      });
    };
    attempt(0);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [load]);
  return <>{children}</>;
}
