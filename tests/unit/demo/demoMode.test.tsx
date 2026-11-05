import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { render, renderHook, screen } from '@testing-library/react';

const msal = vi.hoisted(() => ({
  acquireTokenSilent: vi.fn().mockResolvedValue({ accessToken: 'real-token' }),
  getActiveAccount: vi.fn(() => ({ homeAccountId: 'real', username: 'someone@example.com' })),
}));

vi.mock('@/services/auth/msalInstance', () => ({
  msalInstance: {
    acquireTokenSilent: msal.acquireTokenSilent,
    getActiveAccount: msal.getActiveAccount,
    acquireTokenRedirect: vi.fn(),
  },
  initializeMsal: vi.fn().mockResolvedValue(undefined),
}));

import {
  DEMO_ACCESS_TOKEN,
  DEMO_COMPANY_ID,
  DEMO_ENVIRONMENT,
  DEMO_FLAG_KEY,
  DEMO_USER,
  canStartDemo,
  clearDemoState,
  enableDemoMode,
  isDemoCompany,
  isDemoMode,
  watchForStaleDemoPage,
} from '@/services/demo/demoMode';
import { appStorage } from '@/services/demo/demoStorage';
import { resetDemoBcServer } from '@/services/demo/demoBcServer';
import { getBCAccessToken, getGraphAccessToken } from '@/services/auth/tokenService';
import { getIdToken } from '@/services/auth/tokenService';
import { getLicenceToken } from '@/services/auth/licenceService';
import { AuthenticatedTemplate, UnauthenticatedTemplate, useAuth } from '@/services/auth';
import { bcClient } from '@/services/bc/bcClient';

