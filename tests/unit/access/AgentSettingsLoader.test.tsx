import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { act, render } from '@testing-library/react';

const api = vi.hoisted(() => ({ fetchOrgSettings: vi.fn() }));
vi.mock('@/services/settings/orgSettingsService', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/services/settings/orgSettingsService')>();
  return { ...actual, fetchOrgSettings: () => api.fetchOrgSettings() };
});

import {
  AGENT_SETTINGS_RETRY_DELAYS_MS,
  AgentSettingsLoader,
} from '@/components/access/TenantGate';
import { useAgentSettingsStore } from '@/hooks/useAgentSettingsStore';
import { OrgSettingsError } from '@/services/settings/orgSettingsService';
import { TIMMIE_AGENT } from '@/utils/agentSettings';

const CONTOSO_BOT = { kind: 'custom', name: 'Contoso Bot' } as const;
const settings = { agent: CONTOSO_BOT, canEdit: false, canSave: true };

/** Lets the load's promise chain settle, then moves the clock on by ms */
async function wait(ms: number) {
  await act(async () => {
    await Promise.resolve();
    await vi.advanceTimersByTimeAsync(ms);
  });
}

describe('AgentSettingsLoader', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    api.fetchOrgSettings.mockReset();
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    useAgentSettingsStore.setState({
      agent: TIMMIE_AGENT,
      canEdit: false,
      canSave: true,
      loaded: false,
      loadError: null,
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('retries a failed load, spaced out, until it succeeds', async () => {
    api.fetchOrgSettings
      .mockRejectedValueOnce(new OrgSettingsError('Settings are unavailable right now (503).'))
      .mockRejectedValueOnce(new OrgSettingsError('Settings are unavailable right now (503).'))
      .mockResolvedValue(settings);
    render(<AgentSettingsLoader>page</AgentSettingsLoader>);

    await wait(0);
    expect(api.fetchOrgSettings).toHaveBeenCalledTimes(1);
    expect(useAgentSettingsStore.getState().agent).toEqual(TIMMIE_AGENT);

    await wait(AGENT_SETTINGS_RETRY_DELAYS_MS[0]);
    expect(api.fetchOrgSettings).toHaveBeenCalledTimes(2);

    await wait(AGENT_SETTINGS_RETRY_DELAYS_MS[1]);
    expect(api.fetchOrgSettings).toHaveBeenCalledTimes(3);
    expect(useAgentSettingsStore.getState()).toMatchObject({ agent: CONTOSO_BOT, loaded: true });

    // Loaded: no more tries
    await wait(AGENT_SETTINGS_RETRY_DELAYS_MS[2]);
    expect(api.fetchOrgSettings).toHaveBeenCalledTimes(3);
  });

  it('gives up after the last retry, and stops when unmounted', async () => {
    api.fetchOrgSettings.mockRejectedValue(new OrgSettingsError('Settings are unavailable.'));
    const { unmount } = render(<AgentSettingsLoader>page</AgentSettingsLoader>);

    await wait(0);
    for (const delay of AGENT_SETTINGS_RETRY_DELAYS_MS) await wait(delay);
    expect(api.fetchOrgSettings).toHaveBeenCalledTimes(AGENT_SETTINGS_RETRY_DELAYS_MS.length + 1);
    await wait(60_000);
    expect(api.fetchOrgSettings).toHaveBeenCalledTimes(AGENT_SETTINGS_RETRY_DELAYS_MS.length + 1);

    // A fresh mount with a pending retry that is unmounted doesn't fire it
    useAgentSettingsStore.setState({ loaded: false });
    const second = render(<AgentSettingsLoader>page</AgentSettingsLoader>);
    await wait(0);
    const calls = api.fetchOrgSettings.mock.calls.length;
    second.unmount();
    unmount();
    await wait(AGENT_SETTINGS_RETRY_DELAYS_MS[0]);
    expect(api.fetchOrgSettings).toHaveBeenCalledTimes(calls);
  });
});
