import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

vi.mock('@/services/auth/tokenService', () => ({ getIdToken: () => Promise.resolve('id-token') }));

import {
  OrgSettingsError,
  fetchOrgSettings,
  saveAgentSettings,
} from '@/services/settings/orgSettingsService';
import { TIMMIE_AGENT } from '@/utils/agentSettings';

/** What the server answered: a status and, optionally, a JSON body */
function answer(status: number, body?: unknown) {
  return vi.fn().mockResolvedValue(
    new Response(body === undefined ? null : JSON.stringify(body), {
      status,
      headers: { 'content-type': 'application/json' },
    })
  );
}

describe('orgSettingsService', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', answer(200, { agent: TIMMIE_AGENT, canEdit: false, canSave: true }));
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('sends the ID token and reads the settings back', async () => {
    const settings = await fetchOrgSettings();
    expect(settings).toEqual({ agent: TIMMIE_AGENT, canEdit: false, canSave: true });
    const [url, init] = (fetch as ReturnType<typeof vi.fn>).mock.calls[0] as [string, RequestInit];
    expect(url).toBe('/api/org-settings');
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer id-token');
  });

  it("explains a non-admin's refused save by the server's code", async () => {
    vi.stubGlobal('fetch', answer(403, { code: 'not_admin' }));
    await expect(saveAgentSettings({ kind: 'custom', name: 'Contoso Bot' })).rejects.toThrow(
      'Only Timmie administrators can change this.'
    );
  });

  it("doesn't call an unapproved organisation's 403 an admin problem", async () => {
    vi.stubGlobal('fetch', answer(403, {}));
    await expect(fetchOrgSettings()).rejects.toThrow('Settings are unavailable right now (403).');
  });

  it.each([
    [400, { code: 'invalid_agent' }, 'That agent name isn’t valid.'],
    [
      503,
      { code: 'settings_not_configured' },
      'This Timmie server has no settings storage, so it can’t save this.',
    ],
    [503, { code: 'settings_unavailable' }, 'Settings are unavailable right now (503).'],
    [500, undefined, 'Settings are unavailable right now (500).'],
  ])('turns a %s into a message for the admin', async (status, body, message) => {
    vi.stubGlobal('fetch', answer(status, body));
    const failure = saveAgentSettings(TIMMIE_AGENT);
    await expect(failure).rejects.toBeInstanceOf(OrgSettingsError);
    await expect(failure).rejects.toThrow(message);
  });

  it('refuses settings it does not understand', async () => {
    vi.stubGlobal('fetch', answer(200, { agent: { kind: 'robot' } }));
    await expect(fetchOrgSettings()).rejects.toThrow('doesn’t understand');
  });
});