describe('demo mode switch', () => {
  beforeEach(() => {
    sessionStorage.clear();
    resetDemoBcServer();
    vi.clearAllMocks();
  });

  afterEach(() => {
    sessionStorage.clear();
    vi.unstubAllGlobals();
  });

  it('is off until switched on for the tab, and exiting clears everything it kept', () => {
    expect(isDemoMode()).toBe(false);
    sessionStorage.setItem('unrelated', 'kept');

    expect(enableDemoMode()).toBe(true);
    expect(isDemoMode()).toBe(true);
    appStorage().setItem('timmie-settings-storage', '{}');

    clearDemoState();
    expect(isDemoMode()).toBe(false);
    expect(sessionStorage.getItem(DEMO_FLAG_KEY)).toBeNull();
    expect(sessionStorage.length).toBe(1);
    expect(sessionStorage.getItem('unrelated')).toBe('kept');
  });

  it("can't start when the browser blocks session storage", () => {
    const original = Object.getOwnPropertyDescriptor(window, 'sessionStorage');
    Object.defineProperty(window, 'sessionStorage', {
      configurable: true,
      get() {
        throw new Error('blocked');
      },
    });
    try {
      expect(canStartDemo()).toBe(false);
      expect(enableDemoMode()).toBe(false);
      expect(isDemoMode()).toBe(false);
    } finally {
      if (original) Object.defineProperty(window, 'sessionStorage', original);
      else delete (window as { sessionStorage?: Storage }).sessionStorage;
    }
  });

  it("can't start when session storage is readable but refuses writes", () => {
    const setItem = vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('quota', 'QuotaExceededError');
    });
    try {
      expect(canStartDemo()).toBe(false);
      expect(enableDemoMode()).toBe(false);
    } finally {
      setItem.mockRestore();
    }
    expect(sessionStorage.length).toBe(0);
  });

  it('reloads a page the browser brings back after the demo was left', () => {
    const reload = vi.fn();
    const restored = () => {
      const event = new Event('pageshow');
      Object.defineProperty(event, 'persisted', { value: true });
      window.dispatchEvent(event);
    };
    enableDemoMode();
    const stop = watchForStaleDemoPage(reload);

    // Still in the demo: nothing to do
    restored();
    expect(reload).not.toHaveBeenCalled();

    // "Sign in" or "Exit demo" cleared the flag, then Back brought the page back
    clearDemoState();
    restored();
    expect(reload).toHaveBeenCalledTimes(1);

    stop();
    restored();
    expect(reload).toHaveBeenCalledTimes(1);
  });

  it('reloads a page loaded outside the demo, or in an earlier demo, when brought back', () => {
    const restored = () => {
      const event = new Event('pageshow');
      Object.defineProperty(event, 'persisted', { value: true });
      window.dispatchEvent(event);
    };
    // A real page, then "Try the demo" in the same tab, then Back
    const realReload = vi.fn();
    const stopReal = watchForStaleDemoPage(realReload);
    restored();
    expect(realReload).not.toHaveBeenCalled();
    enableDemoMode();
    restored();
    expect(realReload).toHaveBeenCalledTimes(1);
    stopReal();

    // Demo A's page, then exit and start demo B, then Back to A
    const demoReload = vi.fn();
    const stopDemo = watchForStaleDemoPage(demoReload);
    restored();
    expect(demoReload).not.toHaveBeenCalled();
    clearDemoState();
    enableDemoMode();
    restored();
    expect(demoReload).toHaveBeenCalledTimes(1);
    stopDemo();
  });

  it('recognises the demo company in a link', () => {
    expect(isDemoCompany(DEMO_COMPANY_ID.toUpperCase())).toBe(true);
    expect(isDemoCompany('00000000-0000-0000-0000-000000000001')).toBe(false);
  });

  it("keeps the demo's preferences out of localStorage", () => {
    enableDemoMode();
    appStorage().setItem('timmie_selected_company_id', DEMO_COMPANY_ID);
    expect(window.localStorage.setItem).not.toHaveBeenCalled();
    expect(appStorage().getItem('timmie_selected_company_id')).toBe(DEMO_COMPANY_ID);

    clearDemoState();
    expect(appStorage()).toBe(window.localStorage);
  });

  it('never asks Microsoft Entra for a token in the demo', async () => {
    enableDemoMode();
    expect(await getBCAccessToken()).toBe(DEMO_ACCESS_TOKEN);
    expect(await getGraphAccessToken()).toBeNull();
    expect(await getIdToken()).toBeNull();
    expect(await getLicenceToken()).toBeNull();
    expect(msal.acquireTokenSilent).not.toHaveBeenCalled();
  });

  it('uses the real sign-in outside the demo', async () => {
    expect(await getBCAccessToken()).toBe('real-token');
    expect(msal.acquireTokenSilent).toHaveBeenCalled();
  });

  it('answers Business Central calls in the browser in the demo, sending nothing', async () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    enableDemoMode();
    bcClient.setCompany(DEMO_COMPANY_ID, DEMO_ENVIRONMENT);

    const projects = await bcClient.getProjects();
    const resource = await bcClient.getResourceByEmail(DEMO_USER.username);

    expect(projects.map((p) => p.displayName)).toContain('ERP Rollout Phase 2');
    expect(resource?.name).toBe(DEMO_USER.name);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('goes to Business Central as usual outside the demo', async () => {
    const fetchSpy = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      headers: new Headers(),
      json: async () => ({ value: [] }),
    });
    vi.stubGlobal('fetch', fetchSpy);

    await bcClient.getCompanies();

    expect(fetchSpy).toHaveBeenCalledWith(
      expect.stringContaining('api.businesscentral.dynamics.com'),
      expect.anything()
    );
  });

  it('signs in the fictional demo user, without touching the Microsoft account', () => {
    enableDemoMode();
    const { result } = renderHook(() => useAuth());
    expect(result.current.isAuthenticated).toBe(true);
    expect(result.current.account?.username).toBe(DEMO_USER.username);

    render(
      <>
        <AuthenticatedTemplate>signed in</AuthenticatedTemplate>
        <UnauthenticatedTemplate>signed out</UnauthenticatedTemplate>
      </>
    );
    expect(screen.getByText('signed in')).toBeInTheDocument();
    expect(screen.queryByText('signed out')).toBeNull();
  });

  it('leaves the real sign-in state alone outside the demo', () => {
    const { result } = renderHook(() => useAuth());
    expect(result.current.isAuthenticated).toBe(false);
    expect(result.current.account).toBeNull();
  });
});
